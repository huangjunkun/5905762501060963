package zuffy.events
{
	
	import flash.events.Event;
	
	public class PlayEvent extends Event {
		
		public static const PLAY:String 			= "Play";//播放或继续		
		public static const PAUSE:String 			= "Pause";//播放暂停
		public static const RESUME:String 			= 'Resume';//播放继续
		public static const STOP:String 			= "Stop";//播放停止
		public static const BUFFER_START:String 	= 'BufferStart';//正在缓冲
		public static const BUFFER_END:String 		= 'BufferEnd';//缓冲结束
		public static const REPLAY:String 			= "Replay";//播放或继续
		public static const PLAY_START:String 		= 'PlayStart'; // 播放开始
		public static const PLAY_4_STAGE:String 	= 'PlayForStage'; // 播放开始
		public static const PAUSE_4_STAGE:String 	= 'PauseForStage'; // 播放开始
		public static const SEEK:String 			= 'Seek'; //seek函数事件句柄
		public static const PROGRESS:String			= 'Progress';//缓冲进度
		public static const PLAY_NEW_URL:String		= 'PlayNewUrl';//重新播放一段url
		public static const SEEK_INVALIDTIME:String = 'SeekInvalidTime';//seek到可播放区域以外;
		public static const INIT_STAGE_VIDEO:String = 'InitStageVideo';
		public static const INSTALL:String			= 'Install';//播放前安装xmp播放器
		public static const INVALID:String			= 'Invalid';//非法
		public static const OPEN_WINDOW:String		= 'OpenWindow';//弹出小窗口
		
		public function PlayEvent(type:String,man_made:Boolean=false,info:String = '') {
			super(type, true);
			_manMade = man_made;
			_info = info;
		}
		
		public function get manMade():Boolean{
			return _manMade;
		}
		
		public function get info():String
		{
			return _info;
		}
		
		private var _manMade:Boolean=false;
		private var _info:String = '';
	}
}