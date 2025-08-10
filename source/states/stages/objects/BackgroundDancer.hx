package states.stages.objects;

class BackgroundDancer extends FlxSprite
{
	public function new(x:Float, y:Float)
	{
		super(x, y);

		frames = Paths.getSparrowAtlas("limo/limoDancer");
		animation.addByIndices('danceLeft', 'bg dancer sketch PINK', [for(i in 0...15) i], "", 24, false);
		animation.addByIndices('danceRight', 'bg dancer sketch PINK', [for(i in 15...30) i], "", 24, false);
		animation.play('danceLeft');
		antialiasing = ClientPrefs.data.antialiasing;
	}

	var danceDir:Bool = false;
	public function dance():Void
	{
		danceDir = !danceDir;

		final dAnim:String = danceDir ? 'danceRight' : 'danceLeft';
		animation.play(dAnim, true);
	}
}