package com.common 
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author hwh
	 */
	public class GetVodCodeSocket
	{
		private var socket:Socket;
		private var host:String;
		private var port:uint;
		private var vod:String;
		private var queryPos:Number;
		private var endPos:Number;
		private var responseBytes:ByteArray;
		private var response:String;
		private var completeFun:Function;
		private var origin_url:String;
		private var url:String;
		private var error_code:String;
		
		private static var _instance:GetVodCodeSocket;
		
		public function GetVodCodeSocket() 
		{
			socket = new Socket();
			socket.timeout = 5000;
			socket.addEventListener(Event.CONNECT, connectSuccess);
			socket.addEventListener(ProgressEvent.SOCKET_DATA, receiveSocketData);
			socket.addEventListener(Event.CLOSE, closeSocketHandler);
			socket.addEventListener(IOErrorEvent.IO_ERROR, connectIOError);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, connctSecurityError);
		}
		
		public function connect(obj:Object, _completeFun:Function):void
		{
			origin_url = obj.url;
			error_code = obj.error_code;
			responseBytes = new ByteArray();
			response = null;
			
			completeFun = _completeFun;
			
			url = getRealURL(obj.url);
			host = url.substr(0, url.indexOf("/"));
			port = 80;
			var hostArr:Array = host.split(":");
			if (hostArr.length > 1)
			{
				host = hostArr[0];
				port = hostArr[1];
			}
			vod = url.substr(url.indexOf("/"));
			
			var params:URLVariables = new URLVariables(url);
			queryPos = params["start"];
			endPos = params["end"];
			
			JTracer.sendMessage("GetVodCodeSocket -> connect, \nhost:" + host + "\nport:" + port + "\nvod:" + vod + "\nqueryPos:" + queryPos + "\nendPos:" + endPos);
			
			socket.connect(host, port);
		}
		
		private function closeSocket():void
		{
			if (socket.connected)
			{
				socket.close();
				
				JTracer.sendMessage("GetVodCodeSocket -> socket.close()");
			}
		}
		
		private function connectSuccess(evt:Event):void
		{
			JTracer.sendMessage("GetVodCodeSocket -> Connect Success");
			
			var header:String = "GET " + vod + " \r\n";
			header += "Range: bytes=" + queryPos + "-" + endPos + " \r\n";
			header += "Host: " + host + ":" + port + " \r\n\r\n";
			
			socket.writeUTFBytes(header);
			socket.flush();
		}
		
		private function receiveSocketData(evt:ProgressEvent):void
		{
			JTracer.sendMessage("GetVodCodeSocket -> Receive Socket Data");
			
			if(socket.bytesAvailable > 0)
			{
				responseBytes.clear();
				socket.readBytes(responseBytes, 0, socket.bytesAvailable);
				response = responseBytes.toString();
				
				JTracer.sendMessage("GetVodCodeSocket -> response:\n" + response);
				
				var status:String = getResponseHeader("HTTP/1.1", " ");
				completeFun({origin_url:origin_url, url_type:"vod", status_code:status, error_code:error_code});
				closeSocket();
			}
		}
		
		private function closeSocketHandler(evt:Event):void
		{
			JTracer.sendMessage("GetVodCodeSocket -> Connect Close");
			
			var status:String = getResponseHeader("HTTP/1.1", " ");
			completeFun({origin_url:origin_url, url_type:"vod", status_code:status, error_code:error_code});
			closeSocket();
		}
		
		private function connectIOError(evt:IOErrorEvent):void
		{
			JTracer.sendMessage("GetVodCodeSocket -> Connect IOError");
			
			var status:String = getResponseHeader("HTTP/1.1", " ");
			completeFun({origin_url:origin_url, url_type:"vod", status_code:status, error_code:error_code});
			closeSocket();
		}
		
		private function connctSecurityError(evt:SecurityErrorEvent):void
		{
			JTracer.sendMessage("GetVodCodeSocket -> Connct SecurityError, text:" + evt.text);
			
			var status:String = getResponseHeader("HTTP/1.1", " ");
			completeFun({origin_url:origin_url, url_type:"vod", status_code:status, error_code:error_code});
			closeSocket();
		}
		
		private function getRealURL(url:String):String
		{
			var result:String;
			if (url.indexOf("://") >= 0)
			{
				var splitArr:Array = url.split("://");
				result = splitArr[1];
			}
			else
			{
				result = url;
			}
			return result;
		}
		
		private function getResponseHeader(header:String, separate:String):String
		{
			if (!response || response == "")
			{
				JTracer.sendMessage("GetVodCodeSocket -> not found header:" + header + ", separate:" + separate + ", response:" + response);
				return null;
			}
			
			var headerPos:int = response.indexOf(header);
			if (headerPos < 0)
			{
				JTracer.sendMessage("GetVodCodeSocket -> not found header:" + header);
				return null;
			}
			
			var headerArr:Array = response.split("\r\n");
			var i:*;
			var pos:int;
			var itemArr:Array;
			for (i in headerArr)
			{
				itemArr = headerArr[i].split(separate);
				if (itemArr.length > 1 && trim(itemArr[0]) == header)
				{
					if (separate == ":")
					{
						pos = headerArr[i].indexOf(":");
						return trim(headerArr[i].substr(pos + 1));
					}
					return trim(itemArr[1]);
				}
			}
			
			return null;
		}
		
		//清除前面和后面的空格
		private function trim(s:String):String
		{
			return s.replace(/^\s+/, '').replace(/\s+$/, '');
		}
		
		public static function get instance():GetVodCodeSocket
		{
			if (!_instance)
			{
				_instance = new GetVodCodeSocket();
			}
			
			return _instance;
		}
	}
}