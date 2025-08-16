package states;

import flixel.effects.FlxFlicker;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;
	var isYes:Bool = true;

	var texts:FlxTypedSpriteGroup<FlxText>;
	var bg:FlxSprite;

	override function create()
	{
		super.create();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xff242424;
		add(bg);

		texts = new FlxTypedSpriteGroup<FlxText>();
		add(texts);

		var str:Array<String> = [
			"Hey, watch out!", // 0
			"This Mod contains some flashing lights!", // 1
			"Do you wish to disable them?" // 2
		];
		for(i => line in str)
		{
			var txt:FlxText = new FlxText(0, 240 + (72 * i), FlxG.width, Language.getPhrase('flash_warning_$i', line));
			txt.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, CENTER);
			texts.add(txt);
		}

		for(i => key in ["Yes", "No"]) // 3 - 4
		{
			final button = new FlxText(0, 0, FlxG.width, Language.getPhrase(key));
			button.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, CENTER);
			button.y = (texts.members[2].y + texts.members[2].height) + 24;
			button.x += (128 * i) - 80;
			texts.add(button);
		}

		updateItems();
	}

	override function update(elapsed:Float)
	{
		if(leftState)
		{
			super.update(elapsed);
			return;
		}

		if(controls.UI_LEFT_P || controls.UI_RIGHT_P)
		{
			FlxG.sound.play(Paths.sound("scrollMenu"), 0.7);
			isYes = !isYes;
			updateItems();
		}

		final back:Bool = controls.BACK;
		if(controls.ACCEPT || back)
		{
			leftState = true;

			if(!back)
			{
				ClientPrefs.data.flashing = !isYes;
				ClientPrefs.saveSettings();
				FlxG.sound.play(Paths.sound('confirmMenu'));

				final button = texts.members[isYes ? 3 : 4];
				FlxFlicker.flicker(button, 1, 0.1, false, true, function(flk:FlxFlicker) {
					new FlxTimer().start(0.5, function(tmr:FlxTimer) {
						MusicBeatState.switchState(new TitleState());
					});
				});
			}
			else
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				new FlxTimer().start(0.6, function(tmr:FlxTimer) {
					MusicBeatState.switchState(new TitleState());
				});
			}
		}

		super.update(elapsed);
	}

	function updateItems()
	{
		// it's clunky but it works.
		texts.members[3].alpha = isYes ? 1.0 : 0.6;
		texts.members[4].alpha = isYes ? 0.6 : 1.0;
	}
}