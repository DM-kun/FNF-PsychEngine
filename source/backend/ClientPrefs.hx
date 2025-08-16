package backend;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

import states.InitState;

// Add a variable here and it will get automatically saved
@:structInit @:publicFields
class SaveVariables
{
	var downScroll:Bool = false;
	var middleScroll:Bool = false;
	var opponentStrums:Bool = true;
	var showFPS:Bool = true;
	var flashing:Bool = true;
	var autoPause:Bool = true;
	var antialiasing:Bool = true;
	var noteSkin:String = 'Default';
	var splashSkin:String = 'Psych';
	var splashAlpha:Float = 0.6;
	var lowQuality:Bool = false;
	var shaders:Bool = true;
	var cacheOnGPU:Bool = #if !switch false #else true #end; // GPU Caching made by Raltyro
	var framerate:Int = 60;
	var camZooms:Bool = true;
	var hideHud:Bool = false;
	var noteOffset:Int = 0;
	var ghostTapping:Bool = true;
	var timeBarType:String = 'Time Left';
	var scoreZoom:Bool = true;
	var noReset:Bool = false;
	var healthBarAlpha:Float = 1;
	var hitsoundVolume:Float = 0;
	var pauseMusic:String = 'Tea Time';
	var checkForUpdates:Bool = true;
	var comboStacking:Bool = true;
	var comboOffset:Array<Int> = [0, 0, 0, 0];
	var ratingOffset:Int = 0;
	var sickWindow:Float = 45.0;
	var goodWindow:Float = 90.0;
	var badWindow:Float = 135.0;
	var safeFrames:Float = 10.0;
	var guitarHeroSustains:Bool = true;
	var discordRPC:Bool = true;
	var loadingScreen:Bool = true;
	var language:String = 'en-US';

	var arrowRGB:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
	];
	var arrowRGBPixel:Array<Array<FlxColor>> = [
		[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
		[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
		[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000]
	];

	var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative', 
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false
	];
}

class ClientPrefs
{
	public static var save:FlxSave;

	public static var data:SaveVariables = {};
	public static var defaultData:SaveVariables = {};

	//Every key has two binds, add your key bind down here and then add your control on options/ControlsSubState.hx and Controls.hx
	public static var keyBinds:Map<String, Array<FlxKey>> = [
		//Key Bind, Name for ControlsSubState
		'note_up'		=> [W, UP],
		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_right'	=> [D, RIGHT],

		'ui_up'			=> [W, UP],
		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_right'		=> [D, RIGHT],

		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R],

