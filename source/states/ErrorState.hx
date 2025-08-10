package states;

class ErrorState extends MusicBeatState
{
	public var errorMsg:String;
	public var onAccept:Void->Void;
	public var onReturn:Void->Void;

	public function new(errorMsg:String, onAccept:Void->Void = null, onReturn:Void->Void = null)
	{
		this.errorMsg = errorMsg;
		this.onAccept = onAccept;
		this.onReturn = onReturn;

		super();
	}

	public var errorSine:Float = 0;
	public var errorText:FlxText;
	override function create()
	{
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = FlxColor.GRAY;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		errorText = new FlxText(0, 0, FlxG.width - 300, errorMsg, 32);
		errorText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		errorText.scrollFactor.set();
		errorText.borderSize = 2;
		errorText.screenCenter();
		add(errorText);

		super.create();
	}

	override function update(elapsed:Float)
	{
		errorSine += 180 * elapsed;
		errorText.alpha = 1 - Math.sin((Math.PI * errorSine) / 180);

		if(controls.ACCEPT && onAccept != null) onAccept();
		else if(controls.BACK && onReturn != null) onReturn();

		super.update(elapsed);
	}
}