package zuffy.events
{
	import flash.events.Event;
	/**
	 * ...
	 * @author Drgon.S
	 */
	public class EventFilter extends Event
	{
		public static const FILTER_MINGLIANG:String 			 = 'filter_mingLiang';
		public static const FILTER_ROUHUO:String 			 	 = 'filter_rouHuo';
		public static const FILTER_XIANYAN:String 			 	 = 'filter_xianYan';
		public static const FILTER_FUGU:String					 = 'filter_fugu';
		public static const FILTER_BIAOZHUN:String 			 	 = 'filter_biaoZhun';
			
		private var _info:String;
		
		public function EventFilter(type:String, info:String = null) 
		{
			super(type, true);
			_info = info;
		}
		
		public function get info():String
		{
			return _info;
		}
		
	}

}