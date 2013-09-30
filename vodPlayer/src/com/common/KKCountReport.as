package com.common 
{
	import flash.net.URLRequest;
	import flash.net.sendToURL;
	/**
	 * ...
	 * @author dds
	 */
	public class KKCountReport 
	{
		private static const kkpgv:String = 'http://kkpgv.xunlei.com/?u=flv_player_';
		private static const kkpgv2:String = 'http://kkpgv2.xunlei.com/?u=';
		
		public static function sendKankanPgv(value:*):void
		{
			var rd:String = '_51&rd=' + new Date().getTime().toString();
			var rq:URLRequest = new URLRequest(kkpgv + String(value) + rd);
			//sendToURL(rq);
		}
		
		public static function sendKankanPgv2(value:*):void
		{
			var rd:String = '_51&rd=' + new Date().getTime().toString();
			var rq:URLRequest = new URLRequest(kkpgv2 + String(value) + rd);
			//sendToURL(rq);
		}
	}

}