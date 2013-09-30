package zuffy.events
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class HttpSocketEvent extends Event 
	{
		public static const CONNECT:String = "connect";
        public static const OPEN:String = "open";
        public static const CLOSE:String = "close";
        public static const PROGRESS:String = "progress";
        public static const COMPLETE:String = "complete";
        public static const ERROR:String = "error";
		public static const HEADER:String = "header";
		public static const KEYFRAME_LOADED:String = 'keyframe_loaded';
		public static const KEYFRAME_ERROR:String = 'keyframe_error';

        private var _data:Object;

        public function HttpSocketEvent(type:String, data:Object = null, bubbles:Boolean = false, cancelable:Boolean = false):void
		{
			_data = data;
            super(type, bubbles, cancelable);
        }
		
		public function get data():Object
		{
			return _data;
		}
	}
}