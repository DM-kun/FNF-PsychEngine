package backend;

import flixel.system.ui.FlxSoundTray;
import openfl.display.Bitmap;

class CustomSoundTray extends FlxSoundTray
{
	public var lerpPos:FlxPoint = FlxPoint.get(0, 0);
	public var alphaTarget:Float = 0;

	public var volumeImagePath:String = '';
	public var volumeImages:Array<String> = [];

	public var volumeSoundPath:String = '';
	public var volumeMaxSound:String = 'flixel/sounds/beep';

	public function new()
	{
		super();

		// clears everything for your own custom tray
		clearTray();

		// default tray if there is no custom one
		createDefaultTray();
	}

	private function createDefaultTray()
	{
		volumeImagePath = volumeSoundPath = 'soundTray/';
		volumeUpSound = 'up';
		volumeDownSound = 'down';
		volumeMaxSound = 'max';

		var bg:Bitmap = new Bitmap(Paths.image(volumeImagePath + 'volumebox', false).bitmap);
		bg.scaleX = bg.scaleY = 0.3;
		bg.smoothing = ClientPrefs.data.antialiasing;
		addChild(bg);
		volumeImages.push('volumebox');

		y = -height;
		visible = false;

		var backingBar:Bitmap = new Bitmap(Paths.image(volumeImagePath + 'bars_10', false).bitmap);
		backingBar.x = 9;
		backingBar.y = 5;
		backingBar.scaleX = backingBar.scaleY = 0.3;
		backingBar.smoothing = ClientPrefs.data.antialiasing;
		addChild(backingBar);
		backingBar.alpha = 0.4;

		for(i in 1...11)
		{
			var bar:Bitmap = new Bitmap(Paths.image(volumeImagePath + 'bars_$i', false).bitmap);
			bar.x = 9;
			bar.y = 5;
			bar.scaleX = bar.scaleY = 0.3;
			bar.smoothing = ClientPrefs.data.antialiasing;
			addChild(bar);
			_bars.push(bar);
			volumeImages.push('bars_$i');
		}

		screenCenter();

		cacheTray();
	}

	public function clearTray()
	{
		removeChildren();
		_bars = [];

		volumeImagePath = volumeSoundPath = '';
		volumeImages = [];
		volumeUpSound = volumeDownSound = volumeMaxSound = 'flixel/sounds/beep';
	}

	public function cacheTray()
	{
		for(img in volumeImages)
			Paths.excludeAsset(Paths.getPath('images/$volumeImagePath' + '$img.png', IMAGE));

		for(snd in [volumeUpSound, volumeDownSound, volumeMaxSound])
		{
			Paths.excludeAsset(Paths.getPath('sounds/$volumeSoundPath' + '$snd.${Paths.SOUND_EXT}', SOUND));
			Paths.sound(volumeSoundPath + snd);
		}
	}

	override public function update(ms:Float):Void
	{
		y = smoothLerp(y, lerpPos.y, ms / 1000, 0.768);
		alpha = smoothLerp(alpha, alphaTarget, ms / 1000, 0.307);

		if(!FlxG.sound.muted && FlxG.sound.volume > 0)
		{
			if(_timer > 0) _timer -= (ms / 1000);
			else if (y >= -height)
			{
				lerpPos.y = -height - 10;
				alphaTarget = 0;
			}

			if(y <= -height) visible = active = false;
		}
		else if(!visible) moveTrayMakeVisible();
	}

	override public function show(up:Bool = false):Void
	{
		moveTrayMakeVisible(up);
	}

	public function moveTrayMakeVisible(up:Bool = false):Void
	{
		lerpPos.y = 10;
		_timer = alphaTarget = 1;
		visible = active = true;

		for(i => bar in _bars)
			bar.visible = (i < getGlobalVolume(up));
	}

	public function getGlobalVolume(up:Bool = false):Int
	{
		final globalVolume:Int = (FlxG.sound.muted || FlxG.sound.volume == 0) ? 0 : Math.round(logToLinear(FlxG.sound.volume) * 10);

		if(!silent)
		{
			final sound:String = (globalVolume == 10) ? volumeMaxSound : (up ? volumeUpSound : volumeDownSound);
			if(sound != null && sound.length > 0)
				FlxG.sound.load(Paths.sound(volumeSoundPath + sound)).play().volume = 0.3;
		}

		return globalVolume;
	}

	// taken from FunkinCrew
	public static function logToLinear(x:Float, minValue:Float = 0.001):Float
	{
		// If logarithmic volume is 0, return 0
		if(x <= 0) return 0;

		// Ensure x is between minValue and 1
		x = Math.min(1, x);

		// Convert logarithmic scale to linear
		return 1 - (Math.log(Math.max(x, minValue)) / Math.log(minValue));
	}
	public static function smoothLerp(current:Float, target:Float, elapsed:Float, duration:Float, precision:Float = 1 / 100):Float
	{
		// An alternative algorithm which uses a separate half-life value:
		// var halfLife:Float = -duration / logBase(2, precision);
		// lerp(current, target, 1 - exp2(-elapsed / halfLife));

		if(current == target) return target;

		var result:Float = lerp(current, target, 1 - Math.pow(precision, elapsed / duration));

		// TODO: Is there a better way to ensure a lerp which actually reaches the target?
		// Research a framerate-independent PID lerp.
		if(Math.abs(result - target) < (precision * target)) result = target;

		return result;
	}
	public static function lerp(base:Float, target:Float, progress:Float):Float
	{
		return base + progress * (target - base);
	}
}