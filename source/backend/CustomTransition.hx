package backend;

import flixel.util.FlxGradient;

class CustomTransition extends MusicBeatSubstate
{
	public static var onFinish:Void->Void;
	var camTransition:PsychCamera; // so the camera will be on top!

	var finished:Bool = false;
	var transGradient:FlxSprite;
	var transBlack:FlxSprite;

	var duration:Float = 0.5;
	var isTransIn:Bool = false;
	public function new(duration:Float, isTransIn:Bool)
	{
		this.duration = duration;
		this.isTransIn = isTransIn;
		super();
	}

	override function create()
	{
		camTransition = new PsychCamera();
		camTransition.bgColor.alpha = 0;
		FlxG.cameras.add(camTransition, false);

		cameras = [camTransition];

		final width:Int = Std.int(FlxG.width / Math.max(camera.zoom, 0.001));
		final height:Int = Std.int(FlxG.height / Math.max(camera.zoom, 0.001));

		transGradient = FlxGradient.createGradientFlxSprite(1, height, (isTransIn ? [0x0, FlxColor.BLACK] : [FlxColor.BLACK, 0x0]));
		transGradient.scale.x = width;
		transGradient.updateHitbox();
		transGradient.scrollFactor.set();
		transGradient.screenCenter(X);
		add(transGradient);

		transBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		transBlack.scale.set(width, height + 400);
		transBlack.updateHitbox();
		transBlack.scrollFactor.set();
		transBlack.screenCenter(X);
		add(transBlack);

		if(!isTransIn) transGradient.y = -transGradient.height;
		else transGradient.y = transBlack.y - transBlack.height;

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(finished) close();

		final height:Float = FlxG.height * Math.max(camera.zoom, 0.001);
		final targetPos:Float = transGradient.height + 50 * Math.max(camera.zoom, 0.001);

		if(duration <= 0) transGradient.y = (targetPos) * elapsed;
		else transGradient.y += (height + targetPos) * elapsed / duration;

		if(!isTransIn) transBlack.y = transGradient.y - transBlack.height;
		else transBlack.y = transGradient.y + transGradient.height;

		if(transGradient.y >= targetPos) finished = true;
	}

	// Don't delete this
	override function close():Void
	{
		super.close();

		if(onFinish != null)
		{
			onFinish();
			onFinish = null;
		}
	}
}