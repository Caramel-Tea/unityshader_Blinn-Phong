Shader "Unlit/Blinn-Phong Textured"
{
    Properties
    {
        _MainTex("漫反射纹理", 2D) = "white" {}
        _MainCol("漫反射颜色", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularPow("高光次幂", Range(1, 90)) = 30
        _AmbientCol("环境光颜色", Color) = (0.4, 0.4, 0.4, 1.0)
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0

            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform float4 _MainCol;
            uniform float _SpecularPow;
            uniform float4 _AmbientCol;

            //输入结构
            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            //输出结构
            struct VertexOutput
            {
                float4 posCS : SV_POSITION;
                float4 posWS : TEXCOORD0;
                float3 nDirWS : TEXCOORD1;
                float2 uv : TEXCOORD2; 
            };

            //输入结构>>>顶点shader>>>纹理处理>>>输出结构
            VertexOutput vert(VertexInput v)
            {
                VertexOutput o;
                    o.posCS = UnityObjectToClipPos(v.vertex);
                    o.posWS = mul(unity_ObjectToWorld, v.vertex);
                    o.nDirWS = UnityObjectToWorldNormal(v.normal);
                    o.uv = TRANSFORM_TEX(v.uv, _MainTex); 
                return o;
            }

            //输出结构>>>纹理采样/准备向量>>>计算光照>>>返回结果
            float4 frag(VertexOutput i) : SV_TARGET
            {
                float4 sampledTexColor = tex2D(_MainTex, i.uv);
                float3 diffuseCol = _MainCol.rgb * sampledTexColor.rgb;
                float3 nDirWS = normalize(i.nDirWS);
                float3 lightPos = _WorldSpaceLightPos0.xyz;
                float3 vDir = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
                float3 lDir;
                if (_WorldSpaceLightPos0.w == 0.0)
                    lDir = normalize(lightPos);
                else
                    lDir = normalize(lightPos - i.posWS.xyz);
                float3 hDir = normalize(vDir + lDir);
                float ndotl = max(0.0, dot(nDirWS, lDir));
                float ndoth = max(0.0, dot(nDirWS, hDir));
                float3 diffuseTerm = diffuseCol * _LightColor0.rgb * ndotl;
                float3 specularTerm = _LightColor0.rgb * pow(ndoth, _SpecularPow);
                float3 ambientTerm = _AmbientCol.rgb * diffuseCol;
                float3 finalColor = diffuseTerm + specularTerm + ambientTerm;

                return float4(finalColor, 1.0);
            }

            ENDCG
        }
    }

    FallBack "Diffuse"
}