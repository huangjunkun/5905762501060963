package zuffy.net {
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import com.common.Tools;
	import com.global.GlobalVars;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.utils.setTimeout;
	import flash.utils.clearTimeout;
	import com.serialization.json.JSON;
	import zuffy.interfaces.IVodRequester;
	import com.common.JTracer;
	import flash.net.URLRequestMethod;
	import flash.external.ExternalInterface;
	import flash.events.ProgressEvent;
	import flash.net.Socket;
	
	public class VodRequestManager {
		
		private static var _instance:VodRequestManager;
		private const GET_METHOD_STRING:String = "req_get_method_vod?";

		private var _requester:URLRequest;
		private var _urlLoader:URLLoader;
		private var _timeoutID:uint;
		private var timerFlag:Boolean = true;
		private var timeoutTime:int = 15000;
		private var _isOther:Boolean;
		private var vodPermit:int;
		
		private var _delegate:IVodRequester;

		public static function get instance(): VodRequestManager {
			
			if (!_instance) {
				_instance = new VodRequestManager (new __inner__());
			}
			
			return _instance;
		}
		public function VodRequestManager(__:__inner__) {
		
		}

		public function setup(vodRequester:IVodRequester):void {
			_delegate = vodRequester;
		}

		public function query(url:String, filename:String, gcid:String, cid:String, filesize:String, isOther:Boolean = false):void {
			var queryStr:String;

			queryStr = [
				'url=', encodeURIComponent(url),
				'&platform=0',
				"&userid=", Tools.getUserInfo("userid"),
				"&vip=", Tools.getUserInfo("isvip"),
				"&sessionid=", Tools.getUserInfo("sessionid")
			].join('');

			if(filename)
				queryStr += '&video_name=' + encodeURIComponent(filename);

			if(gcid && cid && filesize)
				queryStr += [
					'&gcid='+ gcid ,
					'&cid=' + cid ,
					'&filesize=' +filesize
				].join('');

			queryStr += [
					'&cache=' + new Date().getTime(),
					'&from='+ Tools.getUserInfo('from')
				].join('');

			_isOther = isOther;
			_requester = new URLRequest(GlobalVars.instance.ISERVER + GET_METHOD_STRING + queryStr);
			_requester.method = URLRequestMethod.GET;
			_urlLoader = new URLLoader();
			_urlLoader.addEventListener(Event.COMPLETE, onCheckUserComplete);
			_urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onCheckUserIOError);
			_urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onCheckUserSecurityError);
			_urlLoader.load(_requester);

			//超时处理
			timerFlag = true;
			_timeoutID = setTimeout(function(){
				if(_isOther)
					_delegate.playOtherFail(false);
				else if(timerFlag){
					// stat({ f:'svrresp', err:'errTimout',gcid:gcid });
					// error("服务器正忙，请稍后再试");
				}
				clearTimeout(_timeoutID);
			}, timeoutTime);
		}

		function onCheckUserComplete(evt:Event):void {
			var resultStr:String = evt.target.data;
			JTracer.sendMessage('onCheckUserComplete:'+resultStr);
			var r:Object = JSON.deserialize(resultStr);
			if(r.resp.vod_permit && typeof (r.resp.vod_permit.ret) != 'undefined')
				vodPermit = r.resp.vod_permit.ret;
			else
				vodPermit = -1;
			
			clearTimeout(_timeoutID);
			timerFlag = false;

			if(_isOther)
				queryOtherBack(r.resp);
			else
				_delegate.queryBack(r.resp);
		}
		
		function onCheckUserIOError(e:IOErrorEvent):void {
			JTracer.sendMessage('IOErrorEvent:' + e)
		}
		
		function onCheckUserSecurityError(e:SecurityErrorEvent):void {
			JTracer.sendMessage('SecurityErrorEvent:' + e)
		}

		function queryOtherBack(req:Object):void {

		}
	}	
}


// inner class..
class __inner__ {
	function __inner__(){}	
}