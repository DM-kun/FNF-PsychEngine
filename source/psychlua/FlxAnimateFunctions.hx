package psychlua;

#if LUA_ALLOWED
class FlxAnimateFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua:State = funk.lua;
		Lua_helper.add_callback(lua, "makeFlxAnimateSprite", function(tag:String, ?x:Float = 0, ?y:Float = 0, ?loadFolder:String = null) {
			tag = tag.replace('.', '');
			var lastSprite = MusicBeatState.getVariables().get(tag);
			if(lastSprite != null)
			{
				lastSprite.kill();
				PlayState.instance.remove(lastSprite);
				lastSprite.destroy();
			}

			var mySprite:PsychSprite = new PsychSprite(x, y);
			if(loadFolder != null) mySprite.frames = Paths.getMultiAnimateAtlas(loadFolder.split(','));
			MusicBeatState.getVariables().set(tag, mySprite);
			mySprite.active = true;
		});

		Lua_helper.add_callback(lua, "loadAnimateAtlas", function(tag:String, folder:String) {
			var spr:PsychSprite = MusicBeatState.getVariables().get(tag);
			if(spr != null) spr.frames = Paths.getMultiAnimateAtlas(folder.split(','));
		});

		Lua_helper.add_callback(lua, "addAnimationBySymbol", function(tag:String, name:String, symbol:String, ?framerate:Float = 24, ?loop:Bool = false, ?flipX:Bool = false, ?flipY:Bool = false)
		{
			var obj:PsychSprite = cast MusicBeatState.getVariables().get(tag);
			if(obj == null) return false;

			obj.addAnim(name, symbol, null, framerate, loop, flipX, flipY);
			if(obj.isAnimationNull())
			{
				var obj2:PsychSprite = cast (obj, PsychSprite);
				if(obj2 != null) obj2.playAnim(name, true); //is PsychSprite
				else obj.anim.play(name, true);
			}
			return true;
		});

		Lua_helper.add_callback(lua, "addAnimationBySymbolIndices", function(tag:String, name:String, symbol:String, ?indices:Any = null, ?framerate:Float = 24, ?loop:Bool = false, ?flipX:Bool = false, ?flipY:Bool = false)
		{
			var obj:PsychSprite = cast MusicBeatState.getVariables().get(tag);
			if(obj == null) return false;

			if(indices == null) indices = [0];
			else if(Std.isOfType(indices, String))
			{
				var strIndices:Array<String> = cast (indices, String).trim().split(',');
				var myIndices:Array<Int> = [];
				for (i in 0...strIndices.length) {
					myIndices.push(Std.parseInt(strIndices[i]));
				}
				indices = myIndices;
			}

			obj.addAnim(name, symbol, indices, framerate, loop, flipX, flipY);
			if(obj.isAnimationNull())
			{
				var obj2:PsychSprite = cast (obj, PsychSprite);
				if(obj2 != null) obj2.playAnim(name, true); //is PsychSprite
				else obj.anim.play(name, true);
			}
			return true;
		});
	}
}
#end