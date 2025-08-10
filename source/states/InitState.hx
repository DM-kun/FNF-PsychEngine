package states;

import flixel.input.keyboard.FlxKey;

class InitState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	override public function create():Void
	{
		trace('Initializing...');

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		super.create();

		#if MODS_ALLOWED Mods.pushGlobalMods(); #end
		Mods.loadTopMod();

		ClientPrefs.loadPrefs();
		Language.reloadPhrases();
		Difficulty.resetList();
		Highscore.load();
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end

		#if html5 FlxG.autoPause = false; #end
		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 30;
		FlxG.keys.preventDefaultKeys = [TAB];

		if(FlxG.save.data != null && FlxG.save.data.fullscreen)
			FlxG.fullscreen = FlxG.save.data.fullscreen;

		persistentUpdate = persistentDraw = true;

		if(FlxG.save.data.weekCompleted != null)
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

		FlxG.mouse.visible = false;

		#if DISCORD_ALLOWED DiscordClient.prepare(); #end

		trace('Init Done!');
		MusicBeatState.switchState(new TitleState());
	}
}