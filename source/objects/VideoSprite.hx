package objects;

import flixel.addons.display.FlxPieDial;

#if hxvlc
import hxvlc.flixel.FlxVideo;
import hxvlc.flixel.FlxVideoSprite;
#end

import psychlua.LuaUtils;

class VideoSprite extends FlxSpriteGroup
{
	#if VIDEOS_ALLOWED
	public static var _videos:Array<VideoSprite> = [];

	public var onOverallFinish:Void->Void = null;
	public var onFinish:Void->Void = null;
	public var onSkip:Void->Void = null;

	public var canSkip(default, set):Bool = false;
	public var canPause:Bool = false;
	public var canExit:Bool = false;

	public var playbackRate(default, set):Float = 1;

	final _timeToSkip:Float = 1;
	public var holdingTime:Float = 0;

	public var videoSprite:FlxVideoSprite;
	public var cover:FlxSprite;
	public var skipSprite:FlxPieDial;

	private var videoName:String;

	public var isWaiting:Bool = false;
	public var isPlaying:Bool = false;
	public var isPaused:Bool = false;
	public var skippedVideo:Bool = false;
	var alreadyDestroyed:Bool = false;

	public function new(videoName:String, isWaiting:Bool, canSkip:Bool = false, shouldLoop:Dynamic = false)
	{
		super();

		this.videoName = videoName;
		this.isWaiting = isWaiting;

		scrollFactor.set();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		if(!isWaiting)
		{
			cover = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
			cover.scale.set(FlxG.width + 100, FlxG.height + 100);
			cover.screenCenter();
			cover.scrollFactor.set();
			add(cover);
		}

		// initialize sprites
		videoSprite = new FlxVideoSprite();
		videoSprite.antialiasing = ClientPrefs.data.antialiasing;
		add(videoSprite);

		this.canSkip = canSkip;

		// callbacks
		if(!shouldLoop) videoSprite.bitmap.onEndReached.add(destroy);

		videoSprite.bitmap.onFormatSetup.add(function()
		{
			videoSprite.setGraphicSize(FlxG.width);
			videoSprite.updateHitbox();
			videoSprite.screenCenter();
		});

		// start video and adjust resolution to screen size
		videoSprite.load(videoName, shouldLoop ? ['input-repeat=65545'] : null);
		_videos.push(this);
	}

	override function destroy()
	{
		if(alreadyDestroyed) return;

		if(videoSprite != null)
		{
			remove(videoSprite);
			videoSprite.destroy();
		}

		if(skipSprite != null)
		{
			remove(skipSprite);
			skipSprite.destroy();
		}

		if(cover != null)
		{
			remove(cover);
			cover.destroy();
		}

		if(skippedVideo)
		{
			if(onSkip != null) onSkip();
			onFinish = null;
		}
		else
		{
			if(onFinish != null) onFinish();
			onSkip = null;
		}

		if(onOverallFinish != null) onOverallFinish();

		trace('Video Destroyed');

		if(LuaUtils.getTargetInstance() != null && LuaUtils.getTargetInstance().members.contains(this))
			LuaUtils.getTargetInstance().remove(this);

		_videos.remove(this);
		super.destroy();

		alreadyDestroyed = true;
	}

	override function update(elapsed:Float)
	{
		if(canSkip)
		{
			if(Controls.instance.pressed('accept'))
				holdingTime = Math.max(0, Math.min(_timeToSkip, holdingTime + elapsed));
			else if (holdingTime > 0)
				holdingTime = Math.max(0, FlxMath.lerp(holdingTime, -0.1, FlxMath.bound(elapsed * 3, 0, 1)));

			updateSkipAlpha();

			if(holdingTime >= _timeToSkip)
			{
				trace('Skipped Video');
				skippedVideo = true;
				destroy();
				return;
			}
		}

		super.update(elapsed);
	}

	function updateSkipAlpha()
	{
		if(skipSprite == null) return;

		skipSprite.amount = Math.min(1, Math.max(0, (holdingTime / _timeToSkip) * 1.025));
		skipSprite.alpha = FlxMath.remapToRange(skipSprite.amount, 0.025, 1, 0, 1);
	}

	function set_canSkip(newValue:Bool)
	{
		canSkip = newValue;
		if(canSkip)
		{
			if(skipSprite == null)
			{
				skipSprite = new FlxPieDial(0, 0, 40, FlxColor.WHITE, 40, true, 24);
				skipSprite.replaceColor(FlxColor.BLACK, FlxColor.TRANSPARENT);
				skipSprite.x = FlxG.width - (skipSprite.width + 80);
				skipSprite.y = FlxG.height - (skipSprite.height + 72);
				skipSprite.amount = 0;
				add(skipSprite);
			}
		}
		else if(skipSprite != null)
		{
			remove(skipSprite);
			skipSprite.destroy();
			skipSprite = null;
		}
		return canSkip;
	}

	function set_playbackRate(newValue:Float)
	{
		playbackRate = newValue;
		if(videoSprite != null) videoSprite.bitmap.rate = newValue;
		return playbackRate;
	}

	public function play()
	{
		isPlaying = true;
		videoSprite?.play();
	}
	public function resume()
	{
		isPaused = false;
		videoSprite?.resume();
	}
	public function pause()
	{
		isPaused = true;
		videoSprite?.pause();
	}

	public static function clearVideos()
	{
		try
		{
			for(vid in _videos)
			{
				vid.destroy();
				vid = null;
			}
			_videos = [];
			trace("Cleared Videos!");
		}
		catch(e:Dynamic)
		{
			trace("Failed Clearing Videos!");
		}
	}
	#end
}