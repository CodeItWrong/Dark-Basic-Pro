string description = "Relief Mapping by Fabio Policarpo";

float tile
<
	string UIName = "Tile Factor";
	string UIWidget = "slider";
	float UIMin = 1.0;
	float UIStep = 1.0;
	float UIMax = 32.0;
> = 2;

float depth
<
	string UIName = "Depth Factor";
	string UIWidget = "slider";
	float UIMin = 0.0f;
	float UIStep = 0.01f;
	float UIMax = 0.25f;
> = 0.005;

float3 ambient
<
	string UIName = "Ambient";
	string UIWidget = "color";
> = {0.3,0.3,0.3};

float3 diffuse
<
	string UIName = "Diffuse";
	string UIWidget = "color";
> = {1,1,1};

float3 specular
<
	string UIName = "Specular";
	string UIWidget = "color";
> = {0.4,0.4,0.4};

float shine
<
    string UIName = "Shine";
	string UIWidget = "slider";
	float UIMin = 8.0f;
	float UIStep = 8;
	float UIMax = 256.0f;
> = 128.0;


float3 lightpos : POINTLIGHT
<
	string UIName="Light Position";
> = { 0.0, 40.0, 820.0 };

float4x4 modelviewproj : WorldViewProjection;
float4x4 modelview : WorldView;
float4x4 modelinv : WorldInverse;
float4x4 view : View;

texture texmap : DIFFUSE
<
    string Name = "rockwall.jpg";
    string Type = "2D";
>;

texture reliefmap : NORMAL
<
    string Name = "rockwall.tga";
    string Type = "2D";
>;

