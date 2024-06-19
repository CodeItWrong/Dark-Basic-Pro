// Reflective/Refractive Bumpy Fresnel Water 
// by Evolved
// http://www.vector3r.com/

//-----------------
// un-tweaks
//-----------------
 matrix WorldVP:WorldViewProjection; 
 matrix World:World;   
 matrix ViewInv:ViewInverse; 
 float time : Time ;

//-----------------
// tweaks
//-----------------
 float WaterScale = 20.0f;
 float WaterBump = 0.01f;
 float2 Speed1 = { -0.02, 0.0 };
 float2 Speed2 = { 0.0 , 0.02 };
 float2 Speed3 = { 0.02 , 0.02 };
 float FresnelScale = 10.0f;
 float FresnelBump = 0.3f;

//-----------------
// Texture
//-----------------
 texture WaterbumpTX <string Name=""; >; 
 sampler2D Waterbump=sampler_state 
     {
	Texture = <WaterbumpTX>;
	MagFilter = Linear;	
	MinFilter = Point;
	MipFilter = None;
     };
 texture WaterRefractTX <string Name=""; >;	
 sampler2D WaterRefract=sampler_state
     {
	Texture = <WaterRefractTX>;
   	ADDRESSU = CLAMP;
   	ADDRESSV = CLAMP;
   	ADDRESSW = CLAMP;
     };
 texture WaterReflectTX <string Name=""; >;	
 sampler2D WaterReflect=sampler_state
     {
	Texture = <WaterReflectTX>;
   	ADDRESSU = CLAMP;
   	ADDRESSV = CLAMP;
   	ADDRESSW = CLAMP;
     };

//-----------------
// structs 
//-----------------
 struct input
     {
 	float4 Pos : POSITION; 
 	float2 UV : TEXCOORD; 
 	float3 Normal : NORMAL; 
 	float3 Tangent : TANGENT;
 	float3 Binormal : BINORMAL; 
     };
 struct output
     {
 	float4 OPos : POSITION; 
 	float2 Tex1 : TEXCOORD0; 
 	float2 Tex2 : TEXCOORD1; 
	float2 Tex3 : TEXCOORD2; 
	float3 ViewVec : TEXCOORD3; 
	float3 ViewFre : TEXCOORD4; 
    	float4 Proj : TEXCOORD5; 
     };

//-----------------
// vertex shader
//-----------------
 output VS(input IN) 
     {
 	output OUT;
	OUT.OPos = mul(IN.Pos,WorldVP); 
 
	OUT.Tex1 = IN.UV*WaterScale*0.5+(time*Speed1);
	OUT.Tex2 = IN.UV*WaterScale    +(time*Speed2);
	OUT.Tex3 = IN.UV*WaterScale*1.5+(time*Speed3);

	float3 WP = mul(IN.Pos,World); 
	float3 WN = mul(IN.Normal,World); WN = normalize(WN);
	float3 WT = mul(IN.Tangent,World); WT = normalize(WT);
	float3 WB = mul(IN.Binormal,World); WB = normalize(WB);
	float3x3 TBN = {WT,WB,WN}; TBN = transpose(TBN);

	float3 VP = ViewInv[3].xyz-WP; 
 	OUT.ViewVec = mul(VP,TBN); 
	OUT.ViewFre = -VP/(-VP.y*FresnelScale); 
  
	float4x4 scalemat = float4x4(0.5,0,0,0.5,0,-0.5,0,0.5,0,0,0.5,0.5,0,0,0,1);
  	OUT.Proj = mul(scalemat,OUT.OPos);

	return OUT;
    }

//-----------------
// pixel shader
//-----------------
 float4 PS(output IN) : COLOR 
  {
     float4 Distort = (tex2D(Waterbump, IN.Tex1)*2-1)*0.33333;
            Distort = Distort+(Distort,tex2D(Waterbump, IN.Tex2)*2-1)*0.33333;
            Distort = Distort+(Distort,tex2D(Waterbump, IN.Tex3)*2-1)*0.33333;
 
    float3 ViewT = normalize(IN.ViewVec);
    float  ViewB = saturate(dot(ViewT,Distort));
    float  Fresnel = 1-saturate(dot(IN.ViewFre,IN.ViewFre));
           Fresnel = saturate((Fresnel*(1-FresnelBump))+(ViewB*FresnelBump));

    	   Distort=Distort*(IN.Proj.z*WaterBump);
    float4 Refraction = tex2Dproj(WaterRefract,IN.Proj+Distort);
    float4 Reflection = tex2Dproj(WaterReflect,IN.Proj+Distort);
    float4 FresnelWater = lerp(Reflection,Refraction,Fresnel);

     return FresnelWater;
     //return Fresnel;
 }

//-----------------
// techniques   
//-----------------
technique Water
 {
  pass p1
   {		
    VertexShader = compile vs_2_0 VS(); 
    PixelShader = compile ps_2_0 PS(); 		
   }
  }
