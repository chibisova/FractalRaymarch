Shader "Hidden/RaymarchShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"
            #include "DistanceFunctions.cginc"
  
            sampler2D _MainTex;
            uniform sampler2D _CameraDepthTexture;
            uniform float4x4 _CamFrustum, _CamToWorld;
            uniform float _maxDistance, _box1round, _boxSphereSmooth, _sphereIntersectSmooth;
            uniform float4 _sphere1, _sphere2, _box1, _fractal;
            uniform float3 _modInterval;
            uniform float3 _LightDir;
            uniform fixed4 _mainColor, _secColor, _skyColor;
            uniform float _precision, _lightIntensity, _shadowIntensity, _aoIntensity, _forceFieldRad, _GlobalScale;
            uniform int _iterations, _functionNum;
            uniform int _useNormal;
            uniform int _useShadow;
            uniform float4 _forceFieldNormal, _forceFieldColor;
            uniform float3 _player;
            uniform float3 _modOffsetPos;
            uniform float3 _modOffsetRot;
            uniform float4x4 _iterationTransform;
            uniform float4x4 _globalTransform;
            uniform float _smoothRadius, _scaleFactor, _innerSphereRad, _power;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 ray : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 ray : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                half index = v.vertex.z;
                v.vertex.z = 0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;

                o.ray = _CamFrustum[(int)index].xyz;

                o.ray /= abs(o.ray.z);

                o.ray = mul(_CamToWorld, o.ray);

                return o;
            }

            // the distancefunction for the forcefield around the player.
            float sdforceField(float3 p)
            {
                //simple sphere
                return sdSphere(p - _player , _forceFieldRad);
            }

            //Ray dicstance count
            float distanceField(float3 p){

                float2 dist;

                if(_functionNum == 1){
                    dist = sdMerger(p,_GlobalScale, _iterations,_modOffsetPos ,_iterationTransform, _globalTransform, _smoothRadius, _scaleFactor);
                }
                //merger cylinder
                else if(_functionNum == 2){
                    dist = sdMergerCyl(p,_GlobalScale, _iterations,_modOffsetPos ,_iterationTransform, _globalTransform, _smoothRadius, _scaleFactor);
                }
                //mergerPyr
                else if(_functionNum == 3){
                    //dist = sdtriangleCross(p, _GlobalScale);
                    dist = sdMergerPyr(p,_GlobalScale, _iterations,_modOffsetPos ,_iterationTransform, _globalTransform, _smoothRadius, _scaleFactor, float4x4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1));
                } 
                // neg sphere
                else if(_functionNum == 4){
                    dist = sdNegSphere(p,_GlobalScale, _iterations,_modOffsetPos ,_iterationTransform, _globalTransform, _innerSphereRad, _scaleFactor);
                }
                // Sierpinski
                else if(_functionNum == 5){
                    dist = sdSierpinski(p, _scaleFactor);
                }
                // Mandelbulb
                else if(_functionNum == 6){
                    dist = mandelbulb(p, _power,  _iterations, _smoothRadius);
                } 
                // Mandelbulb2
                else if(_functionNum == 7){
                    dist = mandelbulb2 (p, _power,  _iterations, _smoothRadius);
                }
                // Tower IFS
                else if(_functionNum == 8){
                    dist = towerIFS(p);
                }
                // Abstract Fractal
                else if(_functionNum == 9){
                    dist = abstFractal(p);
                } 
                // Hartverdrahtet 
                else if(_functionNum == 10){
                    dist = hartverdrahtet(p);
                }
                // Pseudo Kleinian
                else if(_functionNum == 11){
                    dist = pseudo_kleinian(p);
                }
                // Pseudo Knightyan
                else if(_functionNum == 12){
                    dist = pseudo_knightyan(p);
                } 
                //default
                else dist = _maxDistance + 1;


                //float ground = sdPlane(p, float4(0,1,0,0));
                //float boxSphere1 = BoxSphere(p);

                
                //float fractal = sdMergerPyr(p, _fractal.w, int(4), _fractal.xyz, float4x4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1), float4x4 (1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1), float(0.2), float(1), float4x4 (1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1));

                //float fractal3 = sdNegSphere(p, float(6.), int(4), _fractal.xyz, float4x4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1), float4x4 (1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1), _fractal.w, float(1));

                /* this is the method to create an infinite repeat of box-sphere
                float Sphere1 = sdSphere(p - _sphere1.xyz, _sphere1.w);
                float Box1 = sdBox(p - _box1.xyz, _box1.www);
                
                float modX = pMod1(p.x, _modInterval.x);
                float modY = pMod1(p.y, _modInterval.y);
                float modZ = pMod1(p.z, _modInterval.z);
                float Sphere1 = sdSphere(p - _sphere1.xyz, _sphere1.w);
                float Box1 = sdBox(p - _box1.xyz, _box1.www);
                return opS(Sphere1, Box1);
                */
                //float dist = sdNegSphere(p, _GlobalScale, _iterations, _modOffsetPos ,_iterationTransform, _globalTransform, _smoothRadius, _scaleFactor);

                //float r = abs(sin(2 * 3. * _Time.y / 2.0));
                //float d1 = sdRoundBox(fmod(p, float3(6, 6, 6)), 1, r);
                //float d2 = sdSphere(p, 3.0);
                //float d3 = floor(p - float3(0, -3, 0));
                //return smoothMin(smoothMin(d1, d2, 1.0), d3, 1.0);


                //float fractal2 = sdMerger(p, _fractal.w, int(4), _fractal.xyz, float4x4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1), float4x4 (1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1), float(0.2), float(2));

                //float sier1 = sdSierpinski(p, _fractal.x);

                //float bulba1 = mandelbulb(p, _fractal.w, _fractal.x, _fractal.y, float(0.7));

                //float tor1 = torus(twistY(p, 2.0), float2(2.0, 0.6));
                //float ifs1 = pseudo_kleinian(p);

                return dist;
            }

            //Shadow func

            float shadowCalc( in float3 ro, in float3 rd, float mint, float maxt, float k )
            {
                float res = 1.0;
                float ph = 1e20;
                for( float t=mint; t<maxt; )
                {
                    float h = min(distanceField(ro + rd*t),sdforceField(ro + rd*t));
                    if( h<0.001 ) return 0.0;
                    float y = h*h/(2.0*ph);
                    float d = sqrt(h*h-y*y);
                    res = min( res, k*d/max(0.0,t-y) );
                    ph = h;
                    t += h;
                }
                return res;
            }

            // returns the normal in a single point of the fractal
            float3 getNormal(float3 p){
                float d = distanceField(p).x;
                const float2 e = float2(.01, 0);
                float3 n = d - float3(distanceField(p - e.xyy).x,distanceField(p - e.yxy).x,distanceField(p - e.yyx).x);
                return normalize(n);
            }

            // returns the normal of the forcefield
            float3 getNormalForceField(float3 p)
            {

              float d = sdforceField(p);
              const float2 e = float2(.01, 0);
              float3 n = d - float3(sdforceField(p - e.xyy),sdforceField(p - e.yxy),sdforceField(p - e.yyx));
              return normalize(n);

            }

            fixed4 raymarching(float3 ro, float3 rd, float depth){
                fixed4 result = fixed4(0, 0, 0, 0.5);
                const int max_iteration = 400;
                bool _forceFieldHit = false;
                float3 _forceFieldNormal;
                float t = 0; //distance travelled along the ray direction

                for (int i = 0; i < max_iteration; i++) {


                    //sends out ray from the camera
                    float3 p = ro + rd * t;


                    //return distance to forcefield
                    float _forceField = sdforceField(p);
                    /*
                    if (t > _maxDistance || t >= depth){
                        //Environment
                        result = fixed4(rd,0);
                        break;
                    }*/

                    //check for hit in distancefield
                    float2 d = distanceField(p);

                    if (d.x < _precision) { //We have hit smth
                        //shading

                        float3 colorDepth;
                        float light;
                        float shadow;

                        float3 color = float3(_mainColor.rgb*(_iterations-d.y)/_iterations + _secColor.rgb*(d.y)/_iterations);

                        if(_useNormal == 1){
                            float3 n = getNormal(p);
                             light = (dot(-_LightDir, n) * (1 - _lightIntensity) + _lightIntensity); //lambertian shading
                        }
                        else  light = 1;
                        
                        if(_useShadow == 1){
                             shadow = (shadowCalc(p, -_LightDir, 0.1, _maxDistance, 3) * (1 - _shadowIntensity) + _shadowIntensity); // soft shadows

                        }
                        else  shadow = 1;

                        float ao = (1 - 2 * i/float(max_iteration)) * (1 - _aoIntensity) + _aoIntensity; // ambient occlusion
                        float3 colorLight = float3 (color * light * shadow * ao); // multiplying all values between 0 and 1 to return final color
                        colorDepth = float3 (colorLight*(_maxDistance-t)/(_maxDistance) + _skyColor.rgb*(t)/(_maxDistance)); // Background color, multiplying with distance
                       
                        /*float3 n = getNormal(p);
                        float light = dot(-_LightDir, n);*/

                        if(_forceFieldHit == true)
                        {
                            colorDepth =dot(-rd, _forceFieldNormal)* colorDepth + (1-dot(-rd, _forceFieldNormal))*_forceFieldColor; // multiply by transparant forcefield
                            
                        }

                        result = fixed4(colorDepth ,1);
                        break;
                    }

                    // adds distance to the distance traveled and next point

                    if(_forceFieldHit == false)
                    {
                        
                        
                        // closer points get higher precicion to limit overstepping

                        if((d.x) < 10)
                        {
                            t+=  min(d.x * 0.75f, _forceField);
                        }
                        else if( abs(d.x) < 2)
                        {
                            t+= min(d.x * 0.5f, _forceField);
                        }
                        else t+= min(d.x, _forceField);
                        
                        
                    }
                    else t += d.x;
                    
                }
                return result;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
                depth *= length(i.ray);
                fixed3 col = tex2D(_MainTex, i.uv);
                float3 rayDirection = normalize(i.ray.xyz);
                float3 rayOrigin = _WorldSpaceCameraPos;
                fixed4 result = raymarching(rayOrigin, rayDirection, depth);

                return fixed4(col * (1.0 - result.w) + result.xyz * result.w, 1.0);
            }
            ENDCG
        }
    }
}
