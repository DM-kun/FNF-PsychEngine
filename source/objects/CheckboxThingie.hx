package objects;

class CheckboxThingie extends PsychSprite
{
	public var sprTracker:FlxSprite;
	public var checked(default, set):Bool;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var copyAlpha:Bool = true;

	public function new(x:Float = 0, y:Float = 0, ?checked = false)
	{
		super(x, y);

		moves = false;
		immovable = true;

		frames = Paths.getSparrowAtlas('checkboxanim');

		for(fAnim in ['unchecked', 'unchecking', 'checking', 'checked'])
			anim.addByPrefix(fAnim, 'checkbox $fAnim', 24, false);

		addOffset('unchecked', 0, 2);
		addOffset('unchecking', 25, 28);
		addOffset('checking', 34, 25);
		addOffset('checked', 3, 12);

		antialiasing = ClientPrefs.data.antialiasing;
		setGraphicSize(Std.int(0.9 * width));
		updateHitbox();

		animationFinished(checked ? 'checking' : 'unchecking');
		animation.onFinish.add(animationFinished);
		this.checked = checked;
	}

	override function update(elapsed:Float)
	{
		if(sprTracker != null)
		{
			setPosition(sprTracker.x - 130 + offsetX, sprTracker.y + 30 + offsetY);
			if(copyAlpha) alpha = sprTracker.alpha;
		}
		super.update(elapsed);
	}

	private function set_checked(check:Bool):Bool
	{
		if(check)
		{
			if(getAnimationName() != 'checked' && getAnimationName() != 'checking')
				playAnim('checking', true);
		}
		else
		{
			if(getAnimationName() != 'unchecked' && getAnimationName() != 'unchecking')
				playAnim('unchecking', true);
		}
		return check;
	}

	private function animationFinished(name:String)
	{
		switch(name)
		{
			case 'checking': playAnim('checked', true);
			case 'unchecking': playAnim('unchecked', true);
		}
	}
}