package;

#if android
import android.content.Context;
#end

import debug.FPSCounter;

import flixel.FlxGame;
import flixel.util.FlxSave;

import haxe.io.Path;
import lime.app.Application;

import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;

#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import psychlua.HScript.HScriptInfos;
#end

#if (linux || mac)
import lime.graphics.Image;
#end

#if desktop
import backend.ALSoftConfig; // Just to make sure DCE doesn't remove this, since it's not directly referenced anywhere else.
#end

//crash handler stuff
#if CRASH_HANDLER
import haxe.CallStack;
import openfl.events.UncaughtErrorEvent;
#end

#if (linux && !debug)
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end

class Main extends Sprite
{
	public static final game = {
		width: 1280, // GAME width
		height: 720, // GAME height
		initialState: states.InitState, // initial game state
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var fpsVar:FPSCounter;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		#if (cpp && windows) backend.Native.fixScaling(); #end

		// Credits to MAJigsaw77 (he's the og author for this code)
		#if android
		Sys.setCwd(Path.addTrailingSlash(Context.getExternalFilesDir()));
		#elseif ios
		Sys.setCwd(lime.system.System.applicationStorageDirectory);
		#end

		#if VIDEOS_ALLOWED hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0")  ['--no-lua'] #end); #end

		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		ClientPrefs.createSettings();

		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();

		#if MODS_ALLOWED Mods.pushGlobalMods(); #end
		Mods.loadTopMod();

		#if HSCRIPT_ALLOWED
		function getIrisInfo(x:Any, ?pos:haxe.PosInfos):String
		{
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			return msgInfo;
		}

		Iris.warn = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(WARN, x, pos);
			PlayState.instance?.addTextToDebug('WARNING: ' + getIrisInfo(x, pos), FlxColor.YELLOW, false);
		}
		Iris.error = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(ERROR, x, pos);
			PlayState.instance?.addTextToDebug('ERROR: ' + getIrisInfo(x, pos), FlxColor.RED, true);
		}
		Iris.fatal = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(FATAL, x, pos);
			PlayState.instance?.addTextToDebug('FATAL: ' + getIrisInfo(x, pos), 0xFFBB0000, true);
		}
		#end

		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call)); #end

		var funkin:FlxGame = new FlxGame(game.width, game.height, game.initialState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen);
		// @:privateAccess funkin._customSoundTray = backend.CustomSoundTray;
		addChild(funkin);

		#if !mobile
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		fpsVar.visible = ClientPrefs.data.showFPS;

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		#end

		#if (linux || mac) // fix the app icon not showing up on the Linux Panel / Mac Dock
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end

		// shader coords fix
		FlxG.signals.gameResized.add(function(w, h)
		{
			if(FlxG.cameras != null)
			{
				for(cam in FlxG.cameras.list)
				{
					if(cam != null && cam.filters != null)
						resetSpriteCache(cam.flashSprite);
				}
			}

			if(FlxG.game != null) resetSpriteCache(FlxG.game);
		});
	}

	static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess {
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "PsychEngine_" + dateNow + ".txt";

		for(stackItem in callStack)
		{
			switch(stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + ":" + line + "\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error;
		#if officialBuild
		errMsg += "\nPlease report this error to the GitHub page:";
		errMsg += "\nhttps://github.com/DM-kun/FNF-PsychEngine";
		#end
		errMsg += "\n\n> Crash Handler written by: sqirra-rng";

		if(!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Application.current.window.alert(errMsg, "Error!");
		backend.Native.exitGameError();
		//FlxG.resetGame();
	}
	#end
}