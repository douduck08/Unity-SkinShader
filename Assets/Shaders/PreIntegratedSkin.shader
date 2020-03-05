Shader "Skin/Pre-integrated Skin"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Specular ("Specular", Range(0,10)) = 1.0
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpStrength ("Normal Strength", Range(0,2)) = 1

        [Header(Scattering)]
        _SkinLUT ("Skin LUT", 2D) = "white" {}
        _Curve ("Curve", Range(0,1)) = 1.0
        _CurveMap ("Curve Map (R)", 2D) = "white" {}
        [Toggle(_CALC_CURVE)] _CalcuCurve ("Caculate Curve", Int) = 0

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

        #pragma shader_feature _CALC_CURVE
        #include "SkinLighting.cginc"

        struct Input {
            float2 uv_MainTex;
            #ifdef _CALC_CURVE
            float3 worldPos;
            float3 worldNormal;
            INTERNAL_DATA
            #endif
        };

        sampler2D _MainTex;
        sampler2D _BumpMap;
        half _BumpStrength;

        half4 _Color;
        half _Glossiness;
        half _Metallic;
        half _Specular;

        sampler2D _CurveMap;
        half _Curve;
        half _Thickness;
        half _Translucency;

        void surf (Input IN, inout SurfaceOutputSkin o) {
            half4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Alpha = c.a;
            
            o.Normal = UnpackNormal (tex2D (_BumpMap, IN.uv_MainTex));
            o.Normal.xy *= _BumpStrength;

            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Emission = 0;
            o.Occlusion = 1;

            o.Specular = _Specular;
            o.Thickness = _Thickness;
            o.Translucency = _Translucency;

            #ifdef _CALC_CURVE
            o.Curve = length(fwidth(IN.worldNormal)) / length(fwidth(IN.worldPos)) * _Curve;
            #else
            o.Curve = tex2D (_CurveMap, IN.uv_MainTex).r * _Curve;
            #endif
        }

        ENDCG
    }
    FallBack "Diffuse"
}
