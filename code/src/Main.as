package
{   
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.BlendMode;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.Timer;
    import flash.utils.setTimeout;
    
    [SWF(width='640', height='480', backgroundColor='#333333', frameRate='30')]
    public class Main extends Sprite
    {
        private var shadow:ShadowCaster;
        private var lightAlert:LightAlert;
        
        private var fishies:Array = [];
           
        private var angler:Angler;
        private var controller:Controller;
        private var fishLayer:Sprite;
        
        var youWin:YouWin;
        var gameOver:GameOver;
        var home:Home;
        
        
        public function Main()
        {
            youWin = new YouWin();
            gameOver = new GameOver();
            home = new Home();
            
            youWin.playButton.addEventListener(MouseEvent.CLICK, newGame);
            gameOver.playButton.addEventListener(MouseEvent.CLICK, newGame);
            home.playButton.addEventListener(MouseEvent.CLICK, newGame);
            
            youWin.sound.addEventListener(MouseEvent.CLICK, toggleSound);
            gameOver.sound.addEventListener(MouseEvent.CLICK, toggleSound);
            home.sound.addEventListener(MouseEvent.CLICK, toggleSound);
            
            
            controller = Controller.getInstance(stage);
            Controller.registerAction("space",32);
            
            fishLayer = new Sprite();
            addChild(fishLayer);
            
            angler = new Angler();
            angler.scaleX = angler.scaleY = 0.4;
            angler.x = 40;
            angler.y = 350;
            angler.head.addEventListener("biteComplete", bellyJiggle);
            addChild(angler);
            
            shadow = new ShadowCaster();
            shadow.blendMode = BlendMode.LAYER;
            addChild(shadow);
            
            lightAlert = new LightAlert();
            lightAlert.visible = false;
            addChild(lightAlert);
            
            stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
            addEventListener(Event.ENTER_FRAME, update);
            
            SoundManager.startMusic();
            
            addChild(home);
        }
    
        public function toggleSound(e:Event=null):void
        {
            if(SoundManager.MUSICENABLED)
            {
                SoundManager.disableSound();
                SoundManager.stopMusic();
            }else{
                SoundManager.startMusic();
                SoundManager.enableSound();
            }
        }
        public function newGame(e:Event=null):void
        {
            stage.focus = stage;
            while(fishies.length > 0)
            {
                fishLayer.removeChild(fishies[0]);
                fishies.splice(0,1);
            }
            
            if(contains(home)) removeChild(home);
            if(contains(gameOver)) removeChild(gameOver);
            if(contains(youWin)) removeChild(youWin);
            
            angler.scaleX = angler.scaleY = 0.4;
            angler.x = 40;
            angler.y = 350;
        }
        
        public function bellyJiggle(event:Event):void
        {
            angler.body.belly.gotoAndPlay("jiggle");
            isBiting = false;
            
            var timer:Timer = new Timer(10, 24);
            timer.addEventListener(TimerEvent.TIMER, bringingGlowBack, false, 0, true);
            timer.start();
        }
        
        private function bringingGlowBack(e:Event=null):void
        {
            glowStrength = glowStrength - 0.5;
        }
        
        private var bioTimer:int = 0;
        public function updateFins():void
        {
            bioTimer++;
            
            
            var multiplier:Number = Math.sin(((10.0 * bioTimer) % 360) * Math.PI / 180.0);
            
            //oscillate between a bit
            var matrix:Matrix = new Matrix();
            matrix.b = multiplier * 0.09;
            angler.head.pectoral.transform.matrix = matrix;
            
            
            var multiplier2:Number = -1*Math.sin(((5.0*bioTimer) % 360) * Math.PI / 180.0);
            var matrix2:Matrix = angler.body.tailfin.transform.matrix;
            matrix2.b = multiplier2 * 0.03;
            angler.body.tailfin.transform.matrix = matrix2;
        }
        
        public static var MOVE_SPEED:Number = 4;
        private var isBiting:Boolean = false;
        public function update(event:Event):void
        {
            if(contains(gameOver) || contains(home) || contains(youWin)) return;
            
            updateFins();
            updateFishies();
            
            var moveSpeed:Number = MOVE_SPEED*angler.scaleX;
            
            if(isBiting)
            {
                angler.y -= 4*moveSpeed;
                angler.x += 4*moveSpeed;
                checkBounds();
                updateShadow();
                return;
            }
            
            updateLight();
            
            var input:Array = Controller.getUpdates();
            
            if(input[0].indexOf("space") >= 0)
            {
                isBiting = true;
                angler.head.gotoAndPlay("bite");
                SoundManager.playSound("omnomnom");
            }
            
            if(Controller.down)
            {
                angler.y += moveSpeed;
            }
            
            if(Controller.up)
            {
                angler.y -= moveSpeed;                
            }
            
            if(Controller.left)
            {
                angler.x -= moveSpeed;
            }
            
            if(Controller.right)
            {
                angler.x += moveSpeed; 
            }
            
            checkBounds();
            updateShadow();
        }
        
        public static var OPTIMAL_FISH_COUNT:int = 4;
        public function updateFishies():void
        {
            var chance_to_spawn:Number = (OPTIMAL_FISH_COUNT - fishies.length) * Math.random();
            if(chance_to_spawn > 0.98)
            {
                var newFish:FishyAI = new FishyAI(angler.scaleX + 0.5);
                fishies.push(newFish);
                fishLayer.addChild(newFish);
            }
            
            
            var dead:Array = [];
            var lightRect:Rectangle = lightBox;
            for each(var fishy:FishyAI in fishies)
            {
                if(fishy.update())
                {
                    dead.push(fishy);
                }
                
                var fishBounds:Rectangle = fishy.getBounds(stage);
                
                if(isBiting)
                {
                    glowStrength = 20;
                    
                    var biteBounds:Rectangle = angler.head.bite.getBounds(stage);
                    
                    var fishArea:Number = fishBounds.width * fishBounds.height;
                    var biteArea:Number = biteBounds.width * biteBounds.height;
                    
                    var intersect:Rectangle = biteBounds.intersection(fishBounds);
                    var hitArea:Number = intersect.width * intersect.height;
                    
                    if(hitArea / fishArea > 0.1)
                    {
                        trace("GOT A FISH: " + (hitArea/fishArea));
                        
                        var myBounds:Rectangle = angler.getBounds(stage);
                        var myArea:Number = myBounds.width * myBounds.height;
                        
                        if(fishArea > myArea)
                        {
                            trace("BIT OFF MORE THAN WE CAN CHEW");
                            SoundManager.playSound("splat");
                            addChild(gameOver);
                        }else{
                            trace(fishArea / myArea);
                        }
                        
                        dead.push(fishy);
                                               
                        var diminishing:Number = 20.0;
                        if(angler.scaleX > 0.75) diminishing = 40;
                        if(angler.scaleX > 1) diminishing = 60;
                        if(angler.scaleX > 1.25) diminishing = 80;
                        
                        angler.scaleX = angler.scaleY = Math.min( 1.5, angler.scaleY + Math.abs(fishy.scaleX / diminishing));
                        
                        if(angler.scale == 1.5)
                        {
                            addChild(youWin);
                        }
                    }

                }
                
                
                //var intersect:Rectangle = fishBounds.intersection(lightRect);
                if(fishBounds.intersects(lightRect))
                {
                    var manhattan:int = Math.max(1, Math.abs(shadowX - fishy.x) + Math.abs(shadowY - fishy.y));
                    var strength:int = Math.ceil(manhattan / 100.0);
                    
                    if(strength > 0.8 && glowStrength > FEAR_THRESHOLD)
                    {
                        fishy.fightOrFlight = true;
                    }else{
                        fishy.fightOrFlight = false;
                    }
                    
                    fishy.aimFor(shadowX, shadowY, 1.0/strength);
                }
            }
            
            for each(var deadFishy:FishyAI in dead)
            {
                var which:int = fishies.indexOf(deadFishy);
                fishLayer.removeChild(deadFishy);
                fishies.splice(which, 1);
            }
        }
        
        public static var TOP:int = -120;
        public static var BOTTOM:int = 650;
        public static var LEFT:int = -150;
        public static var RIGHT:int = 800;
        public function checkBounds():void
        {
            var bounds:Rectangle = angler.getBounds(stage);
            
            if(bounds.right > RIGHT) angler.x -= (bounds.right - RIGHT);
            if(bounds.bottom > BOTTOM) angler.y -= (bounds.bottom - BOTTOM);
            if(bounds.top < TOP) angler.y -= (bounds.top - TOP);
            if(bounds.left < LEFT) angler.x -= (bounds.left - LEFT);
        }
        
        //number between 1 and 20
        public function get glowStrength():Number
        {
            return shadow.lightClip.scaleX;
        }
        public static var FEAR_THRESHOLD:Number = 8.0;
        public function set glowStrength(n:Number):void
        {
            shadow.lightClip.scaleX = shadow.lightClip.scaleY = Math.min(20, Math.max(1,n));
            
            if(n > FEAR_THRESHOLD && !isBiting)
            {
                lightAlert.visible = true;    
            }else{
                lightAlert.visible = false;
            }
            
        }
        
        public function updateShadow():void
        {
            var coords:Point = angler.head.pole.lure.localToGlobal(new Point(0,0));
            
            shadow.lightClip.x = coords.x;
            shadow.lightClip.y = coords.y;
        }
        
        public var lastX:Number = -1;
        public var shakeList:Array = [];
        public function mouseMove(event:MouseEvent):void
        {
//            if(isBiting) return;
//            var pct:Number = event.stageX / 640;
//            glowStrength = pct*20;
        }
        
        public function updateLight():void
        {
            if(isBiting) return;
            if(lastX == -1)
            {
                lastX = stage.mouseX;
                return;
            }
            
            
            var dx:Number = Math.abs(stage.mouseX - lastX);
            lastX = stage.mouseX;
            shakeList.push(dx);
            
            if(shakeList.length > 25)
            {
                shakeList.shift();
            }
            
            var sum:int = 0;
            for(var i:int = 0; i < shakeList.length; i++)
            {
                sum += shakeList[i];
            }
            var magnitude:Number = sum / shakeList.length;
            
            glowStrength = magnitude / 5;
        }
        
        
        public function get lightBox():Rectangle
        {
            return shadow.lightClip.getBounds(stage);
        }
        public function get shadowX():Number
        {
            return shadow.lightClip.x;            
        }
        public function get shadowY():Number
        {
            return shadow.lightClip.y;
        }
    }
}