package backend;

#if DISCORD_ALLOWED
import Sys.sleep;
import sys.thread.Thread;

import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;
import hxdiscord_rpc.Types.DiscordButton;

import flixel.util.FlxStringUtil;

class DiscordClient
{
	public static var isInitialized:Bool = false;
	private inline static final _defaultID:String = "863222024192262205";
	public static var clientID(default, set):String = _defaultID;
	private static var presence:DiscordPresence = new DiscordPresence();
	// hides this field from scripts and reflection in general
	@:unreflective private static var __thread:Thread;

	public static function check()
	{
		if(ClientPrefs.data.discordRPC) initialize();
		else if(isInitialized) shutdown();
	}

	public static function prepare()
	{
		if(!isInitialized && ClientPrefs.data.discordRPC)
			initialize();

		if(FlxG.stage.window.onClose.has(shutdown))
			FlxG.stage.window.onClose.add(shutdown);
	}

	public dynamic static function shutdown()
	{
		if(!isInitialized) return;

		isInitialized = false;
		Discord.Shutdown();
	}

	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void
	{
		final user:String = cast (request[0].username, String);
		final discriminator:String = cast (request[0].discriminator, String);

		var message:String = '(Discord) Connected to User ';
		if(discriminator != '0') //Old discriminators
			message += '($user#$discriminator)';
		else //New Discord IDs/Discriminator system
			message += '($user)';

		trace(message);
		changePresence();
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		trace('Discord: Error ($errorCode: ${cast(message, String)})');
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		trace('Discord: Disconnected ($errorCode: ${cast(message, String)})');
	}

	public static function initialize()
	{
		if(isInitialized) return;

		var discordHandlers:DiscordEventHandlers = new DiscordEventHandlers();
		discordHandlers.ready = cpp.Function.fromStaticFunction(onReady);
		discordHandlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		discordHandlers.errored = cpp.Function.fromStaticFunction(onError);
		Discord.Initialize(clientID, cpp.RawPointer.addressOf(discordHandlers), false, null);

		trace("Discord Client initialized");

		if(__thread == null)
			__thread = Thread.create(() ->
			{
				while(true)
				{
					if(isInitialized)
					{
						#if DISCORD_DISABLE_IO_THREAD
						Discord.UpdateConnection();
						#end
						Discord.RunCallbacks();
					}

					// Wait 1 second until the next loop...
					Sys.sleep(1.0);
				}
			});

		isInitialized = true;
	}

	public static function changePresence(?details:String = 'In the Menus', ?state:String, ?smallImageKey:String, ?smallImageText:String, ?largeImageKey:String = 'icon', ?largeImageText:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float = 0)
	{
		final startTimestamp:Float = hasStartTimestamp ? Date.now().getTime() : 0;
		if(endTimestamp > 0) endTimestamp = startTimestamp + endTimestamp;

		presence.state = state;
		presence.details = details;
		presence.smallImageKey = smallImageKey;
		presence.smallImageText = (smallImageText != null) ? smallImageText : smallImageKey;
		presence.largeImageKey = largeImageKey;
		presence.largeImageText = (largeImageText != null) ? largeImageText : "Engine Version: " + states.MainMenuState.psychEngineVersion;
		// Obtained times are in milliseconds so they are divided so Discord can use it
		presence.startTimestamp = Std.int(startTimestamp / 1000);
		presence.endTimestamp = Std.int(endTimestamp / 1000);
		updatePresence();

		//trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp, $largeImageKey');
	}

	public static function makeDiscordButton(id:Int, label:String, url:String)
	{
		presence.makeButton(id, label, url);
		updatePresence();
	}

	public static function updatePresence()
	{
		Discord.UpdatePresence(cpp.RawConstPointer.addressOf(presence.__presence));
	}

	inline public static function resetClientID()
	{
		clientID = _defaultID;
	}

