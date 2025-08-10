package objects;

class BGSprite extends PsychSprite
{
	private var idleAnim:String;
	public function new(image:String, x:Float = 0, y:Float = 0, ?scrollX:Float = 1, ?scrollY:Float = 1, ?animArray:Array<String> = null, ?loop:Bool = false, ?fps:Int = 24)
	{
		super(x, y);

		if(animArray != null)
		{
			frames = Paths.getSparrowAtlas(image);
			for(fAnim in animArray)
			{
				try
				{
					anim.addBySymbol(fAnim, fAnim, fps, loop);
					if(!hasAnimation(fAnim)) throw new haxe.Exception('Failed to add Animate Symbol Animation!');
				}
				catch(e:Dynamic)
				{
					anim.addByPrefix(fAnim, fAnim, fps, loop);
				}
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