package backend;

import flixel.util.FlxGradient;

#if HSCRIPT_ALLOWED
import psychlua.HScript;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

class CustomTransition extends MusicBeatSubstate
{
	public static var onFinish:Void->Void;
	var camTransition:PsychCamera; // so the camera will be on top!

	public var finished:Bool = false;
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

	#if HSCRIPT_ALLOWED
	var hscript:HScript;
	#end

	override function create()
	{
		camTransition = new PsychCamera();
		camTransition.bgColor.alpha = 0;
		FlxG.cameras.add(camTransition, false);

		cameras = [camTransition];

		#if HSCRIPT_ALLOWED
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.trim().length > 0)
		{
			var scriptPath:String = 'mods/${Mods.currentModDirectory}/data/Transition.hx'; //mods/My-Mod/data/Transition.hx
			if(!FileSystem.exists(scriptPath)) scriptPath = 'mods/data/Transition.hx';
			if(FileSystem.exists(scriptPath))
			{
				try
				{
					hscript = new HScript(null, scriptPath);
					hscript.set('finished', finished);
	
					if(hscript.exists('onCreate'))
					{
						hscript.call('onCreate');
						trace('initialized hscript interp successfully: $scriptPath');
						return super.create();
					}
					else
					{
						trace('"$scriptPath" contains no \"onCreate" function, stopping script.');
					}
				}
				catch(e:IrisError)
				{
					var pos:HScriptInfos = cast {fileName: scriptPath, showLine: false};
					Iris.error(Printer.errorToString(e, false), pos);
					var hscript:HScript = cast (Iris.instances.get(scriptPath), HScript);
				}
				if(hscript != null) hscript.destroy();
				hscript = null;
			}
		}
		#end

		final width:Int = Std.int(FlxG.width / Math.max(camera.zoom, 0.001));
		final height:Int = Std.int(FlxG.height / Math.max(camera.zoom, 0.001));

		transGradient = FlxGradient.createGradientFlxSprite(1, height, (isTransIn ? [0x0, FlxColor.BLACK] : [FlxColor.BLACK, 0x0]));
		transGradient.scale.x = width;
		transGradient.updateHitbox();
		transGradient.scrollFactor.set();
		transGradient.screenCenter(X);
		add(transGradient);

		transBlack = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		transBlack.antialiasing = false;
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
		
		#if HSCRIPT_ALLOWED
		if(hscript != null)
		{
			if(hscript.exists('onUpdate')) hscript.call('onUpdate', [elapsed]);
			return;
		}
		#end

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
		
		#if HSCRIPT_ALLOWED
		if(hscript != null && hscript.exists('onClose'))
		{
			hscript.call('onClose');
		}
		#end

		if(onFinish != null)
		{
			onFinish();
			onFinish = null;
		}
	}

	#if HSCRIPT_ALLOWED
	override function destroy()
	{
		if(hscript != null)
		{
			if(hscript.exists('onDestroy')) hscript.call('onDestroy');
			hscript.destroy();
		}
		hscript = null;
		super.destroy();
	}
	#end
}