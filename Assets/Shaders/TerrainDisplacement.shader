Shader "Custom/TerrainDisplacement"
{
    Properties
    {
        _MainTex ("Base Texture", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _HeightMap ("Height Map", 2D) = "black" {}
        _DisplacementStrength ("Displacement Strength", Range(1,100)) = 50.0
        _Color ("Base Color", Color) = (1,1,1,1)
        _NormalMapStrength ("Normal Map Strength", Range(0.0, 2.0)) = 1.0
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                float3 worldTangent : TEXCOORD4;
                float3 worldBinormal : TEXCOORD5;
                SHADOW_COORDS(3)
            };

            sampler2D _MainTex;
            sampler2D _NormalMap;
            Texture2D<float4> _HeightMap;
            SamplerState sampler_HeightMap;
            float4 _MainTex_ST;
            float _DisplacementStrength;
            float _NormalMapStrength;
            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                
                float height = _HeightMap.SampleLevel(sampler_HeightMap, v.uv, 0).r;
                
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
                
                o.worldNormal = worldNormal;
                o.worldTangent = worldTangent;
                o.worldBinormal = worldBinormal;
                
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                worldPos += worldNormal * height * _DisplacementStrength;
                
                o.worldPos = worldPos;
                
                o.pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                TRANSFER_SHADOW(o)
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                
                float3 normalMap = UnpackNormal(tex2D(_NormalMap, i.uv));
                normalMap.xy *= _NormalMapStrength;
                normalMap = normalize(normalMap);
                
                float3x3 tangentToWorld = float3x3(
                    normalize(i.worldTangent),
                    normalize(i.worldBinormal),
                    normalize(i.worldNormal)
                );
                
                float3 worldNormal = normalize(mul(normalMap, tangentToWorld));
                
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float NdotL = dot(worldNormal, lightDir);
                
                float attenuation = SHADOW_ATTENUATION(i);
                
                float lighting = max(0.0, NdotL) * attenuation * 0.8 + 0.2;
                
                col.rgb *= lighting;
                
                return col;
            }
            ENDCG
        }
        
        // Shadow caster pass
        Pass
        {
            Tags { "LightMode"="ShadowCaster" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            Texture2D<float4> _HeightMap;
            SamplerState sampler_HeightMap;
            float _DisplacementStrength;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata v)
            {
                v2f o;
                
                float height = _HeightMap.SampleLevel(sampler_HeightMap, v.uv, 0).r;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                worldPos += worldNormal * height * _DisplacementStrength;
                
                v.vertex = mul(unity_WorldToObject, float4(worldPos, 1.0));
                
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
}
