package states.stages.objects;

enum SpraycanState
{
	WAITING;
	ARCING;		// In the air.
	SHOT;		// Hit by the player.
	IMPACTED;	// Impacted the player.
}

class SpraycanAtlasSprite extends FlxSpriteGroup
{
	public var currentState:SpraycanState = WAITING;

	public var canAtlas:FlxAnimate;
	public var explosion:FlxSprite;
	public function new(x:Float = 0, y:Float = 0)
	{
		super();

		canAtlas = new FlxAnimate(x, y);
		canAtlas.frames = Paths.getAnimateAtlas('spraycanAtlas');
		canAtlas.anim.addBySymbolIndices('Can Start', 'Can with Labels', [for(i in 0...19) i], 24, false);
		canAtlas.anim.addBySymbolIndices('Hit Pico', 'Can with Labels', [for(i in 19...26) i], false);
		canAtlas.anim.addBySymbolIndices('Can Shot', 'Can with Labels', [for(i in 26...43) i], 24, false);
		canAtlas.anim.onFinish.add(finishCanAnimation);
		canAtlas.visible = canAtlas.active = false;
		canAtlas.antialiasing = ClientPrefs.data.antialiasing;
		add(canAtlas);

		explosion = new FlxSprite(x - 25, y - 450);
		explosion.frames = Paths.getSparrowAtlas('spraypaintExplosionEZ');
		explosion.animation.addByPrefix('idle', 'explosion round 1 short0', 24, false);
		explosion.animation.onFinish.add((name:String) -> explosion.visible = explosion.active = false);
		explosion.visible = explosion.active = false;
		explosion.antialiasing = ClientPrefs.data.antialiasing;
		add(explosion);
	}

	public var cutscene:Bool = false;
	public function finishCanAnimation(name:String)
	{
		switch(name)
		{
			case 'Can Start':
				playHitPico();
			case 'Can Shot':
				canAtlas.visible = canAtlas.active = false;
				currentState = WAITING;
			case 'Hit Pico':
				if(!cutscene) playHitExplosion();
				canAtlas.visible = canAtlas.active = false;
				currentState = WAITING;
		}
	}

	public function playHitExplosion():Void
	{
		explosion.visible = explosion.active = true;
		explosion.animation.play('idle', true);
	}

	public function playCanStart():Void
	{
		canAtlas.anim.play('Can Start', true);
		canAtlas.visible = canAtlas.active = true;
		currentState = ARCING;
	}

	public function playCanShot():Void
	{
		canAtlas.anim.play('Can Shot', true);
		currentState = SHOT;
	}

	public function playHitPico():Void
	{
		canAtlas.anim.play('Hit Pico', true);
		currentState = IMPACTED;
	}
}