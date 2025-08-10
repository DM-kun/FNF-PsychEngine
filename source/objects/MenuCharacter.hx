package objects;

import openfl.utils.Assets;
import haxe.Json;

import objects.Character;

typedef MenuCharacterFile = {
	var animations:Array<Character.AnimArray>;

	var image:String;
	var scale:Float;
	var position:Array<Float>;
	var flip_x:Bool;
	var no_antialiasing:Bool;
}

class MenuCharacter extends PsychSprite
{
	public var curCharacter:String = null;
	public var curPosition:Int = 0;

	public var hasConfirmAnimation:Bool = false;
	public var loopDance:Bool = false;
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"

	public var positionArray:Array<Float> = [0, 0];

	public var missingCharacter:Bool = false;
	public var missingText:FlxText;

	public function new(x:Float, ?character:String = 'bf', ?position:Int = 0)
	{
		super(x);

		changeCharacter(character);
	}

	public function changeCharacter(?character:String = 'bf', ?position:Int = 0)
	{
		if(character == null) character = '';
		if(character == curCharacter) return;

		animOffsets.clear();
		curCharacter = character;
		curPosition = position;

		final characterPath:String = 'images/menucharacters/$character.json';
		var path:String = Paths.getPath(characterPath, TEXT);
		if(!Paths.fileExists(characterPath))
		{
			path = Paths.getSharedPath('images/menucharacters/' + Character.DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
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

		visible = (character != '');
		hasConfirmAnimation = hasAnimation('confirm');
		recalculateDanceIdle();
		dance();
	}

	public function loadCharacterFile(json:Dynamic)
	{
		scale.set(1, 1);
		updateHitbox();

		final imageFile:String = json.image;
		final imageSheets:Array<String> = [for(img in imageFile.split(',')) 'menucharacters/$img'];
		/*final animJson:String = 'images/' + json.image + '/Animation.json';
		if(Paths.fileExists(animJson)) frames = Paths.getAnimateAtlas(json.image);
		else*/ frames = Paths.getMultiAtlas(imageSheets);

		if(json.scale != 1)
		{
			scale.set(json.scale, json.scale);
			updateHitbox();
		}

		positionArray = json.position;
		flipX = (json.flip_x == true);
		antialiasing = ClientPrefs.data.antialiasing ? (json.no_antialiasing == false) : false;

		final animArray:Array<Character.AnimArray> = json.animations;
		if(animArray != null && animArray.length > 0)
			for(fAnim in animArray)
			{
				if(fAnim.anim == null || fAnim.name == null) continue;

				final animAnim:String = fAnim.anim;
				final animName:String = fAnim.name;
				final animIndices:Array<Int> = fAnim.indices;
				final animFps:Int = fAnim.fps;
				final animLoop:Bool = (fAnim.loop == true);
				final animOffs:Array<Float> = fAnim.offsets;

				try // is there any better way to do this???
				{
					if(animIndices != null && animIndices.length > 0)
						anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
					else
						anim.addBySymbol(animAnim, animName, animFps, animLoop);

					if(!hasAnimation(animAnim)) throw new haxe.Exception('Failed to add Animate Symbol Animation!');
				}
				catch(e:Dynamic)
				{
					if(animIndices != null && animIndices.length > 0)
						anim.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
					else
						anim.addByPrefix(animAnim, animName, animFps, animLoop);
				}

				if(animOffs != null && animOffs.length > 1) addOffset(animAnim, animOffs[0], animOffs[1]);
				else addOffset(animAnim, 0, 0);
			}
	}

	public var danced:Bool = false;
	public function dance()
	{
		if(loopDance) return;

		if(danceIdle)
		{
			danced = !danced;
			playAnim(danced ? 'danceRight' : 'danceLeft');
		}
		else if(hasAnimation('idle'))
			playAnim('idle');
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle()
	{
		final lastDanceIdle:Bool = danceIdle;
		danceIdle = (hasAnimation('danceLeft') && hasAnimation('danceRight'));

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
}