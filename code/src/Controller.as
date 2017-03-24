/*
*
*  Simple controller class I wrote for a platformer I never shipped. The idea was to abstract
*   away the actual input (keyCodes) from the generated commands (left/right/etc) so that these
*   could either bey dynamically re-mapped or easily transitioned to a gamepad or touch scheme.
*
*/

package
{
    
    import flash.display.*;
    import flash.events.*;
    import flash.ui.*;
    import flash.utils.*;
    
    public class Controller
    {
        //singleton vars
        private static var instance:Controller;
        private static var allowInstantiation:Boolean;
        
        private static var game:DisplayObject;
        
        
        public static function get left():Boolean  { return isDown("left"); }
        public static function get right():Boolean { return isDown("right"); }
        public static function get up():Boolean    { return isDown("up"); }
        public static function get down():Boolean  { return isDown("down"); }
        
        //simple key-states: either down or not
        private var actionStates:Array = [false, false, false, false,false,false,false,false];
        //the mapping of which keys to check
        private var actionKeys:Array = [37,38,39,40,65,87,68,83];
        //named lookups
        private var actionNames:Array = ["left","up","right","down","left","up","right","down"];
        //when was the key pressed?
        private var downTimes:Array = [0,0,0,0,0,0,0,0];
        //when was the key released?
        private var upTimes:Array = [0,0,0,0,0,0,0,0];
        //when was the last time we checked this key?
        private var lastChecked:Array = [0,0,0,0,0,0,0,0];
        
        
        public function Controller(g:DisplayObject):void {
            if (!allowInstantiation) {
                throw new Error("Error: Instantiation failed: Use Controller.getInstance() instead of new.");
            }
            
            game = g;
            g.addEventListener(KeyboardEvent.KEY_DOWN, keyDown);
            g.addEventListener(KeyboardEvent.KEY_UP, keyUp);
        }
        
        public static function getInstance(g:DisplayObject = null):Controller {
            if (instance == null) {
                if(g)
                {
                    allowInstantiation = true;
                    instance = new Controller(g);
                    allowInstantiation = false;
                }else{
                    throw new Error("Error: the first call to Controller.getInstance() must include a DisplayObject");
                }
            }
            
            
            return instance;
        }
        
        
        /**** Get an action's state. ****/
        public static function isDown(action:String):Boolean
        {
            var c:Controller = Controller.getInstance();
            for(var i:int = 0; i < c.actionNames.length; i++)
            {
                if(c.actionNames[i] == action && c.actionStates[i])
                {
                    return c.actionStates[i];
                }
            }
            
            return false;
        }
        
        //returns either how long a key has been down or how long it was pressed last time
        public static function pressTime(action:String):int
        {
            var c:Controller = Controller.getInstance();
            for(var i:int = 0; i < c.actionNames.length; i++)
            {
                if(c.actionNames[i] == 'action') return (c.downTimes[i] - (c.upTimes[i] > c.downTimes[i] ? c.upTimes[i] : getTimer()));
            }
            return 0;
        }
        
        public static function registerAction(action:String, keyCode:int):Boolean
        {
            var c:Controller = Controller.getInstance();
            
            if(c.actionNames.indexOf(action) >= 0) return false;
            
            c.actionNames.push(action);
            c.actionStates.push(false);
            c.actionKeys.push(keyCode);
            c.downTimes.push(getTimer());
            c.upTimes.push(getTimer());
            
            return true;
        }
        
        //returns two arrays
        //  [0] = list of newly pressed actions
        //  [1] = list of newly released actions
        public static function getUpdates():Array
        {
            var keysdown:Array = [];
            var keysup:Array   = [];
            
            var nt:int = getTimer();
            var c:Controller = Controller.getInstance();
            for(var i:int = 0; i < c.actionNames.length; i++)
            {
                if(c.downTimes[i] > c.lastChecked[i]) keysdown.push(c.actionNames[i]);
                if(c.upTimes[i]   > c.lastChecked[i]) keysup.push(c.actionNames[i]);
                c.lastChecked[i] = nt;
            }
            
            return [keysdown, keysup];
        }
        
        /**** EVENT EMULATION ***/
        //idea is to let us us do cool stuff like Controler.addTrigger("jump", jumpHandler);
        
        public static function addTrigger(action:String, handler:Function):void
        {
            game.addEventListener("controller:" + action, handler);    
        }
        
        public static function removeTrigger(action:String, handler:Function):void
        {
            game.removeEventListener("controller:" + action, handler);
        }
        
        /**** HANDLE INPUT *****/
        public function keyUp(e:KeyboardEvent):void
        {
            for(var i:int = 0; i < actionKeys.length; i++)
            {
                if(e.keyCode == actionKeys[i])
                {
                    actionStates[i] = false;
                    upTimes[i] = getTimer();
                }
            }
        }
        
        public function keyDown(e:KeyboardEvent):void
        {
            for(var i:int = 0; i < actionKeys.length; i++)
            {
                if(e.keyCode == actionKeys[i])
                {
                    //only record new keypresses, including cases where 2 keys have the same function
                    if(!actionStates[i] && !isDown(actionNames[i]))
                    {
                        actionStates[i] = true;
                        downTimes[i] = getTimer();
                        game.dispatchEvent(new Event("controller:" + actionNames[i]));
                    }
                }
            }      
        }
        
        
        
    }   
    
}