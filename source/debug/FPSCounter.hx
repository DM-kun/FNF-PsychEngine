package debug;

import openfl.text.TextField;
import openfl.text.TextFormat;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
class FPSCounter extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;
	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memoryMegas(get, never):Float;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("_sans", 14, color);
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";
	}

	private var fps:Int = 0;
	private var frameTime:Float = 0.0;
	private var deltaTimeout:Float = 0.0;

	// Event Handlers
	private override function __enterFrame(deltaTime:Float):Void
	{
		fps++;
		frameTime += deltaTime;

		if(frameTime >= 1000)
		{
			currentFPS = fps;
			fps = 0;
			frameTime = 0;
		}

		deltaTimeout += deltaTime;
		if(deltaTimeout < 1000) return;

		updateText();
		deltaTimeout = 0.0;
	}

	// dynamic, so people can override it in hscript
	public dynamic function updateText():Void
	{
		text = 'FPS: ${currentFPS} · Memory: ${flixel.util.FlxStringUtil.formatBytes(memoryMegas)}';
		textColor = (currentFPS < FlxG.drawFramerate * 0.5) ? 0xFFFF0000 : 0xFFFFFFFF;
	}

	inline function get_memoryMegas():Float
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
}