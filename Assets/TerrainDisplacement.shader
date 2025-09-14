Shader "Custom/TerrainDisplacement"
{
    Properties
    {
        _MainTex ("Base Texture", 2D) = "white" {}
        _HeightMap ("Height Map", 2D) = "black" {}
        _DisplacementStrength ("Displacement Strength", Range(1,50)) = 20.0
        _Color ("Base Color", Color) = (1,1,1,1)
        _NormalStrength ("Normal Strength", Range(0.1, 2.0)) = 1.0
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

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
                float4 vertex : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            sampler2D _HeightMap;
            float4 _MainTex_ST;
            float4 _HeightMap_TexelSize;
            float _DisplacementStrength;
            float _NormalStrength;
            fixed4 _Color;

            float3 CalculateNormal(float2 uv)
            {
                float texelSize = _HeightMap_TexelSize.x;
                
                float heightL = tex2Dlod(_HeightMap, float4(uv.x - texelSize, uv.y, 0, 0)).r;
                float heightR = tex2Dlod(_HeightMap, float4(uv.x + texelSize, uv.y, 0, 0)).r;
                float heightD = tex2Dlod(_HeightMap, float4(uv.x, uv.y - texelSize, 0, 0)).r;
                float heightU = tex2Dlod(_HeightMap, float4(uv.x, uv.y + texelSize, 0, 0)).r;
                
                float3 normal;
                normal.x = (heightL - heightR) * _NormalStrength;
                normal.z = (heightD - heightU) * _NormalStrength;
                normal.y = 1.0;
                
                return normalize(normal);
            }

            v2f vert (appdata v)
            {
                v2f o;
                
                float height = tex2Dlod(_HeightMap, float4(v.uv, 0, 0)).r;
                
                float3 calculatedNormal = CalculateNormal(v.uv);
                
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
                
                float3x3 tangentToWorld = float3x3(
                    worldTangent,
                    worldBinormal,
                    worldNormal
                );
                
                o.worldNormal = normalize(mul(calculatedNormal, tangentToWorld));
                
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                worldPos += worldNormal * height * _DisplacementStrength;
                
                o.worldPos = worldPos;
                
                o.vertex = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                
                float3 normal = normalize(i.worldNormal);
                
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float NdotL = dot(normal, lightDir);
                
                float lighting = max(0.0, NdotL) * 0.8 + 0.2; // 0.2 ambient, 0.8 diffuse
                
                col.rgb *= lighting;
                
                return col;
            }
            ENDCG
        }
    }
}