package objects;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

class StrumNote extends PsychSprite
{
	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	private var player:Int;

	// https://github.com/ShadowMario/FNF-PsychEngine/pull/14987
	private var _dirSin:Float;
	private var _dirCos:Float;
	public var direction(default, set):Float;
	private function set_direction(_fDir:Float):Float
	{
		_dirSin = Math.sin(_fDir * 0.01745329251);
		_dirCos = Math.cos(_fDir * 0.01745329251);
		return direction = _fDir;
	}

	public var texture(default, set):String = null;
	private function set_texture(value:String):String
	{
		if(texture != value) reloadNote();
		return texture = value;
	}

	public var useRGBShader:Bool = true;
	public function new(x:Float, y:Float, noteData:Int, player:Int)
	{
		super(x, y);

		direction = 90;
		antialiasing = ClientPrefs.data.antialiasing;

		this.player = player;
		this.noteData = noteData;
		this.ID = noteData;

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));
		rgbShader.enabled = false;
		if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) useRGBShader = false;

		final arr:Array<FlxColor> = PlayState.isPixelStage ? ClientPrefs.data.arrowRGBPixel[noteData] : ClientPrefs.data.arrowRGB[noteData];
		if(noteData <= arr.length)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}

		texture = '';
		scrollFactor.set();
		playAnim('static');
	}

	static var _lastValidChecked:String; //optimization
	public function reloadNote(texture:String = '', postfix:String = '')
	{
		if(texture == null) texture = '';
		if(postfix == null) postfix = '';

		var skin:String = texture + postfix;
		if(texture.length < 1)
		{
			skin = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null;
			if(skin == null || skin.length < 1) skin = Note.defaultNoteSkin + postfix;
		}
		else rgbShader.enabled = false;

		final animName:String = (!isAnimationNull()) ? getAnimationName() : null;
		var skinPixel:String = skin;
		var skinPostfix:String = Note.getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		var path:String = PlayState.isPixelStage ? 'pixelUI/' : '';
		if(customSkin == _lastValidChecked || Paths.fileExists('images/' + path + customSkin + '.png', IMAGE))
		{
			skin = customSkin;
			_lastValidChecked = customSkin;
		}
		else skinPostfix = '';

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + skinPixel + skinPostfix));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + skinPixel + skinPostfix), true, Math.floor(width), Math.floor(height));
			loadPixelNoteAnims();
			antialiasing = false;
		}
		else
		{
			frames = Paths.getSparrowAtlas(skin);
			loadNoteAnims();
			antialiasing = ClientPrefs.data.antialiasing;
		}
		updateHitbox();

		if(animName != null) playAnim(animName, true);
	}

	function loadNoteAnims()
	{
		addAnim('purple', 'arrowLEFT');
		addAnim('blue', 'arrowDOWN');
		addAnim('green', 'arrowUP');
		addAnim('red', 'arrowRIGHT');
		switch(Math.abs(noteData) % 4)
		{
			case 0:
				addAnim('static', 'arrowLEFT');
				addAnim('pressed', 'left press', null, 24, false);
				addAnim('confirm', 'left confirm', null, 24, false);
			case 1:
				addAnim('static', 'arrowDOWN');
				addAnim('pressed', 'down press', null, 24, false);
				addAnim('confirm', 'down confirm', null, 24, false);
			case 2:
				addAnim('static', 'arrowUP');
				addAnim('pressed', 'up press', null, 24, false);
				addAnim('confirm', 'up confirm', null, 24, false);
			case 3:
				addAnim('static', 'arrowRIGHT');
				addAnim('pressed', 'right press', null, 24, false);
				addAnim('confirm', 'right confirm', null, 24, false);
		}
		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	function loadPixelNoteAnims()
	{
		anim.add('purple', [4]);
		anim.add('blue', [5]);
		anim.add('green', [6]);
		anim.add('red', [7]);
		switch(Math.abs(noteData) % 4)
		{
			case 0:
				anim.add('static', [0]);
				anim.add('pressed', [4, 8], 12, false);
				anim.add('confirm', [12, 16], 12, false);
			case 1:
				anim.add('static', [1]);
				anim.add('pressed', [5, 9], 12, false);
				anim.add('confirm', [13, 17], 12, false);
			case 2:
				anim.add('static', [2]);
				anim.add('pressed', [6, 10], 12, false);
				anim.add('confirm', [14, 18], 12, false);
			case 3:
				anim.add('static', [3]);
				anim.add('pressed', [7, 11], 12, false);
				anim.add('confirm', [15, 19], 12, false);
		}
		setGraphicSize(Std.int(width * PlayState.daPixelZoom));
		updateHitbox();
	}

	public function playerPosition()
	{
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);
	}

	override function update(elapsed:Float)
	{
		if(resetAnim > 0)
		{
			resetAnim -= elapsed;
			if(resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}

		super.update(elapsed);
	}

	public override function playAnim(name:String, ?forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0):Void
	{
		super.playAnim(name, forced);

		if(!isAnimationNull())
		{
			centerOffsets();
			centerOrigin();
		}

		if(useRGBShader)
		{
			rgbShader.enabled = (!isAnimationNull() && getAnimationName() != 'static');
			/*if(note != null) rgbShader.copyValues(note.rgbShader.parent);
			else rgbShader.copyValues(Note.globalRgbShaders[noteData % Note.colArray.length]);*/
		}
	}

	override public function destroy()
	{
		super.destroy();
		_lastValidChecked = '';
	}
}