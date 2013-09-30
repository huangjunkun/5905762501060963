package com.slice 
{
	import com.common.Tools;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import com.global.GlobalVars;
	import com.serialization.json.JSON;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class FeeLoader extends URLLoader 
	{
		public var feeSuccess:Function;
		public var feeIOError:Function;
		public var feeSecurityError:Function;
		
		private static var _instance:FeeLoader;
		
		public function FeeLoader() 
		{
			super();
			
			this.addEventListener(Event.COMPLETE, onFeeSuccess);
			this.addEventListener(IOErrorEvent.IO_ERROR, onFeeIOError);
			this.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onFeeSecurityError);
		}
		
		public function startFee(time:Number):void
		{
			var userid:String = Tools.getUserInfo("userid");
			var sessionid:String = Tools.getUserInfo("sessionid");
			var gcid:String = Tools.getUserInfo("gcid");
			var cid:String = Tools.getUserInfo("cid");
			var timeStr:String = time.toString();
			timeStr = timeStr.substr(0, timeStr.indexOf("."));
			var filesize:String = Tools.getUserInfo("filesize");
			var filename:String = encodeURIComponent(Tools.getUserInfo("name"));
			
			var href:String = ExternalInterface.call("function (){return document.location.href;}");
			
			var param:URLVariables = new URLVariables();
			param.href = href;
			
			var req:URLRequest = new URLRequest();
			req.url = encodeURI(encodeURI(GlobalVars.instance.url_deduct_flow + "userid/" + userid + "/sessionid/" + sessionid + "/gcid/" + gcid + "/cid/" + cid + "/filesize/" + filesize + "/filename/" + filename + "/videotime/" + timeStr));
			req.data = param;
			req.method = URLRequestMethod.POST;
			
			this.load(req);
		}
		
		public static function getInstance():FeeLoader
		{
			if (!_instance)
			{
				_instance = new FeeLoader();
			}
			
			return _instance;
		}
		
		private function onFeeSuccess(evt:Event):void
		{
			if (feeSuccess is Function && feeSuccess != null)
			{
				var jsonStr:String = evt.target.data;
				var jsonObj:Object = com.serialization.json.JSON.deserialize(jsonStr);
				feeSuccess(jsonObj);
			}
		}
		
		private function onFeeIOError(evt:IOErrorEvent):void
		{
			if (feeIOError is Function && feeIOError != null)
			{
				feeIOError();
			}
		}
		
		private function onFeeSecurityError(evt:SecurityErrorEvent):void
		{
			if (feeSecurityError is Function && feeSecurityError != null)
			{
				feeSecurityError();
			}
		}
	}

}