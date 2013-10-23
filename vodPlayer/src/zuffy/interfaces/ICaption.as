package zuffy.interfaces {
	
	public interface ICaption{
		
		// 标记视频是否正在加载
		public var isStartPlayLoading:Boolean;
		
		// 标记视频是否在播放
		public var videoIsPlaying:Boolean;

		// 标记视频时间
		public var videoTime:Number;

		// 显示自动加载字幕
		public function showAutoloadTips():void;

		// 显示文字提示
		public function showPlayerTxtTips(tips:String, time:Number):void;

		

	}
}