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

		#if FEATURE_HSCRIPT
		scripts = new ScriptGroup();
		scripts.onAddScript.push(onAddScript);

		initScripts();
		#end
	}

	public  function loadStageData(stage:String)
	{
		if (FlxG.save.data.background)
		{

			switch (stage)
			{
				case 'halloween':
					{
						hasGF = true;
							var hallowTex = FlxAtlasFrames.fromSparrow('assets/images/stages/halloween_bg.png', 'assets/images/stages/halloween_bg.xml');
							var halloweenBG:FlxSprite;
							halloweenBG = new FlxSprite(-200, -100);
							halloweenBG.frames = hallowTex;
							halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
							halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
							halloweenBG.animation.play('idle');
							halloweenBG.antialiasing = true;
							add(halloweenBG);
					}
				case 'philly':
					{
							//curStage = 'philly';
							hasGF = true;
							var bg:FlxSprite = new FlxSprite(-100).loadGraphic('assets/images/philly/sky.png');
							bg.scrollFactor.set(0.1, 0.1);
							add(bg);

							var city:FlxSprite = new FlxSprite(-10).loadGraphic('assets/images/philly/city.png');
							city.scrollFactor.set(0.3, 0.3);
							city.setGraphicSize(Std.int(city.width * 0.85));
							city.updateHitbox();
							add(city);
							var phillyCityLights;
							phillyCityLights = new FlxTypedGroup<FlxSprite>();
							add(phillyCityLights);

							for (i in 0...5)
							{
								var light:FlxSprite = new FlxSprite(city.x).loadGraphic('assets/images/philly/win' + i + '.png');
								light.scrollFactor.set(0.3, 0.3);
								light.visible = false;
								light.setGraphicSize(Std.int(light.width * 0.85));
								light.updateHitbox();
								light.antialiasing = true;
								phillyCityLights.add(light);
							}

							var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic('assets/images/philly/behindTrain.png');
							add(streetBehind);

							var phillyTrain:FlxSprite;
							phillyTrain = new FlxSprite(2000, 360).loadGraphic('assets/images/philly/train.png');
							add(phillyTrain);

							trainSound = new FlxSound().loadEmbedded('assets/sounds/train_passes' + TitleState.soundExt);
							FlxG.sound.list.add(trainSound);

							// var cityLights:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.win0.png);

							var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic('assets/images/philly/street.png');
							add(street);
						}
				case 'limo':
					{
						var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic(Paths.image('stages/limo/limoSunset'));
						skyBG.scrollFactor.set(0.1, 0.1);
						skyBG.antialiasing = FlxG.save.data.antialiasing;
						swagBacks['skyBG'] = skyBG;
						toAdd.push(skyBG);

						var bgLimo:FlxSprite = new FlxSprite(-200, 480);
						bgLimo.frames = Paths.getSparrowAtlas('stages/limo/bgLimo');
						bgLimo.animation.addByPrefix('drive', "background limo pink", Std.int(24 * Conductor.rate));
						bgLimo.animation.play('drive');
						bgLimo.scrollFactor.set(0.4, 0.4);
						bgLimo.antialiasing = FlxG.save.data.antialiasing;
						swagBacks['bgLimo'] = bgLimo;
						toAdd.push(bgLimo);

						var fastCar:FlxSprite;
						fastCar = new FlxSprite(-300, 160).loadGraphic(Paths.image('stages/limo/fastCarLol'));
						fastCar.antialiasing = FlxG.save.data.antialiasing;
						fastCar.visible = false;
						fastCar.moves = true;
						var grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();

						if (FlxG.save.data.quality)
						{
							swagGroup['grpLimoDancers'] = grpLimoDancers;
							toAdd.push(grpLimoDancers);

							for (i in 0...5)
							{
								var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
								dancer.scrollFactor.set(0.4, 0.4);
								grpLimoDancers.add(dancer);
								swagBacks['dancer' + i] = dancer;
							}

							swagBacks['fastCar'] = fastCar;
							layInFront[2].push(fastCar);
							resetFastCar();
						}

						var limoTex = Paths.getSparrowAtlas('stages/limo/limoDrive');

						var limo = new FlxSprite(-120, 550);
						limo.frames = limoTex;
						limo.animation.addByPrefix('drive', "Limo stage", 24);
						limo.animation.play('drive');
						limo.antialiasing = FlxG.save.data.antialiasing;
						layInFront[0].push(limo);
						swagBacks['limo'] = limo;

						if (!FlxG.save.data.quality)
						{
							grpLimoDancers.kill();
							grpLimoDancers.destroy();
							fastCar.kill();
							fastCar.destroy();
						}
					}
				case 'mall':
					{
						var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic(Paths.image('stages/mall/bgWalls'));
						bg.antialiasing = FlxG.save.data.antialiasing;
						bg.scrollFactor.set(0.2, 0.2);
						bg.active = false;
						bg.setGraphicSize(Std.int(bg.width * 0.8));
						bg.updateHitbox();
						swagBacks['bg'] = bg;
						toAdd.push(bg);

						var upperBoppers = new FlxSprite(-240, -90);
						upperBoppers.frames = Paths.getSparrowAtlas('stages/mall/upperBop');
						upperBoppers.animation.addByPrefix('idle', "Upper Crowd Bob", Std.int(24 * Conductor.rate), false);
						upperBoppers.antialiasing = FlxG.save.data.antialiasing;
						upperBoppers.scrollFactor.set(0.33, 0.33);
						upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
						upperBoppers.updateHitbox();
						if (FlxG.save.data.quality)
						{
							swagBacks['upperBoppers'] = upperBoppers;
							toAdd.push(upperBoppers);
							animatedBacks.push(upperBoppers);
						}

						var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic(Paths.image('stages/mall/bgEscalator'));
						bgEscalator.antialiasing = FlxG.save.data.antialiasing;
						bgEscalator.scrollFactor.set(0.3, 0.3);
						bgEscalator.active = false;
						bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
						bgEscalator.updateHitbox();
						swagBacks['bgEscalator'] = bgEscalator;
						toAdd.push(bgEscalator);

						var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic(Paths.image('stages/mall/christmasTree'));
						tree.antialiasing = FlxG.save.data.antialiasing;
						tree.scrollFactor.set(0.40, 0.40);
						swagBacks['tree'] = tree;
						toAdd.push(tree);

						var bottomBoppers = new FlxSprite(-300, 140);
						bottomBoppers.frames = Paths.getSparrowAtlas('stages/mall/bottomBop');
						bottomBoppers.animation.addByPrefix('idle', 'Bottom Level Boppers Idle', Std.int(24 * Conductor.rate), false);
						bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', Std.int(24 * Conductor.rate), false);
						bottomBoppers.antialiasing = FlxG.save.data.antialiasing;
						bottomBoppers.scrollFactor.set(0.9, 0.9);
						bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
						bottomBoppers.updateHitbox();
						if (FlxG.save.data.quality)
						{
							swagBacks['bottomBoppers'] = bottomBoppers;
							toAdd.push(bottomBoppers);
							animatedBacks.push(bottomBoppers);
						}

						var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic(Paths.image('stages/mall/fgSnow'));
						fgSnow.active = false;
						fgSnow.antialiasing = FlxG.save.data.antialiasing;
						swagBacks['fgSnow'] = fgSnow;
						toAdd.push(fgSnow);

						var santa = new FlxSprite(-840, 150);
						santa.frames = Paths.getSparrowAtlas('stages/mall/santa');
						santa.animation.addByPrefix('idle', 'santa idle in fear', Std.int(24 * Conductor.rate), false);
						santa.antialiasing = FlxG.save.data.antialiasing;
						if (FlxG.save.data.quality)
						{
							swagBacks['santa'] = santa;
							toAdd.push(santa);
							animatedBacks.push(santa);
						}
						if (!FlxG.save.data.quality)
						{
							upperBoppers.kill();
							bottomBoppers.kill();
							upperBoppers.destroy();
							bottomBoppers.destroy();
						}
					}
				case 'mallEvil':
					{
						var bg:FlxSprite = new FlxSprite(-400, -500).loadGraphic(Paths.image('stages/mall/evilBG'));
						bg.antialiasing = FlxG.save.data.antialiasing;
						bg.scrollFactor.set(0.2, 0.2);
						bg.active = false;
						bg.setGraphicSize(Std.int(bg.width * 0.8));
						bg.updateHitbox();
						swagBacks['bg'] = bg;
						toAdd.push(bg);

						var evilTree:FlxSprite = new FlxSprite(300, -300).loadGraphic(Paths.image('stages/mall/evilTree'));
						evilTree.antialiasing = FlxG.save.data.antialiasing;
						evilTree.scrollFactor.set(0.2, 0.2);
						swagBacks['evilTree'] = evilTree;
						toAdd.push(evilTree);

						var evilSnow:FlxSprite = new FlxSprite(-200, 700).loadGraphic(Paths.image("stages/mall/evilSnow"));
						evilSnow.antialiasing = FlxG.save.data.antialiasing;
						swagBacks['evilSnow'] = evilSnow;
						toAdd.push(evilSnow);
					}
				case 'school':
					{
						var bgSky = new FlxSprite().loadGraphic(Paths.image('stages/school/weebSky'));
						bgSky.scrollFactor.set(0.1, 0.1);
						bgSky.antialiasing = false;
						swagBacks['bgSky'] = bgSky;
						toAdd.push(bgSky);

						var repositionShit = -200;

						var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic(Paths.image('stages/school/weebSchool'));
						bgSchool.scrollFactor.set(0.6, 0.90);
						bgSchool.antialiasing = false;
						swagBacks['bgSchool'] = bgSchool;
						toAdd.push(bgSchool);

						var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic(Paths.image('stages/school/weebStreet'));
						bgStreet.scrollFactor.set(0.95, 0.95);
						bgStreet.antialiasing = false;
						swagBacks['bgStreet'] = bgStreet;
						toAdd.push(bgStreet);

						var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic(Paths.image('stages/school/weebTreesBack'));
						fgTrees.scrollFactor.set(0.9, 0.9);
						fgTrees.antialiasing = false;
						swagBacks['fgTrees'] = fgTrees;
						toAdd.push(fgTrees);

						var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
						var treetex = Paths.getPackerAtlas('stages/school/weebTrees');
						bgTrees.frames = treetex;
						bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], Std.int(12 * Conductor.rate));
						bgTrees.animation.play('treeLoop');
						bgTrees.antialiasing = false;
						bgTrees.scrollFactor.set(0.85, 0.85);
						swagBacks['bgTrees'] = bgTrees;
						toAdd.push(bgTrees);

						var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
						treeLeaves.frames = Paths.getSparrowAtlas('stages/school/petals');
						treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', Std.int(24 * Conductor.rate), true);
						treeLeaves.animation.play('leaves');
						treeLeaves.antialiasing = false;
						treeLeaves.scrollFactor.set(0.85, 0.85);
						swagBacks['treeLeaves'] = treeLeaves;
						toAdd.push(treeLeaves);

						var widShit = Std.int(bgSky.width * 6);

						bgSky.setGraphicSize(widShit);
						bgSchool.setGraphicSize(widShit);
						bgStreet.setGraphicSize(widShit);
						bgTrees.setGraphicSize(Std.int(widShit * 1.4));
						fgTrees.setGraphicSize(Std.int(widShit * 0.8));
						treeLeaves.setGraphicSize(widShit);

						fgTrees.updateHitbox();
						bgSky.updateHitbox();
						bgSchool.updateHitbox();
						bgStreet.updateHitbox();
						bgTrees.updateHitbox();
						treeLeaves.updateHitbox();

						if (FlxG.save.data.quality)
						{
							var bgGirls = new BackgroundGirls(-100, 190);
							bgGirls.scrollFactor.set(0.9, 0.9);
							//bgGirls.setGraphicSize(Std.int(bgGirls.width * CoolUtil.daPixelZoom)); //reimplement soon i just disabled this since i don't want to deal with it rn
							if (PlayState.SONG != null && PlayState.SONG.song == 'roses')
								bgGirls.getScared();
							bgGirls.updateHitbox();
							swagBacks['bgGirls'] = bgGirls;
							bgGirls.antialiasing = false;
							toAdd.push(bgGirls);
						}
					}
				case 'schoolEvil':
					{
						var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
						var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);

						var posX = 400;
						var posY = 200;

						var bg:FlxSprite = new FlxSprite(posX, posY);
						bg.frames = Paths.getSparrowAtlas('stages/school/animatedEvilSchool');
						bg.animation.addByPrefix('idle', 'background 2', Std.int(Conductor.rate * 24));
						bg.animation.play('idle');
						bg.scrollFactor.set(0.8, 0.9);
						bg.scale.set(6, 6);
						bg.antialiasing = false;
						swagBacks['bg'] = bg;
						toAdd.push(bg);
					}
				// Tank stage temporarily removed. Refers to something not yet backported and causing too many issues.
				case 'void': // In case you want to do chart with videos.
					curStage = 'void';
					var black:FlxSprite = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
					black.scrollFactor.set(0, 0);
					toAdd.push(black);

				case 'stage':
					{
						curStage = 'stage';
						var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('stageback'));
						bg.antialiasing = FlxG.save.data.antialiasing;
						bg.scrollFactor.set(0.9, 0.9);
						bg.active = false;
						swagBacks['bg'] = bg;
						toAdd.push(bg);

						var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('stagefront'));
						stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
						stageFront.updateHitbox();
						stageFront.antialiasing = FlxG.save.data.antialiasing;
						stageFront.scrollFactor.set(0.9, 0.9);
						stageFront.active = false;
						swagBacks['stageFront'] = stageFront;
						toAdd.push(stageFront);

						if (FlxG.save.data.quality)
						{
							var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.image('stagecurtains'));
							stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
							stageCurtains.updateHitbox();
							stageCurtains.antialiasing = FlxG.save.data.antialiasing;
							stageCurtains.scrollFactor.set(1.3, 1.3);
							stageCurtains.active = false;

							swagBacks['stageCurtains'] = stageCurtains;
							toAdd.push(stageCurtains);
						}
					}
			}
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
