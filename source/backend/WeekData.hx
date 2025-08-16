package backend;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;

typedef WeekFile = {
	var songs:Array<Dynamic>;
	var difficulties:String;
	var weekBefore:String;
	var weekName:String;

	var storyName:String;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBackgroundColor:Array<Int>;
	var weekFlashColor:Array<Int>;

	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
}

class WeekData
{
	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weeksList:Array<String> = [];
	public var folder:String = '';

	// JSON variables
	public var songs:Array<Dynamic>;
	public var difficulties:String;
	public var weekBefore:String;
	public var weekName:String;

	public var storyName:String;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBackgroundColor:Array<Int>;
	public var weekFlashColor:Array<Int>;

	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Bool;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;

	public var fileName:String;

	public static function createWeekFile():WeekFile
	{
		return {
			songs: [
				[
					"Test", // Song
					"face", // Icon
					[100, 100, 100], // Color
					false // Hidden
				]
			],
			difficulties: '',
			weekBefore: 'tutorial',
			weekName: 'Custom Week',
			storyName: 'Your New Week',
			weekCharacters: [#if BASE_GAME_FILES 'dad' #else 'bf' #end, 'bf', 'gf'],
			weekBackground: 'stage',
			weekBackgroundColor: [249, 207, 81],
			weekFlashColor: [51, 255, 255],
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false
		};
	}

	// HELP: Is there any way to convert a WeekFile to WeekData without having to put all variables there manually? I'm kind of a noob in haxe lmao
	public function new(weekFile:WeekFile, fileName:String)
	{
		// here ya go - MiguelItsOut
		for(field in Reflect.fields(weekFile))
			if(Reflect.fields(this).contains(field)) // Reflect.hasField() won't fucking work :/
				Reflect.setProperty(this, field, Reflect.getProperty(weekFile, field));

		this.fileName = fileName;
	}

	public static function reloadWeekFiles(?isStoryMode:Null<Bool>)
	{
		if(isStoryMode == null) isStoryMode = PlayState.isStoryMode;

		weeksList = [];
		weeksLoaded.clear();

		var directories:Array<String> = [Paths.getSharedPath()];
		#if MODS_ALLOWED
		directories = [Paths.mods(), Paths.getSharedPath()];
		for(mod in Mods.parseList().enabled) directories.push(Paths.mods(mod + '/'));
		#end
		final originalLength:Int = directories.length;

		final sexList:Array<String> = CoolUtil.coolTextFile(Paths.getSharedPath('weeks/weekList.txt'));
		for(weekName in sexList)
		{
			for(num => dir in directories)
			{
				final fileToCheck:String = dir + 'weeks/$weekName.json';
				if(!weeksLoaded.exists(weekName))
				{
					final week:WeekFile = getWeekFile(fileToCheck);
					if(week != null)
					{
						var weekFile:WeekData = new WeekData(week, weekName);

						#if MODS_ALLOWED
						if(num >= originalLength)
							weekFile.folder = dir.substring(Paths.mods().length, dir.length-1);
						#end

						if(weekFile != null && (isStoryMode == null || (isStoryMode && !weekFile.hideStoryMode) || (!isStoryMode && !weekFile.hideFreeplay)))
						{
							weeksLoaded.set(weekName, weekFile);
							weeksList.push(weekName);
						}
					}
				}
			}
		}

		#if MODS_ALLOWED
		for(i => dir in directories)
		{
			final directory:String = dir + 'weeks/';
			if(FileSystem.exists(directory))
			{
				final listOfWeeks:Array<String> = CoolUtil.coolTextFile(directory + 'weekList.txt');
				for(daWeek in listOfWeeks)
				{
					final path:String = directory + daWeek + '.json';
					if(FileSystem.exists(path)) addWeek(daWeek, path, dir, i, originalLength);
				}

				for(file in FileSystem.readDirectory(directory))
				{
					final path = haxe.io.Path.join([directory, file]);
					if(!FileSystem.isDirectory(path) && file.endsWith('.json'))
						addWeek(file.substr(0, file.length - 5), path, dir, i, originalLength);
				}
			}
		}
		#end
	}

	private static function addWeek(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int)
	{
		if(!weeksLoaded.exists(weekToCheck))
		{
			final week:WeekFile = getWeekFile(path);
			if(week != null)
			{
				var weekFile:WeekData = new WeekData(week, weekToCheck);
				#if MODS_ALLOWED
				if(i >= originalLength)
					weekFile.folder = directory.substring(Paths.mods().length, directory.length-1);
				#end

				if((PlayState.isStoryMode && !weekFile.hideStoryMode) || (!PlayState.isStoryMode && !weekFile.hideFreeplay))
				{
					weeksLoaded.set(weekToCheck, weekFile);
					weeksList.push(weekToCheck);
				}
			}
		}
	}

	public static function getWeekFile(path:String):WeekFile
	{
		var rawJson:String = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(path)) rawJson = File.getContent(path);
		#else
		if(OpenFlAssets.exists(path)) rawJson = Assets.getText(path);
		#end

		if(rawJson != null && rawJson.length > 0)
			return cast tjson.TJSON.parse(rawJson);

		return null;
	}

	//   FUNCTIONS YOU WILL PROBABLY NEVER NEED TO USE

	//To use on PlayState.hx or Highscore stuff
	public static function getWeekFileName():String
		return weeksList[PlayState.storyWeek];

	//Used on LoadingState, nothing really too relevant
	public static function getCurrentWeek():WeekData
		return weeksLoaded.get(weeksList[PlayState.storyWeek]);

	public static function setDirectoryFromWeek(?data:WeekData = null)
	{
		Mods.currentModDirectory = '';
		if(data != null && data.folder != null && data.folder.length > 0)
			Mods.currentModDirectory = data.folder;
	}
}