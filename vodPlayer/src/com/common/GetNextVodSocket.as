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
	public class GetNextVodSocket extends BaseSocket
	{
		private static var _instance:GetNextVodSocket;
		
		public function GetNextVodSocket():void
		{
			
		}
		
		override public function connect(_gdl:String, _completeFun:Function):void
		{
			super.connect(_gdl, _completeFun);
		}
		
		public static function get instance():GetNextVodSocket
		{
			if (!_instance)
			{
				_instance = new GetNextVodSocket();
			}
			
			return _instance;
		}
	}
}