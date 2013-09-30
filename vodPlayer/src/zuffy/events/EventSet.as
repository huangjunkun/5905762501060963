package zuffy.events
{
	import flash.events.Event;
	/**
	 * ...
	 * @author Drgon.S
	 */
	public class EventSet extends Event
	{
		public static const SET_SIZE:String 					= 'set_size';
		public static const SET_AUTOCHANGE:String 				= 'set_autoChange';
		public static const SET_SKIP:String						= 'set_skip';
		public static const SKIP_MOVIE_HEAD:String 				= 'skip_movie_head';
		public static const SHOW_AUTOQUALITY_FACE:String		= 'show_autoQuality_face';
		public static const SHOW_SKIPMOVIE_FACE:String			= 'show_skipMovie_face';
		public static const SET_CHANGED:String					= 'set_changed';
		public static const SET_STAGE_VIDEO:String				= 'set_stageVideo';
		public static const SHOW_STAGE_VIDEO:String				= 'show_stageVideo';
		public static const SHOW_FACE:String					= 'show face';
		public static const SHOW_SET_OPTION:String				= 'show set option';
			
		private var _info:String;
		
		public function EventSet(type:String, info:String = null) 
		{
			super(type,true);
			_info = info;
		}
		
		public function get info():String
		{
			return _info;
		}
		
	}

}