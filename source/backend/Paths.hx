package backend;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets;

import openfl.display.BitmapData;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.system.System;
import openfl.media.Sound;

import lime.utils.Assets;

#if MODS_ALLOWED
import backend.Mods;
#end

@:access(openfl.display.BitmapData)
class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	public static function excludeAsset(key:String)
	{
		if(!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = ['assets/shared/music/freakyMenu.$SOUND_EXT'];
	// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		for(key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if(!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				destroyGraphic(currentTrackedAssets.get(key)); // get rid of the graphic
				currentTrackedAssets.remove(key); // and remove the key from local cache map
			}
		}

		// run the garbage collector for good measure lmfao
		#if !html5 System.gc(); #end
		#if cpp cpp.NativeGc.run(true); #end
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
	public static function clearStoredMemory()
	{
		// clear anything not in the tracked assets list
		for(key in FlxG.bitmap._cache.keys())
		{
			if(!currentTrackedAssets.exists(key))
				destroyGraphic(FlxG.bitmap.get(key));
		}

		// clear all sounds that are cached
		for(key => asset in currentTrackedSounds)
		{
			if(!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}

		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	public static function freeGraphicsFromMemory()
	{
		var protectedGfx:Array<FlxGraphic> = [];
		function checkForGraphics(spr:Dynamic)
		{
			try
			{
				final grp:Array<Dynamic> = Reflect.getProperty(spr, 'members');
				if(grp != null)
				{
					//trace('is actually a group');
					for(member in grp) checkForGraphics(member);
					return;
				}
			}

			//trace('check...');
			try
			{
				final gfx:FlxGraphic = Reflect.getProperty(spr, 'graphic');
				if(gfx != null)
				{
					protectedGfx.push(gfx);
					//trace('gfx added to the list successfully!');
				}
			}
			//catch(haxe.Exception) {}
		}

		for(member in FlxG.state.members)
			checkForGraphics(member);

		if(FlxG.state.subState != null)
			for(member in FlxG.state.subState.members)
				checkForGraphics(member);

		for(key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if(!dumpExclusions.contains(key))
			{
				final graphic:FlxGraphic = currentTrackedAssets.get(key);
				if(!protectedGfx.contains(graphic))
				{
					destroyGraphic(graphic); // get rid of the graphic
					currentTrackedAssets.remove(key); // and remove the key from local cache map
					//trace('deleted $key');
				}
			}
		}
	}

	inline static function destroyGraphic(graphic:FlxGraphic)
	{
		// free some gpu memory
		if(graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null)
			graphic.bitmap.__texture.dispose();
		FlxG.bitmap.remove(graphic);
	}

	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();
	static public function getCurrentLevel():String
		return currentLevel;

	public static function getPath(file:String, ?type:AssetType = TEXT, ?parentfolder:String, ?modsAllowed:Bool = true):String
	{
		#if MODS_ALLOWED
		if(modsAllowed)
		{
			var customFile:String = file;
			if(parentfolder != null) customFile = '$parentfolder/$file';

			final modded:String = modFolders(customFile);
			if(FileSystem.exists(modded)) return modded;
		}
		#end

		if(parentfolder != null) return getFolderPath(file, parentfolder);

		if(currentLevel != null && currentLevel != 'shared')
		{
			final levelPath:String = getFolderPath(file, currentLevel);
			if(OpenFlAssets.exists(levelPath, type)) return levelPath;
		}

		return getSharedPath(file);
	}

	inline static public function getFolderPath(file:String, folder = "shared")
		return 'assets/$folder/$file';

	inline public static function getSharedPath(file:String = '')
		return 'assets/shared/$file';

	inline static public function txt(key:String, ?folder:String)
		return getPath('data/$key.txt', TEXT, folder, true);

	inline static public function xml(key:String, ?folder:String)
		return getPath('data/$key.xml', TEXT, folder, true);

	inline static public function json(key:String, ?folder:String)
		return getPath('data/$key.json', TEXT, folder, true);

	inline static public function shaderFragment(key:String, ?folder:String)
		return getPath('shaders/$key.frag', TEXT, folder, true);

	inline static public function shaderVertex(key:String, ?folder:String)
		return getPath('shaders/$key.vert', TEXT, folder, true);

	inline static public function lua(key:String, ?folder:String)
		return getPath('$key.lua', TEXT, folder, true);

	inline static public function font(key:String)
	{
		final folderKey:String = Language.getFileTranslation('fonts/$key');
		#if MODS_ALLOWED
		final file:String = modFolders(folderKey);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/$folderKey';
	}

	inline static public function video(key:String)
	{
		final folderKey:String = Language.getFileTranslation('videos/$key') + '.$VIDEO_EXT';
		#if MODS_ALLOWED
		final file:String = modFolders(folderKey);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/$folderKey';
	}

	inline static public function svg(key:String, ?folder:String, ?modsAllowed:Bool = true)
	{
		key = Language.getFileTranslation('images/$key') + '.svg';
		return getTextFromFile(key, folder, modsAllowed);
	}

	inline static public function sound(key:String, ?modsAllowed:Bool = true, ?playBeep:Bool = true):Sound
		return returnSound('sounds/$key', null, modsAllowed, playBeep);

	inline static public function music(key:String, ?modsAllowed:Bool = true, ?playBeep:Bool = true):Sound
		return returnSound('music/$key', null, modsAllowed, playBeep);

	inline static public function inst(song:String, postfix:String = null, ?modsAllowed:Bool = true):Sound
	{
		var songKey:String = '${formatToSongPath(song)}/Inst';
		if(postfix != null) songKey += '-' + postfix;
		//trace('songKey test: $songKey');
		return returnSound(songKey, 'songs', modsAllowed, true);
	}

	inline static public function voices(song:String, postfix:String = null, ?modsAllowed:Bool = true):Sound
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		if(postfix != null) songKey += '-' + postfix;
		//trace('songKey test: $songKey');
		return returnSound(songKey, 'songs', modsAllowed, false);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?modsAllowed:Bool = true)
		return sound(key + FlxG.random.int(min, max), modsAllowed);

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	static public function image(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxGraphic
	{
		key = Language.getFileTranslation('images/$key') + '.png';
		if(currentTrackedAssets.exists(key))
		{
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}
		return cacheBitmap(key, parentFolder, null, allowGPU);
	}

	public static function cacheBitmap(key:String, ?parentFolder:String = null, ?bitmap:BitmapData, ?allowGPU:Bool = true):FlxGraphic
	{
		if(bitmap == null)
		{
			final file:String = getPath(key, IMAGE, parentFolder, true);
			#if MODS_ALLOWED
			if(FileSystem.exists(file))
				bitmap = BitmapData.fromFile(file);
			else #end if(OpenFlAssets.exists(file, IMAGE))
				bitmap = OpenFlAssets.getBitmapData(file);

			if(bitmap == null)
			{
				trace('Bitmap not found: $file | key: $key');
				return null;
			}
		}

		if(allowGPU && ClientPrefs.data.cacheOnGPU && bitmap.image != null)
		{
			bitmap.lock();
			if(bitmap.__texture == null)
			{
				bitmap.image.premultiplied = true;
				bitmap.getTexture(FlxG.stage.context3D);
			}
			bitmap.getSurface();
			bitmap.disposeImage();
			bitmap.image.data = null;
			bitmap.image = null;
			bitmap.readable = true;
		}

		var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
		graph.persist = true;
		graph.destroyOnNoUse = false;

		currentTrackedAssets.set(key, graph);
		localTrackedAssets.push(key);
		return graph;
	}

	inline static public function getTextFromFile(key:String, ?parentFolder:String, ?modsAllowed:Bool = true):String
	{
		final path:String = getPath(key, TEXT, parentFolder, modsAllowed);
		#if sys
		return (FileSystem.exists(path)) ? File.getContent(path) : null;
		#else
		return (OpenFlAssets.exists(path, TEXT)) ? Assets.getText(path) : null;
		#end
	}

	public static function fileExists(key:String, ?type:AssetType = TEXT, ?parentFolder:String = null, ?modsAllowed:Bool = true):Bool
	{
		#if MODS_ALLOWED
		if(modsAllowed)
		{
			var modKey:String = key;
			if(parentFolder == 'songs') modKey = 'songs/$key';

			for(mod in Mods.getGlobalMods())
				if (FileSystem.exists(mods('$mod/$modKey')))
					return true;

			if(FileSystem.exists(mods(Mods.currentModDirectory + '/' + modKey)) || FileSystem.exists(mods(modKey)))
				return true;
		}
		#end
		return (OpenFlAssets.exists(getPath(key, type, parentFolder, false)));
	}

	public static function fileExistsAbsolute(key:String, ?modsAllowed:Bool = true):Bool
	{
		return #if MODS_ALLOWED modsAllowed ? (FileSystem.exists(key)) : #end (OpenFlAssets.exists(key));
	}

	static public function getAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		if(fileExists('images/$key.xml', TEXT, parentFolder)) return getSparrowAtlas(key, parentFolder, allowGPU);
		if(fileExists('images/$key.json', TEXT, parentFolder)) return getAsepriteAtlas(key, parentFolder, allowGPU);
		if(fileExists('images/$key/Animation.json', TEXT, parentFolder)) return getAnimateAtlas(key, parentFolder, allowGPU);
		return getPackerAtlas(key, parentFolder);
	}

	static public function getMultiAtlas(keys:Array<String>, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var parentFrames:FlxAtlasFrames = Paths.getAtlas(keys[0].trim());
		if(keys.length > 1)
		{
			final original:FlxAtlasFrames = parentFrames;
			parentFrames = new FlxAtlasFrames(parentFrames.parent);
			parentFrames.addAtlas(original, true);
			for(i in 1...keys.length)
			{
				final extraFrames:FlxAtlasFrames = Paths.getAtlas(keys[i].trim(), parentFolder, allowGPU);
				if(extraFrames != null) parentFrames.addAtlas(extraFrames, true);
			}
		}
		return parentFrames;
	}

	static public function getMultiAnimateAtlas(keys:Array<String>, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAnimateFrames
	{
		var parentFrames:FlxAnimateFrames = cast Paths.getAtlas(keys[0].trim());
		if(keys.length > 1)
		{
			final original:FlxAnimateFrames = parentFrames;
			parentFrames = new FlxAnimateFrames(parentFrames.parent);
			parentFrames.addAtlas(original, true);
			for(i in 1...keys.length)
			{
				final extraFrames:Dynamic = Paths.getAtlas(keys[i].trim(), parentFolder, allowGPU);
				if(extraFrames != null) parentFrames.addAtlas(extraFrames, true);
			}
		}
		return parentFrames;
	}

	inline static public function getSparrowAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		final imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		final xml:String = modsXml(key);
		final xmlExists:Bool = FileSystem.exists(xml);

		return FlxAtlasFrames.fromSparrow(imageLoaded, (xmlExists ? File.getContent(xml) : getPath(Language.getFileTranslation('images/$key') + '.xml', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromSparrow(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.xml', TEXT, parentFolder));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		final imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		final txt:String = modsTxt(key);
		final txtExists:Bool = FileSystem.exists(txt);

		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, (txtExists ? File.getContent(txt) : getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentFolder));
		#end
	}

	inline static public function getAsepriteAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		final imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		#if MODS_ALLOWED
		final json:String = modsImagesJson(key);
		final jsonExists:Bool = FileSystem.exists(json);

		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (jsonExists ? File.getContent(json) : getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentFolder)));
		#else
		return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentFolder));
		#end
	}

	inline static public function getAnimateAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAnimateFrames
	{
		for(i in 1...10) // caching the atlas images
		{
			if(fileExists('images/$key/spritemap$i.png', IMAGE, parentFolder))
				image('$key/spritemap$i', parentFolder, allowGPU);
		}

		final animJson:String = Language.getFileTranslation('images/$key') + '/Animation.json';
		final folderLoaded:String = getPath(animJson, parentFolder);
		return fileExists(animJson, TEXT, parentFolder) ? FlxAnimateFrames.fromAnimate(folderLoaded.replace('/Animation.json', '')) : null;
	}

	inline static public function formatToSongPath(path:String)
	{
		final invalidChars = ~/[~&;:<>#\s]/g;
		final hideChars = ~/[.,'"%?!]/g;
		return hideChars.replace(invalidChars.replace(path, '-'), '').trim().toLowerCase();
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	public static function returnSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true)
	{
		final file:String = getPath(Language.getFileTranslation(key) + '.$SOUND_EXT', SOUND, path, modsAllowed);

		//trace('precaching sound: $file');
		if(!currentTrackedSounds.exists(file))
		{
			if(fileExists(Language.getFileTranslation(key) + '.$SOUND_EXT', SOUND, path, modsAllowed))
				currentTrackedSounds.set(file, #if sys Sound.fromFile(file) #else OpenFlAssets.getSound(file) #end);
			else if(beepOnNull)
			{
				trace('SOUND NOT FOUND: $key, PATH: $path');
				FlxG.log.error('SOUND NOT FOUND: $key, PATH: $path');
				return FlxAssets.getSound('flixel/sounds/beep');
			}
		}
		localTrackedAssets.push(file);
		return currentTrackedSounds.get(file);
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '')
		return 'mods/' + key;

	inline static public function modsImages(key:String)
		return modFolders('images/' + key + '.png');

	inline static public function modsXml(key:String)
		return modFolders('images/' + key + '.xml');

	inline static public function modsTxt(key:String)
		return modFolders('images/' + key + '.txt');

	inline static public function modsJson(key:String)
		return modFolders('data/' + key + '.json');

	inline static public function modsImagesJson(key:String)
		return modFolders('images/' + key + '.json');

	static public function modFolders(key:String)
	{
		if(Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			final fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			if(FileSystem.exists(fileToCheck)) return fileToCheck;
		}

		for(mod in Mods.getGlobalMods())
		{
			final fileToCheck:String = mods(mod + '/' + key);
			if(FileSystem.exists(fileToCheck)) return fileToCheck;
		}

		return 'mods/' + key;
	}
	#end
}