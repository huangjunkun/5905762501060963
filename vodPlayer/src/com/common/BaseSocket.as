package com.common
{
	import com.global.GlobalVars;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.Socket;
	import flash.system.Security;
	import flash.utils.getTimer;
	/**
	 * ...
	 * @author hwh
	 */
	public class BaseSocket
	{
		private var socket:Socket;
		private var host:String;
		private var port:Number;
		private var gdlLink:String;
		private var cookie:String;
		private var referer:String;
		private var response:String;
		private var gdl:String;
		private var completeFun:Function;
		private var utype:String;
		private var startTime:int;
		
		public function BaseSocket():void
		{
			socket = new Socket();
			socket.timeout = 5000;
			socket.addEventListener(Event.CONNECT, connectSuccess);
			socket.addEventListener(ProgressEvent.SOCKET_DATA, receiveSocketData);
			socket.addEventListener(Event.CLOSE, closeSocketHandler);
			socket.addEventListener(IOErrorEvent.IO_ERROR, connectIOError);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, connctSecurityError);
		}
		
		public function connect(_gdl:String, _completeFun:Function):void
		{
			gdl = _gdl;
			completeFun = _completeFun;
			utype = "vod";
			
			//已经取得vod地址
			if (GlobalVars.instance.isVodGetted)
			{
				JTracer.sendMessage("GetVodSocket -> connect, socket已成功取vod地址, vod url:" + GlobalVars.instance.vodURL);
				completeFun(replaceTS(GlobalVars.instance.vodURL), utype, "200", 0);
				return;
			}
			if(GlobalVars.instance.isIPLink){
				GlobalVars.instance.isVodGetted = true;
				GlobalVars.instance.vodURL = gdl;
				JTracer.sendMessage("GetVodSocket -> connect, 使用ip地址播放, ip_gdl url:" + gdl);
				completeFun(replaceTS(GlobalVars.instance.vodURL), 'ip', "200", 0);
				return;
			}
			//页面传递vod地址
			var gdlURL:String = getFormatURL(gdl);
			var hostURL:String = gdlURL.substr(0, gdlURL.indexOf("/"));
			if (hostURL.indexOf("gdl") != 0 && hostURL.indexOf("dl") != 0)
			{
				GlobalVars.instance.isVodGetted = true;
				GlobalVars.instance.vodURL = gdl;
				
				JTracer.sendMessage("GetVodSocket -> connect, 页面传递vod地址, vod url:" + GlobalVars.instance.vodURL);
				completeFun(replaceTS(GlobalVars.instance.vodURL), utype, "200", 0);
				return;
			}
			
			startTime = getTimer();
			utype = "gdl";
			if (hostURL.indexOf("dl") == 0)
			{
				utype = "dl";
			}
			
			//页面传递gdl地址
			JTracer.sendMessage("GetVodSocket -> connect, 页面传递gdl地址, gdl url:" + gdl);
			
			var hostObj:Object = StringUtil.getHostPort(gdlURL);
			host = hostObj.host;
			port = hostObj.port;
			//host = "gdl.lxtest.lixian.vip.xunlei.com";
			//port = 80;
			gdlLink = gdlURL.substr(gdlURL.indexOf("/"));
			cookie = ExternalInterface.call("G_PLAYER_INSTANCE.getParamInfo", "oriCookie") || "utype="+utype;
			referer = ExternalInterface.call("G_PLAYER_INSTANCE.getParamInfo", "referer") || "http://vod.xunlei.com";
			
			JTracer.sendMessage("GetVodSocket -> connect, \nhost:" + host + "\nport:" + port + "\ngdl:" + gdlLink + "\ncookie:" + cookie + "\nreferer:" + referer);
			JTracer.sendMessage("GetVodSocket -> start connect");
			
			GlobalVars.instance.isVodGetted = false;
			
			response = "";
			socket.connect(host, port);
		}
		
		private function replaceTS(url:String):String
		{
			if (!url)
			{
				return null;
			}
			
			var tsIdx:int = url.indexOf("&ts=");
			if (tsIdx >= 0)
			{
				var resultTs:String = int(new Date().getTime() / 1000).toString();
				var prefix:String = url.substr(0, tsIdx);
				var subfix:String = url.substr(tsIdx + 14);
				var resultURL:String = prefix + "&ts=" + resultTs + subfix;
				
				return resultURL;
			}
			
			return url;
		}
		
		private function closeSocket():void
		{
			if (socket.connected)
			{
				socket.close();
				
				JTracer.sendMessage("GetVodSocket -> socket.close()");
			}
		}
		
		private function getFormatURL(url:String):String
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
		
		private function connectSuccess(evt:Event):void
		{
			JTracer.sendMessage("GetVodSocket -> Connect Success");
			//
			GlobalVars.instance.connectGldTime = getTimer() - startTime;
			//http://vod.lixian.xunlei.com/media/vodPlayer_2.8.swf?v=2.816
			
			var header:String = "GET " + gdlLink + " HTTP/1.1 \r\n";
			header += "Host: " + host + " \r\n";
			header += "User-Agent: Mozilla/5.0 (Windows NT 5.1; rv:14.0) Gecko/20100101 Firefox/14.0.1 \r\n";
			header += "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8 \r\n";
			header += "Accept-Language: zh-cn,zh;q=0.8,en-us;q=0.5,en;q=0.3 \r\n";
			header += "Accept-Encoding: gzip, deflate \r\n";
			header += "Connection: keep-alive \r\n";
			header += "Referer: " + referer + " \r\n";
			header += "Cookie: " + cookie + " \r\n";
    		header += "UA-CPU: x86 \r\n";
    		header += "Cache-Control: no-cache \r\n\r\n";
			JTracer.sendMessage('BaseSocket -> connectSuccess: header-->' + header)
			socket.writeUTFBytes(header);
			socket.flush();
		}
		
		private function receiveSocketData(evt:ProgressEvent):void
		{
			JTracer.sendMessage("GetVodSocket -> Receive Socket Data");
			
			var str:String = socket.readUTFBytes(socket.bytesAvailable);
    		response += str;
			var status:String = getResponseHeader("HTTP/1.1", " ");
			
			JTracer.sendMessage("GetVodSocket -> response:\n" + response + "\nstatus:" + status);
			
			var endPos:int = response.indexOf("\r\n\r\n");
			if (endPos < 0)
			{
				JTracer.sendMessage("GetVodSocket -> response header not receive finish");
				
				GlobalVars.instance.isVodGetted = false;
				completeFun(null, utype, status, getTimer() - startTime);
				closeSocket();
				return;
			}

			var _vodurl:String = getResponseHeader("Location", ":");
			
			closeSocket();
			JTracer.sendMessage('GetVodSocket ->receiveSocketData:'+host +' vod?:'+_vodurl);
			var theVodHost:String = _vodurl.substr(7);
			GlobalVars.instance.vodAddr = theVodHost.substr(0, theVodHost.indexOf('/'));
			/*
			// 6-17 号注释; 获取vod连接时有小部分情况返回dl链接;
			if( _vodurl.indexOf('http://dl') == 0 ){
				var pre:int = _vodurl.indexOf('//')+2;
				var end:int = _vodurl.lastIndexOf('/');
				host = _vodurl.substring(pre,end);
				JTracer.sendMessage('GetVodSocket ->receiveSocketData:dl 链接重连,获取vod链接');
				JTracer.sendMessage('GetVodSocket ->receiveSocketData:'+host + ' port:'+port);
				response = "";
				socket.connect(host, port);

				return;
			}*/
			
			GlobalVars.instance.isVodGetted = _vodurl ? true : false;				
			GlobalVars.instance.vodURL = _vodurl;
			completeFun(replaceTS(GlobalVars.instance.vodURL), utype, status, getTimer() - startTime);
			closeSocket();
		}
		
		private function closeSocketHandler(evt:Event):void
		{
			JTracer.sendMessage("GetVodSocket -> Connect Close");
			
			var status:String = getResponseHeader("HTTP/1.1", " ");
			
			GlobalVars.instance.isVodGetted = false;
			completeFun(null, utype, status, getTimer() - startTime);
			closeSocket();
		}
		
		private function connectIOError(evt:IOErrorEvent):void
		{
			JTracer.sendMessage("GetVodSocket -> Connect IOError");
			
			var status:String = getResponseHeader("HTTP/1.1", " ");
			
			GlobalVars.instance.isVodGetted = false;
			completeFun(null, utype, status, getTimer() - startTime);
			closeSocket();
		}
		
		private function connctSecurityError(evt:SecurityErrorEvent):void
		{
			JTracer.sendMessage("GetVodSocket -> Connct SecurityError, text:" + evt.text);
			
			var status:String = getResponseHeader("HTTP/1.1", " ");
			
			GlobalVars.instance.isVodGetted = false;
			completeFun(null, utype, status, getTimer() - startTime);
			closeSocket();
		}
		
		private function getResponseHeader(header:String, separate:String):String
		{
			if (!response || response == "")
			{
				JTracer.sendMessage("GetVodSocket -> not found header:" + header + ", separate:" + separate + ", response:" + response);
				return null;
			}
			
			var headerPos:int = response.indexOf(header);
			if (headerPos < 0)
			{
				JTracer.sendMessage("GetVodSocket -> not found header:" + header);
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
	}
}