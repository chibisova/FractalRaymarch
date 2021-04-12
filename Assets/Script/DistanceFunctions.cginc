// Sphere
// s: radius
float sdSphere(float3 p, float s)
{
	return length(p) - s;
}

// Box
// b: size of box in x/y/z
float sdBox(float3 p, float3 b)
{
	float3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) +
		length(max(d, 0.0));
}

// Rounded Box
float sdRoundBox(in float3 p, in float3 b, in float r)
{
	float3 q = abs(p) - b;
	return min(max(q.x,max(q.y,q.z)),0.0) + length(max(q,0.0)) - r;
}


// (Infinite) Plane
// n.xyz: normal of the plane (normalized);
// n.w: offset
float sdPlane(float3 p, float4 n)
{
	//n must be normalized
	return dot(p, n.xyz) + n.w;
}

// InfBox
            // b: size of box in x/y/z
            float sd2DBox(float2 p, float2 b)
            {
                float2 d = abs(p) - b;
                return sqrt( length(max(d, 0.0))) + min(max(d.x, d.y), 0.0);
            }

            //InfCylinder
            float sd2DCylinder(float2 p, float c)
            {
                return length(p) - c;
            }


            // Cross
            // s: size of cross
            float sdCross(in float3 p, float b)
            {
                float da = sd2DBox( p.xy, 1.1 * b);
                float db = sd2DBox( p.yz, 1.1 * b);
                float dc = sd2DBox( p.xz, 1.1 * b);
                return min(da, min(db, dc));
            }

            float sdCylinderCross(in float3 p, float b)
            {
                float da = sd2DCylinder(p.xy, b);
                float db = sd2DCylinder(p.yz, b);
                float dc = sd2DCylinder(p.xz, b);
                return min(da, min(db, dc));
            }

//Menger Cylinder
//For the building one call:
//return sdMergerCyl(p, float3(4,5, 6), int(1), float3(1,1,1), float4x4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1), float4x4 (1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1), float(0.2), float(2));
float sdMergerCyl(float3 p, float3 b, int _iterations, float3 _modOffsetPos, float4x4 _iterationTransform, float4x4 _globalTransform, float _smoothRadius, float _scaleFactor)
{
                p = mul(_globalTransform, p);

                float d = sdBox(p, b);

                float s = 1.0;
                for (int m = 0; m < _iterations; m++)
                {
                    p = mul(_iterationTransform,p);
                    float px = b * _modOffsetPos.x *2/s;
                    float py = b * _modOffsetPos.y *2/s;
                    float pz = b * _modOffsetPos.z *2/s;
                
                    p.x = modf(p.x, px);
                    p.y = modf(p.y, py);
                    p.z = modf(p.z, pz);


                    s *= _scaleFactor * 3;
                    float3 r = (p) * s;
                    float c = (sdCross(r, b - _smoothRadius) - _smoothRadius) / s;
                    //d = max(d,-c);


                    if (-c > d)
                    {
                        d = -c;

                    }

                }

                return d;
}


// BOOLEAN OPERATORS //

// Union
float opU(float d1, float d2)
{
	return min(d1, d2);
}

// Subtraction
float opS(float d1, float d2)
{
	return max(-d1, d2);
}

// Intersection
float opI(float d1, float d2)
{
	return max(d1, d2);
}

// Mod Position Axis
float pMod1 (inout float p, float size)
{
	float halfsize = size * 0.5;
	float c = floor((p+halfsize)/size);
	p = fmod(p+halfsize,size)-halfsize;
	p = fmod(-p+halfsize,size)-halfsize;
	return c;
}


// SMOOTH BOOLEAN OPERATORS

float4 opUS( float4 d1, float4 d2, float k ) 
{
    float h = clamp( 0.5 + 0.5*(d2.w-d1.w)/k, 0.0, 1.0 );
 float3 color = lerp(d2.rgb, d1.rgb, h);
    float dist = lerp( d2.w, d1.w, h ) - k*h*(1.0-h); 
 return float4(color,dist);
}

float opSS( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return lerp( d2, -d1, h ) + k*h*(1.0-h); 
}

float opIS( float d1, float d2, float k ) 
{
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return lerp( d2, d1, h ) + k*h*(1.0-h); 
}