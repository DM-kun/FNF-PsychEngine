package objects;

import flixel.util.FlxSort;
import flixel.system.FlxAssets.FlxGraphicAsset;

import backend.animation.PsychAnimateController;

class PsychSprite extends FlxAnimate
{
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	public function new(?x:Float = 0, ?y:Float = 0, ?graphic:FlxGraphicAsset = null)
	{
		super(x, y, graphic);
		anim = new PsychAnimateController(this);
		antialiasing = ClientPrefs.data.antialiasing;
	}

	var _lastPlayedAnimation:String;
	inline public function getAnimationName():String
	{
		return (_lastPlayedAnimation != null) ? _lastPlayedAnimation : anim.curAnim.name;
	}

	inline public function isAnimationNull():Bool
	{
		return (anim.curAnim == null);
	}

	public function hasAnimation(fAnim:String):Bool
	{
		return (animOffsets.exists(fAnim) || (anim.getByName(fAnim) != null));
	}

	public function isAnimationLooped():Bool
	{
		if(isAnimationNull()) return false;
		return anim.curAnim.looped;
	}

	public function isAnimationFinished():Bool
	{
		if(isAnimationNull()) return false;
		return anim.curAnim.finished;
	}

	public function finishAnimation():Void
	{
		if(isAnimationNull()) return;
		return anim.curAnim.finish();
	}

	public var animPaused(get, set):Bool;
	private function get_animPaused():Bool
	{
		if(isAnimationNull()) return false;
		return anim.curAnim.paused;
	}
	private function set_animPaused(value:Bool):Bool
	{
		if(isAnimationNull()) return value;
		return anim.curAnim.paused = value;
	}

	public function addAnim(name:String, prefix:String, ?indices:Array<Int> = null, ?fps:Float = 24, ?loop:Bool = false, ?flipX:Bool = false, ?flipY:Bool = false)
	{
		try // is there any better way to do this???
		{
			if(indices != null && indices.length > 0)
				anim.addBySymbolIndices(name, prefix, indices, fps, loop, flipX, flipY);
			else
				anim.addBySymbol(name, prefix, fps, loop, flipX, flipY);

			if(!hasAnimation(name)) throw new haxe.Exception('Failed to add Animate Symbol Animation!');
		}
		catch(e:Dynamic)
		{
			if(indices != null && indices.length > 0)
				anim.addByIndices(name, prefix, indices, "", fps, loop, flipX, flipY);
			else
				anim.addByPrefix(name, prefix, fps, loop, flipX, flipY);
		}
	}

	public function playAnim(name:String, ?forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
	{
		if(!hasAnimation(name)) return;

		anim.play(name, forced, reverse, startFrame);
		_lastPlayedAnimation = name;

		if(animOffsets.get(name) == null) addOffset(name);
		final daOffset:Array<Float> = animOffsets.get(name);
		offset.set(daOffset[0], daOffset[1]);
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets.set(name, [x, y]);
	}

	public function quickAnimAdd(name:String, fAnim:String)
	{
		try
		{
			anim.addBySymbol(name, fAnim, 24, false);
			if(!hasAnimation(name)) throw new haxe.Exception('Failed to add Animate Symbol Animation!');
		}
		catch(e:Dynamic)
		{
			anim.addByPrefix(name, fAnim, 24, false);
		}
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
}