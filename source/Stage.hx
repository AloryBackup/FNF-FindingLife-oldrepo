package;

import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.group.FlxGroup;
import flixel.math.FlxAngle;
import haxe.DynamicAccess;
//Modified from KEC
import StageData;
import openfl.Assets as OpenFlAssets;
import openfl.display.BlendMode;
import openfl.filters.ShaderFilter;/*
#if FEATURE_HSCRIPT
import kec.backend.script.Script;
import kec.backend.script.ScriptGroup;
import kec.backend.script.ScriptUtil;
#end*/
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;

class Stage extends MusicBeatState
{
	#if FEATURE_HSCRIPT
	public var scripts:ScriptGroup;
	#end

	public var stageJSON:StageData;
	public var curStage:String = '';

	private var phillyWindow:FlxSprite;

	public var doesExist = false;
	public var stageDir:String = '';
	public var inEditor:Bool = false; // stop events from triggering and crashing the editor.

	public static var instance:Stage = null;

	public var camZoom:Float = 1.05; // The zoom of the camera to have at the start of the game
	public var hasGF:Bool = true; // Whether The Stage Has GF In It Or Not.
	public var staticCam:Bool = false; // Whether The Camera Moves In The Song.
	public var camPosition:Array<Float> = []; // Camera Position

	public var hideLastBG:Bool = false; // True = hide last BGs and show ones from slowBacks on certain step, False = Toggle visibility of BGs from SlowBacks on certain step
	// Use visible property to manage if BG would be visible or not at the start of the game
	public var tweenDuration:Float = 2; // How long will it tween hiding/showing BGs, variable above must be set to True for tween to activate
	public var toAdd:Array<Dynamic> = []; // Add BGs on stage startup, load BG in by using "toAdd.push(bgVar);"
	// Layering algorithm for noobs: Everything loads by the method of "On Top", example: You load wall first(Every other added BG layers on it), then you load road(comes on top of wall and doesn't clip through it), then loading street lights(comes on top of wall and road)
	public var swagBacks:Map<String,
		Dynamic> = []; // Store BGs here to use them later (for example with slowBacks, using your custom stage event or to adjust position in stage debug menu(press 8 while in PlayState with debug build of the game))
	public var swagGroup:Map<String, FlxTypedGroup<Dynamic>> = []; // Store Groups
	public var animatedBacks:Array<FlxSprite> = []; // Store animated backgrounds and make them play animation(Animation must be named Idle!! Else use swagGroup/swagBacks and script it in stepHit/beatHit function of this file!!)
	public var layInFront:Array<Array<FlxSprite>> = [[], [], []]; // BG layering, format: first [0] - in front of GF, second [1] - in front of opponent, third [2] - in front of boyfriend(and technically also opponent since Haxe layering moment)
	public var slowBacks:Map<Int,
		Array<FlxSprite>> = []; // Change/add/remove backgrounds mid song! Format: "slowBacks[StepToBeActivated] = [Sprites,To,Be,Changed,Or,Added];"

	// BGs still must be added by using toAdd Array for them to show in game after slowBacks take effect!!
	// BGs still must be added by using toAdd Array for them to show in game after slowBacks take effect!!
	var phillyLightsColors:Array<FlxColor>; // colors for week3 stage

	// All of the above must be set or used in your stage case code block!!
	public var positions:Map<String, Map<String, Array<Float>>> = [
		// Assign your characters positions on stage here! Or use the json system.
	];

	public function new(daStage:String)
	{
		super();

		this.curStage = daStage;
		stageJSON = StageJSON.loadJSONFile(daStage);
	}

