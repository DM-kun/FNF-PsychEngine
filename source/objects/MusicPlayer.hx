package objects;

import flixel.group.FlxGroup;
import flixel.ui.FlxBar;
import flixel.util.FlxStringUtil;

/**
 * Music player used mainly for the Freeplay State
 * Modified to be used in other states as well
 * 
 * Requirements:
 * - public var holdTime:Float = 0;
 * - public var bottomString:String;
 * - public var bottomText:FlxText;
 */
class MusicPlayer extends FlxGroup 
{
	public var instance:Dynamic;
	public var controls:Controls;

	public var playing(get, never):Bool;
	private function get_playing():Bool 
		return FlxG.sound.music.playing;

	public var playingMusic:Bool = false;
	public var curTime:Float;

	public var voices:Array<FlxSound> = [];
	public var objects:Array<Dynamic> = [];

	public var songName:String = null;

	var songBG:FlxSprite;
	var songTxt:FlxText;
	var timeTxt:FlxText;
	var progressBar:FlxBar;
	var playbackBG:FlxSprite;
	var playbackSymbols:Array<FlxText> = [];
	var playbackTxt:FlxText;

	var wasPlaying:Bool = false;
	var muteVocals:Bool = false;

	var holdPitchTime:Float = 0;

	public var playbackRate(default, set):Float = 1;
	private function set_playbackRate(value:Float):Float
	{
		FlxG.sound.music.pitch = value;
		for(snd in voices)
		{
			if(snd == null) continue;
			snd.pitch = value;
		}
		return playbackRate = FlxMath.bound(FlxMath.roundDecimal(value, 2), 0.25, 3);
	}

	public function new(instance:Dynamic, controls:Controls, ?objects:Array<Dynamic> = null)
	{
		super();

		this.instance = instance;
		this.controls = controls;
		if(objects != null) this.objects = objects;

		final xPos:Float = FlxG.width * 0.7;

		songBG = new FlxSprite(xPos - 6, 0).makeGraphic(1, 100, 0xFF000000);
		songBG.alpha = 0.6;
		add(songBG);

		playbackBG = new FlxSprite(xPos - 6, 0).makeGraphic(1, 100, 0xFF000000);
		playbackBG.alpha = 0.6;
		add(playbackBG);

		songTxt = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		songTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		add(songTxt);

		timeTxt = new FlxText(xPos, songTxt.y + 60, 0, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		add(timeTxt);

		for(i in 0...2)
		{
			var text:FlxText = new FlxText();
			text.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER);
			text.text = '^';
			text.flipY = (i == 1);
			text.visible = false;
			playbackSymbols.push(text);
			add(text);
		}

		progressBar = new FlxBar(timeTxt.x, timeTxt.y + timeTxt.height, LEFT_TO_RIGHT, Std.int(timeTxt.width), 8, null, "", 0, Math.POSITIVE_INFINITY);
		progressBar.createFilledBar(FlxColor.WHITE, FlxColor.BLACK);
		add(progressBar);

		playbackTxt = new FlxText(FlxG.width * 0.6, 20, 0, "", 32);
		playbackTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE);
		add(playbackTxt);

		switchPlayMusic();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(!playingMusic) return;

		if(playing && !wasPlaying) songTxt.text = Language.getPhrase('musicplayer_playing', 'PLAYING: {1}', [songName]);
		else songTxt.text = Language.getPhrase('musicplayer_paused', 'PLAYING: {1} (PAUSED)', [songName]);

		if(controls.UI_LEFT_P)
		{
			if(playing) wasPlaying = true;

			pauseOrResume();

			curTime = FlxG.sound.music.time - 1000;
			instance.holdTime = 0;

			if(curTime < 0) curTime = 0;

			FlxG.sound.music.time = curTime;
			setVocalsTime(curTime);
		}
		if(controls.UI_RIGHT_P)
		{
			if(playing) wasPlaying = true;

			pauseOrResume();

			curTime = FlxG.sound.music.time + 1000;
			instance.holdTime = 0;

			if(curTime > FlxG.sound.music.length)
				curTime = FlxG.sound.music.length;

			FlxG.sound.music.time = curTime;
			setVocalsTime(curTime);
		}

		if(controls.UI_LEFT || controls.UI_RIGHT)
		{
			instance.holdTime += elapsed;
			if(instance.holdTime > 0.5) curTime += 40000 * elapsed * (controls.UI_LEFT ? -1 : 1);

			final difference:Float = Math.abs(curTime - FlxG.sound.music.time);
			if(curTime + difference > FlxG.sound.music.length) curTime = FlxG.sound.music.length;
			else if(curTime - difference < 0) curTime = 0;

			FlxG.sound.music.time = curTime;
			setVocalsTime(curTime);
		}

		if(controls.UI_LEFT_R || controls.UI_RIGHT_R)
		{
			FlxG.sound.music.time = curTime;
			setVocalsTime(curTime);

			if(wasPlaying)
			{
				pauseOrResume(true);
				wasPlaying = false;
			}
		}

		if(controls.UI_UP_P)
		{
			holdPitchTime = 0;
			playbackRate += 0.05;
		}
		else if(controls.UI_DOWN_P)
		{
			holdPitchTime = 0;
			playbackRate -= 0.05;
		}
		if(controls.UI_DOWN || controls.UI_UP)
		{
			holdPitchTime += elapsed;
			if(holdPitchTime > 0.6)
				playbackRate += 0.05 * (controls.UI_UP ? 1 : -1);
		}
	
