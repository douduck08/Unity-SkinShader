Shader "Skin/Pre-integrated Skin (Fixed Curve)"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _KelemenLUT ("Kelemen LUT", 2D) = "white" {}

        [Header(Scattering)]
        _SkinLUT ("Skin LUT", 2D) = "white" {}
        _Scattering ("Scattering", Range(0,1)) = 1.0
        _Curve ("Curve", Range(0,1)) = 1.0

        [Header(Translucency)]
        _TranslucencyLUT ("Translucency LUT", 2D) = "white" {}
        _Thickness ("Thickness", Range(0,1)) = 1.0
        _Translucency ("Translucency", Range(0,1)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Skin fullforwardshadows
        #pragma target 3.0

        #include "UnityPBSLighting.cginc"

        struct Input {
            float2 uv_MainTex;
            float3 worldPos;
            float3 worldNormal;
        };

        struct SurfaceOutputSkin {
            half3 Albedo;
            half3 Normal;
            half3 Emission;
            half Metallic;
            half Smoothness;
            half Occlusion;
            half Alpha;

            float3 worldNormal;
            float3 worldPos;
        };
        
        sampler2D _MainTex;
        half4 _Color;
        half _Glossiness;
        half _Metallic;

        sampler2D _KelemenLUT;
        sampler2D _SkinLUT;
        half _Scattering;
        half _Curve;

        sampler2D _TranslucencyLUT;
        half _Thickness;
        half _Translucency;

        void surf (Input IN, inout SurfaceOutputSkin o) {
            half4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
            o.Emission = 0;
            o.Occlusion = 1;

            o.worldNormal = IN.worldNormal;
            o.worldPos = IN.worldPos;
        }

        inline half4 LightingSkin (SurfaceOutputSkin s, float3 viewDir, UnityGI gi) {
            s.Normal = normalize(s.Normal);

            half oneMinusReflectivity;
            half3 specColor;
            s.Albedo = DiffuseAndSpecularFromMetallic (s.Albedo, s.Metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

            half outputAlpha;
            s.Albedo = PreMultiplyAlpha (s.Albedo, s.Alpha, oneMinusReflectivity, /*out*/ outputAlpha);

            // half4 c = UNITY_BRDF_PBS (s.Albedo, specColor, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, gi.light, gi.indirect);
            half4 c = 0;
            c.a = outputAlpha;

            // Skin Shading
            float NdotL = dot(gi.light.dir, s.Normal);
            // float curve = length(fwidth(s.worldNormal)) / length(fwidth(s.worldPos));
            half4 lutDiffuse = tex2D (_SkinLUT, float2(NdotL * 0.5 + 0.5, _Curve));
            c.rgb = lutDiffuse.rgb * s.Albedo * _Scattering;

            float3 halfDir = normalize(gi.light.dir + viewDir);
            float NdotH = dot(halfDir, s.Normal);
            half3 specular = pow(max(0, NdotH), 10.0) * s.Smoothness * specColor;
            // half PH = pow(2.0 * tex2D(KelemenLUT, float2(NoH, s.Smoothness)).r, 10.0 );
            // float F = 0.028; // fresnelReflectance(H, viewDir, 0.028 );
            // half3 specular = max(PH * F / dot( _h, _h ), 0) * specColor;
            c.rgb += specular;

            half transDot = max(0.3 + dot(s.worldNormal, -gi.light.dir), 0);
            half d = _Thickness;
            half3 transColor = tex2D (_TranslucencyLUT, float2(d, 0));
            half3 transmittance = transColor * gi.light.color * s.Albedo * _Translucency;
            c.rgb += transmittance.rgb;

            return c;
        }

        inline void LightingSkin_GI (SurfaceOutputSkin s, UnityGIInput data, inout UnityGI gi) {
            #if defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
            gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal);
            #else
            Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.Smoothness, data.worldViewDir, s.Normal, lerp(unity_ColorSpaceDielectricSpec.rgb, s.Albedo, s.Metallic));
            gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal, g);
            #endif
        }

        ENDCG
    }
    FallBack "Diffuse"
}
