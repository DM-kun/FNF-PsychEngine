package objects;

import backend.animation.PsychAnimationController;
import flixel.util.FlxDestroyUtil;

class HealthIcon extends PsychSprite
{
	public var sprTracker:FlxSprite;
	public var autoAdjustOffset:Bool = true;

	private var isAnimated:Bool = false;
	private var iconOffsets:FlxPoint = FlxPoint.get(0, 0);
	private var curCharacter:String = null;
	private var allowGPU:Bool = true;

	public var char(get, set):String;
	private function get_char():String
		return curCharacter;

	private function set_char(value:String):String
	{
		if(curCharacter != value) changeIcon(value);
		return curCharacter = value;
	}

	public var isPlayer(default, set):Bool = false;
	private function set_isPlayer(value:Bool):Bool
		return flipX = value;

	public function new(char:String = 'face', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();

		animation = new PsychAnimationController(this);
		scrollFactor.set();

		this.allowGPU = allowGPU;
		this.char = char;
		this.isPlayer = isPlayer;
	}

	public function changeIcon(texture:String = '', ?allowGPU:Null<Bool> = null)
	{
		if(texture == null || texture.length < 1) texture = 'face';
		if(allowGPU == null) allowGPU = this.allowGPU;

		var name:String = texture;
		if(!Paths.fileExists('images/icons/$name.png', IMAGE)) name = 'icon-$texture'; //Older versions of psych engine's support
		if(!Paths.fileExists('images/icons/$name.png', IMAGE)) name = 'icon-face'; //Prevents crash from missing icon

		var graphic = Paths.image('icons/$name', allowGPU);
		var iSize:Float = Math.round(graphic.width / graphic.height);
		loadGraphic(graphic, true, Math.floor(graphic.width / iSize), Math.floor(graphic.height));
		iconOffsets.x = (width - 150) / iSize;
		iconOffsets.y = (height - 150) / iSize;
		updateHitbox();

		animation.add(texture, [for(i in 0...frames.frames.length) i], 0, false);
		animation.play(texture);

		if(texture.endsWith('-pixel')) antialiasing = false;
		else antialiasing = ClientPrefs.data.antialiasing;

		curCharacter = texture;
	}

	public override function playAnim(name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
	{
		if(isAnimated) super.playAnim(name, forced, reverse, startFrame);
		else animation.curAnim.curFrame = Std.parseInt(name);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		if(autoAdjustOffset)
		{
			offset.x = iconOffsets.x;
			offset.y = iconOffsets.y;
		}
	}

	override function destroy()
	{
		iconOffsets = FlxDestroyUtil.put(iconOffsets);
		super.destroy();
	}
}