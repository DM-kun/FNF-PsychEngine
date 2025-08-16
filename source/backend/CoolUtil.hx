package backend;

import openfl.utils.Assets;

class CoolUtil
{
	public static function checkForUpdates(url:String = null):String
	{
		if(url == null || url.length == 0)
			url = "https://raw.githubusercontent.com/DM-kun/FNF-PsychEngine/main/gitVersion.txt";

		var version:String = states.MainMenuState.psychEngineVersion.trim();
		if(ClientPrefs.data.checkForUpdates)
		{
			trace('Checking for Updates...');

			var http = new haxe.Http(url);
			http.onData = function(data:String)
			{
				trace('Current Version: $version');
				final newVersion:String = data.split('\n')[0].trim();
				trace('Version Online: $newVersion');
				if(newVersion != version)
				{
					trace('Update Found!');
					version = newVersion;
					http.onData = null;
					http.onError = null;
					http = null;
				}
			}
			http.onError = function(error)
			{
				trace('error: $error');
			}
			http.request();
		}
		return version;
	}

	inline public static function quantize(f:Float, snap:Float)
	{
		final m:Float = Math.fround(f * snap);
		return (m / snap);
	}

	inline public static function capitalize(text:String)
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();

	inline public static function coolTextFile(path:String):Array<String>
	{
		var daList:String = null;
		#if (sys && MODS_ALLOWED)
		if(FileSystem.exists(path)) daList = File.getContent(path);
		#else
		if(Assets.exists(path)) daList = Assets.getText(path);
		#end
		return daList != null ? listFromString(daList) : [];
	}

	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - (color.length >= 10 ? 8 : 6));

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	inline public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = string.trim().split('\n');
		for(i => line in daList) daList[i] = line.trim();
		return daList;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if(decimals < 1) return Math.floor(value);
		return Math.floor(value * Math.pow(10, decimals)) / Math.pow(10, decimals);
	}

	inline public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth)
		{
			for(row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:FlxColor = sprite.pixels.getPixel32(col, row);
				if(colorOfThisPixel.alphaFloat > 0.05)
				{
					colorOfThisPixel = FlxColor.fromRGB(colorOfThisPixel.red, colorOfThisPixel.green, colorOfThisPixel.blue, 255);
					var count:Int = countByColor.exists(colorOfThisPixel) ? countByColor[colorOfThisPixel] : 0;
					countByColor[colorOfThisPixel] = count + 1;
				}
			}
		}

		var maxCount = 0;
		var maxKey:Int = 0; //after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for(key => count in countByColor)
		{
			if(count >= maxCount)
			{
				maxCount = count;
				maxKey = key;
			}
		}
		countByColor.clear();
		return maxKey;
	}

	inline public static function browserLoad(site:String)
	{
		try
		{
			#if linux
			Sys.command('/usr/bin/xdg-open $site &');
			#else
			FlxG.openURL(site);
			#end
		}
		catch(e:Dynamic)
		{
			FlxG.log.warn("Couldn't open site!");
		}
	}

	public static function setTextBorderFromString(text:FlxText, border:String)
	{
		text.borderStyle = switch(border.toLowerCase().trim())
		{
			case 'shadow': SHADOW;
			case 'outline': OUTLINE;
			case 'outline_fast', 'outlinefast': OUTLINE_FAST;
			default: NONE;
		};
	}

	/**
		Helper Function to Fix Save Files for Flixel 5

		this function is used to get the save path, period.
		since newer flixel versions are being enforced anyways.
		@crowplexus
	**/
	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String
	{
		// #if (flixel < "5.0.0") return company; #else
		return '${FlxG.stage.application.meta.get('company')}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
		// #end
	}
}