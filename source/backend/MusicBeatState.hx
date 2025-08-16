package backend;

import flixel.FlxState;
import backend.PsychCamera;

class MusicBeatState extends FlxState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;

	var _psychCameraInitialized:Bool = false;

	public var controls(get, never):Controls;
	private function get_controls()
		return Controls.instance;

	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static function getVariables()
		return getState().variables;

	override function create()
	{
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		#if MODS_ALLOWED Mods.updatedOnState = false; #end

		if(!_psychCameraInitialized) initPsychCamera();

		super.create();

		if(!skip) openSubState(new CustomTransition(0.5, true));

		FlxG.fixedTimestep = false;
		FlxTransitionableState.skipNextTransOut = false;
		timePassedOnState = 0;
	}

	public function initPsychCamera():PsychCamera
	{
		var camera:PsychCamera = new PsychCamera();
		FlxG.cameras.reset(camera);
		FlxG.cameras.setDefaultDrawTarget(camera, true);
		_psychCameraInitialized = true;
		return camera;
	}

	public static var timePassedOnState:Float = 0;
	override function update(elapsed:Float)
	{
		//everyStep();
		final oldStep:Int = curStep;
		timePassedOnState += elapsed;

		updateCurStep();
		updateBeat();

		if(oldStep != curStep)
		{
			if(curStep > 0) stepHit();

			if(PlayState.SONG != null)
			{
				if(oldStep < curStep) updateSection();
				else rollbackSection();
			}
		}

		if(FlxG.keys.justPressed.F5) FlxG.resetState();
		if(FlxG.keys.justPressed.F11) FlxG.fullscreen = !FlxG.fullscreen;
		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;

		stagesFunc(function(stage:BaseStage) {
			stage.update(elapsed);
		});

		super.update(elapsed);
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			stepsToDo += Math.round(getBeatsOnSection() * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		final lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for(i in 0...PlayState.SONG.notes.length)
		{
			if(PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;

				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void
	{
		final lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);
		final shit = ((Conductor.songPosition - ClientPrefs.data.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	override function startOutro(onOutroComplete:()->Void):Void
	{
		if(!FlxTransitionableState.skipNextTransIn)
		{
			FlxG.state.openSubState(new CustomTransition(0.5, false));
			CustomTransition.onFinish = onOutroComplete;
			return;
		}

		FlxTransitionableState.skipNextTransIn = false;
		if(onOutroComplete != null) onOutroComplete();
	}

	// purely here because my lazy ass doesn't want to edit a few lines
	public static function switchState(nextState:FlxState = null)
	{
		FlxG.switchState(() -> nextState);
	}
	public static function resetState()
	{
		FlxG.resetState();
	}

	public static function getState():MusicBeatState
		return cast (FlxG.state, MusicBeatState);

	public static function getSubState():MusicBeatSubstate
		return cast (FlxG.state.subState, MusicBeatSubstate);

	public function stepHit():Void
	{
		stagesFunc(function(stage:BaseStage) {
			stage.curStep = curStep;
			stage.curDecStep = curDecStep;
			stage.stepHit();
		});

		if(curStep % 4 == 0) beatHit();
	}

	public var stages:Array<BaseStage> = [];
	public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
		stagesFunc(function(stage:BaseStage) {
			stage.curBeat = curBeat;
			stage.curDecBeat = curDecBeat;
			stage.beatHit();
		});
	}

	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
		stagesFunc(function(stage:BaseStage) {
			stage.curSection = curSection;
			stage.sectionHit();
		});
	}

	function stagesFunc(func:BaseStage->Void)
	{
		for(stage in stages)
			if(stage != null && stage.exists && stage.active)
				func(stage);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}