sampler2D texmap_sampler = sampler_state
{
	Texture = <texmap>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

sampler2D reliefmap_sampler = sampler_state
{
	Texture = <reliefmap>;
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
};

struct a2v 
{
    float4 pos		: POSITION;
    float4 color	: COLOR0;
    float3 normal	: NORMAL;
    float2 txcoord	: TEXCOORD0;
    float3 tangent	: TANGENT0;
    float3 binormal	: BINORMAL0;
};

struct v2f
{
    float4 hpos		: POSITION;
	float4 color	: COLOR0;
    float2 txcoord	: TEXCOORD0;
    float3 vpos		: TEXCOORD1;
    float3 tangent	: TEXCOORD2;
    float3 binormal	: TEXCOORD3;
    float3 normal	: TEXCOORD4;
	float4 lightpos	: TEXCOORD5;
};

v2f view_space(a2v IN)
{
	v2f OUT;

	// vertex position in object space
	float4 pos=float4(IN.pos.x,IN.pos.y,IN.pos.z,1.0);

	// compute modelview rotation only part
	float3x3 modelviewrot;
	modelviewrot[0]=modelview[0].xyz;
	modelviewrot[1]=modelview[1].xyz;
	modelviewrot[2]=modelview[2].xyz;

	// vertex position in clip space
	OUT.hpos=mul(pos,modelviewproj);

	// vertex position in view space (with model transformations)
	OUT.vpos=mul(pos,modelview).xyz;

	// light position in view space
	float4 lp=float4(lightpos.x,lightpos.y,lightpos.z,1);
	OUT.lightpos=mul(lp,view);

	// tangent space vectors in view space (with model transformations)
	OUT.tangent=mul(IN.tangent,modelviewrot);
	OUT.binormal=mul(IN.binormal,modelviewrot);
	OUT.normal=mul(IN.normal,modelviewrot);
	
	// copy color and texture coordinates
	OUT.color=IN.color;
	OUT.txcoord=IN.txcoord.xy;

	return OUT;
}

float4 normal_map(
	v2f IN,
	uniform sampler2D texmap,
	uniform sampler2D reliefmap) : COLOR
{
	float4 normal=tex2D(reliefmap,IN.txcoord);//*tile);
	normal.xy=normal.xy*2.0-1.0; // trafsform to [-1,1] range
	normal.z=sqrt(1.0-dot(normal.xy,normal.xy)); // compute z component
	
	// transform normal to world space
	normal.xyz=normalize(normal.x*IN.tangent-normal.y*IN.binormal+normal.z*IN.normal);
	
	// color map
	float4 color=tex2D(texmap,IN.txcoord);//*tile);

	// view and light directions
	float3 v = normalize(IN.vpos);
	float3 l = normalize(IN.lightpos.xyz-IN.vpos);

	// compute diffuse and specular terms
	float att=saturate(dot(l,IN.normal.xyz));
	float diff=saturate(dot(l,normal.xyz));
	float spec=saturate(dot(normalize(l-v),normal.xyz));

	// compute final color
	float4 finalcolor;
	finalcolor.xyz=ambient*color.xyz+
		att*(color.xyz*diffuse.xyz*diff+specular.xyz*pow(spec,shine));
	finalcolor.w=1.0;

	return finalcolor;
}

float4 parallax_map(
	v2f IN,
	uniform sampler2D texmap,
	uniform sampler2D reliefmap) : COLOR
{
   	// view and light directions
	float3 v = normalize(IN.vpos);
	float3 l = normalize(IN.lightpos.xyz-IN.vpos);

	float2 uv = IN.txcoord;//*tile;

	// parallax code
	float3x3 tbn = float3x3(IN.tangent,IN.binormal,IN.normal);
	float height = tex2D(reliefmap,uv).w * 0.02 - 0.01;
	uv += height * mul(tbn,v);

	// normal map
	float4 normal=tex2D(reliefmap,uv);
	normal.xy=normal.xy*2.0-1.0; // trafsform to [-1,1] range
	normal.z=sqrt(1.0-dot(normal.xy,normal.xy)); // compute z component

	// transform normal to world space
	normal.xyz=normalize(normal.x*IN.tangent-normal.y*IN.binormal+normal.z*IN.normal);

	// color map
	float4 color=tex2D(texmap,uv);

	// compute diffuse and specular terms
	float att=saturate(dot(l,IN.normal.xyz));
	float diff=saturate(dot(l,normal.xyz));
	float spec=saturate(dot(normalize(l-v),normal.xyz));

	// compute final color
	float4 finalcolor;
	finalcolor.xyz=ambient*color.xyz+
		att*(color.xyz*diffuse.xyz*diff+specular.xyz*pow(spec,shine));
	finalcolor.w=1.0;

	return finalcolor;
}

float ray_intersect_rm(
		in sampler2D reliefmap,
		in float2 dp, 
		in float2 ds)
{
	const int linear_search_steps=15;
	const int binary_search_steps=5;
	float depth_step=1.0/linear_search_steps;

	// current size of search window
	float size=depth_step;
	// current depth position
	float depth=0.0;
	// best match found (starts with last position 1.0)
	float best_depth=1.0;

	// search front to back for first point inside object
	for( int i=0;i<linear_search_steps-1;i++ )
	{
		depth+=size;
		float4 t=tex2D(reliefmap,dp+ds*depth);

		if (best_depth>0.996)	// if no depth found yet
		if (depth>=t.w)
			best_depth=depth;	// store best depth
	}
	depth=best_depth;
	
	// recurse around first point (depth) for closest match
	for( int i=0;i<binary_search_steps;i++ )
	{
		size*=0.5;
		float4 t=tex2D(reliefmap,dp+ds*depth);
		if (depth>=t.w)
		{
			best_depth=depth;
			depth-=2*size;
		}
		depth+=size;
	}

	return best_depth;
}

float ray_intersect_rm2(
		in sampler2D reliefmap,
		in float2 dp, 
		in float2 ds)
{
	const int linear_search_steps=15;
	const int binary_search_steps=5;
	float depth_step=1.0/linear_search_steps;

	// current size of search window
	float size=depth_step;
	// current depth position
	float depth=0.0;
	// best match found (starts with last position 1.0)
	float best_depth=1.0;

	// search front to back for first point inside object
	for( int i=0;i<linear_search_steps-1;i++ )
	{
		depth+=size;
		float4 t=tex2Dlod(reliefmap,float4(dp+ds*depth,0,0));

		if (best_depth>0.996)	// if no depth found yet
		if (depth>=t.w)
			best_depth=depth;	// store best depth
	}
	depth=best_depth;
	
	// recurse around first point (depth) for closest match
	for( int i=0;i<binary_search_steps;i++ )
	{
		size*=0.5;
		float4 t=tex2Dlod(reliefmap,float4(dp+ds*depth,0,0));
		if (depth>=t.w)
		{
			best_depth=depth;
			depth-=2*size;
		}
		depth+=size;
	}

	return best_depth;
}


float4 relief_map(
	v2f IN,
	uniform sampler2D texmap,
	uniform sampler2D reliefmap) : COLOR
{
	float4 t;
	float3 p,v,l,s,c;
	float2 dp,ds,uv;
	float d,a;

	// ray intersect in view direction
	p  = IN.vpos;
	v  = normalize(p);
	a  = dot(IN.normal,-v);
	s  = normalize(float3(dot(v,IN.tangent),dot(v,IN.binormal),a));
	s *= depth/a;
	ds = s.xy;
	//dp = IN.txcoord*tile;
	dp = IN.txcoord;
	d  = ray_intersect_rm(reliefmap,dp,ds);
	
	// get rm and color texture points
	uv=dp+ds*d;
	t=tex2D(reliefmap,uv);
	c=tex2D(texmap,uv);

	// expand normal from normal map in local polygon space
	t.xy=t.xy*2.0-1.0;
	t.z=sqrt(1.0-dot(t.xy,t.xy));
	t.xyz=normalize(t.x*IN.tangent-t.y*IN.binormal+t.z*IN.normal);

	// compute light direction
	p += v*d*a;
	l=normalize(p-IN.lightpos.xyz);
	
	// compute diffuse and specular terms
	float att=saturate(dot(-l,IN.normal.xyz));
	float diff=saturate(dot(-l,t.xyz));
	float spec=saturate(dot(normalize(-l-v),t.xyz));

	// compute final color
	float4 finalcolor;
	finalcolor.xyz=ambient*c+att*(c*diffuse*diff+specular.xyz*pow(spec,shine));
	finalcolor.w=1.0;

	return finalcolor;
}

float4 relief_map_shadows(
	v2f IN,
	uniform sampler2D texmap,
	uniform sampler2D reliefmap) : COLOR
{
	float4 t;
	float3 p,v,l,s,c;
	float2 dp,ds,uv;
	float d,a;

	// ray intersect in view direction
	p  = IN.vpos;
	v  = normalize(p);
	a  = dot(IN.normal,-v);
	s  = normalize(float3(dot(v,IN.tangent),dot(v,IN.binormal),a));
	s  *= depth/a;
	ds = s.xy;
	dp = IN.txcoord;
	d  = ray_intersect_rm(reliefmap,dp,ds);
	
	// get rm and color texture points
	uv=dp+ds*d;
	t=tex2D(reliefmap,uv);
	c=tex2D(texmap,uv);

	// expand normal from normal map in local polygon space
	t.xy=t.xy*2.0-1.0;
	t.z=sqrt(1.0-dot(t.xy,t.xy));
	t.xyz=normalize(t.x*IN.tangent-t.y*IN.binormal+t.z*IN.normal);

	// compute light direction
	p += v*d*a;
	l=normalize(p-IN.lightpos.xyz);

	// ray intersect in light direction
	dp+= ds*d;
	a  = dot(IN.normal,-l);
	s  = normalize(float3(dot(l,IN.tangent),dot(l,IN.binormal),a));
	s *= depth/a;
	ds = s.xy;
	dp-= ds*d;
	float dl = ray_intersect_rm(reliefmap,dp,s.xy);
	float shadow = 1.0;
	if (dl<d-0.05) // if pixel in shadow
	{
		shadow=dot(ambient,1)*0.333333;
		specular=0;
	}

	// compute diffuse and specular terms
	float att=saturate(dot(-l,IN.normal.xyz));
	float diff=shadow*saturate(dot(-l,t.xyz));
	float spec=saturate(dot(normalize(-l-v),t.xyz));

	// compute final color
	float4 finalcolor;
	finalcolor.xyz=ambient*c+att*(c*diffuse*diff+specular.xyz*pow(spec,shine));
	finalcolor.w=1.0;

	return finalcolor;
}

float4 dynamic_map(
	v2f IN,
	uniform sampler2D texmap,
	uniform sampler2D reliefmap) : COLOR
{
     // float3 vpos = normalize(IN.vpos);
	//float fDist = dot(-vpos,IN.normal);

      float2 dx = ddx( IN.txcoord );
      float2 dy = ddy( IN.txcoord );

	if ( dot(IN.vpos,IN.vpos) > 16100 )
      {
          //return parallax_map(IN,texmap,reliefmap);
          //return float4(1.0,0,0,0);

          float4 normal=tex2Dgrad(reliefmap,IN.txcoord,dx,dy);//*tile);
	    normal.xy=normal.xy*2.0-1.0; // trafsform to [-1,1] range
	    normal.z=sqrt(1.0-dot(normal.xy,normal.xy)); // compute z component
	
	    // transform normal to world space
	    normal.xyz=normalize(normal.x*IN.tangent-normal.y*IN.binormal+normal.z*IN.normal);
	
	    // color map
	    float4 color=tex2Dgrad(texmap,IN.txcoord,dx,dy);//*tile);

	    // view and light directions
	    float3 v = normalize(IN.vpos);
	    float3 l = normalize(IN.lightpos.xyz-IN.vpos);

	    // compute diffuse and specular terms
	    float att=saturate(dot(l,IN.normal.xyz));
	    float diff=saturate(dot(l,normal.xyz));
	    float spec=saturate(dot(normalize(l-v),normal.xyz));

	    // compute final color
	    float4 finalcolor;
	    finalcolor.xyz=ambient*color.xyz+
	        	att*(color.xyz*diffuse.xyz*diff+specular.xyz*pow(spec,shine));
	    finalcolor.w=1.0;

	    return finalcolor;



      }
      else
      {
          //if ( fDist <= 8100 )
	    //{

              //return relief_map(IN,texmap,reliefmap);
	        //return float4(0,1.0,0,0);


              float4 t;
	        float3 p,v,l,s,c;
	        float2 dp,ds,uv;
	        float d,a;

	        // ray intersect in view direction
	        p  = IN.vpos;
	        v  = normalize(p);
	        a  = dot(IN.normal,-v);
	        s  = normalize(float3(dot(v,IN.tangent),dot(v,IN.binormal),a));
	        s *= depth/a;
	        ds = s.xy;
	        //dp = IN.txcoord*tile;
	        dp = IN.txcoord;
	        d  = ray_intersect_rm2(reliefmap,dp,ds);
	
	        // get rm and color texture points
	        uv=dp+ds*d;
	        t=tex2Dgrad(reliefmap,uv,dx,dy);
	        c=tex2Dgrad(texmap,uv,dx,dy);

	        // expand normal from normal map in local polygon space
	        t.xy=t.xy*2.0-1.0;
	        t.z=sqrt(1.0-dot(t.xy,t.xy));
	        t.xyz=normalize(t.x*IN.tangent-t.y*IN.binormal+t.z*IN.normal);

	        // compute light direction
	        p += v*d*a;
	        l=normalize(p-IN.lightpos.xyz);
	
	        // compute diffuse and specular terms
	        float att=saturate(dot(-l,IN.normal.xyz));
	        float diff=saturate(dot(-l,t.xyz));
	        float spec=saturate(dot(normalize(-l-v),t.xyz));

	        // compute final color
	        float4 finalcolor;
	        finalcolor.xyz=ambient*c+att*(c*diffuse*diff+specular.xyz*pow(spec,shine));
	        finalcolor.w=1.0;

	        return finalcolor;



          //}
          //else
          //{
          //    fDist = ( sqrt(fDist) - 90.0 ) / 10.0;
              
          //    float4 value1 = relief_map(IN,texmap,reliefmap);
          //    float4 value2 = parallax_map(IN,texmap,reliefmap);

          //    return lerp(value1,value2,float4(fDist,fDist,fDist,fDist));
          //}
      }
}

technique dynamic_mapping
{
    pass p0
    {
      CullMode = CCW;
            VertexShader = compile vs_1_1 view_space();
            PixelShader  = compile ps_3_0 dynamic_map(texmap_sampler,reliefmap_sampler);
    }
}

technique relief_mapping
{
    pass p0 
    {
    	CullMode = CCW;
		VertexShader = compile vs_1_1 view_space();
		PixelShader  = compile ps_2_a relief_map(texmap_sampler,reliefmap_sampler);
    }
}

technique relief_mapping_shadows
{
    pass p0 
    {
    	CullMode = CCW;
		VertexShader = compile vs_1_1 view_space();
		PixelShader  = compile ps_2_a relief_map_shadows(texmap_sampler,reliefmap_sampler);
    }
}

technique parallax_mapping
{
    pass p0 
    {
    	CullMode = CCW;
		VertexShader = compile vs_1_1 view_space();
		PixelShader  = compile ps_2_0 parallax_map(texmap_sampler,reliefmap_sampler);
    }
}

technique normal_mapping
{
    pass p0 
    {
    	CullMode = CCW;
		VertexShader = compile vs_1_1 view_space();
		PixelShader  = compile ps_2_0 normal_map(texmap_sampler,reliefmap_sampler);
    }
}