		if(controls.RESET)
		{
			playbackRate = 1;
			FlxG.sound.music.time = 0;
			setVocalsTime(0);
		}

		if(FlxG.keys.justPressed.V) muteVocals = !muteVocals;

		if(playing)
		{
			var num:Int = 0;
			for(snd in voices)
			{
				if(snd == null || num != 0) continue;

				setVocalsVolume(0.8);
				if(snd.length > FlxG.sound.music.time && Math.abs(FlxG.sound.music.time - snd.time) >= 25)
				{
					pauseOrResume();
					setVocalsTime(FlxG.sound.music.time);
					pauseOrResume(true);
				}
				num++;
			}
		}

		positionSong();
		updateTimeTxt();
		updatePlaybackTxt();
	}

	function setVocalsVolume(volume:Float)
	{
		for(snd in voices)
		{
			if(snd == null) continue;
			if(muteVocals) snd.volume = 0;
			else snd.volume = (snd.length > FlxG.sound.music.time) ? volume : 0;
		}
	}

	function setVocalsTime(time:Float)
	{
		for(snd in voices)
		{
			if(snd == null) continue;
			if(snd.length > time) snd.time = time;
		}
	}

	public function pauseOrResume(resume:Bool = false) 
	{
		if(resume)
		{
			if(!FlxG.sound.music.playing)
				FlxG.sound.music.resume();

			for(snd in voices)
			{
				if(snd == null) continue;
				if(snd.length > FlxG.sound.music.time && !snd.playing)
					snd.resume();
			}
		}
		else 
		{
			FlxG.sound.music.pause();

			for(snd in voices)
			{
				if(snd == null) continue;
				snd.pause();
			}
		}
	}

	public function switchPlayMusic()
	{
		FlxG.autoPause = (!playingMusic && ClientPrefs.data.autoPause);
		active = visible = playingMusic;

		for(obj in objects) obj.visible = !playingMusic; //Hide selected objects if playingMusic is true
		songTxt.visible = timeTxt.visible = songBG.visible = playbackTxt.visible = playbackBG.visible = progressBar.visible = playingMusic; //Show Music Player texts and boxes if playingMusic is true

		for(i in playbackSymbols) i.visible = playingMusic;

		holdPitchTime = 0;
		instance.holdTime = 0;
		playbackRate = 1;
		updatePlaybackTxt();

		if(playingMusic)
		{
			instance.bottomText.text = Language.getPhrase('musicplayer_tip', 'Press SPACE to Pause / Press BACK to Exit / Press RESET to Reset the Song / Press V to Mute the Voices');
			positionSong();

			progressBar.setRange(0, FlxG.sound.music.length);
			progressBar.setParent(FlxG.sound.music, "time");
			progressBar.numDivisions = 1600;

			updateTimeTxt();
		}
		else
		{
			progressBar.setRange(0, Math.POSITIVE_INFINITY);
			progressBar.setParent(null, "");
			progressBar.numDivisions = 0;

			instance.bottomText.text = instance.bottomString;
		}
		progressBar.updateBar();
	}

	function updatePlaybackTxt()
	{
		var text:String = "";
		if(playbackRate is Int) text = playbackRate + '.00';
		else
		{
			var playbackRate:String = Std.string(playbackRate);
			// for Playback rates with only 1 decimal
			if(playbackRate.split('.')[1].length < 2) playbackRate += '0';
			text = playbackRate;
		}
		playbackTxt.text = text + 'x';
	}

	function positionSong() 
	{
		final length:Int = songName.length;
		final shortName:Bool = length < 5; // Fix for song names like Ugh, Guns

		songTxt.x = FlxG.width - songTxt.width - 6;
		if(shortName) songTxt.x -= 10 * length - length;

		songBG.scale.x = FlxG.width - songTxt.x + 12;
		if(shortName) songBG.scale.x += 6 * length;
		songBG.x = FlxG.width - (songBG.scale.x / 2);

		timeTxt.x = Std.int(songBG.x + (songBG.width / 2));
		timeTxt.x -= timeTxt.width / 2;
		if(shortName) timeTxt.x -= length - 5;

		playbackBG.scale.x = playbackTxt.width + 30;
		playbackBG.x = songBG.x - (songBG.scale.x / 2);
		playbackBG.x -= playbackBG.scale.x;

		playbackTxt.x = playbackBG.x - playbackTxt.width / 2;
		playbackTxt.y = playbackTxt.height;

		progressBar.setGraphicSize(Std.int(songTxt.width), 5);
		progressBar.y = songTxt.y + songTxt.height + 10;
		progressBar.x = songTxt.x + songTxt.width / 2 - 15;
		if(shortName)
		{
			progressBar.scale.x += length / 2;
			progressBar.x -= length - 10;
		}

		for(i in 0...2)
		{
			var text:FlxText = playbackSymbols[i];
			text.x = playbackTxt.x + playbackTxt.width / 2 - 10;
			text.y = playbackTxt.y;

			if(i == 0) text.y -= playbackTxt.height;
			else text.y += playbackTxt.height;
		}
	}

	function updateTimeTxt()
	{
		final text:String = FlxStringUtil.formatTime(FlxG.sound.music.time / 1000, false) + ' / ' + FlxStringUtil.formatTime(FlxG.sound.music.length / 1000, false);
		timeTxt.text = '< ' + text + ' >';
	}
}