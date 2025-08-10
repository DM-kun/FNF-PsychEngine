package objects;

class MenuItem extends FlxSprite
{
	private var isFlashing:Bool = false;
	private var flashingElapsed:Float = 0;
	final flashes_ps:Int = 6;

	public var targetY:Float = 0;
	public var flashColor:FlxColor = 0xFF33FFFF;

	public function new(x:Float, y:Float, weekName:String = '', ?flashColor:FlxColor = 0xFF33FFFF)
	{
		super(x, y);

		loadGraphic(Paths.image('storymenu/$weekName'));
		antialiasing = ClientPrefs.data.antialiasing;
		this.flashColor = flashColor;
	}

	public function startFlashing()
	{
		flashingElapsed = 0;
		color = flashColor;
		isFlashing = true;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(!isFlashing) return;

		flashingElapsed += elapsed;
		color = (Math.floor(flashingElapsed * FlxG.updateFramerate * flashes_ps) % 2 == 0) ? flashColor : FlxColor.WHITE;
	}
}