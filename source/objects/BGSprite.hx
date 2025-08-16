package objects;

class BGSprite extends PsychSprite
{
	private var idleAnim:String;
	public function new(image:String, x:Float = 0, y:Float = 0, ?scrollX:Float = 1, ?scrollY:Float = 1, ?animArray:Array<String> = null, ?fps:Float = 24, ?loop:Bool = false)
	{
		super(x, y);

		if(animArray != null)
		{
			frames = Paths.getMultiAtlas(image.split(','));
			for(fAnim in animArray)
			{
				addAnim(fAnim, fAnim, null, fps, loop);
				if(idleAnim == null)
				{
					idleAnim = fAnim;
					playAnim(fAnim);
				}
			}
		}
		else
		{
			if(image != null) loadGraphic(Paths.image(image));
			active = false;
		}

		scrollFactor.set(scrollX, scrollY);
		antialiasing = ClientPrefs.data.antialiasing;
	}

	public function dance(?force:Bool = false)
	{
		if(idleAnim != null) playAnim(idleAnim, force);
	}
}