	private static function set_clientID(newID:String)
	{
		if(newID == null || newID.trim().length < 1) newID = _defaultID;

		final change:Bool = (clientID != newID);
		clientID = newID;

		if(change && isInitialized)
		{
			shutdown();
			initialize();
			updatePresence();
		}
		return newID;
	}

	#if MODS_ALLOWED
	public static function loadModRPC()
	{
		var pack:Dynamic = Mods.getPack();
		if(pack != null && pack.discordRPC != null && pack.discordRPC != clientID)
		{
			clientID = pack.discordRPC;
			//trace('Changing clientID! $clientID, $_defaultID');
		}
	}
	#end

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State)
	{
		Lua_helper.add_callback(lua, "changeDiscordPresence", changePresence);
		Lua_helper.add_callback(lua, "changeDiscordClientID", function(?newID:String) {
			if(newID == null) newID = _defaultID;
			clientID = newID;
		});
		Lua_helper.add_callback(lua, "makeDiscordButton", makeDiscordButton);
	}
	#end
}

@:allow(backend.DiscordClient)
private final class DiscordPresence
{
	public var state(get, set):String;
	public var details(get, set):String;
	public var smallImageKey(get, set):String;
	public var smallImageText(get, set):String;
	public var largeImageKey(get, set):String;
	public var largeImageText(get, set):String;
	public var startTimestamp(get, set):Int;
	public var endTimestamp(get, set):Int;

	@:noCompletion private var __presence:DiscordRichPresence;

	function new()
	{
		__presence = new DiscordRichPresence();
	}

	public function makeButton(id:Int, label:String, url:String):DiscordButton
	{
		id = Std.int(FlxMath.bound(id, 0, 1));
		final button = new DiscordButton();
		button.label = label;
		button.url = url;
		return __presence.buttons[id] = button;
	}

	public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("state", state),
			LabelValuePair.weak("details", details),
			LabelValuePair.weak("smallImageKey", smallImageKey),
			LabelValuePair.weak("smallImageText", smallImageText),
			LabelValuePair.weak("largeImageKey", largeImageKey),
			LabelValuePair.weak("largeImageText", largeImageText),
			LabelValuePair.weak("startTimestamp", startTimestamp),
			LabelValuePair.weak("endTimestamp", endTimestamp)
		]);
	}

	@:noCompletion inline function get_state():String
	{
		return __presence.state;
	}

	@:noCompletion inline function set_state(value:String):String
	{
		return __presence.state = value;
	}

	@:noCompletion inline function get_details():String
	{
		return __presence.details;
	}

	@:noCompletion inline function set_details(value:String):String
	{
		return __presence.details = value;
	}

	@:noCompletion inline function get_smallImageKey():String
	{
		return __presence.smallImageKey;
	}

	@:noCompletion inline function set_smallImageKey(value:String):String
	{
		return __presence.smallImageKey = value;
	}

	@:noCompletion inline function get_smallImageText():String
	{
		return __presence.smallImageText;
	}

	@:noCompletion inline function set_smallImageText(value:String):String
	{
		return __presence.smallImageText = value;
	}

	@:noCompletion inline function get_largeImageKey():String
	{
		return __presence.largeImageKey;
	}
	
	@:noCompletion inline function set_largeImageKey(value:String):String
	{
		return __presence.largeImageKey = value;
	}

	@:noCompletion inline function get_largeImageText():String
	{
		return __presence.largeImageText;
	}

	@:noCompletion inline function set_largeImageText(value:String):String
	{
		return __presence.largeImageText = value;
	}

	@:noCompletion inline function get_startTimestamp():Int
	{
		return __presence.startTimestamp;
	}

	@:noCompletion inline function set_startTimestamp(value:Int):Int
	{
		return __presence.startTimestamp = value;
	}

	@:noCompletion inline function get_endTimestamp():Int
	{
		return __presence.endTimestamp;
	}

	@:noCompletion inline function set_endTimestamp(value:Int):Int
	{
		return __presence.endTimestamp = value;
	}
}
#end