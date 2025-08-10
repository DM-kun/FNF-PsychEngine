package shaders;

// STOLEN FROM HAXEFLIXEL DEMO LOL
import flixel.system.FlxAssets.FlxShader;

enum abstract WiggleEffectType(Int) to Int
{
	var DREAMY = 0;
	var WAVY = 1;
	var HEAT_WAVE_HORIZONTAL = 2;
	var HEAT_WAVE_VERTICAL = 3;
	var FLAG = 4;
}

class WiggleEffect
{
	public var shader(default, null):WiggleShader = new WiggleShader();
	public var effectType(default, set):WiggleEffectType = DREAMY;
	public var waveSpeed(default, set):Float = 0;
	public var waveFrequency(default, set):Float = 0;
	public var waveAmplitude(default, set):Float = 0;

	public function new():Void
	{
		shader.uTime.value[0] = 0;
	}

	public function update(elapsed:Float):Void
	{
		shader.uTime.value[0] += elapsed;
	}

	public function setValue(value:Float):Void
	{
		shader.uTime.value[0] = value;
	}

	function set_effectType(value:WiggleEffectType):WiggleEffectType
	{
		effectType = value;
		shader.effectType.value[0] = value;
		return value;
	}

	function set_waveSpeed(value:Float):Float
	{
		waveSpeed = value;
		shader.uSpeed.value = [waveSpeed];
		return value;
	}

	function set_waveFrequency(value:Float):Float
	{
		waveFrequency = value;
		shader.uFrequency.value = [waveFrequency];
		return value;
	}

	function set_waveAmplitude(value:Float):Float
	{
		waveAmplitude = value;
		shader.uWaveAmplitude.value = [waveAmplitude];
		return value;
	}
}

class WiggleShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		//uniform float tx, ty; // x,y waves phase
		uniform float uTime;

		uniform int effectType;

		/**
		 * How fast the waves move over time
		 */
		uniform float uSpeed;

		/**
		 * Number of waves over time
		 */
		uniform float uFrequency;

		/**
		 * How much the pixels are going to stretch over the waves
		 */
		uniform float uWaveAmplitude;

		vec2 sineWave(vec2 pt)
		{
			float x = 0.0;
			float y = 0.0;

			if (effectType == 0) 
			{
				float offsetX = sin(pt.y * uFrequency + uTime * uSpeed) * uWaveAmplitude;
                pt.x += offsetX; // * (pt.y - 1.0); // <- Uncomment to stop bottom part of the screen from moving
			}
			else if (effectType == 1) 
			{
				float offsetY = sin(pt.x * uFrequency + uTime * uSpeed) * uWaveAmplitude;
				pt.y += offsetY; // * (pt.y - 1.0); // <- Uncomment to stop bottom part of the screen from moving
			}
			else if (effectType == 2)
			{
				x = sin(pt.x * uFrequency + uTime * uSpeed) * uWaveAmplitude;
			}
			else if (effectType == 3)
			{
				y = sin(pt.y * uFrequency + uTime * uSpeed) * uWaveAmplitude;
			}
			else if (effectType == 4)
			{
				y = sin(pt.y * uFrequency + 10.0 * pt.x + uTime * uSpeed) * uWaveAmplitude;
				x = sin(pt.x * uFrequency + 5.0 * pt.y + uTime * uSpeed) * uWaveAmplitude;
			}

			return vec2(pt.x + x, pt.y + y);
		}

		void main()
		{
			vec2 uv = sineWave(openfl_TextureCoordv);
			gl_FragColor = texture2D(bitmap, uv);
		}')
	public function new()
	{
		super();
	}
}