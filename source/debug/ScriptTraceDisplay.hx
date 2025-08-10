/*package debug;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

class ScriptTraceDisplay extends Sprite
{
	public var maxTraces(default, set):Int = 12;
	public var traces:Array<ScriptTraceText> = [];

	public function new()
	{
		super();
	}

	private override function __enterFrame(deltaTime:Float):Void
	{
		for(text in traces)
		{
			if(contains(text))
			{
				text.update(deltaTime)
				if(text.alpha == 0 || text.y >= FlxG.height)
				{
					if(traces.contains(text))
						traces.remove(text);
					removeChild(text)
				}
			}
		}
	}

	public function print(text:String, color:Int = 0xFF0000)
	{
		var newText:ScriptTraceText = new ScriptTraceText(10, 10, color);
		newText.text = text;
		newText.disableTime = 6;
		newText.alpha = 1;

		for(text in traces)
		{
			if(contains(text)) text.y += newText.height + 2;
		}

		addChild(newText);
		traces.push(newText);
	}

	private function set_maxTraces(value:Int):Int
	{
		for(num => text in traces)
		{
			if((num + 1) < value) continue;

			if(traces.contains(text)) traces.remove(text);
			if(contains(text)) removeChild(text)
		}
		return maxTraces = value;
	}
}

class ScriptTraceText extends TextField
{
	public var disableTime:Float = 6;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat(Paths.font('vcr.ttf'), 16, color);
		autoSize = LEFT;
		multiline = true;
		wordWrap = true;
		text = " ";
	}

	public function update(deltaTime:Float):Void
	{
		disableTime -= deltaTime / 1000;
		if(disableTime < 0) disableTime = 0;
		if(disableTime < 1) alpha = disableTime;
	}
}*/