package  com.slice
{
	import com.Player;
	import com.common.GetNextVodSocket;
	import com.common.JTracer;
	import com.common.Tools;
	import com.global.GlobalVars;
	
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.NetStreamAppendBytesAction;
	import flash.net.URLRequest;
	import flash.net.sendToURL;
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import zuffy.events.TryPlayEvent;
	import zuffy.ctr.manager.CtrBarManager;
	
	/**
	 * p2s多段拼接
	 * @author ...dds
	 */
	public class SliceStreamBytes
	{
		private var _sIntervalTime:Number = 60*10;
		private var _spliceByteArr:Array = [];
		private var _spliceTimeArr:Array = [];
		private var _byteArr:Array = [];
		private var _timeArr:Array = [];
		private var _nextStream:NetStream;
		private var _nextVideo:Video;
		private var _preIndex:int = 0;
		private var _curIndex:int = 0;
		private var _spliceCheckTimer:Timer;
		private var _player:Player;
		private var _firstByteEnd:Number = 0;
		private var _playCheckTimer:Timer;
		private var _cacheStream:NetStream;
		private var _spliceInit:Boolean = false;
		private var _totalTime:Number = 0;
		private var _totalByte:Number = 0;
		private var cn:NetConnection;
		private var _onerror:String;
		private var _arrError:Array = new Array();
		private var _buffer:Boolean = false;
		private var _isReloadNext:Boolean = false;//是否在缓冲下一个切片
		private var _isReplaceNext:Boolean = false;//是否替换为下一下切片
		private var _huanNextStream:NetStream;
		private var _feeLoader:FeeLoader;
		private var _isFirstFee:Boolean = true;//是否第一次扣费
		private var _startTime:Number;//开始时间
		private var _endTime:Number;//结束时间
		private var _globalVars:GlobalVars;
		private var _timeInterval:Number;
		private var _remainTimes:Number;
		private var _hasNextStream:Boolean = true;//是否还有下一切片
		private var block_size:uint = 128 * 1024;
		private var socket_count:uint = 3;
		private var socket_array:Array = [];
		private var current_pos:uint;
		private var is_append_header:Boolean;
		private var loading_pos:Number;
		private var loading_time:Number;
		private var isRetry:Boolean//是否已重试
		private var sliceSize:uint;
		private var sliceStart:uint;
		private var isLostData:Boolean;
		
		public var query_pos:uint;


		private static var id:int = 0;
		public var __id:int = 0;
		
		public function SliceStreamBytes(player:Player) 
		{
			_player = player;
			
			_globalVars = GlobalVars.instance;
			
			_globalVars.preFeeTime = 0;
			_globalVars.nowFeeTime = 0;
			
			_feeLoader = FeeLoader.getInstance();
			_feeLoader.feeSuccess = onFeeSuccess;
			_feeLoader.feeIOError = onFeeIOError;
			_feeLoader.feeSecurityError = onFeeSecurityError;
		}
		
		public function changeByteType():void
		{
			var i:uint;
			var socket:SingleSocket;
			for (i = 0; i < socket_array.length; i++)
			{
				socket = socket_array[i];
				socket.setByteType(GlobalVars.instance.type_curstream);
			}
		}
		
		public function get bytesLoaded():Number
		{
			if (GlobalVars.instance.isUseHttpSocket)
			{
				var loaded_length:uint;
				var i:uint;
				var socket:SingleSocket;
				for (i = 0; i < socket_array.length; i++)
				{
					socket = socket_array[i];
					loaded_length += socket.bytesLoaded;
				}
				
				return loaded_length;
			}
			
			return _nextStream.bytesLoaded;
		}
		
		public function get bytesTotal():Number
		{
			if (GlobalVars.instance.isUseHttpSocket)
			{
				var total_length:uint;
				var i:uint;
				var socket:SingleSocket;
				for (i = 0; i < socket_array.length; i++)
				{
					socket = socket_array[i];
					total_length += socket.bytesTotal;
				}
				
				return total_length / socket_count;
			}
			
			return _nextStream.bytesTotal;
		}
		
		public function spliceStartCheckTimer():void
		{
			_startTime = getTimer();
			if(GlobalVars.instance.isUseHttpSocket)return;
			if (_spliceCheckTimer == null ) {
				_spliceCheckTimer = new Timer(100, 0);
				_spliceCheckTimer.addEventListener(TimerEvent.TIMER, spliceCheckTimeHandler);
				JTracer.sendMessage('SliceStreamBytes -> spliceStartCheckTimer addEventListener spliceCheckTimeHandler')
			}
			_spliceCheckTimer.start();
			JTracer.sendMessage('SliceStreamBytes -> spliceStartCheckTimer started');
		}
		
		private function spliceCheckTimeHandler(e:TimerEvent):void
		{
			block_complete(null);
			
			_endTime = getTimer();
			_timeInterval = _endTime - _startTime;
			_startTime = _endTime;
			
			//普通会员扣费
			var vodPermit:Number = Number(Tools.getUserInfo("vodPermit"));
			if ((vodPermit == 6 || vodPermit == 8 || vodPermit == 10) && Tools.getUserInfo("from") != _globalVars.fromXLPan)
			{
				if (_player.main_mc.isChangeQuality)
				{
					_globalVars.nowFeeTime = 0;
					_globalVars.preFeeTime = 0;
				}
				
				if (!_player.isPause && !_player.isStop && !_player.main_mc.isBuffering)
				{
					_globalVars.nowFeeTime += _timeInterval;
				}
				
				if (_globalVars.nowFeeTime - _globalVars.preFeeTime >= _globalVars.feeInterval)
				{
					var timePre:Number = _globalVars.preFeeTime;
					var timeAll:Number = _globalVars.nowFeeTime;
					
					_globalVars.preFeeTime = _globalVars.nowFeeTime;
					
					_feeLoader.startFee(timeAll / 1000);
					JTracer.sendMessage("SliceStreamBytes -> startFee, timePre:" + timePre + ", timeAll:" + timeAll);
				}
			}
			
			spliceCheckTime(_player.time);
		}
		
		private function onFeeSuccess(obj:Object):void
		{
			if (obj)
			{
				_remainTimes = obj.remain;
				
				switch(obj.result)
				{
					case "0":
						break;
					case "1":
						//请求参数错误
						break;
					case "2":
						//播放特权会员用户无需扣费
						break;
					case "3":
						//session验证失败，或账号异常
						//网盘用户不提示
						if (Tools.getUserInfo("from") != _globalVars.fromXLPan)
						{
							_player.main_mc.showInvalidLoginLogo();
						}
						break;
					case "4":
						//网盘用户无需扣费
						break;
					case "5":
						//流量不足
						//网盘用户不提示
						if (Tools.getUserInfo("from") != _globalVars.fromXLPan)
						{
							//_player.main_mc.showAddBytesFace(0, 0, 0);
							var info:Object = {remainTimes:_remainTimes};
							var evt:TryPlayEvent = new TryPlayEvent(TryPlayEvent.FEE_SUCCESS,info);
							_player.dispatchEvent(evt);
							//暂停
							if (!_player.isStop)
							{
								CtrBarManager.instance.dispatchPause();
							}
							
							JTracer.sendMessage("SliceStreamBytes -> 时长用完导致播放停止, ygcid:" + Tools.getUserInfo("ygcid") + ", userid:" + Tools.getUserInfo("userid"));
							Tools.stat('f=fluxoutstop&gcid=' + Tools.getUserInfo("ygcid"));
						}
						break;
					case "6":
						//网络延迟范围内重复扣取
						break;
					case "7":
						//超过有效时长
						break;
				}
			}
			else
			{
				
			}
		}
		
		private function onFeeIOError():void
		{
			
		}
		
		private function onFeeSecurityError():void
		{
			
		}
		
		private function spliceCheckTime(time:Number):void
		{
			if (time <= 0 || _spliceTimeArr.length == 0) { return; }
			var tempCompare:Number = _spliceTimeArr[_curIndex + 1];
			var dexTime:Number = tempCompare - time;
			//JTracer.sendMessage("dexTime:" + dexTime + ", bytesLoaded/bytesTotal:" + this.bytesLoaded / this.bytesTotal + ", _preIndex:" + _preIndex + ", _curIndex:" + _curIndex + ", _isReloadNext:" + _isReloadNext);
			
			if (_player.bytesLoaded >= _player.bytesTotal && _player.bytesTotal < _player.sliceSize - 51200 && !isLostData && !GlobalVars.instance.isUseHttpSocket)
			{
				isLostData = true;
				
				var nearIndex:Number = getNearValueIndex(_byteArr, _player.sliceStart + _player.bytesTotal) + 1;
				nearIndex = nearIndex < 1 ? 1 : nearIndex;
				
				var lastTime:Number = _spliceTimeArr[_curIndex + 1];
				var lastPos:Number = _spliceByteArr[_curIndex + 1];
				var replaceTime:Number = _timeArr[nearIndex];
				var replacePos:Number = _byteArr[nearIndex];
				_spliceTimeArr[_curIndex + 1] = replaceTime;
				_spliceByteArr[_curIndex + 1] = replacePos;
				
				JTracer.sendMessage("SliceStreamBytes -> spliceCheckTime, lostData, replace pos, \nlastTime:" + lastTime + "\nlastPos:" + lastPos + "\nreplaceTime:" + replaceTime + "\nreplacePos:" + replacePos + "\nnearIndex:" + nearIndex + "\n_curIndex+1:" + (_curIndex + 1));
			}
			
			if (dexTime > 120 && !_player.isPause) {
				return;
			} else if (_player.bytesLoaded / _player.bytesTotal < 0.95) {
				return;
			} else if (_preIndex != _curIndex + 1 && !_isReloadNext && _hasNextStream) {
				isRetry = false;
				isLostData = false;
				_isReloadNext = true;
				preLoadNextStream();
				//GlobalVars.instance.isReplaceURL = false;
			}
			
			if (dexTime < 0.5 && time >= 20 && _totalTime - time >= 0.5 && _nextStream && (_nextStream.time > 0 || GlobalVars.instance.isUseHttpSocket)) {
				JTracer.sendMessage('SliceStreamBytes -> replaceNextStream, _spliceTimeArr[' + _preIndex + ']:' + _spliceTimeArr[_preIndex] + ', time:' + time);
				_player.replaceNextStream(_nextStream, _nextVideo, replaceCompeleteHandler, _onerror);
			} else {
				//_arrError.push('dextime:' + dexTime + ',time:' + time);
			}
		}
		
		private function preLoadNextStream():void
		{
			is_append_header = false;
			
			_onerror = null;
			_arrError = new Array();
			if (_curIndex >= _spliceByteArr.length - 2) { 
				return;
			}
			var metaObject:Object = new Object();
			metaObject.onMetaData = spliceOnMetaDataHandler;
			
			cn = new NetConnection();
			cn.connect(null);
			if (_nextStream != null) {
				_nextStream.removeEventListener(NetStatusEvent.NET_STATUS, nullNetStatusEventHandler);
				_nextStream.close();
				_nextStream = null;
			}
			_nextStream = new NetStream(cn);
			_nextStream.bufferTime = 0.001;
			_nextStream.client = metaObject;
			_nextStream.soundTransform = new SoundTransform(0);
			_nextStream.addEventListener(NetStatusEvent.NET_STATUS, nullNetStatusEventHandler);
			
			_huanNextStream = _nextStream;
			++id;
			__id = id;
			_nextVideo = new Video(_player.width, _player.height);
			_nextVideo.smoothing = true;
			_nextVideo.visible = false;
			_nextVideo.attachNetStream(_nextStream);
			_player.addChild(_nextVideo);
			
			_buffer = true;
			
			var start:Number = _curIndex == -1 ? (GlobalVars.instance.isUseHttpSocket ? StreamList.getHeader().length : 0) :_spliceByteArr[_curIndex + 1];
			var end:Number;
			if (_player.isPause)
			{
				_hasNextStream = false;
				end = _totalByte;
			}
			else
			{
				_hasNextStream = true;
				end = (_curIndex == _spliceByteArr.length - 3) ? _totalByte : _spliceByteArr[_curIndex + 2];
			}
			sliceStart = start;
			sliceSize = end - start;
			
			//loading_pos = start;
			loading_pos = _player.query_pos;
			loading_time = _curIndex == -1 ? 0 :_spliceTimeArr[_curIndex + 1];
			
			var suffixUrl:String = '&start=' +  start + "&end=" + end + "&type=normal&du=" + _player.vduration;
			var gdlUrl:String = _player.playUrl + suffixUrl;
			
			if (GlobalVars.instance.isUseSocket)
			{
				JTracer.sendMessage("SliceStreamBytes -> preLoadNextStream, connect socket");
				
				GetNextVodSocket.instance.connect(_player.playUrl, function(vod_url:String, utype:String, status_code:String, cost_time:int)
				{
					GlobalVars.instance.isChangeURL = false;
					
					if (!vod_url)
					{
						_player.vodUrl = null;
						JTracer.sendMessage("SliceStreamBytes -> preLoadNextStream, get vod url fail, gdl url:" + gdlUrl);
						_nextStream.play(gdlUrl);
					}
					else
					{
						_player.vodUrl = vod_url + suffixUrl;
						
						if (GlobalVars.instance.isUseHttpSocket)
						{
							current_pos = loading_pos;
							query_pos = loading_pos + socket_count * block_size;
							
							JTracer.sendMessage('SliceStreamBytes -> use socket, preLoadNextStream, get vod url success, vod url:' + vod_url + ", start_pos:" + loading_pos + ", end_pos:" + end + ", next_pos:" + query_pos);
							
							downloadStream(vod_url, loading_pos, end);
						}
						else
						{
							JTracer.sendMessage("SliceStreamBytes -> preLoadNextStream, get vod url success, vod url:" + _player.vodUrl);
							
							_nextStream.play(_player.vodUrl);
						}
					}
					
					_preIndex = _curIndex + 1;
				});
			}
			else
			{
				GlobalVars.instance.isChangeURL = false;
				
				_nextStream.play(gdlUrl);
				
				_preIndex = _curIndex + 1;
			}
			
			//_nextStream.pause();
			JTracer.sendMessage('SliceStreamBytes -> netstream preLoadNextStream, time=' + _player.time);
		}
		
		public function clearSocket():void
		{
			var i:uint;
			var socket:SingleSocket;
			for (i = 0; i < socket_array.length; i++)
			{
				socket = socket_array[i];
				socket.removeEventListener(SingleSocket.All_Complete, all_block_complete);
				//socket.removeEventListener(SingleSocket.Complete, block_complete);
				socket.removeEventListener(SingleSocket.SocketError, block_error);
				socket.clear();
				socket = null;
			}
			socket_array = [];
		}
		
		private function downloadStream(url:String, start_pos:uint, end_pos:uint):void
		{
			StreamList.clearNextList();
			
			clearSocket();
			
			var i:uint;
			var socket:SingleSocket;
			if (socket_array.length == 0)
			{
				for(i = 0; i < socket_count; i++)
				{
					socket = new SingleSocket(this, url, block_size, socket_count, start_pos + i * block_size, end_pos, end_pos - start_pos, GlobalVars.instance.type_nextstream);
					socket.addEventListener(SingleSocket.All_Complete, all_block_complete);
					//socket.addEventListener(SingleSocket.Complete, block_complete);
					socket.addEventListener(SingleSocket.SocketError, block_error);
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
					socket.setQueryRange(start_pos + i * block_size, end_pos, end_pos - start_pos);
					socket.connectSocket();
				}
			}
		}
		
		private function all_block_complete(evt:Event):void
		{
			var socket:SingleSocket = evt.currentTarget as SingleSocket;
			socket.clearSocket();
			var pos_obj:Object = socket.getCompletePos();
			
			_player.query_pos = query_pos;
			
			JTracer.sendMessage("SliceStreamBytes -> all_block_complete, start_pos:" + pos_obj.start_pos + ", end_pos:" + pos_obj.end_pos + ", next_pos:" + query_pos);
		}
		
		private function block_complete(evt:Event):void
		{
			if (!GlobalVars.instance.isUseHttpSocket)
			{
				return;
			}
			
			if (!_nextStream)
			{
				return;
			}
			
			if (!is_append_header)
			{
				is_append_header = true;
				
				_nextStream.play(null);
				_nextStream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
				_nextStream.appendBytes(StreamList.getHeader());
				_nextStream.appendBytesAction(NetStreamAppendBytesAction.RESET_SEEK);
				
				_nextVideo.attachNetStream(_nextStream);
			}
			
			var cur_bytes:ByteArray = StreamList.getBytes(GlobalVars.instance.type_nextstream, current_pos, current_pos + block_size - 1) as ByteArray;
			if (cur_bytes)
			{
				//trace("==========" + start_pos + " -> length:" + cur_bytes.length);
				_nextStream.appendBytes(cur_bytes);
				current_pos += block_size;
			}
		}
		
		private function block_error(evt:Event):void
		{
			var socket:SingleSocket = evt.currentTarget as SingleSocket;
			JTracer.sendMessage("SliceStreamBytes -> block_error, error_info:" + socket.getErrorInfo());
		}
		
		private function nullNetStatusEventHandler(event:NetStatusEvent = null):void
		{
			JTracer.sendMessage("SliceStreamBytes -> status:" + event.info.code);
			if (event.info.code == 'NetStream.Buffer.Full') {
				if (_nextStream != null) {
					JTracer.sendMessage('SliceStreamBytes -> NetStream.Buffer.Full');
					_buffer = false;
					checkStreamPlayStart();
				}
			} else if (event.info.code == 'NetStream.Play.Start') {
				JTracer.sendLoaclMsg('SliceStreamBytes -> NetStream.Play.Start');
			} else if (event.info.code == 'NetStream.Play.StreamNotFound') {
				JTracer.sendMessage('SliceStreamBytes -> NetStream.Play.StreamNotFound, 加载字节数:' + _nextStream.bytesLoaded);
				_onerror = '302';
				_nextStream.close();
				_nextStream = null;
				cn.close();
				cn = null;
				
				//重试
				if (!isRetry)
				{
					isRetry = true;
					
					_isReloadNext = true;
					preLoadNextStream();
				}
			}
		}
		
		private function clearPlayCheckTimer():void
		{
			if (_playCheckTimer != null) {
				_playCheckTimer.stop();
				_playCheckTimer.removeEventListener(TimerEvent.TIMER, playCheckTimerHandler);
				_playCheckTimer = null;
			}
		}
		
		private function checkStreamPlayStart():void
		{
			clearPlayCheckTimer();
			_playCheckTimer = new Timer(100, 0);
			_playCheckTimer.addEventListener(TimerEvent.TIMER, playCheckTimerHandler);
			_playCheckTimer.start();
		}

		private function playCheckTimerHandler(e:TimerEvent):void
		{
			if(_nextStream){
				JTracer.sendMessage('SliceStreamBytes -> playCheckTimerHandler at Stream:'+__id + " bufferLength:"+_nextStream.bufferLength + " bufferTime:"+_nextStream.bufferTime);
			}
			if (_nextStream && (_nextStream.time > Number(_spliceTimeArr[_preIndex]) + 0.1) || _playCheckTimer.currentCount > 20 * 10) {
				JTracer.sendMessage('SliceStreamBytes -> playCheckTimerHandler, _nextStream.pause, _nextStream.time:' + _nextStream.time + ', _spliceTimeArr[' + _preIndex + ']:' + _spliceTimeArr[_preIndex]);
				_nextStream.pause();
				clearPlayCheckTimer();
			}
		}
		
		private function spliceOnMetaDataHandler(info:Object):void {
			
		}
		
		public function spliceGetEndByte(startByte:Number):Number
		{
			if (_spliceInit == false) { return _totalByte; }
			var iIndex:int = 0;
			var nByteEnd:Number = 0;
			while (iIndex < _spliceByteArr.length - 1) {
				if (_spliceByteArr[iIndex] <= startByte && startByte < _spliceByteArr[iIndex + 1]) {
					nByteEnd = _spliceByteArr[iIndex + 1];
					JTracer.sendMessage("SliceStreamBytes -> spliceGetEndByte, find index:" + iIndex + ", nByteEnd:" + nByteEnd);
					break;
				}
				iIndex++;
			}
			JTracer.sendMessage('SliceStreamBytes -> spliceGetEndByte, startByte:' + startByte + ', nByteEnd:' + nByteEnd + ', _totalByte:' + _totalByte + ', _spliceByteArr[_spliceByteArr.length - 1]:' + _spliceByteArr[_spliceByteArr.length - 1]);
			if (iIndex == _spliceByteArr.length - 2) {
				nByteEnd = _totalByte;
			}
			nByteEnd = (nByteEnd == 0) ? _totalByte : nByteEnd;
			//处理影片时长小于10秒且只有两个关键帧的影片，计算影片总大小返回videoUrlArr[0].totalByte
			nByteEnd = (iIndex == 1 && _player.dragTime[1] == 0 && _player.dragTime.length == 2) ? _player.getVideoUrlArr[0].totalByte : nByteEnd;
			return nByteEnd;
		}
		
		public function spliceGetStartByte(startByte:Number):Number
		{
			var iIndex:int = 0;
			var nByteStart:Number = startByte;
			for (var i:int = 0, len:int = _spliceTimeArr.length; i < len; i++) {
				var nDex:Number = _spliceTimeArr[i] - startByte;
				if (nDex > 0 && nDex < 5) {
					nByteStart = _spliceTimeArr[i];
					break;
				}
			}
			return nByteStart;
		}
		
		public function spliceCheckStartTime(time:Number):Number
		{
			var iIndex:int = 0;
			var nTimeStart:Number = time;
			for (var i:int = 0, len:int = _spliceTimeArr.length; i < len; i++) {
				var nDex:Number = _spliceTimeArr[i] - time;
				if (nDex > 0 && nDex < 5) {
					nTimeStart = _spliceTimeArr[i];
					break;
				}
			}
			return nTimeStart;
		}
		
		public function spliceReplaceRightNow(time:Number):void
		{
			var dexTime:Number = _spliceTimeArr[_curIndex + 1] - time;
			JTracer.sendMessage("spliceTimeArr:[" + _spliceTimeArr.join(',') + "]");
			JTracer.sendMessage("dexTime:" + dexTime + " spliceTime:" + _spliceTimeArr[_curIndex + 1] + " playTime:"+time)
			if (time <= 0 || _spliceTimeArr.length == 0) { return; }
			if (dexTime < 0.5 && time >= 20) {
				_player.replaceNextStream(_nextStream, _nextVideo, replaceCompeleteHandler, _onerror);
			}
		}
		
		public function spliceUpdateArray(timeArr:Array, positionArr:Array):void
		{
			_timeArr = timeArr;
			_byteArr = positionArr;
			
			/*
			var tStr:String = "全部关键帧信息:";
			for (var j:* in _timeArr) {
				tStr += "\n" + "_timeArr[" + j + "]:" + _timeArr[j] + ",\t_byteArr[" + j + "]:" + _byteArr[j];
			}
			JTracer.sendMessage(tStr);
			*/
			//JTracer.sendMessage("timeArr: [" + timeArr.join(",") + "]");
			JTracer.sendMessage("SliceStreamBytes -> spliceUpdateArray, timeArr[" + (timeArr.length - 1) + "]:" + timeArr[timeArr.length - 1] + ", byteArr[" + (positionArr.length - 1) + "]:" + positionArr[positionArr.length - 1]);
			
			/*
			if (parseInt(timeArr[timeArr.length - 1]) - parseInt(timeArr[timeArr.length - 2]) <= 60)
			{
				timeArr[timeArr.length - 2] = timeArr[timeArr.length - 1];
				timeArr.pop();
				
				positionArr[positionArr.length - 2] = positionArr[positionArr.length - 1];
				positionArr.pop();
			}
			*/
			
			if (timeArr.length != positionArr.length || timeArr.length == 0) {
				JTracer.sendMessage('SliceStreamBytes -> spliceUpdateArray, timeArr.length != positionArr.length, can not match! timeArr.length:' + timeArr.length + ', positionArr.length:' + positionArr.length);
				return;
			}
			
			var idx:int = getNearValueIndex(timeArr, _sIntervalTime) + 1;
			JTracer.sendMessage('SliceStreamBytes -> spliceUpdateArray, 最接近的id:' + idx);
			var curInd:int = idx;
			var arrLen:int = timeArr.length;
			_spliceByteArr = [], _spliceTimeArr = [];
			_spliceByteArr.push(positionArr[0]);
			_spliceTimeArr.push(timeArr[0]);
			while (curInd < arrLen - 1 && idx > 0) {
				_spliceByteArr.push(positionArr[curInd]);
				_spliceTimeArr.push(timeArr[curInd]);
				curInd += idx;
			}
			_spliceByteArr.push(positionArr[arrLen - 1]);
			_spliceTimeArr.push(timeArr[arrLen - 1]);
			
			if (_firstByteEnd != 0 && _spliceByteArr.length > 2) {
				var firstIndex:Number = getNearValueIndex(positionArr, _firstByteEnd) + 1;
				firstIndex = firstIndex < 1 ? 1 : firstIndex;
				_spliceByteArr[1] = positionArr[firstIndex];
				_spliceTimeArr[1] = timeArr[firstIndex];
			}
			
			var str:String = "SliceStreamBytes -> spliceUpdateArray:";
			for (var i:* in _spliceTimeArr) {
				str += "\n" + "_spliceTimeArr[" + i + "]:" + _spliceTimeArr[i] + ",\t_spliceByteArr[" + i + "]:" + _spliceByteArr[i];
			}
			JTracer.sendMessage(str);
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
		
		public function replaceCompeleteHandler():void
		{
			JTracer.sendMessage("SliceStreamBytes -> replaceCompeleteHandler")
			_player.sliceStart = sliceStart;
			_player.sliceSize = sliceSize;
			_isReloadNext = false;
			_isReplaceNext = true;
			if (_nextStream)
			{
				_nextStream.removeEventListener(NetStatusEvent.NET_STATUS, nullNetStatusEventHandler);
			}
			_nextStream = null;
			_nextVideo = null;
			_curIndex = _preIndex;
			clearPlayCheckTimer();
			if(cn){
				cn.close();
				cn = null;
			}
			_onerror = null;
			_buffer = false;
		}
		
		public function spliceUpdate(time:Number):void
		{
			var i:int = 0, len:int = _spliceTimeArr.length;
			for (i = 0; i < len; i++) {
				if (_spliceTimeArr[i] > time) {
					//var j:int = (i == len - 1) ? len : i;//去除最后一段
					setCurIndex(i, time);
					break;
				}
				else
				{
					if (i == _spliceTimeArr.length - 1)
					{
						setCurIndex(i, time);
						break;
					}
				}
			}
		}
		
		private function setCurIndex(idx:int, time:Number):void
		{
			_curIndex = idx - 1;
			_preIndex = idx - 1;
			if (_nextStream) {
				_nextStream.close();
				_nextStream = null;
			}
			if (cn) {
				cn.close();
				cn = null;
			}
			_onerror = null;
			_buffer = false;
			_isReloadNext = false;
			clearPlayCheckTimer();
			JTracer.sendMessage('SliceStreamBytes -> spliceUpdate after seek! _curIndex:' + _curIndex + ', time:' + time);
		}
		
		public function clear():void
		{
			JTracer.sendMessage("SliceStreamBytes -> clear");
			_spliceByteArr = [];
			_spliceTimeArr = [];
			_curIndex = 0;
			_preIndex = 0;
			_firstByteEnd = 0;
			if (_nextStream)
			{
				_nextStream.close();
				_nextStream = null;
			}
			if (cn) {
				cn.close();
				cn = null;
			}
			clearPlayCheckTimer();
			clearSocket();
			_onerror = null;
			_buffer = false;
			_isReloadNext = false;
			_isReplaceNext = false;
			if (_spliceCheckTimer) {
				_spliceCheckTimer.removeEventListener(TimerEvent.TIMER, spliceCheckTimeHandler);
				_spliceCheckTimer.stop();
				_spliceCheckTimer = null;
			}
		}
		
		public function get bufferStartTime():Number
		{
			JTracer.sendMessage("SliceStreamBytes -> bufferStartTime, _curIndex:" + _curIndex);
			return _spliceTimeArr[_curIndex] || 0;
		}
		
		public function get bufferEndTime():Number
		{
			var idx:int = !_isReloadNext ? _curIndex + 2 : _curIndex + 1;
			//处理影片时长小于10秒且只有两个关键帧的影片，计算缓冲结束点返回总时长
			if (idx == 1 && _spliceTimeArr[1] == 0 && _spliceTimeArr.length == 2)
			{
				return _totalTime;
			}
			return _spliceTimeArr[idx] || _spliceTimeArr[_spliceTimeArr.length - 1];
		}
		
		public function set firstByteEnd(byte:Number):void
		{
			JTracer.sendMessage('SliceStreamBytes -> firstByteEnd:' + byte);
			_firstByteEnd = byte;
		}
		
		public function set sliceTime(interval:Number):void
		{
			_sIntervalTime = interval < 30 ? 30 : interval;
			_spliceInit = true;
			JTracer.sendMessage('SliceStreamBytes -> sliceTime:' + interval);
		}
		
		public function get spliceInit():Boolean
		{
			return _spliceInit;
		}
		
		public function set totalByte(num:Number):void
		{
			_totalByte = num;
		}
		
		public function set totalTime(num:Number):void
		{
			_totalTime = num;
		}
		
		public function get arrError():Array
		{
			return _arrError;
		}
		
		public function get buffer():Boolean
		{
			return _buffer;
		}
		
		//luoyuqiang
		public function get nextStream():NetStream { return _nextStream; }
		
		public function get sliceStartTime():Number
		{
			return _spliceTimeArr[_curIndex];
		}
		
		public function get sliceEndTime():Number
		{
			if (!_hasNextStream && !_isReloadNext)
			{
				return _totalTime;
			}
			
			var idx:int = _curIndex + 1;
			//处理影片时长小于10秒且只有两个关键帧的影片，计算缓冲结束点返回总时长
			if (idx == 1 && _spliceTimeArr[1] == 0 && _spliceTimeArr.length == 2)
			{
				return _totalTime;
			}
			return _spliceTimeArr[idx] || _spliceTimeArr[_spliceTimeArr.length - 1];
		}
		
		public function get sliceEnd2Time():Number
		{
			if (!_hasNextStream)
			{
				return _totalTime;
			}
			
			var idx:int = _curIndex + 2;
			if (idx >= _spliceTimeArr.length)
			{
				return _totalTime;
			} else {
				return _spliceTimeArr[idx];
			}
		}
		
		public function get nextVideo():Video { return _nextVideo; }
		
		public function get isReloadNext():Boolean { return _isReloadNext; }
		
		public function get isReplaceNext():Boolean { return _isReplaceNext; }
		
		public function set isReplaceNext(value:Boolean):void
		{
			_isReplaceNext = value;
		}
		
		public function get huanNextStream():NetStream { return _huanNextStream; }
		
		public function set hasNextStream(value:Boolean):void
		{
			_hasNextStream = value;
		}
		
		public function get loadingPos():Number
		{
			return loading_pos;
		}
		
		public function get loadingTime():Number
		{
			return loading_time;
		}
	}
}