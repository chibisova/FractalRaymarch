﻿#define PI      3.1415926535897932384626433832795


/* ---- Basics ----- */

float3 rotateX(float3 p, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float3(p.x, c*p.y+s*p.z, -s*p.y+c*p.z);
}

float3 rotateY(float3 p, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float3(c*p.x-s*p.z, p.y, s*p.x+c*p.z);
}

float3 rotateZ(float3 p, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float3(c*p.x+s*p.y, -s*p.x+c*p.y, p.z);
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

//infinite cylinder
float sdCylinder( float2 p, float c )
{
  return length(p)-c;
}

//triangle prism
float sdTriPrism( float2 p, float2 h )
{
    p.y = p.y;
    p.y += h.x;
    const float k = sqrt(3.0);
    h.x *= 0.5*k;
    p.xy /= h.x;
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0/k;
    if( p.x+k*p.y>0.0 ) p.xy=float2(p.x-k*p.y,-k*p.x-p.y)/2.0;
    p.x -= clamp( p.x, -2.0, 0.0 );
    float d1 = length(p.xy)*sign(-p.y)*h.x;
    float d2 = -h.y;
    return length(max(float2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

// Tetrahedron
float sdTetrahedron(float3 p, float a, float4x4 rotate45)
{
    
  p = mul(rotate45, float4(p,1)).xyz;
  return (max( abs(p.x+p.y)-p.z,abs(p.x-p.y)+p.z)-a)/sqrt(3.);
  
    
}
//pyramid
float sdPyramid( float3 p, float h)
{
  float m2 = h*h + 0.25;
    
  p.xz = abs(p.xz);
  p.xz = (p.z>p.x) ? p.zx : p.xz;
  p.xz -= 0.5;

  float3 q = float3( p.z, h*p.y - 0.5*p.x, h*p.x + 0.5*p.y);
   
  float s = max(-q.x,0.0);
  float t = clamp( (q.y-0.5*p.z)/(m2+0.25), 0.0, 1.0 );
    
  float a = m2*(q.x+s)*(q.x+s) + q.y*q.y;
  float b = m2*(q.x+0.5*t)*(q.x+0.5*t) + (q.y-m2*t)*(q.y-m2*t);
    
  float d2 = min(q.y,-q.x*m2-q.y*0.5) > 0.0 ? 0.0 : min(a,b);
    
  return sqrt( (d2+q.z*q.z)/m2 ) * sign(max(q.z,-p.y));
}


// Octahedron
float sdOctahedron(float3 p, float a, float4x4 rotate45)
{
  p = mul(rotate45, float4(p,1)).xyz;
  return (abs(p.x)+abs(p.y)+abs(p.z)-a)/3;
}

//trianglecross
float sdtriangleCross( in float3 p, float2 b)
{
  float da = sdTriPrism(p.xy,float2(b.x,b.y* 0.2));
  float db = sdTriPrism(p.zy,float2(b.x,b.y* 0.2));
  
  return min(da,db);
}

// (Infinite) Plane
// n.xyz: normal of the plane (normalized);
// n.w: offset
float sdPlane(float3 p, float4 n)
{
	//n must be normalized
	return dot(p, n.xyz) + n.w;
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
float pMod ( float p, float size)
{
    float halfsize = size * 0.5;
    float c = floor((p+halfsize)/size);
    p = fmod(p+halfsize,size)-halfsize;
    p = fmod(p-halfsize,size)+halfsize;
    return p;
}

// InfBox
// b: size of box in x/y/z
float sd2DBox( in float2 p, in float2 b )
{
    float2 d = abs(p)-b;
    return length(max(d,float2(0,0))) + min(max(d.x,d.y),0.0);
}


//InfCylinder
float sd2DCylinder(float2 p, float c)
{
    return length(p) - c;
}

// Cross
// s: size of cross
float sdCross( in float3 p, float b )
{
  float da = sd2DBox(p.xy,float2(b,b));
  float db = sd2DBox(p.yz,float2(b,b));
  float dc = sd2DBox(p.zx,float2(b,b));
  return min(da,min(db,dc));
}

// CylinderCross
// s: size of cross
float sdCylinderCross( in float3 p, float b )
{
  float da = sdCylinder(p.xy,b);
  float db = sdCylinder(p.yz,b);
  float dc = sdCylinder(p.zx,b);
  return min(da,min(db,dc));
}


//MERGER FUNCTS FAMILY

//Merger Sponge
float2 sdMerger( in float3 p, float b, int _iterations, float3 _modOffsetPos , float4x4 _iterationTransform, float4x4 _globalTransform, float _smoothRadius, float _scaleFactor)
{
   
   p = mul(_globalTransform, float4(p,1)).xyz;
   
   
   float2 d = float2(sdBox(p,float3(b- _smoothRadius,b- _smoothRadius,b- _smoothRadius)),0)- _smoothRadius;

   float s = 1.0;
   for( int m=0; m<_iterations; m++ )
   {
        p = mul(_iterationTransform, float4(p,1)).xyz;
        p.x = pMod(p.x,b*_modOffsetPos.x * 2/s);
        p.y = pMod(p.y,b*_modOffsetPos.y * 2/s);
        p.z = pMod(p.z,b*_modOffsetPos.z * 2/s);
      
        s *= _scaleFactor * 3;
        float3 r =(p)*s; 
        float c = (sdCross(r,b- _smoothRadius/s)- _smoothRadius)/s;
        
        if(-c>d.x)
        {
            d.x = -c;
            d = float2( d.x, m);
            
        }
   }  
   return d;
}

//Merrger Sponge Cylinder
float2 sdMergerCyl( in float3 p, float b, int _iterations, float3 _modOffsetPos , float4x4 _iterationTransform, float4x4 _globalTransform, float _smoothRadius, float _scaleFactor)
{
   
   p = mul(_globalTransform, float4(p,1)).xyz;
   
   
   float2 d = float2(sdSphere(p,float3(b- _smoothRadius,b- _smoothRadius,b- _smoothRadius)),0)- _smoothRadius;

   float s = 1.0;
   for( int m=0; m<_iterations; m++ )
   {
        p = mul(_iterationTransform, float4(p,1)).xyz;
        p.x = pMod(p.x,b*_modOffsetPos.x * 2/s);
        p.y = pMod(p.y,b*_modOffsetPos.y * 2/s);
        p.z = pMod(p.z,b*_modOffsetPos.z * 2/s);
      
        s *= _scaleFactor * 3;
        float3 r =(p)*s; 
        float c = (sdCylinderCross(r,b- _smoothRadius/s)- _smoothRadius)/s;
        
        if(-c>d.x)
        {
            d.x = -c;
            d = float2( d.x, m);
            
        }
   }  
   return d;
}

//Merger Piramid

float2 sdMergerPyr( in float3 p, float b, int _iterations, float3 _modOffsetPos , float4x4 _iterationTransform, float4x4 _globalTransform, float _smoothRadius, float _scaleFactor, float4x4 rotate45)
{
   b = 2*b;
   p = mul(_globalTransform, float4(p,1)).xyz;
   
   
   float2 d = float2(sdPyramid(p / b,sqrt(3)/2) * b,0);

   float s = 1.0;
   for( int m=0; m<_iterations; m++ )
   {
        p = mul(_iterationTransform, float4(p,1)).xyz;
        //p = abs(p);
        p.x = pMod(p.x,b*_modOffsetPos.x * 0.5/s);
        p.y = pMod(p.y,b*_modOffsetPos.y * (sqrt(3)/2)/s);
        p.z = pMod(p.z,b*_modOffsetPos.z * 0.5/s);
      
        s *= _scaleFactor * 2;
        float3 r =(p)*s;
        float c  = (sdtriangleCross(float3(r.x, -r.y,r.z),b / sqrt(3)))/s;
        
        if(-c>d.x)
        {
            d.x = -c;
            d = float2( d.x, m);
            
        }
   }  
   return d;
}

//Negative Sphere

float2 sdNegSphere (in float3 p, float b, int _iterations, float3 _modOffsetPos , float4x4 _iterationTransform, float4x4 _globalTransform, float _sphere1, float _scaleFactor)
{
    p = mul(_globalTransform, float4(p,1)).xyz;
   
   
   float2 d = float2(sdBox(p,float3(b,b,b)),0);

   float s = 1.0;
   for( int m=0; m<_iterations; m++ )
   {
        p = mul(_iterationTransform, float4(p,1)).xyz;
        p.x = pMod(p.x,b*_modOffsetPos.x * 2/s);
        p.y = pMod(p.y,b*_modOffsetPos.y * 2/s);
        p.z = pMod(p.z,b*_modOffsetPos.z * 2/s);
        s *= _sphere1;
        float3 r =(p)*s; 
        float c = sdSphere(r,b)/s;
        s *= _scaleFactor * 3;

        if(-c>d.x)
        {
            d.x = -c;
            d = float2( d.x, m);
            
        }
   }  
   return d;

}

//SIERPINSKI TRIENGLE FAMILY

//Sierpinski triangle
float sdSierpinski(float3 p, float psize) {
    const float3 p0 = float3(-1,-1,-1);
    const float3 p1 = float3(1,1,-1);
    const float3 p2 = float3(1,-1,1);
    const float3 p3 = float3(-1,1,1);

    const int maxit = 15;
    const float scale = 2.;
    for (int i = 0; i < maxit; ++i) {
        float d = length(p-p0);
        float3 c = p0;
        
        float t = length(p-p1);
        if (t < d) {
            d = t;
            c = p1;
        }
        
        t = length(p-p2);
        if (t < d) {
            d = t;
            c = p2;
        }
        
        t = length(p-p3);
        if (t < d) {
            d = t;
            c = p3;
        }
        
        p = (p-c)*scale;
    }
    
    return length(p) * pow(scale, float(-maxit)) - psize; // let the leaves be one pixel in size
}

//Recursive Sierpinski

float recursiveSierpinski(float3 p, int loop)
{
    p = fmod(p / 2, 3.0);

    const float3 a1 = float3( 1.0,  1.0,  1.0);
    const float3 a2 = float3(-1.0, -1.0,  1.0);
    const float3 a3 = float3( 1.0, -1.0, -1.0);
    const float3 a4 = float3(-1.0,  1.0, -1.0);

    const float scale = 2.0;
    float d;
    for (int n = 0; n < loop; ++n) {
        float3 c = a1; 
        float minDist = length(p - a1);
        d = length(p - a2); if (d < minDist) { c = a2; minDist = d; }
        d = length(p - a3); if (d < minDist) { c = a3; minDist = d; }
        d = length(p - a4); if (d < minDist) { c = a4; minDist = d; }
        p = scale * p - c * (scale - 1.0);
    }
 
    return length(p) * pow(scale, float(-n));
}

//MANDELBULB FAMILY

//Mandelbulb
float mandelbulb (in float3 p,float _power, float _iterations, float _smoothRadius){
    
    float3 w = p;
    float m = dot(w,w);
    float dr = 1.0;
  
    int iterations = 0;

    for (int i = 0; i < _iterations ; i++) {
        iterations = i;
       
        dr = pow(sqrt(m),_power-1) *_power*dr +1;
        //dz = 8.0*pow(m,3.5)*dz + 1.0;
        
        float r = length(w);
        float b = _power * acos( w.z/r);
        float a = _power * atan( w.y/ w.x );
        w = p + pow(r,_power) * float3( sin(b)*cos(a), sin(b)*sin(a), cos(b) );
        

        m = dot(w,w);
        if( m > 256.0 )
            break;
    }
    float dst = 0.25*log(m)* sqrt(m)/dr;
    return float2(dst*_smoothRadius, iterations);
   
}

// Mandelbulb2
float mandelbulb2 (in float3 p,float _power, float _iterations,float _smoothRadius){
    
    
    float3 w = p;
    float m = dot(w,w);
    float dr = 1.0;
  
    int iterations = 0;


    for (int i = 0; i < _iterations ; i++) {
        iterations = i;
       
        float m2 = m*m;
        float m4 = m2*m2;
        dr = _power*sqrt(m4*m2*m)*dr + 1.0;
        
        float x = w.x; float x2 = x*x; float x4 = x2*x2;
        float y = w.y; float y2 = y*y; float y4 = y2*y2;
        float z = w.z; float z2 = z*z; float z4 = z2*z2;

        float k3 = x2 + z2;
        float k2 = 1/sqrt( k3*k3*k3*k3*k3*k3*k3 );
        float k1 = x4 + y4 + z4 - 6.0*y2*z2 - 6.0*x2*y2 + 2.0*z2*x2;
        float k4 = x2 - y2 + z2;

        w.x =  64.0*x*y*z*(x2-z2)*k4*(x4-6.0*x2*z2+z4)*k1*k2;
        w.y = -16.0*y2*k3*k4*k4 + k1*k1;
        w.z = -8.0*y*k4*(x4*x4 - 28.0*x4*x2*z2 + 70.0*x4*z4 - 28.0*x2*z2*z4 + z4*z4)*k1*k2;
        

        m = dot(w,w);
        if( m > 256.0 )
            break;
    }
    float dst = 0.25*log(m)* sqrt(m)/dr;
    return float2(dst*_smoothRadius, iterations);
   
}

//OTHER FRACTAL FUNCTIONS

float towerIFS(float3 z)
{
    int FRACT_ITER      = 20;
    float FRACT_SCALE   = 1.8;
    float FRACT_OFFSET  = 1.0;

    float c = 2.0;
    z.y = modf(z.y, c)-c/2.0;
    z = rotateZ(z, PI/2.0);
    float r;
    int n1 = 0;
    for (int n = 0; n < FRACT_ITER; n++) {
        float rotate = PI*0.5;
        z = rotateX(z, rotate);
        z = rotateY(z, rotate);
        z = rotateZ(z, rotate);

        z.xy = abs(z.xy);
        if (z.x+z.y<0.0) z.xy = -z.yx; // fold 1
        if (z.x+z.z<0.0) z.xz = -z.zx; // fold 2
        if (z.y+z.z<0.0) z.zy = -z.yz; // fold 3
        z = z*FRACT_SCALE - FRACT_OFFSET*(FRACT_SCALE-1.0);
    }
    return (length(z) ) * pow(FRACT_SCALE, -float(FRACT_ITER));
}

float abstFractal(float3 z0)
{
    z0 = fmod(z0, 2.0);

    float mr=0.25, mxr=1.0;
    float4 scale=float4(-3.12,-3.12,-3.12,3.12), p0=float4(0.0,1.59,-1.0,0.0);
    float4 z = float4(z0,1.0);
    for (int n = 0; n < 3; n++) {
        z.xyz=clamp(z.xyz, -0.94, 0.94)*2.0-z.xyz;
        z*=scale/clamp(dot(z.xyz,z.xyz),mr,mxr);
        z+=p0;
    }
    float dS=(length(max(abs(z.xyz)-float3(1.2,49.0,1.4),0.0))-0.06)/z.w;
    return dS;
}

float hartverdrahtet(float3 f)
{
    float3 cs=float3(.808,.808,1.167);
    float fs=1.;
    float3 fc=0;
    float fu=10.;
    float fd=.763;
    
    // scene selection
    {
        float time = _Time.y;
        int i = int(fmod(time/2.0, 9.0));
        if(i==0) cs.y=.58;
        if(i==1) cs.xy=.5;
        if(i==2) cs.xy=.5;
        if(i==3) fu=1.01,cs.x=.9;
        if(i==4) fu=1.01,cs.x=.9;
        if(i==6) cs=float3(.5,.5,1.04);
        if(i==5) fu=.9;
        if(i==7) fd=.7,fs=1.34,cs.xy=.5;
        if(i==8) fc.z=-.38;
    }
    
    //cs += sin(time)*0.2;

    float v=1.;
    for(int i=0; i<12; i++){
        f=2.*clamp(f,-cs,cs)-f;
        float c=max(fs/dot(f,f),1.);
        f*=c;
        v*=c;
        f+=fc;
    }
    float z=length(f.xy)-fu;
    return fd*max(z,abs(length(f.xy)*f.z)/sqrt(dot(f,f)))/abs(v);
}

float pseudo_kleinian(float3 p)
{
    float3 CSize = float3(0.92436,0.90756,0.92436);
    float Size = 1.0;
    float3 C = float3(0.0,0.0,0.0);
    float DEfactor=1.;
    float3 Offset = float3(0.0,0.0,0.0);
    float3 ap=p+1.;
    for(int i=0;i<10 ;i++){
        ap=p;
        p=2.*clamp(p, -CSize, CSize)-p;
        float r2 = dot(p,p);
        float k = max(Size/r2,1.);
        p *= k;
        DEfactor *= k + 0.05;
        p += C;
    }
    float r = abs(0.5*abs(p.z-Offset.z)/DEfactor);
    return r;
}

float pseudo_knightyan(float3 p)
{
    float3 CSize = float3(0.63248,0.78632,0.875);
    float DEfactor=1.;
    for(int i=0;i<6;i++){
        p = 2.*clamp(p, -CSize, CSize)-p;
        float k = max(0.70968/dot(p,p),1.);
        p *= k;
        DEfactor *= k + 0.05;
    }
    float rxy=length(p.xy);
    return max(rxy-0.92784, abs(rxy*p.z) / length(p))/DEfactor;
}

/*----Tree----*/
/*
float c_t(vec3 pt, float x1, float x2, float x3)
{    
    mat4 posR = Rz(-(25.7/360.)*2.*PI);
    mat4 negR = Rz(25.7/360.*2.*PI);
    mat4 bendP = Ry(25.7/360.*2.*PI);
    mat4 bendR = Ry(-25.7/360.*2.*PI);
    
    const int depth = 7;
    const int branches = 3; 
    float len = 1.5;
    float wid = .05;
    float widf= .9;
    
    float trunk = sdCylinder(pt-vec3(0.,0., 0.), (wid));
    float d = trunk;
    float x = sdSphere((Disp(vec3(0.,-2.5*len,0.))*vec4(pt, 1.)).xyz,1.8*len);
    if (x > 2.*len/2.) return min(x,d);

    vec3 pt_n = pt;
      for (int i = 1; i <= depth; ++i)
      {
        wid *= widf;
        float l = len*pow(.5,float(i));
       
        mat4 mx1 = Rz(-0.2*sin(iTime+6.2))*posR*bendP*Disp(vec3(0,-2.*l - l/2.,0));

        mat4 wind = Rz(0.2*sin(iTime+6.2));
        mat4 mx2 = wind*negR*bendP*Disp(vec3(0,-2.*l,0));

        wind = Rz(0.2*sin(iTime+1.));
        mat4 mx3 = wind*Disp(vec3(0,-4.*l,0)) ;
        
        vec3 pt_1 = (mx1 * vec4(pt_n,1)).xyz;
        vec3 pt_2 = (mx2 * vec4(pt_n,1)).xyz;
        vec3 pt_3 = (mx3 * vec4(pt_n,1)).xyz;
          
        // bounding sphere test
        float z1 = sdSphere((Disp(vec3(0.,-x1*l,0.))*vec4(pt_1, 1.)).xyz,2.5*l);
        float z2 = sdSphere((Disp(vec3(0.,-x2*l,0.))*vec4(pt_2, 1.)).xyz,2.5*l);
        float z3 = sdSphere((Disp(vec3(0.,-x3*l,0.))*vec4(pt_3, 1.)).xyz,2.5*l);
          
        // potential cylinders
        float y1= sdCappedCylinder(pt_1, vec2(wid,l));
        float y2= sdCappedCylinder(pt_2, vec2(wid,l));
        float y3= sdCappedCylinder(pt_3, vec2(wid,l));

        // calc closest
        float mi = min(z1, min(z2,z3));
          
        vec3 pt = (z1<z2) ? pt_1 : pt_2;
        pt_n = (min(z1,z2)<z3) ? pt   : pt_3;

        d = min( d, min(y1,min(y2,y3)) );
        float epsilon = .5;
        #ifdef DEBUG
        epsilon = .0;
        #endif
        if (mi < epsilon) {continue;} 
          //break;
          return min(mi,d);
     }
   return d; 
    
}
*/