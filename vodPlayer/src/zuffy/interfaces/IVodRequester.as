package zuffy.interfaces {
	
	public interface IVodRequester {

		// 请求其他视频出错;
		function playOtherFail(boo:Boolean, tips:String = ""):void;
		function queryBack(req:Object):void;
	}
}