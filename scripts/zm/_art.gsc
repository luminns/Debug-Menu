#using scripts\codescripts\struct;

#using scripts\shared\system_shared;
#using scripts\shared\util_shared;

#using scripts\zm\menu\core;

#insert scripts\shared\shared.gsh;

#namespace art;

REGISTER_SYSTEM( "art", &__init__, undefined )

// This function should take care of grain and glow settings for each map, plus anything else that artists 
// need to be able to tweak without bothering level designers.

function __init__()
{
	if( !isdefined( level.dofDefault ) )
	{
		level.dofDefault["nearStart"] = 0; 
		level.dofDefault["nearEnd"] = 1; 
		level.dofDefault["farStart"] = 8000; 
		level.dofDefault["farEnd"] = 10000; 
		level.dofDefault["nearBlur"] = 6; 
		level.dofDefault["farBlur"] = 0; 
	}

	level.curDoF = ( level.dofDefault["farStart"] - level.dofDefault["nearEnd"] ) / 2; 
	
	if( !isdefined( level.script ) )
	{
		level.script = tolower( GetDvarString( "mapname" ) ); 
	}	
}

function artfxprintln( file, string )
{
}


// Nate - hack Fixmed and replace with proper script command call once it's fixed.
// assumes " " as the deliiter. I'm not getting fancy.  
// I would really like to go work on jeepride so here's a 
// quick function that works for now untill engineering fixes strtok.

function strtok_loc( string, par1 )
{
	stringlist = []; 
	indexstring = ""; 
	for( i = 0 ; i < string.size ; i ++ )
	{
		if( string[i] == " " )
		{
			stringlist[stringlist.size] = indexstring; 
			indexstring = ""; 
		}
		else
		{
			indexstring = indexstring+string[i]; 
		}
	}
	if( indexstring.size )
	{
		stringlist[stringlist.size] = indexstring; 
	}
	return stringlist; 
}


function setfogsliders()
{
	//fixme.  replace strtok_loc with strtok if it ever works properly.
	fogall = strtok_loc( GetDvarString( "g_fogColorReadOnly" ), " " ) ;
	red = fogall[ 0 ];
	green = fogall[ 1 ];
	blue = fogall[ 2 ];
	halfplane = GetDvarString( "g_fogHalfDistReadOnly" );
	nearplane = GetDvarString( "g_fogStartDistReadOnly" );
		
	if ( !isdefined( red )
		 || !isdefined( green )
		 || !isdefined( blue )
		 || !isdefined( halfplane )
		 )
	{
		red = 1;
		green = 1;
		blue = 1;
		halfplane = 10000001;
		nearplane = 10000000;
	}
	SetDvar("scr_fog_exp_halfplane",halfplane);
	SetDvar("scr_fog_nearplane",nearplane);
	SetDvar("scr_fog_color",red+" "+green+" "+blue);
}