	public  function loadStageData(stage:String)
	{
	// Replace function soon.
			funny_A.updateHitbox();
			spriteCollection.add(funny_A);
			//trace("Array [i]: " + i.graphic);
		}

	}

	public function initStageProperties()
	{
		switch (curStage)
		{
			case 'stage':
				camZoom = 0.9;
				doesExist = true;
			case 'halloween':
				camZoom = 1.05;
				doesExist = true;
			case 'philly':
				camZoom = 1.05;
				doesExist = true;
			case 'limo':
				camZoom = 0.9;
				doesExist = true;
			case 'mall':
				camZoom = 0.8;
				doesExist = true;
			case 'mallEvil':
				camZoom = 1.05;
				doesExist = true;
			case 'school':
				camZoom = 1.05;
				doesExist = true;
			case 'schoolEvil':
				camZoom = 1.05;
				doesExist = true;
			case 'tank':
				camZoom = 0.9;
				doesExist = true;
			case 'void':
				camZoom = 0.9;
				doesExist = true;
			default:
				camZoom = 1.05;
				stageDir = "shared";
		}

		overridePropertiesFromJSON();
	}


	public function loadElements(){
//loadBackgroundElements



		for (i in menuEntries){
			funny_A = new FlxSprite();
			//funny_A.loadGraphic("assets/images/num1.png");
			funny_A.loadGraphic(i.graphic);

				// Built in FlxSprite features. All are one-liners as it makes it slightly more digestible to read.
					if (i.x != null) funny_A.x = i.x;
					if (i.y != null) funny_A.y = i.y;
					if (i.flipX != null) funny_A.flipX = i.flipX;
					if (i.flipY != null) funny_A.flipY = i.flipY;

				// Optional yet Built-In
					if (i.scale != null){
						funny_A.scale.x = i.scale[0];
						funny_A.scale.y = i.scale[1];
					}
					if (i.antialiasing != null) funny_A.antialiasing = i.antialiasing;
					if (i.angle != null) funny_A.angle = i.angle;

				// Optional Features Here
					if (i.sparrow == true){ // If the JSON has a value called sparrow (bool). Also supports xml (string)
						if (i.xml != null){
							funny_A.frames = FlxAtlasFrames.fromSparrow(i.graphic, i.xml);
						}else{
							funny_A.frames = FlxAtlasFrames.fromSparrow('${i.graphic}.png', '${i.graphic}.xml');
						}

						if (i.animations != null){ // Checks to see if it's not null, and then proceeds.
								var spriteAnims:Array<Dynamic> = i.animations;

								for (craftedAnimConfigs in spriteAnims){
									funny_A.animation.addByPrefix(craftedAnimConfigs[0], craftedAnimConfigs[1], craftedAnimConfigs[2]);
									// Animation name, animation in XML file, and framerate.
								}

								if (i.startAnim != null){funny_A.animation.play(i.startAnim);}
						}else{
							if (i.startAnim != null){trace("You're attempting to make sprite [" + i + "] (Named: " + i.name + ") play an animation despite it lacking any! Please check your configuration!");}
						}
					}



	}








	// Initial and default Camera position, needs to be called after initStageProperties because of loading GF property.
	public function initCamPos()
	{
		if (camPosition.length == 0)
		{
			if (PlayState.SONG.gf != null)
			{
				camPosition = [
					PlayState.instance.gf.getGraphicMidpoint().x + PlayState.instance.gf.data.camPos[0],
					PlayState.instance.gf.getGraphicMidpoint().y + PlayState.instance.gf.data.camPos[1]
				];
			}
			else
			{
				camPosition = [0, 0];
			}
		}
	}

	private function overridePropertiesFromJSON()
	{
		if (stageJSON != null)
		{
			doesExist = true;
			if (stageJSON.staticCam != null)
				if (Std.isOfType(stageJSON.staticCam, Bool))
					staticCam = stageJSON.staticCam;

			if (stageJSON.camZoom != null)
				if (Std.isOfType(stageJSON.camZoom, Type.resolveClass('Float')))
					camZoom = stageJSON.camZoom;

			if (stageJSON.hasGF != null)
				if (Std.isOfType(stageJSON.hasGF, Bool))
					hasGF = stageJSON.hasGF;

			if (stageJSON.camPosition != null)
				if (Std.isOfType(stageJSON.camPosition, Type.resolveClass('Array')))
					camPosition = stageJSON.camPosition;

			if (stageJSON.positions != null)
			{
				var posesMap:DynamicAccess<Array<Float>> = haxe.Json.parse(haxe.Json.stringify(stageJSON.positions));
				var charMap:Map<String, Array<Float>> = [];
				for (char in posesMap.keys())
				{ // Don't use get(char) method because it crashes the game without any log
					charMap.set(char, posesMap[char]);
					positions.set(curStage, charMap);
				}
			}
		}
	}

	override public function update(elapsed:Float)
	{
		if (FlxG.save.data.background)
		{

			if (!inEditor)
			{
				switch (curStage)
				{
					case 'philly':
						if (trainMoving)
						{
							trainFrameTiming += elapsed;

							if (trainFrameTiming >= 1 / 24)
							{
								updateTrainPos();
								trainFrameTiming = 0;
							}
						}
					// phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed;

				}
			}
		}
		super.update(elapsed);
	}
	/*override function stepHit(curStep:Int):Void // an override, defined in MusicBeatState
	{
		super.stepHit(); //had curStep in it before

		if (FlxG.save.data.background)
		{
			var array = slowBacks[curStep];
			if (array != null && array.length > 0)
			{
				if (hideLastBG)
				{
					for (bg in swagBacks)
					{
						if (!array.contains(bg))
						{
							var tween = FlxTween.tween(bg, {alpha: 0}, tweenDuration, {
								onComplete: function(tween:FlxTween):Void
								{
									bg.visible = false;
								}
							});
						}
					}
					for (bg in array)
					{
						bg.visible = true;
						FlxTween.tween(bg, {alpha: 1}, tweenDuration);
					}
				}
				else
				{
					for (bg in array)
						bg.visible = !bg.visible;
				}
			}
		}
	}

	 function beatHit(curBeat:Int) //originally an override
	{
		super.beatHit();

		if (FlxG.save.data.quality && animatedBacks.length > 0 && FlxG.save.data.background)
		{
			for (bg in animatedBacks)
				bg.animation.play('idle', true);
		}

		if (FlxG.save.data.quality && FlxG.save.data.background)
		{
			switch (curStage)
			{
				case 'halloween':
					if (FlxG.random.bool(Conductor.bpm > 320 ? 100 : 10) && curBeat > lightningStrikeBeat + lightningOffset && !inEditor)
						if (FlxG.save.data.quality)
							lightningStrikeShit();
				case 'school':
					if (FlxG.save.data.quality)
						swagBacks['bgGirls'].dance();
				case 'limo':
					if (FlxG.save.data.quality)
					{
						swagGroup['grpLimoDancers'].forEach(function(dancer:BackgroundDancer)
						{
							dancer.dance();
						});

						if (FlxG.random.bool(10) && fastCarCanDrive && !inEditor)
							fastCarDrive();
					}
				case 'mall':
					if (!inEditor)
					{
						switch (PlayState.SONG.song)
						{
							case 'cocoa':
								switch (curBeat)
								{
									case 15 | 31 | 47 | 63 | 143:
										swagBacks['bottomBoppers'].animation.play('hey', true);
								}
							case 'eggnog':
								switch (curBeat)
								{
									case 15 | 23 | 31 | 39 | 47 | 55 | 63 | 79 | 87 | 95 | 103 | 119 | 127 | 135 | 143 | 151 | 159 | 167 | 175 | 191 | 199 |
										207 | 215:
										swagBacks['bottomBoppers'].animation.play('hey', true);
								}
								// I'm not happy with the amount of heys there are in these songs.
						}
					}
				case "philly":

					if (curBeat % 8 == 4
						&& FlxG.random.bool(Conductor.bpm > 320 ? 150 : 30)
						&& !trainMoving
						&& trainCooldown > 8
						&& !inEditor)
					{
						if (FlxG.save.data.quality)
						{
							trainCooldown = FlxG.random.int(-4, 0);
							trainStart();
						}
					}
			}
		}
	}

	override function sectionHit()
	{
		super.sectionHit();

	}*/

	// Variables and Functions for Stages
	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;
	var curLight:Int = 0;

	function lightningStrikeShit():Void
	{
		//FlxG.sound.play(Paths.sound('thunder_${FlxG.random.int(1, 2)}'));
		swagBacks['halloweenBG'].animation.play('lightning');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if (PlayState.instance.boyfriend != null
			&& PlayState.instance.gf != null
			&& PlayState.instance.boyfriend.data.char == 'bf'
			&& PlayState.instance.gf.data.char == 'gf')
		{
			PlayState.instance.boyfriend.playAnim('scared', true);
			PlayState.instance.gf.playAnim('scared', true);
		}
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;
	var trainSound:FlxSound;

	function trainStart():Void
	{
		if (FlxG.save.data.quality && FlxG.save.data.background && curStage == 'philly')
		{
			trainMoving = true;
			trainSound.play(true);
		}
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (FlxG.save.data.quality && curStage == 'philly')
		{
			if (trainSound.time >= 4700)
			{
				startedMoving = true;

				if (PlayState.instance.gf != null && PlayState.instance.gf.data.char == 'gftrain')
					PlayState.instance.gf.playAnim('hairBlow');
			}

			if (startedMoving)
			{
				var phillyTrain = swagBacks['phillyTrain'];
				phillyTrain.x -= 400;

				if (phillyTrain.x < -2000 && !trainFinishing)
				{
					phillyTrain.x = -1150;
					trainCars -= 1;

					if (trainCars <= 0)
						trainFinishing = true;
				}

				if (phillyTrain.x < -4000 && trainFinishing)
					trainReset();
			}
		}
	}

	function trainReset():Void
	{
		if (FlxG.save.data.quality && curStage == 'philly')
		{
			if (PlayState.instance.gf != null && PlayState.instance.gf.data.char == 'gftrain')
				PlayState.instance.gf.playAnim('hairFall');

			swagBacks['phillyTrain'].x = FlxG.width + 200;
			trainMoving = false;
			// trainSound.stop();
			// trainSound.time = 0;
			trainCars = 8;
			trainFinishing = false;
			startedMoving = false;
		}
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		if (FlxG.save.data.quality && curStage == 'limo')
		{
			var fastCar = swagBacks['fastCar'];
			fastCar.x = -12600;
			fastCar.y = FlxG.random.int(140, 250);
			fastCar.velocity.x = 0;
			fastCar.visible = false;
			fastCarCanDrive = true;
		}
	}

	function fastCarDrive()
	{
		if (FlxG.save.data.quality && curStage == 'limo')
		{
			//FlxG.sound.play(Paths.sounds('carPass${FlxG.random.int(0, 1)}'), 0.7);

			swagBacks['fastCar'].visible = true;
			swagBacks['fastCar'].velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
			fastCarCanDrive = false;
			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				resetFastCar();
			});
		}
	}

	override function destroy()
	{
		super.destroy();
		for (sprite in swagBacks.keys())
		{
			if (swagBacks[sprite] != null)
				swagBacks[sprite].destroy();
		}

		swagBacks.clear();

		while (toAdd.length > 0)
			toAdd.pop().destroy();
		while (animatedBacks.length > 0)
			animatedBacks.pop().destroy();
		for (array in layInFront)
			while (array.length > 0)
				array.pop().destroy();
		// thanks sword

		for (swag in swagGroup.keys())
		{
			if (swagGroup[swag].members != null)
				for (member in swagGroup[swag].members)
				{
					swagGroup[swag].members.remove(member);
					member.destroy();
				}
		}

		swagGroup.clear();

		#if FEATURE_HSCRIPT
		if (scripts != null)
		{
			scripts.active = false;
			scripts.destroy();
			scripts = null;
		}
		#end
	}
}
