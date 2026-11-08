package stage;

import lime.app.Application; // For the error.
    import openfl.events.UncaughtErrorEvent; // Also for the error.
import flixel.group.FlxGroup.FlxTypedGroup; // Groups
import flixel.graphics.frames.FlxAtlasFrames; // for animated sprites
import PlayState; // To reference in-game characters.
import flixel.FlxState;

// This code is slightly modified from some JSON sprite code I made yesterday or the day before but finished today (2026-11-6). I think it might be on GitHub but I don't know for sure. I hope it may be useful to somebody!

class JSONStage extends FlxState
{
            var spriteLoadingScheme:String;
            var requestedStage:String = "stage";

            var levelSprite:FlxSprite;
            var parsedFile = haxe.Json.parse("{ }"); // The reason that there's two curly brackets is so that we can make the variable into a JSON later and not at the start. This is so we can use different JSON files and not worry about any errors further on!

            public var currentSpriteLoader:Array<Dynamic>;
            public var allSpriteLoader:Array<Dynamic>; // Used for the kill() function. Probably does not need to be public.

            public var back_spriteCollection:FlxTypedGroup<FlxSprite>;
            public var front_spriteCollection:FlxTypedGroup<FlxSprite>;

            // Recycled-external variables:
                public var camZoom:Float = 1.0;
                public var toAdd:Array<Dynamic> = []; // Add BGs on stage startup, load BG in by using "toAdd.push(bgVar);" // From KEC, it might be what solves my problems!

            public function new (requestedStage:String, spriteLoadingScheme:String){
            //super.new();
            super();
                trace("loadElements ran from new lol");
                loadElements(requestedStage, spriteLoadingScheme);
            }

            public function loadElements(requestedStage:String, spriteLoadingScheme:String){ // backSprites and foregroundSprites, use "front" and "back"
                // Loads JSON file for the stage and sends a trace to cofirm it's loaded.

                    if (requestedStage == null || requestedStage.length < 1) requestedStage = 'stage';

                    parsedFile = haxe.Json.parse(sys.io.File.getContent('assets/data/stages/$requestedStage.json'));
                    trace('Loading stage file: $requestedStage as assets/data/stages/$requestedStage.json');
                    currentSpriteLoader = parsedFile.backSprites;


                //  Parses the back and front sprites.
                    if(spriteLoadingScheme.toLowerCase() == "front"){
                    currentSpriteLoader = parsedFile.frontSprites; // If you don't have any foreground sprites, then keep it as just: "frontSprites":[], -- That way the game won't crash. I will try to find a way to make it so that the foreground and background sprites can be optional.
                    }else if(spriteLoadingScheme.toLowerCase() == "back"){
                        currentSpriteLoader = parsedFile.backSprites;
                    }else{
                            currentSpriteLoader = null;
                            var e:UncaughtErrorEvent;
                            //Application.current.window.alert(e.error, "Invalid operation! (Loading JSON Elements that have no definition, load front or back sprites!)");
                            trace("Invalid operation! (Loading JSON Elements that have no definition, load front or back sprites!)");
                        }

                    // Parses the opposite variable
                        if(currentSpriteLoader == parsedFile.frontSprites){ // Function to make the other variable the opposite of this.
                                allSpriteLoader = parsedFile.backSprites;
                            }else{
                                allSpriteLoader = parsedFile.frontSprites;
                            }

                // Checks all values.
                //(if currentSpriteLoader != null){
                            for (i in currentSpriteLoader){ // for sprites in either front or back
                                            levelSprite = new FlxSprite();

                                            if (i.directory != null)
                                                levelSprite.loadGraphic(i.directory + i.graphic); //directory and graphic. directory should end with a forward slash /
                                            else
                                                levelSprite.loadGraphic(i.graphic); //graphic

                                            if (i.x != null) levelSprite.x = i.x; // x || int, all real numbers
                                            if (i.y != null) levelSprite.y = i.y; // y

                                            if (i.flipX != null) levelSprite.flipX = i.flipX; //flipX || bool: true/false
                                            if (i.flipY != null) levelSprite.flipY = i.flipY; //flipY

                                            if (i.scale != null){levelSprite.scale.x = i.scale[0]; levelSprite.scale.y = i.scale[1];} // scale || array of floats: [float, float]
                                            if (i.antialiasing != null) levelSprite.antialiasing = i.antialiasing; //antialiasing || bool: true/false

                                        // Optional Features Here
                                            if (i.sparrow == true){     // sparrow || bool: true/false
                                                if (i.xml != null){            // xml || string "text"
                                                    levelSprite.frames = FlxAtlasFrames.fromSparrow(i.graphic, i.xml);
                                                }else{
                                                    levelSprite.frames = FlxAtlasFrames.fromSparrow('${i.graphic}.png', '${i.graphic}.xml');
                                                }

                                                if (i.animations != null){ // animations || dynamic array, has a null check.
                                                        var spriteAnims:Array<Dynamic> = i.animations;
                                                        for (craftedAnimConfigs in spriteAnims){
                                                            levelSprite.animation.addByPrefix(craftedAnimConfigs[0], craftedAnimConfigs[1], craftedAnimConfigs[2]);
                                                        }
                                                        if (i.startAnim != null){levelSprite.animation.play(i.startAnim);}
                                                }else{
                                                        if (i.startAnim != null){trace("You're attempting to make sprite [" + i + "] (Named: " + i.name + ") play an animation despite it lacking any! Please check your configuration!");}
                                                }
                                            } // sparrow ends here



                                    // FNF Required Features
     //                                   if (i.scrollFactor != null) levelSprite.scrollFactor.set(i.scrollFactor); // scrollFactor || array of floats. must have TWO values!
                                        // I thought there was going to be more.

                                    // ENSURE THIS IS NOT IN THE CHECK FOR SPARROWS
                                    add(levelSprite);
                                    if (currentSpriteLoader == parsedFile.backSprites)
                                        //back_spriteCollection.add(levelSprite);
                                    if (currentSpriteLoader == parsedFile.frontSprites)
                                        //front_spriteCollection.add(levelSprite);

                                    toAdd.push(levelSprite);
                            }

                         /*   for (sprite in )

                                trace("JSONObject  toAdd variable: " + toAdd);*/

                                add(back_spriteCollection);
                                add(front_spriteCollection);
               // }



            }




            public override function kill()
                {
                    super.kill();
                        for (i in back_spriteCollection){i.destroy();}
                        for (i in front_spriteCollection){i.destroy();}

                    /*for (prop in this.namedProps)
                    {
                        prop.destroy();
                    }
                    namedProps.clear();

                    for (char in this.characters)
                    {
                        char.destroy();
                    }
                    characters.clear();

                    for (sprite in this.group)
                    {
                        sprite.destroy();
                    }
                    group.clear();*/
                }
}
