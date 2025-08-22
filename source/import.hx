#if !macro
#if sys
import sys.*;
import sys.io.*;
#elseif js
import js.html.*;
#end

//Discord API
#if DISCORD_ALLOWED
import backend.Discord;
#end

//Psych
#if LUA_ALLOWED
import llua.*;
import llua.Lua;
#end

#if ACHIEVEMENTS_ALLOWED
import backend.Achievements;
#end

import backend.ui.*; //Psych-UI
import backend.Paths;
import backend.Controls;
import backend.CoolUtil;
import backend.MusicBeatState;
import backend.MusicBeatSubstate;
import backend.CustomTransition;
import backend.ClientPrefs;
import backend.Conductor;
import backend.BaseStage;
import backend.Difficulty;
import backend.Mods;
import backend.Language;
import backend.Highscore;
import backend.PsychCamera;

import objects.Alphabet;
import objects.BGSprite;
import objects.PsychSprite;

import states.PlayState;
import states.LoadingState;

import animate.*; //flixel-animate

import flxsvg.FlxSvgSprite;

//Flixel
import flixel.sound.FlxSound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxAssets.FlxShader;
import flixel.addons.transition.FlxTransitionableState;

using StringTools;
#end