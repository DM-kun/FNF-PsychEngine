package backend;

import haxe.io.Path;

// A class that simply points OpenALSoft to a custom configuration file when the game starts up.
// The config overrides a few global OpenALSoft settings with the aim of improving audio quality on desktop targets.
@:keep class ALSoftConfig
{
	#if desktop
	static final CONFIG_EXT = #if windows "ini" #else "conf" #end;
	static function __init__():Void
	{
		final origin:String = #if hl Sys.getCwd() #else Sys.programPath() #end;

		var configPath:String = Path.directory(Path.withoutExtension(origin));
		#if mac configPath = '${Path.directory(configPath)}/Resources'; #end
		configPath += '/plugins/alsoft';

		Sys.putEnv("ALSOFT_CONF", FileSystem.fullPath('$configPath.$CONFIG_EXT'));
	}
	#end
}