		'volume_mute'	=> [ZERO],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],

		'debug_1'		=> [SEVEN],
		'debug_2'		=> [EIGHT]
	];
	public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
		'note_up'		=> [DPAD_UP, Y],
		'note_left'		=> [DPAD_LEFT, X],
		'note_down'		=> [DPAD_DOWN, A],
		'note_right'	=> [DPAD_RIGHT, B],

		'ui_up'			=> [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'ui_left'		=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'ui_down'		=> [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'ui_right'		=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],

		'accept'		=> [A, START],
		'back'			=> [B],
		'pause'			=> [START],
		'reset'			=> [BACK]
	];

	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;

	public static function resetKeys(controller:Null<Bool> = null) //Null = both, False = Keyboard, True = Controller
	{
		if(controller != true)
			for(key in keyBinds.keys())
				if(defaultKeys.exists(key))
					keyBinds.set(key, defaultKeys.get(key).copy());

		if(controller != false)
			for(button in gamepadBinds.keys())
				if(defaultButtons.exists(button))
					gamepadBinds.set(button, defaultButtons.get(button).copy());
	}

	public static function clearInvalidKeys(key:String)
	{
		var keyBind:Array<FlxKey> = keyBinds.get(key);
		var gamepadBind:Array<FlxGamepadInputID> = gamepadBinds.get(key);
		while(keyBind != null && keyBind.contains(NONE)) keyBind.remove(NONE);
		while(gamepadBind != null && gamepadBind.contains(NONE)) gamepadBind.remove(NONE);
	}

	public static function loadDefaultKeys()
	{
		defaultKeys = keyBinds.copy();
		defaultButtons = gamepadBinds.copy();
	}

	public static function createSettings()
	{
		if(save != null) return;

		save = new FlxSave();
		save.bind('options', CoolUtil.getSavePath());

		FlxG.log.add("Settings created!");
	}

	public static function saveSettings()
	{
		for(key in Reflect.fields(data))
			Reflect.setField(save.data, key, Reflect.field(data, key));

		save.flush();
		#if ACHIEVEMENTS_ALLOWED Achievements.save(); #end
		FlxG.save.flush();

		//Placing this in a separate save so that it can be manually deleted without removing your Score and stuff
		var conSave:FlxSave = new FlxSave();
		conSave.bind('controls_v3', CoolUtil.getSavePath());
		conSave.data.keyboard = keyBinds;
		conSave.data.gamepad = gamepadBinds;
		conSave.flush();

		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs()
	{
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end

		for(key in Reflect.fields(data))
			if(key != 'gameplaySettings' && Reflect.hasField(save.data, key))
				Reflect.setField(data, key, Reflect.field(save.data, key));

		if(Main.fpsVar != null) Main.fpsVar.visible = data.showFPS;

		#if (!html5 && !switch)
		FlxG.autoPause = data.autoPause;

		if(save.data.framerate == null)
		{
			final refreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
			data.framerate = Std.int(FlxMath.bound(refreshRate, 30, 360));
		}
		#end

		if(data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = data.framerate;
			FlxG.drawFramerate = data.framerate;
		}
		else
		{
			FlxG.drawFramerate = data.framerate;
			FlxG.updateFramerate = data.framerate;
		}

		if(save.data.gameplaySettings != null)
		{
			final savedMap:Map<String, Dynamic> = save.data.gameplaySettings;
			for(name => value in savedMap)
				data.gameplaySettings.set(name, value);
		}

		FlxG.game.stage.quality = data.antialiasing ? BEST : LOW;
		// FlxSprite.defaultAntialiasing = data.antialiasing;

		// flixel automatically saves your volume!
		if(FlxG.save.data.volume != null) FlxG.sound.volume = FlxG.save.data.volume;
		if(FlxG.save.data.mute != null) FlxG.sound.muted = FlxG.save.data.mute;

		#if DISCORD_ALLOWED DiscordClient.check(); #end

		// controls on a separate save file
		var conSave:FlxSave = new FlxSave();
		conSave.bind('controls_v3', CoolUtil.getSavePath());
		if(conSave != null)
		{
			if(conSave.data.keyboard != null)
			{
				var loadedControls:Map<String, Array<FlxKey>> = conSave.data.keyboard;
				for(control => keys in loadedControls)
					if(keyBinds.exists(control)) keyBinds.set(control, keys);
			}
			if(conSave.data.gamepad != null)
			{
				var loadedControls:Map<String, Array<FlxGamepadInputID>> = conSave.data.gamepad;
				for(control => keys in loadedControls)
					if(gamepadBinds.exists(control)) gamepadBinds.set(control, keys);
			}
			reloadVolumeKeys();
		}
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic
	{
		if(!customDefaultValue) defaultValue = defaultData.gameplaySettings.get(name);
		return /*PlayState.isStoryMode ? defaultValue : */ (data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadVolumeKeys()
	{
		InitState.muteKeys = keyBinds.get('volume_mute').copy();
		InitState.volumeDownKeys = keyBinds.get('volume_down').copy();
		InitState.volumeUpKeys = keyBinds.get('volume_up').copy();
		toggleVolumeKeys(true);
	}

	public static function toggleVolumeKeys(?turnOn:Bool = true)
	{
		final emptyArray = [];
		FlxG.sound.muteKeys = turnOn ? InitState.muteKeys : emptyArray;
		FlxG.sound.volumeDownKeys = turnOn ? InitState.volumeDownKeys : emptyArray;
		FlxG.sound.volumeUpKeys = turnOn ? InitState.volumeUpKeys : emptyArray;
	}
}