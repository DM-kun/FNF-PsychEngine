package states;

import backend.WeekData;
import backend.Song;

import flixel.group.FlxGroup;
import flixel.graphics.FlxGraphic;

import objects.MenuItem;
import objects.MenuCharacter;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import backend.StageData;

class StoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();
	private static var curWeek:Int = 0;

	private static var lastDifficultyName:String = '';
	var curDifficulty:Int = 1;
	var selectedSomething:Bool = false;

	var scoreText:FlxText;
	var weekTitleTxt:FlxText;

	var intendedColor:Int;
	var bgYellow:FlxSprite;
	var bgSprite:FlxSprite;

	var txtTracklist:FlxText;

	var characterMap:Map<String, MenuCharacter> = new Map<String, MenuCharacter>();
	var weekCharacters:FlxTypedGroup<MenuCharacter>;

	var grpWeekText:FlxTypedGroup<MenuItem>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	var loadedWeeks:Array<WeekData> = [];

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		Conductor.bpm = TitleState.musicBPM;

		persistentUpdate = persistentDraw = true;
		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		if(WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR STORY MODE\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() MusicBeatState.switchState(new states.MainMenuState())));
			return;
		}

		if(curWeek >= WeekData.weeksList.length) curWeek = 0;

		scoreText = new FlxText(10, 10, 0, Language.getPhrase('week_score', 'WEEK SCORE: {1}', [lerpScore]), 36);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32);

		weekTitleTxt = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		weekTitleTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		weekTitleTxt.alpha = 0.7;

		bgYellow = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		bgSprite = new FlxSprite(0, 56);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		add(new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK));

		weekCharacters = new FlxTypedGroup<MenuCharacter>();

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		var num:Int = 0;
		var itemTargetY:Float = 0;
		for(i => week in WeekData.weeksList)
		{
			final weekFile:WeekData = WeekData.weeksLoaded.get(week);
			final isLocked:Bool = weekIsLocked(week);
			if(!isLocked || !weekFile.hiddenUntilUnlocked)
			{
				loadedWeeks.push(weekFile);
				WeekData.setDirectoryFromWeek(weekFile);

				var flashColor:FlxColor = 0xFF33FFFF;
				if(weekFile.weekFlashColor != null && weekFile.weekFlashColor.length > 2)
					flashColor = FlxColor.fromRGB(weekFile.weekFlashColor[0], weekFile.weekFlashColor[1], weekFile.weekFlashColor[2]);

				var weekThing:MenuItem = new MenuItem(0, bgSprite.y + 396, week, flashColor);
				weekThing.y += ((weekThing.height + 20) * num);
				weekThing.ID = num;
				weekThing.targetY = itemTargetY;
				weekThing.screenCenter(X);
				grpWeekText.add(weekThing);

				itemTargetY += Math.max(weekThing.height, 110) + 10;

				// Needs an offset thingie
				if(isLocked)
				{
					var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x).loadGraphic(Paths.image('Menu_Lock'));
					lock.antialiasing = ClientPrefs.data.antialiasing;
					lock.ID = i;
					grpLocks.add(lock);
				}
				num++;
			}
		}

		for(week in loadedWeeks)
		{
			WeekData.setDirectoryFromWeek(week);
			for(num => char in week.weekCharacters)
				addCharacterToList(char, num);

			final assetName:String = week.weekBackground;
			if(assetName != null && assetName.length > 0)
				if(Paths.fileExists('images/menubackgrounds/menu_$assetName.png', IMAGE))
					Paths.image('menubackgrounds/menu_$assetName');
		}

		WeekData.setDirectoryFromWeek(loadedWeeks[curWeek]);
		final charArray:Array<String> = loadedWeeks[curWeek].weekCharacters;
		for(num => char in charArray)
		{
			if(!characterMap.exists(char)) addCharacterToList(char, num);

			for(weekChar in weekCharacters.members)
			{
				if(weekChar != null && weekChar.curPosition == num)
					weekChar.alpha = (weekChar.curCharacter == char) ? 1 : 0.00001;
			}
		}

		final weekColor:Array<Int> = loadedWeeks[curWeek].weekBackgroundColor;
		final newColor:Int = (weekColor == null || weekColor.length < 3) ? 0xFFF9CF51 : FlxColor.fromRGB(weekColor[0], weekColor[1], weekColor[2]);
		bgYellow.color = newColor;
		intendedColor = bgYellow.color;

		final assetName:String = loadedWeeks[curWeek].weekBackground;
		if(assetName != null && assetName.length > 0)
			if(Paths.fileExists('images/menubackgrounds/menu_$assetName.png', IMAGE))
				bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_$assetName'));

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		leftArrow = new FlxSprite(850, grpWeekText.members[0].y + 10);
		leftArrow.antialiasing = ClientPrefs.data.antialiasing;
		leftArrow.frames = Paths.getSparrowAtlas('Menu_ArrowLeft');
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		Difficulty.resetList();
		if(lastDifficultyName == '') lastDifficultyName = Difficulty.getDefault();
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		sprDifficulty = new FlxSprite(0, leftArrow.y);
		sprDifficulty.antialiasing = ClientPrefs.data.antialiasing;
		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.antialiasing = ClientPrefs.data.antialiasing;
		rightArrow.frames = Paths.getSparrowAtlas('Menu_ArrowRight');
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);

		add(bgYellow);
		add(bgSprite);
		add(weekCharacters);

		var tracksSprite:FlxSprite = new FlxSprite(FlxG.width * 0.07 + 100, bgSprite.y + 425).loadGraphic(Paths.image('Menu_Tracks'));
		tracksSprite.antialiasing = ClientPrefs.data.antialiasing;
		tracksSprite.x -= tracksSprite.width/2;
		add(tracksSprite);

		txtTracklist = new FlxText(FlxG.width * 0.05, tracksSprite.y + 60, 0, "", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = Paths.font("vcr.ttf");
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		add(scoreText);
		add(weekTitleTxt);

		changeWeek();
		changeDifficulty();

		super.create();
	}

	function addCharacterToList(newCharacter:String, ?placement:Int = 0)
	{
		if(newCharacter == null || newCharacter.length < 1 || characterMap.exists(newCharacter)) return;

		var weekChar:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + placement) - 150, newCharacter, placement);
		weekChar.x += weekChar.positionArray[0];
		weekChar.y += weekChar.positionArray[1] + 70;
		characterMap.set(newCharacter, weekChar);
		weekCharacters.add(weekChar);
		weekChar.alpha = 0.00001;
	}

	override function closeSubState()
	{
		persistentUpdate = true;
		changeWeek();
		super.closeSubState();
	}

	override function update(elapsed:Float)
	{
		if(WeekData.weeksList.length < 1)
		{
			if(controls.BACK && !selectedSomething)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				selectedSomething = true;
				MusicBeatState.switchState(new MainMenuState());
			}
			super.update(elapsed);
			return;
		}

		if(FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;

		// scoreText.setFormat(Paths.font("vcr.ttf"), 32);
		if(intendedScore != lerpScore)
		{
			lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 30)));
			if(Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;
	
			scoreText.text = Language.getPhrase('week_score', 'WEEK SCORE: {1}', [lerpScore]);
		}

		// FlxG.watch.addQuick('font', scoreText.font);

		if(!selectedSomething)
		{
			var changeDiff:Bool = false;
			if (controls.UI_UP_P)
			{
				changeWeek(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeDiff = true;
			}

			if (controls.UI_DOWN_P)
			{
				changeWeek(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeDiff = true;
			}

			if(FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				changeWeek(-FlxG.mouse.wheel);
				changeDifficulty();
			}

			rightArrow.animation.play(controls.UI_RIGHT ? 'press' : 'idle');
			leftArrow.animation.play(controls.UI_LEFT ? 'press' : 'idle');

			if(controls.UI_RIGHT_P) changeDifficulty(1);
			else if(controls.UI_LEFT_P) changeDifficulty(-1);
			else if(changeDiff) changeDifficulty();

			if(FlxG.keys.justPressed.CONTROL)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate());
			}
			else if(controls.RESET)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
				//FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			else if(controls.ACCEPT) selectWeek();

			if(controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				selectedSomething = true;
				MusicBeatState.switchState(new MainMenuState());
			}

			/*#if desktop
			if(controls.justPressed('debug_1'))
			{
				selectedSomething = true;
				final weekFile:String = getPath('weeks/' + loadedWeeks[curWeek].fileName + '.json', TEXT, null, true);
				MusicBeatState.switchState(new states.editors.WeekEditorState(WeekData.getWeekFile(weekFile)));
			}
			if(controls.justPressed('debug_2'))
			{
				selectedSomething = true;
				MusicBeatState.switchState(new states.editors.MenuCharacterEditorState());
			}
			#end*/
		}

		super.update(elapsed);
		
		final offY:Float = grpWeekText.members[curWeek].targetY;
		for(item in grpWeekText.members)
			item.y = FlxMath.lerp(item.targetY - offY + 480, item.y, Math.exp(-elapsed * 10.2));

		for(lock in grpLocks.members)
			lock.y = grpWeekText.members[lock.ID].y + grpWeekText.members[lock.ID].height/2 - lock.height/2;
	}

	override function beatHit()
	{
		for(char in weekCharacters.members)
		{
			if(char != null && curBeat % char.danceEveryNumBeats == 0 && !char.getAnimationName().startsWith('confirm'))
				char.dance();
		}

		super.beatHit();
	}

	function selectWeek()
	{
		if(!weekIsLocked(loadedWeeks[curWeek].fileName))
		{
			// We can't use Dynamic Array .copy() because that crashes HTML5, here's a workaround.
			final leWeek:Array<Dynamic> = loadedWeeks[curWeek].songs;
			var songArray:Array<String> = [];
			for(data in leWeek) songArray.push(data[0]);

			// Nevermind that's stupid lmao
			try
			{
				PlayState.storyPlaylist = songArray;
				PlayState.isStoryMode = true;
				selectedSomething = true;
	
				var diffic = Difficulty.getFilePath(curDifficulty);
				if(diffic == null) diffic = '';
	
				PlayState.storyDifficulty = curDifficulty;
	
				Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
				PlayState.campaignScore = 0;
				PlayState.campaignMisses = 0;
			}
			catch(e:Dynamic)
			{
				trace('ERROR! $e');
				return;
			}

			FlxG.sound.play(Paths.sound('confirmMenu'));

			grpWeekText.members[curWeek].startFlashing();
			for(char in weekCharacters.members)
			{
				if(char == null) continue;
				if(char.hasConfirmAnimation) char.playAnim('confirm', true);
			}

			final directory = StageData.forceNextDirectory;
			LoadingState.loadNextDirectory();
			StageData.forceNextDirectory = directory;

			@:privateAccess
			if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
			{
				trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
				Paths.freeGraphicsFromMemory();
			}
			LoadingState.prepareToSong();
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
				LoadingState.loadAndSwitchState(new PlayState(), true);
			});
			
			#if (MODS_ALLOWED && DISCORD_ALLOWED)
			DiscordClient.loadModRPC();
			#end
		}
		else FlxG.sound.play(Paths.sound('cancelMenu'));
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length-1);

		WeekData.setDirectoryFromWeek(loadedWeeks[curWeek]);

		final diff:String = Difficulty.getString(curDifficulty, false);
		final newImage:FlxGraphic = Paths.image('menudifficulties/' + Paths.formatToSongPath(diff));
		if(sprDifficulty.graphic != newImage)
		{
			sprDifficulty.loadGraphic(newImage);
			sprDifficulty.x = leftArrow.x + 60;
			sprDifficulty.x += (308 - sprDifficulty.width) / 3;
			sprDifficulty.alpha = 0;
			sprDifficulty.y = leftArrow.y - sprDifficulty.height + 50;

			FlxTween.cancelTweensOf(sprDifficulty);
			FlxTween.tween(sprDifficulty, {y: sprDifficulty.y + 30, alpha: 1}, 0.07);
		}
		lastDifficultyName = diff;

		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}

	var lerpScore:Int = 49324858;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		curWeek = FlxMath.wrap(curWeek + change, 0, loadedWeeks.length - 1);

		final leWeek:WeekData = loadedWeeks[curWeek];
		WeekData.setDirectoryFromWeek(leWeek);

		final leName:String = Language.getPhrase('storyname_${leWeek.fileName}', leWeek.storyName);
		weekTitleTxt.text = leName.toUpperCase();
		weekTitleTxt.x = FlxG.width - (weekTitleTxt.width + 10);

		final unlocked:Bool = !weekIsLocked(leWeek.fileName);
		for(num => item in grpWeekText.members)
			item.alpha = (num - curWeek == 0 && unlocked) ? 1 : 0.6;

		final weekColor:Array<Int> = leWeek.weekBackgroundColor;
		final newColor:Int = (weekColor == null || weekColor.length < 3) ? 0xFFF9CF51 : FlxColor.fromRGB(weekColor[0], weekColor[1], weekColor[2]);
		if(newColor != intendedColor)
		{
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bgYellow);
			FlxTween.color(bgYellow, 1, bgYellow.color, intendedColor);
		}

		bgSprite.visible = true;
		final assetName:String = leWeek.weekBackground;
		if(assetName == null || assetName.length < 1) bgSprite.visible = false;
		else
		{
			if(!Paths.fileExists('images/menubackgrounds/menu_$assetName.png', IMAGE)) bgSprite.visible = false;
			else bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_$assetName'));
		}

		final charArray:Array<String> = leWeek.weekCharacters;
		for(num => char in charArray)
		{
			if(!characterMap.exists(char)) addCharacterToList(char, num);

			for(weekChar in weekCharacters.members)
			{
				if(weekChar != null && weekChar.curPosition == num)
					weekChar.alpha = (weekChar.curCharacter == char) ? 1 : 0.00001;
			}
		}

		PlayState.storyWeek = curWeek;

		Difficulty.loadFromWeek();
		difficultySelectors.visible = unlocked;

		if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		final newPos:Int = Difficulty.list.indexOf(lastDifficultyName);
		//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if(newPos > -1) curDifficulty = newPos;

		updateText();
	}

	function weekIsLocked(name:String):Bool
	{
		final leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}

	function updateText()
	{
		final leWeek:WeekData = loadedWeeks[curWeek];
		var stringThing:Array<String> = [];
		for(data in leWeek.songs)
		{
			if(data[3] != null && data[3] == true && (!weekCompleted.exists(leWeek.fileName) && !weekCompleted.get(leWeek.fileName)))
				continue;

			stringThing.push(data[0]);
		}

		txtTracklist.text = '';
		for(track in stringThing) txtTracklist.text += track + '\n';
		txtTracklist.text = txtTracklist.text.toUpperCase();
		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		#if !switch
		intendedScore = Highscore.getWeekScore(leWeek.fileName, curDifficulty);
		#end
	}
}