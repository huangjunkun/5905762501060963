package zuffy.interfaces {
	
	public interface ICaption{
		
		// 标记视频是否正在加载
		function get isStartPlayLoading():Boolean;
		
		// 标记视频是否在播放
		function get videoIsPlaying():Boolean;

		// 标记视频时间
		function get videoTime():Number;

		// 显示自动加载字幕
		function showAutoloadTips():void;

		// 显示文字提示
		function showPlayerTxtTips(tips:String, time:Number):void;

		

	}
}