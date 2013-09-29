package zuffy.events
{
	import flash.events.Event;
	
	public class CaptionEvent extends Event
	{
		public static const SET_STYLE:String = 'set_style';//设置字幕样式
		public static const LOAD_CONTENT:String = 'load_content';//加载字幕内容
		public static const SET_CONTENT:String = 'set_content';//设置字幕内容
		public static const HIDE_CAPTION:String = 'hide_caption';//隐藏字幕
		public static const APPLY_SUCCESS:String = 'apply_success';//应用成功
		public static const APPLY_ERROR:String = 'apply_error';//应用失败
		public static const LOAD_STYLE:String = 'load_style';//加载字幕样式
		public static const SELECT_FILE:String = 'select_file';//选择文件
		public static const UPLOAD_COMPLETE:String = 'upload_complete';//上传完成
		public static const UPLOAD_ERROR:String = 'upload_error';
		public static const LOAD_COMPLETE:String = 'load_complete';//上传加载数据完成
		public static const LOAD_TIME:String = 'load_time';//加载时间轴调整信息
		public static const SET_TIME:String = 'set_time';//设置时间轴调整信息
		
		private var _info:Object;
		
		public function CaptionEvent(type:String, info:Object = null)
		{
			super(type, true);
			_info = info;
		}
		
		public function get info():Object
		{
			return _info;
		}
	}
}