#ifndef SKIN_LIGHTING_INCLUDED
#define SKIN_LIGHTING_INCLUDED


struct SurfaceOutputSkin {
    half3 Albedo;
    half3 Normal;
    half3 Emission;
    half Metallic;
    half Smoothness;
    half Occlusion;
    half Alpha;

    half Specular;
    half Curve;
    half Thickness;
    half Translucency;
};

// sampler2D _KelemenLUT; // TODO
sampler2D _SkinLUT;
sampler2D _TranslucencyLUT;

float CaculateCurve(float3 worldNormal, float3 worldPos) {
    return length(fwidth(worldNormal)) / length(fwidth(worldPos));
}

half FresnelReflectance(half3 H, half3 V, half F0) {
    half base = 1.0 - dot(V, H);
    half exponential = pow(base, 5.0);
    return exponential + F0 * (1.0 - exponential);
} 

half PHBeckmann(half ndoth, half m) {
    half alpha = acos(ndoth);
    half ta = tan(alpha);
    half val = 1.0 / (m * m * pow(ndoth, 4.0)) * exp(-(ta * ta) / (m * m));
    return val;
}

half3 PreintegratedDiffuse(half NdotL, half curve) {
    return tex2D(_SkinLUT, half2(NdotL * 0.5 + 0.5, curve)).rgb;
}

half SpecularBRDF(half3 normal, half3 lightDir, half3 viewDir, half roughness) {
    // Kelemen and Szirmay-Kalos specular BRDF
    // D: Beckmann
    // G: Simplification of the Cook-Torrance

    half3 halfDir = lightDir + viewDir;
    half G = rcp(dot(halfDir, halfDir)); // Simplify from `G_original / (4 * NdotL * NdotV)`

    halfDir = normalize(halfDir);
    half NdotH = dot(halfDir, normal);
    half D = PHBeckmann(NdotH, roughness);
    half F = FresnelReflectance(halfDir, viewDir, 0.028);

    return max(D * G * F, 0);
}

half3 Transmittance (half3 normal, half3 lightDir, half d) {
    half irradiance = max(0.3 + dot(-normal, lightDir), 0.0);
    return tex2D(_TranslucencyLUT, half2(d, 0)).rgb * irradiance;
}

inline half4 LightingSkin (SurfaceOutputSkin s, float3 viewDir, UnityGI gi) {
    s.Normal = normalize(s.Normal);

    half oneMinusReflectivity;
    half3 specColor;
    s.Albedo = DiffuseAndSpecularFromMetallic (s.Albedo, s.Metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

    half outputAlpha;
    s.Albedo = PreMultiplyAlpha (s.Albedo, s.Alpha, oneMinusReflectivity, /*out*/ outputAlpha);

    // -- lighting --
    half NdotL = saturate(dot(gi.light.dir, s.Normal));
    half roughness = max(0.02, (1 - s.Smoothness) * (1 - s.Smoothness));

    half3 diffuseTerm = PreintegratedDiffuse(NdotL, s.Curve);
    half3 transmitTerm = Transmittance(s.Normal, gi.light.dir, s.Thickness) * s.Translucency;
    half3 specularTerm = SpecularBRDF(s.Normal, gi.light.dir, viewDir, roughness) * NdotL * s.Specular;

    half3 diffuse = gi.light.color * NdotL;
    half3 c = s.Albedo * (gi.light.color * (diffuseTerm + transmitTerm) + gi.indirect.diffuse);
    c += specColor * gi.light.color * specularTerm;

    return half4(c, outputAlpha);
}

inline void LightingSkin_GI (SurfaceOutputSkin s, UnityGIInput data, inout UnityGI gi) {
    #if defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
    gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal);
    #else
    Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.Smoothness, data.worldViewDir, s.Normal, lerp(unity_ColorSpaceDielectricSpec.rgb, s.Albedo, s.Metallic));
    gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal, g);
    #endif
}

#endif // SKIN_LIGHTING_INCLUDED