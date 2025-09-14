Shader "Custom/GrassBillboard"
{
    Properties
    {
        _MainTex ("Grass Texture", 2D) = "white" {}
        _Cutoff ("Alpha Cutoff", Range(0,1)) = 0.5
        _Color ("Tint Color", Color) = (1,1,1,1)
        _WindDirection ("Wind Direction", Vector) = (1,0,0,0)
        _WindStrength ("Wind Strength", Float) = 0.5
        _WindSpeed ("Wind Speed", Float) = 1.0
        _WindScaleInfluence ("Wind Scale Influence", Float) = 1.0
    }
    
    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest" }
        Cull Off
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
            #include "UnityCG.cginc"

            struct GrassData
            {
                float3 position;
                float rotation;
                float scale;
            };

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                uint instanceID : SV_InstanceID;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            StructuredBuffer<GrassData> _GrassBuffer;
            float3 _ManagerPosition;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed _Cutoff;
            float2 _WindDirection;
            float _WindStrength;
            float _WindSpeed;
            float _WindScaleInfluence;

            v2f vert (appdata v)
            {
                v2f o;
                
                GrassData grassData = _GrassBuffer[v.instanceID];
                
                float3 worldPos = _ManagerPosition + grassData.position;
                float cosR = cos(grassData.rotation);
                float sinR = sin(grassData.rotation);
                float scale = grassData.scale * 0.5;
                
                float3 rotatedVertex = float3(
                    v.vertex.x * cosR - v.vertex.z * sinR,
                    v.vertex.y,
                    v.vertex.x * sinR + v.vertex.z * cosR
                ) * scale;
                
                float windPhase = _Time.y * _WindSpeed + worldPos.x * 0.1 + worldPos.z * 0.1;
                float windWave = sin(windPhase);
                
                float windInfluence = v.uv.y;
                
                float scaleInfluence = lerp(1.0, grassData.scale, _WindScaleInfluence);
                
                float3 windOffset = float3(
                    _WindDirection.x * windWave * _WindStrength * windInfluence * scaleInfluence,
                    0,
                    _WindDirection.y * windWave * _WindStrength * windInfluence * scaleInfluence
                );
                
                float3 finalWorldPos = worldPos + rotatedVertex + windOffset;
                
                o.vertex = mul(UNITY_MATRIX_VP, float4(finalWorldPos, 1.0));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                clip(col.a - _Cutoff);
                return col;
            }
            ENDCG
        }
    }
}
