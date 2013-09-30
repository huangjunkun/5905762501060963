package com.common
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.Socket;
	import flash.system.Security;
	/**
	 * ...
	 * @author hwh
	 */
	public class GetVodSocket extends BaseSocket
	{
		private static var _instance:GetVodSocket;
		
		public function GetVodSocket():void
		{
			
		}
		
		override public function connect(_gdl:String, _completeFun:Function):void
		{
			super.connect(_gdl, _completeFun);
		}
		
		public static function get instance():GetVodSocket
		{
			if (!_instance)
			{
				_instance = new GetVodSocket();
			}
			
			return _instance;
		}
	}
}