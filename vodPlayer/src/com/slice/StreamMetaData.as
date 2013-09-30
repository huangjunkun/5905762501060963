package com.slice 
{
	import com.common.StringUtil;
	import com.Player;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetStream;
	import flash.net.NetConnection;
	import flash.events.NetStatusEvent;
	import flash.events.AsyncErrorEvent;
	import flash.events.IOErrorEvent;
	import com.common.GetVodSocket;
	import com.common.JTracer;
	import com.global.GlobalVars;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.net.NetStreamAppendBytesAction;
	import flash.utils.Timer;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class StreamMetaData extends EventDispatcher
	{	
		public static const KEYFRAME_LOADED:String = 'key frame loaded';
		public static const KEYFRAME_ERROR:String = 'key frame error';
		private var _endByte:Number = 80 * 1024;
		private var _conn:NetConnection;
		private var _stream:NetStream;
		private var _url:String;
		private var _client:Object;
		private var _timeArr:Array = [];
		private var _byteArr:Array = [];
		private var _sIntervalTime:Number;
		private var _spliceByteArr:Array = [];
		private var _spliceTimeArr:Array = [];
		private var _firstByteEnd:Number;
		private var _isAdd:Boolean;//是否添加切片
		private var _totalByte:Number;
		private var _player:Player;
		private var socket_count:uint = 1;			//socket链接个数
		private var socket_array:Array = [];		//socket对象数组
		private var block_size:uint = 80 * 1024;	//socket请求的分块大小
		private var current_pos:uint = 0;			//socket下载开始点
		private var appendTimer:Timer;
		private var gdlUrl:String = '';
		public var query_pos:uint;
		public var loadNextSocketsData = true;
		
		public function StreamMetaData(player:Player) 
		{
			_player = player;
			
			_conn = new NetConnection();
			_conn.connect(null);
			
			_client = {};
			_client.onMetaData = metaDataHandler;
			
			_stream = new NetStream(_conn);
			_stream.client = _client;
			_stream.bufferTime = 1;
			_stream.soundTransform = new SoundTransform(0);
			_stream.addEventListener(NetStatusEvent.NET_STATUS, netstatusEventHandler);
			_stream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorEventHandler);
			_stream.addEventListener(IOErrorEvent.IO_ERROR, ioErrorEventHandler);
		}
		
		public function loadMetaData(url:String, vduration:Number):void
		{
			var suffixUrl:String = '&start=0&end=' + _endByte + '&flash_meta=0&type=loadmetadata&du=' + vduration;
			gdlUrl = url + suffixUrl;
			
			if (GlobalVars.instance.isUseSocket)
			{
				JTracer.sendMessage("StreamMetaData -> loadMetaData, connect socket");
				
				GetVodSocket.instance.connect(url, function(vod_url:String, utype:String, status_code:String, cost_time:int)
				{
					if (GlobalVars.instance.getVodTime == 0)
					{
						GlobalVars.instance.getVodTime = cost_time;
					}
					
					if (!vod_url)
					{
						GlobalVars.instance.isUseHttpSocket = false;
						
						_player.vodUrl = null;
						JTracer.sendMessage("StreamMetaData -> loadMetaData, get vod url fail, gdl url:" + gdlUrl);
						_stream.play(gdlUrl);
					}
					else
					{
						GlobalVars.instance.isUseHttpSocket = checkIsUseHttpSocket(vod_url);
						JTracer.sendMessage("StreamMetaData -> loadMetaData, isUseHttpSocket:" + GlobalVars.instance.isUseHttpSocket);
						if (GlobalVars.instance.isUseHttpSocket)
						{
							current_pos = 0;
							query_pos = socket_count * block_size;
							
							_conn = new NetConnection();
							_conn.connect(null);
							
							_client = {};
							_client.onMetaData = metaDataHandler;
							
							_stream = new NetStream(_conn);
							_stream.client = _client;
							_stream.bufferTime = 1;
							_stream.soundTransform = new SoundTransform(0);
							_stream.addEventListener(NetStatusEvent.NET_STATUS, netstatusEventHandler);
							_stream.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorEventHandler);
							_stream.addEventListener(IOErrorEvent.IO_ERROR, ioErrorEventHandler);
							_stream.play(null);
							_stream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
							
							_player.vodUrl = vod_url + suffixUrl;
							JTracer.sendMessage("StreamMetaData -> loadMetaData, use socket, get vod url success, vod url:" + vod_url + ", start_pos:0, end_pos:" + _endByte + ", next_pos:" + query_pos);
							downloadStream(vod_url, 0, _endByte);
						}
						else
						{
							_player.vodUrl = vod_url + suffixUrl;
							JTracer.sendMessage("StreamMetaData -> loadMetaData, get vod url success, vod url:" + _player.vodUrl);
							_stream.play(_player.vodUrl);
						}
					}
				});
			}
			else
			{
				JTracer.sendMessage('StreamMetaData -> loadMetaData, gdl url=' + gdlUrl);
				_stream.play(gdlUrl);
			}
			
			initialAppendTimer();
		}
		
		private function initialAppendTimer():void {
			if (appendTimer == null)
			{
				appendTimer = new Timer(100);
				appendTimer.addEventListener(TimerEvent.TIMER, handleAppendTimer);
				appendTimer.start();
			}
		}
		
		private function clearAppendTimer():void {
			if (appendTimer)
			{
				appendTimer.stop();
				appendTimer.removeEventListener(TimerEvent.TIMER, handleAppendTimer);
				appendTimer = null;
			}
		}
		
		private function handleAppendTimer(evt:TimerEvent):void
		{
			block_complete(null);
		}
		
		private function checkIsUseHttpSocket(url:String):Boolean
		{
			var hostObj:Object = StringUtil.getHostPort(url);
			var hostUrl:String = hostObj.host;
			var ipHost:String = GlobalVars.instance.vodAddr;
			var machines:Array = GlobalVars.instance.httpSocketMachines['multi'] || [];
			if(GlobalVars.instance.feeUser)return false;
			for (var k:* in machines)
			{
				JTracer.sendMessage("machines:" + machines[k]+'\n');
				if (ipHost.indexOf(machines[k]) > -1 || hostUrl.indexOf(machines[k]) > -1)
				{
					return true;
				}
			}
			
			return false;
		}
		
		private function clearSocket():void
		{
			var i:uint;
			var socket:SingleSocket;
			for (i = 0; i < socket_array.length; i++)
			{
				socket = socket_array[i];
				socket.removeEventListener(SingleSocket.All_Complete, all_block_complete);
				//socket.removeEventListener(SingleSocket.Complete, block_complete);
				socket.removeEventListener(SingleSocket.SocketError, block_error);
				socket.removeEventListener(SingleSocket.SocketSecurityError, block_error);
				socket.clear();
				socket = null;
			}
			socket_array = [];
		}
		
		private function downloadStream(url:String, start_pos:uint, end_pos:uint):void
		{
			StreamList.clearHeader();
			
			clearSocket();
			
			var i:uint;
			var socket:SingleSocket;
			if (socket_array.length == 0)
			{
				for(i = 0; i < socket_count; i++)
				{
					socket = new SingleSocket(this, url, block_size, socket_count, start_pos + i * block_size, end_pos, end_pos - start_pos, GlobalVars.instance.type_metadata, _player.getVideoUrlArr[0].totalByte);
					socket.addEventListener(SingleSocket.All_Complete, all_block_complete);
					//socket.addEventListener(SingleSocket.Complete, block_complete);
					socket.addEventListener(SingleSocket.SocketError, block_error);
					socket.addEventListener(SingleSocket.SocketSecurityError, block_error);
					socket.connectSocket();
					
					socket_array.push(socket);
				}
			}
			else
			{
				for (i = 0; i < socket_count; i++)
				{
					socket = socket_array[i];
					socket.clear();
					socket.setQueryUrl(url);
					socket.setQueryRange(start_pos + i * block_size, end_pos, end_pos - start_pos, _player.getVideoUrlArr[0].totalByte);
					socket.connectSocket();
				}
			}
		}
		
		private function all_block_complete(evt:Event):void
		{
			var socket:SingleSocket = evt.currentTarget as SingleSocket;
			socket.clearSocket();
			var pos_obj:Object = socket.getCompletePos();
			JTracer.sendMessage("StreamMetaData -> all_block_complete, start_pos:" + pos_obj.start_pos + ", end_pos:" + pos_obj.end_pos + ", next_pos:" + query_pos);
		}
		
		private function block_complete(evt:Event):void
		{
			if (!GlobalVars.instance.isUseHttpSocket || GlobalVars.instance.isHeaderGetted)
			{
				return;
			}
			
			var cur_bytes:ByteArray = StreamList.getBytes(GlobalVars.instance.type_metadata, current_pos, current_pos + block_size - 1) as ByteArray;
			if (cur_bytes)
			{
				//JTracer.sendMessage("StreamMetaData -> start_pos:" + current_pos + ", end_pos:" + (current_pos + block_size - 1) + " -> length:" + cur_bytes.length);
				_stream.appendBytes(cur_bytes);
				current_pos += block_size;
			}
		}
		
		private function block_error(evt:Event):void
		{
			var socket:SingleSocket = evt.currentTarget as SingleSocket;
			JTracer.sendMessage("StreamMetaData -> block_error, error_info:" + socket.getErrorInfo());
			if( evt.type == "SocketSecurityError" ){
				GlobalVars.instance.isUseHttpSocket = false;
				GlobalVars.instance.isHeaderGetted = false;
				GlobalVars.instance.isUseSocket = false;
				if(_player.vodUrl){
					JTracer.sendMessage('StreamMetaData -> block_error SecurityError starting play vod url')
					_stream.play(_player.vodUrl)
				}
				else{
					JTracer.sendMessage('StreamMetaData -> block_error SecurityError starting play gdl url')
					_stream.play(gdlUrl);
				}
			}
		}
		
		public function set totalByte(num:Number):void
		{
			_totalByte = num;
		}
		
		public function set sliceTime(interval:Number):void
		{
			_sIntervalTime = interval < 30 ? 30 : interval;
			JTracer.sendMessage('StreamMetaData -> sliceTime:' + interval);
		}
		
		public function spliceUpdateArray():void
		{
			/*
			if (parseInt(_timeArr[_timeArr.length - 1]) - parseInt(_timeArr[_timeArr.length - 2]) <= 60)
			{
				_timeArr[_timeArr.length - 2] = _timeArr[_timeArr.length - 1];
				_timeArr.pop();
				
				_byteArr[_byteArr.length - 2] = _byteArr[_byteArr.length - 1];
				_byteArr.pop();
			}
			*/
			
			if (_timeArr.length != _byteArr.length || _timeArr.length == 0) {
				JTracer.sendMessage('StreamMetaData -> spliceUpdateArray, _timeArr.length != _byteArr.length, can not match! _timeArr.length:' + _timeArr.length + ', _byteArr.length:' + _byteArr.length);
				return;
			}
			
			_isAdd = false;
			
			var idx:int = getNearValueIndex(_timeArr, _sIntervalTime) + 1;
			JTracer.sendMessage('StreamMetaData -> spliceUpdateArray, 最接近的id:' + idx);
			var curInd:int = idx;
			var arrLen:int = _timeArr.length;
			_spliceByteArr = [], _spliceTimeArr = [];
			_spliceByteArr.push(_byteArr[0]);
			_spliceTimeArr.push(_timeArr[0]);
			while (curInd < arrLen - 1 && idx > 0) {
				_spliceByteArr.push(_byteArr[curInd]);
				_spliceTimeArr.push(_timeArr[curInd]);
				curInd += idx;
			}
			_spliceByteArr.push(_byteArr[arrLen - 1]);
			_spliceTimeArr.push(_timeArr[arrLen - 1]);
			
			if (_firstByteEnd != 0 && _spliceByteArr.length > 2) {
				var firstIndex:Number = getNearValueIndex(_byteArr, _firstByteEnd) + 1;
				firstIndex = firstIndex < 1 ? 1 : firstIndex;
				_spliceByteArr[1] = _byteArr[firstIndex];
				_spliceTimeArr[1] = _timeArr[firstIndex];
			}
			
			var str:String = "StreamMetaData -> spliceUpdateArray:";
			for (var i:* in _spliceTimeArr) {
				str += "\n" + "_spliceTimeArr[" + i + "]:" + _spliceTimeArr[i] + ",\t_spliceByteArr[" + i + "]:" + _spliceByteArr[i];
			}
			JTracer.sendMessage(str);
		}
		
		public function set firstByteEnd(byte:Number):void
		{
			JTracer.sendMessage('StreamMetaData -> firstByteEnd:' + byte);
			_firstByteEnd = byte;
		}
		
		public function getStartTime(time:Number):Number
		{
			var idx:int = getNearValueIndex(_timeArr, time) + 1;
			idx = Math.max(0, Math.min(_timeArr.length - 2, idx));
			var times:Number = _timeArr[idx];
			JTracer.sendMessage('StreamMetaData -> 获取的开始时间是:' + time + ', index:' + idx);
			return times;
		}
		
		public function getStartByte(time:Number):Number
		{
			var idx:int = getNearValueIndex(_timeArr, time) + 1;
			idx = Math.max(0, Math.min(_timeArr.length - 2, idx));
			var bytes:Number = _byteArr[idx];
			JTracer.sendMessage('StreamMetaData -> 获取的开始字节位置为:' + bytes + ', 时间是:' + time + ', index:' + idx);
			return bytes;
		}
		
		public function getEndByte(time:Number):Number
		{
			var idx:int = getNearValueIndex(_timeArr, time) + 2;
			idx = Math.max(1, Math.min(_timeArr.length - 1, idx));
			var bytes:Number = _byteArr[idx];
			JTracer.sendMessage('StreamMetaData -> 获取的结束字节位置为:' + bytes + ', 时间是:' + time + ', index:' + idx);
			return bytes;
		}
		
		public function getSpliceEndByte(time:Number):Number
		{
			var idx:int = getNearValueIndex(_spliceTimeArr, time) + 2;
			idx = Math.max(1, Math.min(_spliceTimeArr.length - 1, idx));
			var bytes:Number = _spliceByteArr[idx];
			if (idx == _spliceTimeArr.length - 1)
			{
				bytes = _totalByte;
			}
			JTracer.sendMessage('StreamMetaData -> 获取的结束字节位置为:' + bytes + ', 时间是:' + time + ', index:' + idx);
			return bytes;
		}
		
		private function getNearValueIndex(arr:Array, value:Number):int
		{
			var index:int = -3;
			for (var i:int = 0, len:int = arr.length; i < len; i++ ) {
				if (arr[i] > value) {
					index = i - 2;
					break;
				}
			}
			return index == -3 ? arr.length - 1 : index;
		}
		
		public function startByte(time:Number):Number
		{
			if (time < 0) { time = 0; }
			var bytes:Number = 0;
			if (_timeArr.length > 1 )
			{
				var t1:uint = 0;
				var playTimeHeadIndex:uint = 0;
				var haveMatched:Boolean = false;
				var len:uint = _timeArr.length;
				while (t1 < len - 1) {
					var t2:uint = t1 + 1;
					if (_timeArr[t1] <= time && _timeArr[t2] > time) {
						playTimeHeadIndex = t1;
						haveMatched = true;
						break;
					}
					t1++;
				}
				if (playTimeHeadIndex == 0) 
				{
					playTimeHeadIndex = haveMatched ? 1 : _timeArr.length - 1;
				}
				playTimeHeadIndex = Math.min(_timeArr.length - 1, Math.max(1, playTimeHeadIndex));
				bytes = _byteArr[playTimeHeadIndex];
			}
			JTracer.sendMessage('StreamMetaData -> 获取的开始字节位置为:' + bytes + ', 时间是:' + time + ', index:' + playTimeHeadIndex);
			return bytes;
		}
		
		public function endByte(time:Number):Number
		{
			var bytes:Number = 0;
			if (_timeArr.length > 1 ) 
			{
				var t1:int = 0;
				var playTimeHeadIndex:uint = 0;
				var haveMatched:Boolean = false;
				var len:uint = _timeArr.length;
				while (t1 < len - 1) {
					var t2:uint = t1 + 1;
					if (_timeArr[t1] <= time && _timeArr[t2] > time) {
						playTimeHeadIndex = t1;
						haveMatched = true;
						break;
					}
					t1++;
				}
				if (playTimeHeadIndex == 0)
				{
					playTimeHeadIndex = haveMatched ? 1 : _timeArr.length - 1;
				}
				playTimeHeadIndex = Math.min(_timeArr.length - 1, Math.max(1, playTimeHeadIndex));
				bytes = _byteArr[playTimeHeadIndex];
			}
			JTracer.sendMessage('StreamMetaData -> 获取的结束字节位置为:' + bytes + ', 时间是:' + time + ', index:' + playTimeHeadIndex);
			return bytes;
		}
		
		public function get timeArr():Array
		{
			return _timeArr;
		}
		
		public function get byteArr():Array
		{
			return _byteArr;
		}
		
		public function clear():void
		{
			_timeArr = [];
			_byteArr = [];
			_stream.close();
			_conn.close();
		}
		
		private function isHasValue(arr:Array, value:Number):Boolean
		{
			var i:*;
			for (i in arr)
			{
				if (arr[i] == value)
				{
					return true;
				}
			}
			
			return false;
		}
		
		private function netstatusEventHandler(e:NetStatusEvent):void
		{
			if (e.info.code == 'NetStream.Play.StreamNotFound') {
				JTracer.sendMessage('StreamMetaData -> NetStream.Play.StreamNotFound');
				dispatchEvent(new Event(StreamMetaData.KEYFRAME_ERROR));
			}
		}
		
		private function securityErrorEventHandler(e:SecurityErrorEvent):void
		{
			JTracer.sendMessage('StreamMetaData -> SecurityErrorEvent');
			dispatchEvent(new Event(StreamMetaData.KEYFRAME_ERROR));
		}
		
		private function ioErrorEventHandler(e:IOErrorEvent):void
		{
			JTracer.sendMessage('StreamMetaData -> IOErrorEvent');
			dispatchEvent(new Event(StreamMetaData.KEYFRAME_ERROR));
		}
		
		private function metaDataHandler(info:Object):void
		{
			try {
				if (info.keyframes)
				{
					_timeArr = String(info.keyframes.times).split(",");
					_byteArr = String(info.keyframes.filepositions).split(",");
				}else if (info.seekpoints) {
					var arr:Array = info.seekpoints;
					_timeArr = [];
					_byteArr = [];
					var j:uint;
					var len:uint = arr.length;
					for ( j = 0; j < len; j++ ) {
						_timeArr.push(arr[j].time);
						_byteArr.push(arr[j].time);
					}
				}
			} catch (e:Error) {
				_timeArr = new Array();
				_byteArr = new Array();
			}
			
			/*var str:String = "";
			for (var j:* in _timeArr) {
				str += "\n" + "timeArr[" + j + "]:" + _timeArr[j] + ",\tpositionArr[" + j + "]:" + _byteArr[j];
			}
			JTracer.sendMessage(str);*/
			
			clearSocket();
			clearAppendTimer();
			if( GlobalVars.instance.isUseHttpSocket )
			{
				GlobalVars.instance.isHeaderGetted = true;
			}
			JTracer.sendMessage("StreamMetaData -> metaDataHandler, 获取关键帧数组完毕");
			dispatchEvent(new Event(StreamMetaData.KEYFRAME_LOADED));
		}
	}
}