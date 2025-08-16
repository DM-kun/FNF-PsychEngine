package backend;

import lime.system.System;

#if (cpp && windows)
import lime.app.Application;
import lime.system.Display;

// not sure which ones to keep and which ones to remove...
@:buildXml('
<target id="haxe">
	<lib name="dwmapi.lib" if="windows"/>
	<lib name="gdi32.lib" if="windows"/>
</target>
')
@:cppFileCode('
#include <windows.h>
#include <dwmapi.h>
#include <winuser.h>
#include <wingdi.h>
')
#end
class Native
{
	#if (cpp && windows)
	public static function __init__():Void
	{
		registerDPIAware();
	}

	public static function registerDPIAware():Void
	{
		// DPI Scaling fix for windows 
		// this shouldn't be needed for other systems
		// Credit to YoshiCrafter29 for finding this function
		untyped __cpp__('
			SetProcessDPIAware();	
			#ifdef DPI_AWARENESS_CONTEXT
			SetProcessDpiAwarenessContext(
				#ifdef DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
				DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2
				#else
				DPI_AWARENESS_CONTEXT_SYSTEM_AWARE
				#endif
			);
			#endif
		');
	}

	private static var fixedScaling:Bool = false;
	public static function fixScaling():Void
	{
		if(fixedScaling) return;
		fixedScaling = true;

		final display:Null<Display> = System.getDisplay(0);
		if (display != null)
		{
			final dpiScale:Float = display.dpi / 96;
			Application.current.window.resize(Std.int(Main.game.width * dpiScale), Std.int(Main.game.height * dpiScale));
			Application.current.window.x = Std.int((Application.current.window.display.bounds.width - Application.current.window.width) / 2);
			Application.current.window.y = Std.int((Application.current.window.display.bounds.height - Application.current.window.height) / 2);
		}
	}
	#end

	private static var closedGame:Bool = false;
	public static function exitGame():Void
	{
		if(closedGame) return;
		closedGame = true;

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end
	}

	public static function exitGameError():Void
	{
		if(closedGame) return;
		exitGame();
		System.exit(1);
	}
}