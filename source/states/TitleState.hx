package states;

import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.keyboard.FlxKey;

#if !MODS_ALLOWED
import openfl.Assets;
#end

import objects.Character;

import shaders.ColorSwap;

import states.MainMenuState;

typedef TitleData = {
	var title:String;
	var title_x:Float;
	var title_y:Float;

	var start:String;
	var start_x:Float;
	var start_y:Float;

	var gf:String;
	var gf_x:Float;
	var gf_y:Float;

	var background:String;
	var music:String;
	var bpm:Float;
}

class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;
	public static var closedState:Bool = false;
	public static var didStartFlash:Bool = false;
	public static var musicBPM:Float = 102;

	var musicName:String = 'freakyMenu';

	var credGroup:FlxGroup = new FlxGroup();
	var textGroup:FlxGroup = new FlxGroup();

	var curWacky:Array<String> = [];

	var blackScreen:FlxSprite;
	var ngSpr:FlxSprite;

	var newTitle:Bool = false;
	var titleTimer:Float = 0;
	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, 0.64];

	private static var playJingle:Bool = false;
	#if TITLE_SCREEN_EASTER_EGG
	final easterEggKeys:Array<String> = [
		'SHADOW', 'RIVEREN', 'BBPANZU', 'PESSY', 'DEMI'
	];
	final allowedKeys:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	var easterEggKeysBuffer:String = '';
	#end

	var gfDance:Character;
	var logoBl:FlxSprite;
	var titleText:FlxSprite;
	var swagShader:ColorSwap = null;

	var transitioning:Bool = false;

	override public function create():Void
	{
		if(!initialized)
		{
			persistentUpdate = persistentDraw = true;
			if(FlxG.sound.music == null)
				FlxG.sound.playMusic(Paths.music(musicName), 0);
		}

		loadIntroText();
		loadJsonData();
		#if TITLE_SCREEN_EASTER_EGG easterEggData(); #end
		Conductor.bpm = musicBPM;

		gfDance = new Character(gfPosition.x, gfPosition.y, gfData, false, 'images');
		gfDance.x += gfDance.positionArray[0];
		gfDance.y += gfDance.positionArray[1];
		add(gfDance);

		logoBl = new FlxSprite(logoPosition.x, logoPosition.y);
		logoBl.frames = Paths.getSparrowAtlas(logoImage);
		logoBl.antialiasing = ClientPrefs.data.antialiasing;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();
		add(logoBl);

		if(ClientPrefs.data.shaders)
		{
			swagShader = new ColorSwap();
			gfDance.shader = swagShader.shader;
			logoBl.shader = swagShader.shader;
		}

		var animFrames:Array<FlxFrame> = [];
		titleText = new FlxSprite(enterPosition.x, enterPosition.y);
		titleText.frames = Paths.getSparrowAtlas(enterImage);
		@:privateAccess
		{
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}

		if(newTitle = animFrames.length > 0)
		{
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else
		{
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		titleText.animation.play('idle');
		titleText.updateHitbox();
		add(titleText);

		blackScreen = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		blackScreen.scale.set(FlxG.width, FlxG.height);
		blackScreen.updateHitbox();
		credGroup.add(blackScreen);

		add(credGroup);

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = ClientPrefs.data.antialiasing;
		add(ngSpr);

		super.create();

		if(initialized) skipIntro();
		else initialized = true;
	}

	// JSON data
	var gfData:String = 'gfDanceTitle';
	var gfPosition:FlxPoint = FlxPoint.get(512, 40);

	var logoImage:String = 'logoBumpin';
	var logoPosition:FlxPoint = FlxPoint.get(-150, -100);

	var enterImage:String = 'titleEnter';
	var enterPosition:FlxPoint = FlxPoint.get(100, 576);

	function loadJsonData()
	{
		if(!Paths.fileExists('data/titleData.json', TEXT)) return;

		final titleRaw:String = Paths.getTextFromFile('data/titleData.json');
		if(titleRaw != null && titleRaw.length > 0)
		{
			try
			{
				final titleJSON:TitleData = tjson.TJSON.parse(titleRaw);

				gfPosition.set(titleJSON.gf_x, titleJSON.gf_y);
				logoPosition.set(titleJSON.title_x, titleJSON.title_y);
				enterPosition.set(titleJSON.start_x, titleJSON.start_y);

				if(titleJSON.background != null && titleJSON.background.trim().length > 0)
				{
					var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image(titleJSON.background));
					bg.antialiasing = titleJSON.background.endsWith('-pixel') ? false : ClientPrefs.data.antialiasing;
					add(bg);
				}

				if(Paths.fileExists('music/' + titleJSON.music)) musicName = titleJSON.music;
				musicBPM = titleJSON.bpm;
			}
			catch(e:haxe.Exception)
			{
				trace('[WARN] Title JSON might broken, ignoring issue...\n${e.details()}');
			}
		}
		else trace('[WARN] No Title JSON detected, using default values.');
	}

	function easterEggData()
	{
		if(FlxG.save.data.psychDevsEasterEgg == null) FlxG.save.data.psychDevsEasterEgg = ''; //Crash prevention

		final easterEgg:String = FlxG.save.data.psychDevsEasterEgg;
		switch(easterEgg.toUpperCase())
		{
			case 'SHADOW': gfData = 'ShadowBump';
			case 'RIVEREN': gfData = 'ZRiverBump';
			case 'BBPANZU': gfData = 'BBBump';
			case 'PESSY': gfData = 'PessyBump';
		}
	}

	function loadIntroText()
	{
		#if MODS_ALLOWED
		final firstArray:Array<String> = Mods.mergeAllTextsNamed('data/introText.txt');
		#else
		final fullText:String = Assets.getText(Paths.txt('introText'));
		final firstArray:Array<String> = fullText.split('\n');
		#end

		var swagGoodArray:Array<Array<String>> = [];
		for(i in firstArray) swagGoodArray.push(i.split('--'));

		curWacky = FlxG.random.getObject(swagGoodArray);
	}

	override function update(elapsed:Float)
	{
		if(FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		#if mobile
		for(touch in FlxG.touches.list)
		{
			if(touch.justPressed) pressedEnter = true;
		}
		#end

		final gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		if(gamepad != null)
		{
			if(gamepad.justPressed.START) pressedEnter = true;
			#if switch
			if(gamepad.justPressed.B) pressedEnter = true;
			#end
		}

		if(newTitle)
		{
			titleTimer += FlxMath.bound(elapsed, 0, 1);
			if(titleTimer > 2) titleTimer -= 2;
		}

		// EASTER EGG

		if(initialized && !transitioning && skippedIntro)
		{
			if(newTitle && !pressedEnter)
			{
				final timer:Float = FlxEase.quadInOut((titleTimer >= 1) ? (-titleTimer) + 2 : titleTimer);
				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}
			
			if(pressedEnter)
			{
				titleText.color = FlxColor.WHITE;
				titleText.alpha = 1;

				if(titleText != null) titleText.animation.play('press');

				if(gfDance.hasAnimation('cheer')) gfDance.playAnim('cheer', true);
				else gfDance.playAnim('hey', true);

				FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

				transitioning = true;
				// FlxG.sound.music.stop();

				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					MusicBeatState.switchState(new MainMenuState());
					closedState = true;
				});
				// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
			}
			#if TITLE_SCREEN_EASTER_EGG
			else if(FlxG.keys.firstJustPressed() != FlxKey.NONE)
			{
				final keyPressed:FlxKey = FlxG.keys.firstJustPressed();
				final keyName:String = Std.string(keyPressed);
				if(allowedKeys.contains(keyName))
				{
					easterEggKeysBuffer += keyName;
					if(easterEggKeysBuffer.length >= 32) easterEggKeysBuffer = easterEggKeysBuffer.substring(1);

					for(wordRaw in easterEggKeys)
					{
						final word:String = wordRaw.toUpperCase(); // just for being sure you're doing it right
						if(easterEggKeysBuffer.contains(word))
						{
							if(FlxG.save.data.psychDevsEasterEgg == word)
								FlxG.save.data.psychDevsEasterEgg = '';
							else
								FlxG.save.data.psychDevsEasterEgg = word;
							FlxG.save.flush();

							FlxG.sound.play(Paths.sound('secret'));

							var black:FlxSprite = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.BLACK);
							black.scale.set(FlxG.width, FlxG.height);
							black.updateHitbox();
							black.alpha = 0;
							add(black);

							FlxTween.tween(black, {alpha: 1}, 1, {
								onComplete: function(twn:FlxTween)
								{
									FlxTransitionableState.skipNextTransIn = true;
									FlxTransitionableState.skipNextTransOut = true;
									MusicBeatState.switchState(new TitleState());
								}
							});

							FlxG.sound.music.fadeOut();

							closedState = true;
							transitioning = true;
							playJingle = true;
							easterEggKeysBuffer = '';
							break;
						}
					}
				}
			}
			#end
		}

		if(initialized && pressedEnter && !skippedIntro) skipIntro();

		if(swagShader != null)
		{
			if(controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
			if(controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
		}

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for(i => txt in textArray)
		{
			var money:Alphabet = new Alphabet(0, 0, txt, true);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			if(credGroup != null && textGroup != null)
			{
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if(textGroup == null || credGroup == null) return;

		var coolText:Alphabet = new Alphabet(0, 0, text, true);
		coolText.screenCenter(X);
		coolText.y += (textGroup.length * 60) + 200 + offset;
		credGroup.add(coolText);
		textGroup.add(coolText);
	}

	function deleteCoolText()
	{
		while(textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	override function beatHit()
	{
		super.beatHit();

		if(gfDance != null) gfDance.dance();
		if(logoBl != null) logoBl.animation.play('bump', true);

		if(!closedState)
		{
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					//FlxG.sound.music.stop();
					FlxG.sound.playMusic(Paths.music(musicName), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				case 2:
					createCoolText(['Psych Engine by'], 40);
				case 4:
					addMoreText('Shadow Mario', 40);
					addMoreText('Riveren', 40);
				case 5:
					deleteCoolText();
				case 6:
					createCoolText(['Not associated', 'with'], -40);
				case 8:
					addMoreText('newgrounds', -40);
					ngSpr.visible = true;
				case 9:
					deleteCoolText();
					ngSpr.visible = false;
				case 10:
					createCoolText([curWacky[0]]);
				case 12:
					addMoreText(curWacky[1]);
				case 13:
					deleteCoolText();
				case 14:
					addMoreText('Friday');
				case 15:
					addMoreText('Night');
				case 16:
					addMoreText("Funkin'");

				case 17:
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	function skipIntro():Void
	{
		if(skippedIntro) return;

		#if TITLE_SCREEN_EASTER_EGG
		if(playJingle) //Ignore deez
		{
			playJingle = false;

			if(FlxG.save.data.psychDevsEasterEgg == null) FlxG.save.data.psychDevsEasterEgg = '';
			final easteregg:String = FlxG.save.data.psychDevsEasterEgg.toUpperCase();

			var sound:FlxSound = null;
			switch(easteregg)
			{
				case 'RIVEREN': sound = FlxG.sound.play(Paths.sound('JingleRiver'));
				case 'SHADOW': FlxG.sound.play(Paths.sound('JingleShadow'));
				case 'BBPANZU': sound = FlxG.sound.play(Paths.sound('JingleBB'));
				case 'PESSY': sound = FlxG.sound.play(Paths.sound('JinglePessy'));
				default: //Go back to normal ugly ass boring GF
					remove(ngSpr);
					remove(credGroup);
					FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 2);
					skippedIntro = true;

					FlxG.sound.playMusic(Paths.music(musicName), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
					return;
			}

			transitioning = true;
			if(easteregg == 'SHADOW')
			{
				new FlxTimer().start(3.2, function(tmr:FlxTimer)
				{
					remove(ngSpr);
					remove(credGroup);
					FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 0.6);
					transitioning = false;
				});
			}
			else
			{
				remove(ngSpr);
				remove(credGroup);
				FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 3);
				sound.onComplete = function()
				{
					FlxG.sound.playMusic(Paths.music(musicName), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
					transitioning = false;
					#if ACHIEVEMENTS_ALLOWED
					if(easteregg == 'PESSY') Achievements.unlock('pessy_easter_egg');
					#end
				};
			}
		}
		else #end //Default! Edit this one!!
		{
			remove(ngSpr);
			remove(credGroup);

			if(!didStartFlash) FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 4);
			didStartFlash = true;

			#if TITLE_SCREEN_EASTER_EGG
			var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
			if(easteregg == null) easteregg = '';
			easteregg = easteregg.toUpperCase();
			if(easteregg == 'SHADOW') FlxG.sound.music.fadeOut();
			#end
		}
		skippedIntro = true;
	}
}