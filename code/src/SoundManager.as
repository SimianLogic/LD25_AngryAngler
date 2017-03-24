//singleton Sound Manager class
package {
	
	import flash.media.*;
	import flash.events.Event;
	
	public class SoundManager {
		
		//singleton vars
		private static var instance:SoundManager;
		private static var allowInstantiation:Boolean;
		
		//settings
		public static var SOUNDENABLED:Boolean = true;   
		public static var MUSICENABLED:Boolean = true; 
		
		//SFX vars for this project
		private var musicSound:Sound;
		private var musicClasses:Array = [Underwater];
		private var musicNames:Array   = ["bg"];
		private var musicSelection:int = 0;
		private var musicChannel:SoundChannel;
		private var musicVolume:Number = 1.0;    
		
		private var sounds:Array = [];
		private var soundClasses:Array = [OmNomNom, Splat];
		private var soundNames:Array   = ["omnomnom", "splat"];
		private var soundVolumes:Array = [0.2, 0.65];
		
		private static var soundToggles:Array = [];
		private static var musicToggles:Array = [];
		
		public function SoundManager():void {
			if (!allowInstantiation) {
				throw new Error("Error: Instantiation failed: Use SoundManager.getInstance() instead of new.");
			}
			
			for(var i:int = 0; i < soundClasses.length; i++)
			{
				sounds.push(new soundClasses[i]() as Sound);
			}
			
			if(musicClasses.length > 0) musicSound = new musicClasses[musicSelection]();
		}
		
		public static function setTrack(trackName:String):void
		{
			var sm:SoundManager = SoundManager.getInstance();
			sm.iSetTrack(trackName); 
		}
		
		//instance method for setting the music track    
		public function iSetTrack(trackName:String):void
		{
			var which:int = musicNames.indexOf(trackName);
			if(which < 0)
			{
				return;
			}
			
			iStopMusic();
			musicSelection = which;
			musicSound = new musicClasses[musicSelection]();      
			
			//use the static function so we run the enabled check
			SoundManager.startMusic();
		}
		
		//for simpler games with all sound either on or off
		public static function toggleSound():void
		{
			if(SoundManager.SOUNDENABLED)
			{
				SoundManager.disableSound();
				SOUNDENABLED = false;
			}else{
				SoundManager.enableSound();
				SOUNDENABLED = true;        
			}
		}
		
		public static function toggleMusic():void
		{
			if(SoundManager.MUSICENABLED)
			{
				SoundManager.stopMusic();
				MUSICENABLED = false;
			}else{
				SoundManager.startMusic();
				MUSICENABLED = true;        
			}
		}    
		
		public static function enableSound():void
		{      
			SoundManager.SOUNDENABLED = true;
		}
		
		public static function disableSound():void
		{
			SoundManager.SOUNDENABLED = false;
		}
		
		public static function stopMusic():void
		{
			MUSICENABLED = false;
			var sm:SoundManager = SoundManager.getInstance();
			sm.iStopMusic();      
		}
		
		public function iStopMusic():void
		{
			if(musicChannel) musicChannel.stop();    
		}   
		
		public static function startMusic():void
		{
			MUSICENABLED = true;
			var sm:SoundManager = SoundManager.getInstance();
			sm.iStartMusic();
		}
		
		//instance start music
		public function iStartMusic():void
		{
			if(musicClasses.length == 0) return;
			
			if(musicChannel) musicChannel.stop();
			
			var mst:SoundTransform = new SoundTransform(musicVolume);
			musicChannel = musicSound.play(0,100,mst);
		}
		
		public static function playSound(soundname:String):void
		{
			if(!SOUNDENABLED) return;
			
			var sm:SoundManager = SoundManager.getInstance();
			sm.iPlaySound(soundname);
		}
		
		//instance play
		public function iPlaySound(soundname:String):void
		{
			var which:int = soundNames.indexOf(soundname);
			if(which < 0)
			{
				return;
			}
			
			var st:SoundTransform = new SoundTransform(soundVolumes[which]);
			sounds[which].play(0,0,st);      
		}
		
		
		public static function getInstance():SoundManager {
			if (instance == null) {
				allowInstantiation = true;
				instance = new SoundManager();
				allowInstantiation = false;
			}
			return instance;
		}    
		
	}
}