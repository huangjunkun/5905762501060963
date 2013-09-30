package zuffy.events
{
	import flash.events.Event;
	/**
	 * ...
	 * @author Drgon.S
	 */
	public class sizeEvent extends Event
	{
		public static const BIG_BUTTON_CLICK:String 		= "big button click";
		public static const SMALL_BUTTON_CLICK:String 		= "small button click";
		public static const MIDDLE_BUTTON_CLICK:String 		= "middle button click";
		public static const FULLSCREEN:String 				= "full screen";
		public static const NORMALSCREEN:String 			= "normal screen";
		public static const CHANGETITLE:String				= "change title"
		
		public function sizeEvent(type:String, info:String) 
		{
			super(type, true);
			_size = info;
		}
		
		public function get size():String
		{
			return _size;
		}
		
		private var _size:String;
		
	}

}