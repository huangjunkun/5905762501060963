package zuffy.events
{
	import flash.events.Event;
	/**
	 * ...
	 * @author Drgon.S
	 */
	public class SetQulityEvent extends Event
	{
		public static const CHANGE_QUILTY:String    	= 'change_quilty'; //清晰度改变
		public static const SUPERHEIGH_QULITY:String 	= 'super_high_qulity';
		public static const HEIGH_QULITY:String 		= 'high_qulity';
		public static const NORMAL_QULITY:String 		= 'norml_qulity';
		public static const STANDARD_QULITY:String  	= 'standard_qulity';
		public static const INIT_QULITY:String			= 'init_qulity';  //初始化清晰度
		public static const LOWER_QULITY:String			= 'lower_qulity'; //切换到更低清晰度
		public static const HAS_QULITY:String			= 'has_qulity';	//没有更低清晰度
		public static const NO_QULITY:String			= 'no_qulity';	//有更低清晰度
		public static const AUTIO_QULITY:String			= 'autio_qulity';	//有更低清晰度
		public static const PAUSE_FOR_QUALITY_TIP:String= 'pause_for_quality_tip';//清晰度提示的时候按了暂停
		public static const CLICK_QULITY:String			= 'click_qulity';//点击清晰度
		
		public function SetQulityEvent(type:String,qulity:String = '0') 
		{
			super ( type, true );
			_qulity = qulity;
		}
		
		public function get qulity():String
		{
			return _qulity;
		}
		
		private var _qulity:String;
		
	}

}