function tweakart()
{
	 /#
	if( !isdefined( level.tweakfile ) )
	{
		level.tweakfile = false; 
	}
	

	// Default values
	
	if(GetDvarString( "scr_fog_baseheight") == "")
	{
		SetDvar( "scr_fog_exp_halfplane", "500" ); 
		SetDvar( "scr_fog_exp_halfheight", "500" ); 
		SetDvar( "scr_fog_nearplane", "0" ); 
		SetDvar( "scr_fog_baseheight", "0" ); 
	}

	// not in DEVGUI
	SetDvar( "scr_fog_fraction", "1.0" ); 
	SetDvar( "scr_art_dump", "0" ); 
	SetDvar("scr_art_sun_fog_dir_set", "0");

	// update the devgui variables to current settings
	SetDvar( "scr_dof_nearStart", level.dofDefault["nearStart"] ); 
	SetDvar( "scr_dof_nearEnd", level.dofDefault["nearEnd"] ); 
	SetDvar( "scr_dof_farStart", level.dofDefault["farStart"] ); 
	SetDvar( "scr_dof_farEnd", level.dofDefault["farEnd"] ); 
	SetDvar( "scr_dof_nearBlur", level.dofDefault["nearBlur"] ); 
	SetDvar( "scr_dof_farBlur", level.dofDefault["farBlur"] ); 	


	file = undefined; 
	filename = undefined; 
	
	// set dofvars from < levelname > _art.gsc
	
	
	tweak_toggle = 1;	
	for( ;; )
	{
		while(GetDvarint( "scr_art_tweak" ) == 0 )
		{
			tweak_toggle = 1;
			wait .05; 
		}
		
		if(tweak_toggle)
		{
			tweak_toggle = 0;
			fogsettings = getfogsettings();

			SetDvar( "scr_fog_nearplane", fogsettings[0] ); 
			SetDvar( "scr_fog_exp_halfplane", fogsettings[1] ); 
			SetDvar( "scr_fog_exp_halfheight", fogsettings[3] ); 
			SetDvar( "scr_fog_baseheight", fogsettings[2] ); 

			SetDvar("scr_fog_color", fogsettings[4]+" "+fogsettings[5]+" "+fogsettings[6]);
			SetDvar("scr_fog_color_scale", fogsettings[7]);
			SetDvar("scr_sun_fog_color", fogsettings[8]+" "+fogsettings[9]+" "+fogsettings[10]);
			
			level.fogsundir = [];
			level.fogsundir[0] = fogsettings[11];
			level.fogsundir[1] = fogsettings[12];
			level.fogsundir[2] = fogsettings[13];

			SetDvar("scr_sun_fog_start_angle",fogsettings[14] );
			SetDvar("scr_sun_fog_end_angle",fogsettings[15] );

			SetDvar("scr_fog_max_opacity", fogsettings[16]);
		
		
		}
		
		//translate the slider values to script variables

		level.fogexphalfplane = GetDvarfloat( "scr_fog_exp_halfplane");
		level.fogexphalfheight = GetDvarfloat( "scr_fog_exp_halfheight");
		level.fognearplane = GetDvarfloat( "scr_fog_nearplane");
		level.fogbaseheight = GetDvarfloat( "scr_fog_baseheight");

		colors = StrTok(GetDvarString("scr_fog_color")," ");
		level.fogcolorred = int(colors[0]);
		level.fogcolorgreen = int(colors[1]);
		level.fogcolorblue = int(colors[2]);
		level.fogcolorscale = GetDvarfloat( "scr_fog_color_scale");

		colors = StrTok(GetDvarString("scr_sun_fog_color")," ");
		level.sunfogcolorred = int(colors[0]);
		level.sunfogcolorgreen = int(colors[1]);
		level.sunfogcolorblue = int(colors[2]);
		
		level.sunstartangle = GetDvarfloat( "scr_sun_fog_start_angle");
		level.sunendangle = GetDvarfloat( "scr_sun_fog_end_angle");
		level.fogmaxopacity = GetDvarfloat( "scr_fog_max_opacity");

		if(	GetDvarint( "scr_art_sun_fog_dir_set") ) 
		{
			SetDvar( "scr_art_sun_fog_dir_set", "0" );
			
			println("Setting sun fog direction to facing of player");
			
			players = GetPlayers();

			dir = VectorNormalize( AnglesToForward( players[0] GetPlayerAngles() ) );

			level.fogsundir = [];
			level.fogsundir[0] = dir[0];
			level.fogsundir[1] = dir[1];
			level.fogsundir[2] = dir[2];
		}
		
		
		// catch all those cases where a slider can be pushed to a place of conflict
		fovslidercheck(); 

		dumpsettings(); // dumps and returns true if the dump dvar is set
		
		// updates fog to the variables

		if ( ! GetDvarint( "scr_fog_disable" ) )
		{
			if(!isdefined(level.fogsundir)) {
				level.fogsundir = [];
				level.fogsundir[0] = 1;
				level.fogsundir[1] = 0;
				level.fogsundir[2] = 0;
			}

			setVolFog( level.fognearplane, level.fogexphalfplane, level.fogexphalfheight, level.fogbaseheight, level.fogcolorred, level.fogcolorgreen, level.fogcolorblue, 
				level.fogcolorscale, level.sunfogcolorred, level.sunfogcolorgreen, level.sunfogcolorblue, level.fogsundir[0], level.fogsundir[1], level.fogsundir[2], level.sunstartangle, level.sunendangle, 0, level.fogmaxopacity ); 
		}
		else
		{
			setExpFog( 100000000, 100000001, 0, 0, 0, 0 ); // couldn't find discreet fog disabling other than to never set it in the first place
		}

		wait .1; 
	}
	#/ 
}         

function fovslidercheck()
{
	// catch all those cases where a slider can be pushed to a place of conflict
	if( level.dofDefault["nearStart"] >= level.dofDefault["nearEnd"] )
	{
		level.dofDefault["nearStart"] = level.dofDefault["nearEnd"] - 1; 
		SetDvar( "scr_dof_nearStart", level.dofDefault["nearStart"] ); 
	}
	if( level.dofDefault["nearEnd"] <= level.dofDefault["nearStart"] )
	{
		level.dofDefault["nearEnd"] = level.dofDefault["nearStart"] + 1; 
		SetDvar( "scr_dof_nearEnd", level.dofDefault["nearEnd"] ); 
	}
	if( level.dofDefault["farStart"] >= level.dofDefault["farEnd"] )
	{
		level.dofDefault["farStart"] = level.dofDefault["farEnd"] - 1; 
		SetDvar( "scr_dof_farStart", level.dofDefault["farStart"] ); 
	}
	if( level.dofDefault["farEnd"] <= level.dofDefault["farStart"] )
	{
		level.dofDefault["farEnd"] = level.dofDefault["farStart"] + 1; 
		SetDvar( "scr_dof_farEnd", level.dofDefault["farEnd"] ); 
	}
	if( level.dofDefault["farBlur"] >= level.dofDefault["nearBlur"] )
	{
		level.dofDefault["farBlur"] = level.dofDefault["nearBlur"] - .1; 
		SetDvar( "scr_dof_farBlur", level.dofDefault["farBlur"] ); 
	}
	if( level.dofDefault["farStart"] <= level.dofDefault["nearEnd"] )
	{
		level.dofDefault["farStart"] = level.dofDefault["nearEnd"] + 1; 
		SetDvar( "scr_dof_farStart", level.dofDefault["farStart"] ); 
	}
} 

function dumpsettings()
{
}
