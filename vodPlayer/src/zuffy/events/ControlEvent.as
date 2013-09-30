package zuffy.events
{
	import flash.events.Event;
	
	/**
	 * ...
	 * @author dds
	 */
	public class ControlEvent extends Event 
	{
		public static const SHOW_CTRBAR:String = 'show ctrbar';
		private var _info:String;
		
		public function ControlEvent(type:String,info:String = null, bubbles:Boolean=true, cancelable:Boolean=false) 
		{ 
			super(type, bubbles, cancelable);
			_info = info;
		} 
		
		public override function clone():Event 
		{ 
			return new ControlEvent(type,this.info, bubbles, cancelable);
		} 
		
		public override function toString():String 
		{ 
			return formatToString("ControlEvent", "type", "bubbles", "cancelable", "eventPhase"); 
		}
		
		public function get info():String
		{
			return _info;
		}
		
	}
	
}