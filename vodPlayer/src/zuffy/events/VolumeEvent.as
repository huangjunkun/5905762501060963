package zuffy.events 
{
	import flash.events.Event;
	/**
	 * ...
	 * @author Drgon.S
	 */
	public class VolumeEvent extends Event
	{
		public static const VOLUME_CHANGE:String 		= 'volume change';
		public static const VOLUME_MUTE:String 			= 'volume mute';
		public static const VOLUME_UNMUTE:String		= 'volume unmute';
		public static const VOLEME_TIPS:String			= 'volume tips';
		
		public function VolumeEvent(type:String, info:String) 
		{
			super(type, true);
			_volume = info;
		}
		
		public function get volume():String
		{
			return _volume;
		}
		
		private var _volume:String;
	}

}