package
{
    import flash.display.Sprite;
    import flash.geom.Matrix;

    public class FishyAI extends Fishy
    {
        public var velocityX:Number;
        public var velocityY:Number;
        
        public var fightOrFlight:Boolean = false;
        public var moveSpeed:Number;
        public static var DEFAULT_MOVE_SPEED:Number = 5.0;
        
        public var debug:Sprite;
        public var drawDebug:Boolean = false;
        public function FishyAI(maxSize:Number = 1.0)
        {
            var depth:int = Math.random()*480;
            y = depth;
            
            var size:Number = 0.5 + Math.random()*maxSize;
            scaleX = scaleY = size/2;
            
            moveSpeed = DEFAULT_MOVE_SPEED * Math.max(0.2, (0.2 + 1-size));
            velocityY = 0;
            
            var direction:Number = Math.random();
            if(direction > 0.5)
            {
                x = -20;
                velocityX = moveSpeed;
            }else{
                x = 680;
                scaleX = scaleX * -1;
                velocityX = moveSpeed * -1;
            }
            
            debug = new Sprite();
            addChild(debug);
        }
        
        //strength will be a fraction of how strongly we should steer for the target
        public var courseCorrection:Number = 1.0;
        public function aimFor(targetX:Number, targetY:Number, strength:Number):void
        {
            var maxAngle:Number;
            if(velocityX > 0)
            {
                maxAngle = 180 / Math.PI * Math.atan2(targetY-y, targetX - x);
                //moving left to right
                //chase!
                if(targetX > x)
                {
                    
                    if(targetY > y && rotation < maxAngle)
                    {
                        if(fightOrFlight)
                        {
                            rotation -= courseCorrection * strength;
                        }else{
                            rotation += courseCorrection * strength;    
                        }
                    }else if(targetY < y && rotation > maxAngle){
                        //if we're under the angler fish, see it and run away!
                        rotation += courseCorrection * strength;  
                    }
                }else{               
                //course correct!
                    if(rotation < 0)
                    {
                        rotation += courseCorrection*strength;
                    }
                    if(rotation > 0)
                    {
                        rotation -= courseCorrection*strength;
                    }
                }
            }else{
                //moving right to left  (scaleX = -1)
                
                maxAngle = -1*(180 / Math.PI * Math.atan2(targetY-y, x - targetX));
                
                if(targetX < x)
                {
                    if(targetY > y && rotation > maxAngle)
                    {
                        if(fightOrFlight)
                        {
                            rotation += courseCorrection * strength;
                        }else{
                            rotation -= courseCorrection * strength;    
                        }
                                  
                    }else if(targetY < y && rotation < maxAngle){
                        //if we're under the angler fish, see it and run away!
                        rotation -= courseCorrection * strength;  
                    }
                }else{               
                    //course correct!
                    if(rotation < 0)
                    {
                        rotation += courseCorrection*strength;
                    }
                    if(rotation > 0)
                    {
                        rotation -= courseCorrection*strength;
                    }
                }
            }
            
            
            if(drawDebug)
            {
                debug.graphics.clear();
                debug.graphics.lineStyle(25, 0x0000ff);
                debug.graphics.lineTo(Math.cos(maxAngle * Math.PI / 180)*150, Math.sin(maxAngle*Math.PI / 180)*150);
            }
            
            var radian:Number = rotation * Math.PI / 180;
            velocityX = Math.cos(radian) * moveSpeed * Math.abs(scaleX)/scaleX;
            velocityY = Math.sin(radian) * moveSpeed * Math.abs(scaleX)/scaleX;
            
//            if(scaleX < 0) angle = Math.PI - angle;
//            rotation = angle*180/Math.PI;
        }
        
        
        
        public function update():Boolean
        {
            x += velocityX;
            y += velocityY;
            
            if((velocityX > 0 && x > 840) || (velocityX < 0 && x < -200) )
            {
                return true;
            }

            updateFins();
            return false;
        }
        
        private var bioTimer:int = 0;
        public function updateFins():void
        {
            bioTimer++;
            
            
            var multiplier:Number = Math.sin(((25.0 * bioTimer) % 360) * Math.PI / 180.0);
            
            //oscillate between a bit
            var matrix:Matrix = pectoral.transform.matrix;
            matrix.c = multiplier * 0.15;
            pectoral.transform.matrix = matrix;
            
            
            var multiplier2:Number = -1*Math.sin(((15.0*bioTimer) % 360) * Math.PI / 180.0);           
            tailfin.scaleX = 0.9 + multiplier2 * 0.1;

        }
        
        
    }
}