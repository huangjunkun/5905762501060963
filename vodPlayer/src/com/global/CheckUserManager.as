package com.global{
	import com.common.JTracer;
	import com.common.Tools;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.external.ExternalInterface;
	
	public class CheckUserManager{
		
		private static var _instance:CheckUserManager;
		public static function get instance():CheckUserManager
		{
			if (!_instance)
			{
				_instance = new CheckUserManager();
			}
			
			return _instance;
		}

		//登陆是否有效，默认有效
		private var _isValid:Boolean = true;
		public function get isValid():Boolean { return _isValid;}
		public function set isValid(value:Boolean):void{_isValid = value;}

		public var checkUserCompleteHandler:Function;
		public var checkUserErrorHandler:Function;
		public var checkFlowCompleteHandler:Function;
		public var checkFlowErrorHandler:Function;
		public var checkSuccess:Function;

		private var _checkUserLoader:URLLoader;
		private var _checkFlowLoader:URLLoader;

		public function CheckUserManager(){
			init();
		}

		private function init():void{

			_checkUserLoader = new URLLoader();
			_checkUserLoader.addEventListener(Event.COMPLETE, onCheckUserComplete);
			_checkUserLoader.addEventListener(IOErrorEvent.IO_ERROR, onCheckUserIOError);
			_checkUserLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onCheckUserSecurityError);
			
			_checkFlowLoader = new URLLoader();
			_checkFlowLoader.addEventListener(Event.COMPLETE, onCheckFlowComplete);
			_checkFlowLoader.addEventListener(IOErrorEvent.IO_ERROR, onCheckFlowIOError);
			_checkFlowLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onCheckFlowSecurityError);

		}

		private function onCheckUserComplete(evt:Event):void
		{
			checkUserCompleteHandler && checkUserCompleteHandler(evt.target.data);			
		}

		private function onCheckUserIOError(evt:IOErrorEvent):void
		{
			_isValid = true;
			checkUserErrorHandler && checkUserErrorHandler();
		}
		
		private function onCheckUserSecurityError(evt:SecurityErrorEvent):void
		{
			checkUserErrorHandler && checkUserErrorHandler();
		}
				
		private function onCheckFlowComplete(evt:Event):void
		{
			checkFlowCompleteHandler && checkFlowCompleteHandler(evt.target.data);
		}
		
		private function onCheckFlowIOError(evt:IOErrorEvent):void
		{
			JTracer.sendMessage("PlayerCtrl -> onCheckFlowIOError");
			checkFlowErrorHandler && checkFlowErrorHandler();
		}
		
		private function onCheckFlowSecurityError(evt:SecurityErrorEvent):void
		{
			JTracer.sendMessage("PlayerCtrl -> onCheckFlowSecurityError");
			checkFlowErrorHandler && checkFlowErrorHandler();
		}

		public function checkIsValid():void
		{
			if (_isValid)
			{
				checkSuccess && checkSuccess();
				return;
			}

			ExternalInterface.call("XL_CLOUD_FX_INSTANCE.uUpdate");
			
			Tools.setUserInfo("sessionid", ExternalInterface.call("G_PLAYER_INSTANCE.getParamInfo", "sessionid"));
			var userid:String = Tools.getUserInfo("userid");
			var sessionid:String = Tools.getUserInfo("sessionid");
			var ip:String = "1.2.3.4";
			var from:String = Tools.getUserInfo("from");
			var url:String = GlobalVars.instance.url_check_account + "?userid=" + userid + "&sessionid=" + sessionid + "&ip=" + ip + "&from=" + from + "&r=" + Math.random();
			
			JTracer.sendMessage("PlayerCtrl -> check is valid start, url:" + url);
			
			var req:URLRequest = new URLRequest(url);
			_checkUserLoader.load(req);
		}
				
		public function checkFlow():void{
			//有流量用户检测是否有足够时长，网盘用户不检测
			var vodPermit:Number = Number(Tools.getUserInfo("vodPermit"));
			if ((vodPermit == 6 || vodPermit == 8 || vodPermit == 10) && Tools.getUserInfo("from") != GlobalVars.instance.fromXLPan)
			{
				var href:String = GlobalVars.instance.url_check_flow + "userid/" + Tools.getUserInfo("userid") + "?t=" + new Date().time;
				var req:URLRequest = new URLRequest(href);
				JTracer.sendMessage("PlayerCtrl -> flv_setPlayeUrl, 查询时长, url:" + req.url);
				_checkFlowLoader.load(req);
				
			}
			
		}
	}
}