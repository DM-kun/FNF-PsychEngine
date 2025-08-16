package objects;

import openfl.utils.Assets;
import haxe.Json;

import backend.Song;
import states.stages.objects.TankmenBG;

typedef CharacterFile = {
	var animations:Array<AnimArray>;

	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var vocals_file:String;

	@:optional var death_data:DeathData;
	@:optional var speaker:SpeakerData;
	@:optional var _editor_isPlayer:Null<Bool>;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Float;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Float>;
	@:optional var flipX:Bool;
	@:optional var flipY:Bool;
}

typedef DeathData = {
	var character:String;
	var start_sound:String;
	var end_sound:String;
	var music:String;
	var music_bpm:Float;
}

typedef SpeakerData = {
	var name:String;
	var position:Array<Float>;
	var on_top:Bool;
}

class Character extends PsychSprite
{
	/**
	 * In case a character is missing, it will use this on its place
	**/
	public static final DEFAULT_CHARACTER:String = 'bf';

	public var extraData:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var debugMode:Bool = false;

	@:isVar public var isPlayer(get, set):Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var missingCharacter:Bool = false;
	public var missingText:FlxText;
	public var hasMissAnimations:Bool = false;
	public var vocalsFile:String = '';

	public var deathData:DeathData = null;
	public var speakerData:SpeakerData = null;

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var editorIsPlayer:Null<Bool> = null;

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false, ?parentFolder:String = 'characters')
	{
		super(x, y);

		changeCharacter(character, parentFolder);
		this.isPlayer = isPlayer;

		anim.onFinish.add(function(animName:String)
		{
			specialAnim = false;
			if(hasAnimation('$animName-loop') && !debugMode)
				playAnim('$animName-loop');
		});

		switch(curCharacter)
		{
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
			case 'pico-blazin', 'darnell-blazin':
				skipDance = true;
		}
	}

	public function changeCharacter(character:String, ?parentFolder:String = 'characters')
	{
		animationsArray = [];
		animOffsets.clear();

		curCharacter = character;

		final characterPath:String = '$parentFolder/$character.json';
		var path:String = Paths.getPath(characterPath, TEXT);
		if(!Paths.fileExists(characterPath))
		{
			path = Paths.getSharedPath('$parentFolder/$DEFAULT_CHARACTER.json'); //If a character couldn't be found, change him to BF just to prevent a crash
			missingCharacter = true;
			missingText = new FlxText(0, 0, 300, 'ERROR:\n$character.json', 16);
			missingText.alignment = CENTER;
		}

		try
		{
			#if MODS_ALLOWED
			loadCharacterFile(Json.parse(File.getContent(path)));
			#else
			loadCharacterFile(Json.parse(Assets.getText(path)));
			#end
		}
		catch(e:Dynamic)
		{
			trace('Error loading character file of "$character": $e');
		}

		skipDance = false;
		hasMissAnimations = hasAnimation('singLEFTmiss') || hasAnimation('singDOWNmiss') || hasAnimation('singUPmiss') || hasAnimation('singRIGHTmiss');
		recalculateDanceIdle();
		dance();
	}

	public function loadCharacterFile(json:Dynamic)
	{
		scale.set(1, 1);
		updateHitbox();

		frames = Paths.getMultiAtlas(json.image.split(','));

		imageFile = json.image;
		jsonScale = json.scale;
		if(json.scale != 1)
		{
			scale.set(jsonScale, jsonScale);
			updateHitbox();
		}

		// positioning
		positionArray = json.position;
		cameraPosition = json.camera_position;

		// data
		healthIcon = json.healthicon;
		singDuration = json.sing_duration;
		healthColorArray = (json.healthbar_colors != null && json.healthbar_colors.length > 2) ? json.healthbar_colors : [161, 161, 161];
		vocalsFile = json.vocals_file != null ? json.vocals_file : '';
		originalFlipX = (json.flip_x == true);
		deathData = json.death_data;
		speakerData = json.speaker;
		editorIsPlayer = json._editor_isPlayer;

		// antialiasing
		noAntialiasing = (json.no_antialiasing == true);
		antialiasing = ClientPrefs.data.antialiasing ? !noAntialiasing : false;

		// animations
		animationsArray = json.animations;
		if(animationsArray != null && animationsArray.length > 0)
			for(fAnim in animationsArray)
			{
				if(fAnim.anim == null || fAnim.name == null) continue;

				final animName:String = fAnim.anim;
				final animPrefix:String = fAnim.name;
				final animIndices:Array<Int> = fAnim.indices;
				final animFps:Float = fAnim.fps;
				final animLoop:Bool = (fAnim.loop == true);
				final animFlipX:Bool = (fAnim.flipX == true);
				final animFlipY:Bool = (fAnim.flipY == true);
				final animOffs:Array<Float> = fAnim.offsets;

				addAnim(animName, animPrefix, animIndices, animFps, animLoop, animFlipX, animFlipY);
				if(animOffs != null && animOffs.length > 1) addOffset(animName, animOffs[0], animOffs[1]);
				else addOffset(animName, 0, 0);
			}

		//trace('Loaded file to character ' + curCharacter);
	}

	override function update(elapsed:Float)
	{
		if(debugMode || isAnimationNull())
		{
			super.update(elapsed);
			return;
		}

		final name:String = getAnimationName();
		if(heyTimer > 0)
		{
			final rate:Float = (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
			heyTimer -= elapsed * rate;
			if(heyTimer <= 0)
			{
				if(specialAnim && (name == 'hey' || name == 'cheer'))
				{
					specialAnim = false;
					dance();
				}
				heyTimer = 0;
			}
		}
		else if(specialAnim && isAnimationFinished())
		{
			specialAnim = false;
			dance();
		}
		else if(name.endsWith('miss') && isAnimationFinished())
		{
			dance();
			finishAnimation();
		}

		switch(curCharacter)
		{
			case 'pico-speaker':
				if(animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
				{
					var noteData:Int = 1;
					if(animationNotes[0][1] > 2) noteData = 3;

					noteData += FlxG.random.int(0, 1);
					playAnim('shoot' + noteData, true);
					animationNotes.shift();
				}
				if(isAnimationFinished()) playAnim(name, false, false, anim.curAnim.frames.length - 3);
		}

		if(name.startsWith('sing')) holdTimer += elapsed;
		else if(isPlayer) holdTimer = 0;

		if(!isPlayer && holdTimer >= Conductor.stepCrochet * (0.0011 #if FLX_PITCH / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1) #end) * singDuration)
		{
			dance();
			holdTimer = 0;
		}

		super.update(elapsed);
	}

	public var danced:Bool = false;
	public function dance()
	{
		if(!debugMode && !skipDance && !specialAnim)
		{
			if(danceIdle)
			{
				danced = !danced;
				playAnim((danced ? 'danceRight' : 'danceLeft') + idleSuffix);
			}
			else if(hasAnimation('idle' + idleSuffix))
				playAnim('idle' + idleSuffix);
		}
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle()
	{
		final lastDanceIdle:Bool = danceIdle;
		danceIdle = (hasAnimation('danceLeft' + idleSuffix) && hasAnimation('danceRight' + idleSuffix));

		if(settingCharacterUp) danceEveryNumBeats = (danceIdle ? 1 : 2);
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle) calc /= 2;
			else calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public override function playAnim(name:String, ?forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0):Void
	{
		specialAnim = false;

		if(name.endsWith('alt') && !hasAnimation(name))
			name = name.split('-')[0];

		super.playAnim(name, forced, reverse, startFrame);

		if(curCharacter.startsWith('gf-') || curCharacter == 'gf')
		{
			if(name.startsWith('singLEFT')) danced = true;
			else if(name.startsWith('singRIGHT')) danced = false;

			if(name.startsWith('singUP') || name.startsWith('singDOWN'))
				danced = !danced;
		}
	}

	function loadMappedAnims():Void
	{
		try
		{
			final songData:SwagSong = Song.getChart('speaker', Paths.formatToSongPath(Song.loadedSongName));
			if(songData != null)
				for(section in songData.notes)
					for(songNotes in section.sectionNotes)
						animationNotes.push(songNotes);

			TankmenBG.animationNotes = animationNotes;
			animationNotes.sort(sortAnims);
		}
		catch(e:Dynamic)
		{
			FlxG.log.warn("Failed to load mapped Animations!");
		}
	}

	@:noCompletion
	private function get_isPlayer():Bool
	{
		return isPlayer;
	}
	@:noCompletion
	private function set_isPlayer(value:Bool):Bool
	{
		flipX = value;
		return isPlayer = value;
	}

	@:noCompletion
	override function set_flipX(value:Bool):Bool
	{
		value = (originalFlipX != value);
		return super.set_flipX(value);
	}

	public override function draw()
	{
		final lastAlpha:Float = alpha;
		final lastColor:FlxColor = color;
		if(missingCharacter)
		{
			alpha *= 0.6;
			color = FlxColor.BLACK;
		}

		super.draw();

		if(missingCharacter && visible)
		{
			alpha = lastAlpha;
			color = lastColor;
			missingText.x = getMidpoint().x - 150;
			missingText.y = getMidpoint().y - 10;
			missingText.cameras = cameras;
			missingText.draw();
		}
	}
}