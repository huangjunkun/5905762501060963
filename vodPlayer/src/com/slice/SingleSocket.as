package com.slice
{
	import com.common.JTracer;
	import com.common.StringUtil;
	import com.global.GlobalVars;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.Timer;
	import flash.utils.*;
	import flash.events.*;
	import flash.net.Socket;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class SingleSocket extends EventDispatcher
	{
		private var m_socket:Socket;
		private var m_url:String;
		private var m_host:String;
		private var m_port:uint;
		private var m_block_size:uint;
		private var m_socket_count:uint;
		private var m_query_pos:uint;
		private var m_query_end_pos:uint;
		private var m_next_pos:uint;
		private var m_end_pos:uint;
		private var cache_length:uint = 0;
		private var video_length:uint = 0;
		private var video_total_length:uint = 0;
		private var buffer_cache:ByteArray = new ByteArray();
		private var buffer_video:ByteArray = new ByteArray();
		private var error_info:String;
		private var parentObj:*;
		private var m_byte_type:String;
		private var m_video_end_byte:Number;
		private var query_size:uint=0;
		
		public static const Complete:String = "Complete";
		public static const All_Complete:String = "all_complete";
		public static const SocketError:String = "SocketError";
		public static const SocketSecurityError:String = "SocketSecurityError";
		public static const SocketReStartToQueryDataEvent:String = "SocketReStartToQueryDataEvent";

		private static var ID:int = 0;
		private var __id:int = 0;

		public function SingleSocket(parent_obj:*, url:String, block_size:uint, socket_count:uint, start_pos:uint, end_pos:uint, total_size:uint, byte_type:String, video_end_byte:Number=0):void
		{
			parentObj = parent_obj;
			
			var url_info:Object = StringUtil.getHostPort(url);
			m_url = replaceDT(url_info.url);
			m_host = url_info.host;
			m_port = url_info.port;
			
			m_block_size = block_size;
		    m_socket_count = socket_count;
			m_next_pos = start_pos;
			m_end_pos = end_pos;
			video_total_length = total_size;
			m_byte_type = byte_type;
			m_video_end_byte = video_end_byte;
			ID ++;
			__id = ID;

			addEventListener(SocketReStartToQueryDataEvent, function(e:Event):void{
				JTracer.sendMessage('Socket at:'+__id +' restart to query data.')
				loadNextStream();
			})

		}
		
		public function getCompletePos():Object
		{
			return { start_pos:m_query_pos, end_pos:m_query_end_pos };
		}
		
		public function getErrorInfo():String
		{
			return error_info;
		}
		
		public function get bytesLoaded():uint
		{
			return video_length;
		}
		
		public function get bytesTotal():uint
		{
			return video_total_length;
		}
		
		public function setByteType(byte_type:String):void
		{
			m_byte_type = byte_type;
		}

		public function get byteType():String{
			return m_byte_type;
		}
		
		public function setQueryUrl(url:String):void
		{
			var url_info:Object = StringUtil.getHostPort(url);
			m_url = url_info.url;
			m_host = url_info.host;
			m_port = url_info.port;
		}
		
		public function setQueryRange(start_pos:uint, end_pos:uint, total_size:uint, video_end_byte:Number=0):void
		{
			m_next_pos = start_pos;
			m_end_pos = end_pos;
			video_total_length = total_size;
			m_video_end_byte = video_end_byte;			
		}
		
		public function clear():void
		{
			m_query_pos = 0;
			m_next_pos = 0;
			m_end_pos = 0;
			cache_length = 0;
			video_length = 0;
			video_total_length = 0;
			buffer_video.clear();
			buffer_cache.clear();
			clearSocket();
		}
		
		public function clearSocket():void
		{
			if (m_socket)
			{
				m_socket.removeEventListener(Event.CONNECT, connectSuccess);
				m_socket.removeEventListener(ProgressEvent.SOCKET_DATA, receiveSocketData);
				m_socket.removeEventListener(Event.CLOSE, connectClose);
				m_socket.removeEventListener(IOErrorEvent.IO_ERROR, connectIOError);
				m_socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, connctSecurityError);
				if (m_socket.connected)
				{
					m_socket.close();
				}
				m_socket = null;
			}
		}
		
		public function connectSocket():void
		{
			initSocket();
			m_socket.connect(m_host, m_port);
			
			/*initSocket();
			
			if (!m_socket.connected)
			{
				m_socket.connect(m_host, m_port);
			}
			else
			{
				sendQuery();
			}*/
		}
		
		private function replaceDT(url:String):String
		{
			if (!url)
			{
				return null;
			}
			
			var idx:int = url.indexOf("dt=");
			if (idx >= 0)
			{
				var prefix:String = url.substr(0, idx);
				var subfix:String = url.substr(idx + 5);
				var resultURL:String = prefix + "dt=17" + subfix;
				
				return resultURL;
			}
			
			return url;
		}
		
		private function initSocket():void
		{
			if (!m_socket)
			{
				m_socket = new Socket();
				m_socket.timeout = 5000;
				m_socket.addEventListener(Event.CONNECT, connectSuccess);
				m_socket.addEventListener(ProgressEvent.SOCKET_DATA, receiveSocketData);
				m_socket.addEventListener(Event.CLOSE, connectClose);
				m_socket.addEventListener(IOErrorEvent.IO_ERROR, connectIOError);
				m_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, connctSecurityError);
			}
		}
		
		private function connectSuccess(evt:Event):void
		{
			buffer_video.clear();
			cache_length = 0;
			sendQuery();
		}
		
		private function sendQuery():void
		{
			var pos_obj:Object = StreamList.findBytesRange(m_next_pos)
			if(pos_obj.start){
				trace('Socket at:'+__id+' sendQuery: m_next_pos='+m_next_pos);
				JTracer.sendMessage('Socket at:'+__id+' sendQuery: m_next_pos='+m_next_pos)
				loadNextStream();
				return;
			}
			m_query_pos = m_next_pos;
			m_query_end_pos = Math.min(m_query_pos + m_block_size - 1,  m_video_end_byte-1);
			
			var header:String = "GET " + m_url + " HTTP/1.1 \r\n";
	        header += "Range: bytes=" + m_query_pos + "-" + m_query_end_pos + " \r\n";
			header += "Host: " + m_host + ":" + m_port + " \r\n\r\n";
			
			query_size = (m_query_end_pos - m_query_pos);
			
			//m_next_pos = m_query_end_pos + (m_socket_count - 1) * m_block_size + 1;
			JTracer.sendMessage('Socket at'+__id+' Range:('+m_query_pos+'-'+m_query_end_pos+') end:' + m_end_pos + ' video_end:'+ m_video_end_byte);
			m_socket.writeUTFBytes(header);
			m_socket.flush();
		}
		
		private function receiveSocketData(evt:ProgressEvent):void
		{
			var data_length:uint = m_socket.bytesAvailable;
			video_length += data_length;
			
			buffer_cache.clear();
			m_socket.readBytes(buffer_cache, 0, m_socket.bytesAvailable);
			trace('receiveSocketData >>>>>>>>>>>>>>>>>>>>>>>  '+ __id +' >>>>>>>>>>>>>>>>>>>>>>>  ')
			var temp_str:String = buffer_cache.toString();
			var end_pos:int = temp_str.indexOf("\r\n\r\n");
			if (end_pos > 0 && end_pos + 4 < data_length)
			{
				trace(getTime() +' end_pos:'+end_pos)
				var headstr:String = temp_str.substring(0, end_pos);
				var http_result:String = StringUtil.getResponseHeader(headstr, "HTTP/1.1", " ");
				if (http_result &&  parseInt(http_result) >= 300)
				{
					error_info = http_result;
			        dispatchEvent(new Event(SocketError));
					return;
				}
				
				var read_begin:uint = 0;
				if (headstr.indexOf("HTTP/1.1") >= 0)
				{
					read_begin = end_pos + 4;
					JTracer.sendMessage("SingleSocket -> receiveSocketData, m_byte_type:" + m_byte_type + ", start_pos:" + m_query_pos + ", end_pos:" + m_query_end_pos + ", read_begin:" + read_begin);
				}
				
				trace(getTime()+' read_begin:'+read_begin);
				var read_length:uint = data_length - read_begin;
				trace(getTime()+' read_length:'+read_length)
				if (read_length > 0)
				{
					//JTracer.sendMessage("1 start_pos:" + m_query_pos + ", available:" + buffer_cache.bytesAvailable + ", read begin:" + read_begin + ", read length:" + read_length);
					buffer_video.writeBytes(buffer_cache, read_begin, read_length);
					cache_length += read_length;
					trace(getTime()+" buffer_video length:"+buffer_video.length+" read_length:"+read_length+" cache_length"+cache_length)
					if(cache_length >= m_block_size - read_begin)
					{
						StreamList.setBytes(m_byte_type, m_query_pos, m_query_end_pos, buffer_video, __id);
						buffer_video.clear();
						cache_length = 0;
						dispatchEvent(new Event(Complete));
						
						loadNextStream();
					}
				}
		    }
			else if (end_pos < 0)
			{
				//JTracer.sendMessage("2 start_pos:" + m_query_pos + ", available:" + buffer_cache.bytesAvailable + ", read length:" + data_length);
				buffer_video.writeBytes(buffer_cache, 0, data_length);
				cache_length += data_length;
				trace(getTime()+' row data--- data_length:'+data_length + ' cache_length:'+cache_length+' buffer_video.length:'+buffer_video.length)
				if(cache_length >= query_size)
				{
					StreamList.setBytes(m_byte_type, m_query_pos, m_query_end_pos, buffer_video, __id);
					buffer_video.clear();
					cache_length = 0;
					
					dispatchEvent(new Event(Complete));
					
					loadNextStream();
				}
			}else{
				trace('\ndata:'+temp_str+'\n')
			}
			trace('receiveSocketData end .....................................................................<<<')
		}
		
		private function loadNextStream():void
		{
			if (m_next_pos + m_socket_count * m_block_size - 1 < m_end_pos ){
				m_next_pos = parentObj.query_pos;
				if(!parentObj.loadNextSocketsData){
					JTracer.sendMessage('Socket at:'+__id +' stop a while.')
					return;
				}
				parentObj.query_pos += m_block_size;
				sendQuery();
			}
			else
			{
				dispatchEvent(new Event(All_Complete));
			}
		}
		
		private function connectClose(evt:Event):void
		{
			if (m_next_pos < m_end_pos)
			{
				//m_query_pos -= m_socket_count * m_block_size;
				setTimeout(function(){
					clearSocket();
					connectSocket();
					trace('socket at '+__id+' reconnect.')
				},500)
			}
			
			error_info = "Connect Close at Socket:"+__id;
			dispatchEvent(new Event(SocketError));
		}
		
		private function connectIOError(evt:IOErrorEvent):void
		{
			error_info = "Connect IOError at Socket:"+__id;
			dispatchEvent(new Event(SocketError));
		}
		
		private function connctSecurityError(evt:SecurityErrorEvent):void
		{
			error_info = "Connect SecurityError at Socket:"+ __id+", text:" + evt.text;
			dispatchEvent(new Event(SocketSecurityError));
		}
		private static function getTime():String
		{
			var dateObj:Date = new Date();
			var year:String = dateObj.getFullYear().toString();
			var month:String = formatZero(dateObj.getMonth() + 1);
			var date:String = formatZero(dateObj.getDate());
			var hour:String = formatZero(dateObj.getHours());
			var minute:String = formatZero(dateObj.getMinutes());
			var second:String = formatZero(dateObj.getSeconds());
			var milisecond:String = dateObj.getMilliseconds().toString();
			
			return (year + "-" + month + "-" + date + " " + hour + ":" + minute + ":" + second + " " + milisecond);
		}
		private static function formatZero(num:Number):String
		{
			if (num < 10)
			{
				return "0" + num.toString();
			}
			
			return num.toString();
		}
	}
}