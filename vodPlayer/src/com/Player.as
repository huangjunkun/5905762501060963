package com
{
	import flash.display.*;
	import flash.events.*;
	import flash.external.*;
	import flash.geom.*;
	import flash.media.*;
	import flash.net.*;
	import flash.system.*;
	import flash.utils.*;
	import com.common.*;
	import com.slice.*;
	import com.global.*;
	import com.serialization.json.JSON;
	import zuffy.events.*;
	import zuffy.display.statuMenu.VideoMask;
	import zuffy.core.PlayerCtrl;
	
	public class Player extends Sprite
	{
		public static const SET_QUALITY:String = "set quality";
		public static const AUTO_PLAY:String = "auto play";
		public static const INIT_PAUSE:String = "init pause";
		public var streamInPlay:NetStream;//当前正在使用的视频流
		public var isStop:Boolean = false;
		public var isStartPause:Boolean = true;
		public var swf_width:Number;
		public var swf_height:Number;
		public var isPause:Boolean;
		public var nomarl_width:int;
		public var nomarl_height:int;
		public var nomarl_x:int;
		public var nomarl_y:int;
		public var v_w:uint;
		public var v_h:uint;
		public var customClient:Object;
		public var dragTime:Array = [];
		public var dragPosition:Array = [];
		public var startTimer:Number;
		private var bufferStart:Number = 0;			//socket专用
		private var bufferStartTime:Number = 0;
		public var bufferEndTime:Number = 0;
		public var fixedTime:Number = -1;
		public var fixedByte:Number = 0;
		public var main_mc:PlayerCtrl;
		public var downLoadTimer:Timer;
		public var myTimer:Timer;					//onProgress计时器
		private var _totalTime:int;
		private var _sliceStream:SliceStreamBytes;
		private var _streamMetaData:StreamMetaData;
		private var _streamStartByte:Number = 0;
		private var _streamEndByte:Number = 0;
		private var _streamStartTime:Number = 0;
		private var _avarageSpeedArray:Array = [];	//平均速度数组
		private var _totalSpeedArray:Array = [];	//全部速度数组
		private var _isSubmitSpeed:Boolean;			//是否上报过速度
		private var _isResetStart:Boolean;			//是否重置过videoUrlArr[0].start = 0
		private var _isInvalidTime:Boolean;			//是否无效时间
		private var _urlType:String = "normal";		//视频地址type，normal-正常，changeformat-切换清晰度，loadmetadata-加载索引，lostdata-断线重连，preview-进度条预览
		private var _timePlayed:Number = 0;			//播放时长，单位毫秒
		private var _curTimePlayed:Number = 120;	//当前已播放时长，2分钟，单位秒
		private var _timeDownload:Number = 0;		//下载时长
		private var _gdlUrl:String;					//gdl地址
		private var _originGdlUrl:String;			//原始gdl地址
		private var _suffixUrl:String;
		private var _vodUrl:String;					//vod地址
		private var _playUrl:String;
		private var _lastUrl:String;
		private var __old__currentSeq:int;
		private var _currentPlayID:String;
		private var __old__statLoader:URLLoader;
		private var _highSpeedSpeedArray:Array = [];//判断是否有更高清晰度速度数组
		private var _isStartHighSpeedTimer:Boolean;	//是否开始有更高清晰度提示计时
		private var socket_count:uint = 4;			//socket链接个数
		private var socket_array:Array = [];		//socket对象数组
		private var block_size:uint = 128 * 1024;	//socket请求的分块大小
		private var current_pos:uint;				//socket下载开始点
		private var is_append_header:Boolean;
		private var is_seek_finish:Boolean = true;
		private var appendTimer:Timer;
		private var isSpliceUpdate:Boolean;
		private var playTimeHeadIndex:Number;
		
		//多链将要下载的所有数据，用于显示进度比例.
		private var _preloadBytesTotal:uint = 0;

		//多链重新下数据时间点
		private var _nextDownLoadTime:Number = 0;

		//多链重新下数据时间点,用于显示缓冲进度.
		private var socketStartDownloadTime:Number = 0;

		//private var fileRef:FileReference = new FileReference();
		//private var fileBytes:ByteArray = new ByteArray();
		
		public static var p2p_type:String = "p2p";//"p2p", "dap"

		public var query_pos:uint;
		public var is_invalid_time:Boolean = true;
		public var sliceSize:uint;//切片总大小
		public var sliceStart:uint;//切片开始点

		private var _retryLastTimeStat:String = "";
		public function get retryLastTimeStat():String{
			var ret = _retryLastTimeStat;
			//一次最终上报
			if(ret != "") _retryLastTimeStat = "";
			return ret;
		}
		public function set retryLastTimeStat(val:String):void{
			_retryLastTimeStat = val;
		}
		public var playEnd:Boolean = false;
		
		public function Player(w:Number, h:Number, fc:Number, p:PlayerCtrl)
		{
			super();
			main_mc = p;
			swf_width = w;
			swf_height = h;
			addPlayEventHandler();
			fnOnProgress();
			this.mouseEnabled = false;
			this.mouseChildren = false;
			playEnd = false;
			_sliceStream = new SliceStreamBytes(this);
			_streamMetaData = new StreamMetaData(this);
			_streamMetaData.addEventListener(StreamMetaData.KEYFRAME_ERROR, streamMetaDataHandler);
			_streamMetaData.addEventListener(StreamMetaData.KEYFRAME_LOADED, streamMetaDataHandler);
		}
		
		private function streamMetaDataHandler(e:Event):void
		{
			if (e.type == StreamMetaData.KEYFRAME_ERROR) {
				_errorInfo = '301';
				JTracer.sendMessage("Player -> onErrorInfo, code:" + _errorInfo);
				main_mc.showPlayError(_errorInfo);
				Tools.stat("f=playerror&e=" + _errorInfo + "&gcid=" + Tools.getUserInfo("ygcid") + this.retryLastTimeStat);
				ExternalInterface.call("flv_playerEvent", "onErrorInfo", _errorInfo);
			}else if (e.type == StreamMetaData.KEYFRAME_LOADED) {
				var endByte:Number = Math.round(videoUrlArr[0].sliceTime * videoUrlArr[0].totalByte / videoUrlArr[0].totalTime);
				
				_streamMetaData.firstByteEnd = endByte;
				_streamMetaData.totalByte = totalByte;
				_streamMetaData.sliceTime = videoUrlArr[0].sliceTime;
				_streamMetaData.spliceUpdateArray();
				
				_streamStartByte = _streamMetaData.getStartByte(videoUrlArr[0].start);
				_streamStartTime = _streamMetaData.getStartTime(videoUrlArr[0].start);
				_streamEndByte = _streamMetaData.getSpliceEndByte(videoUrlArr[0].start);
				
				connectStream();
			}
		}
		//音量调节
		private function fnOnEnterFrame():void
		{
			if (streamInPlay)
			{
				if (!main_mc._ctrBar.isVolume)
				{
					this.volum = 0;
					return;
				}
				var _so:SharedObject=SharedObject.getLocal("kkV");
				var vv:Number = _so.data.v ? _so.data.v : (main_mc._ctrBar.cacheVolume);
				this.volum = vv;
			}
		}
		
		private function fnOnProgress():void
		{
			myTimer = new Timer(1000, 0);
			myTimer.addEventListener("timer", function():void {ExternalInterface.call("flv_playerEvent", "onProgress");});
		}
		
		public function setPlayUrl(arr:Array):void 
		{
			startTimer = getTimer();
			is_seek_finish = true;
			_streamStartByte = 0;
			_streamStartTime = 0;
			_isSubmitSpeed = false;
			_isResetStart = false;
			if (_isChangeQuality) {
				_urlType = "changeformat";
			}
			else
			{
				_urlType = "normal";
				//开始新的影片时，把速度清空，播放时长置0，切换清晰度不清空
				_totalSpeedArray = [];
				_avarageSpeedArray = [];
				_timePlayed = 0;
				//当前上报次序
				__old__currentSeq = 1;
				//当前播放id
				_currentPlayID = "";
			}
			videoUrlArr = arr;
			playUrl = getNextUrl();
			lastUrl = playUrl;
			GlobalVars.instance.isVodGetted = false;
			//链接是否为ip形式，如果是直接用netStream播放;
			var matchs:Array;
			if( matchs = playUrl.match(/^http:\/\/\d+\.\d+\.\d+\.\d+/) ){
				GlobalVars.instance.vodAddr = matchs[0].substr(7);
				JTracer.sendMessage('host:' + GlobalVars.instance.vodAddr)
				GlobalVars.instance.isIPLink = true;
			}
			if(matchs = playUrl.match(/&cc=[^&]+/)){
				GlobalVars.instance.statCC = matchs[0];
			}
			JTracer.sendMessage("Player -> setPlayUrl, get next play url:" + playUrl);
			
			var autoplay:int = videoUrlArr[0].autoplay;
			if (autoplay == 0)
			{
				dispatchEvent(new Event(INIT_PAUSE));
				isStop = false;
				isPause = false;
				isStartPause = true;
			} else if (autoplay == 1){
				dispatchEvent(new Event(AUTO_PLAY));
				isStop = false;
				isPause = false;
				isStartPause = false;
				play();
			} else if (autoplay == 2) {
				
			} else if (autoplay == 4) {
				
			}
			
			main_mc._ctrBar.formatShowBtn = arr[0].format || 'p';
			dispatchEvent(new ControlEvent(ControlEvent.SHOW_CTRBAR, 'show'));
		}
		
		private function initialConnection():void
		{
			if (myConnection)
			{
				myConnection.close();
				myConnection = null;
			}
			myConnection = new NetConnection();
			myConnection.connect(null);
		}

		private function initialStream():void
		{
			if (customClient)
			{
				customClient = null;
			}
			customClient = new Object();
			customClient.onMetaData = metaDataHandler(this);
			
			if (streamInPlay)
			{
				streamInPlay.close();
				streamInPlay.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				streamInPlay = null;
			}
			streamInPlay = new NetStream(myConnection);
			streamInPlay.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			streamInPlay.client = customClient;
			streamInPlay.bufferTime = _bufferTime;
			streamInPlay.soundTransform = new SoundTransform(0);
		}
		
		private function initialVideo():void 
		{
			if (classicVideo)
			{
				removeChild(classicVideo);
				classicVideo.clear();
				classicVideo = null;
			}
			classicVideo = new Video();
			classicVideo.visible = true;
			classicVideo.smoothing = true;
			classicVideo.width = this.width;
			classicVideo.height = this.height;
			dispatchEvent(new PlayEvent(PlayEvent.INIT_STAGE_VIDEO));
		}
		
		private function initialDownLoadTimer():void {
			if (downLoadTimer == null)
			{
				downLoadTimer = new Timer(1000);
				downLoadTimer.addEventListener(TimerEvent.TIMER, handleDoanLoadTimer);	
				downLoadTimer.start();
			}
		}
		
		private function initialAppendTimer():void {
			if (appendTimer == null)
			{
				appendTimer = new Timer(200);
				appendTimer.addEventListener(TimerEvent.TIMER, handleAppendTimer);
				appendTimer.start();
			}
		}
		
		private function addPlayEventHandler():void
		{
			this.addEventListener(PlayEvent.PLAY,playEventHandler);
			this.addEventListener(PlayEvent.STOP,playEventHandler);
			this.addEventListener(PlayEvent.PAUSE, playEventHandler);
			this.addEventListener(PlayEvent.REPLAY, playEventHandler);
		}
		
		public function playEventHandler(e:PlayEvent):void
		{
			switch(e.type){
				case 'Pause':pause();break;
				case 'Play':play(); break;
				case 'Stop':stop(); break;
				case 'Replay':replay(); break;
				case 'PlayStart':playStart(); break;
			}
		}
		public function pause():void
		{
			if(GlobalVars.instance.isXLNetStreamValid == 1){
				p2p_pause();
				return;
			}
			JTracer.sendMessage("Player -> pause");
			if (myTimer)
			{
				myTimer.start();
			}
			_status = 1;
			if (streamInPlay)
			{
				streamInPlay.pause();
			}
			isStop = false;
			isPause = true;
			isStartPause = false;
			ExternalInterface.call("flv_playerEvent","onPlayStatusChanged");
		}
		public function p2p_pause():void
		{
			JTracer.sendMessage("Player -> pause");
			if (myTimer)
			{
				myTimer.start();
			}
			_status = 1;
			if (streamInPlay)
			{
				streamInPlay.pause();
			}
			isStop = false;
			isPause = true;
			isStartPause = false;
			ExternalInterface.call("flv_playerEvent","onPlayStatusChanged");
		}

		public function play():void 
		{
			JTracer.sendMessage('Player -> isXLNetStreamValid:'+GlobalVars.instance.isXLNetStreamValid)
			
			if (!videoUrlArr || videoUrlArr.length == 0)
			{
				return;
			}
			
			JTracer.sendMessage("Player -> play");
			if (myTimer)
			{
				myTimer.start();
			}
			_status = 0;
			ExternalInterface.call("flv_playerEvent", "onPlayStatusChanged");
			initialDownLoadTimer();
			initialAppendTimer();
			if((streamInPlay && streamInPlay.time > 0 && isStop == false ) || isPause== true )
			{
				if (streamInPlay)
				{
					streamInPlay.resume();
				}
				ExternalInterface.call("flv_playerEvent", "onplaying");
				JTracer.sendMessage('Player -> onplaying');
			}else {
				dispatchEvent(new PlayEvent(PlayEvent.PLAY_NEW_URL));
				if (videoUrlArr[0].start > 0) {
				JTracer.sendMessage("Player -> play, netstream, loadMetaData");
					if (_streamMetaData)
					{
						_streamMetaData.loadMetaData(playUrl, vduration);
					}
				} else {
					JTracer.sendMessage("Player -> play, connectStream");
					connectStream();
				}
			}
			isStop = false;
			isPause = false;
			isStartPause = false;
			main_mc.isStopNormal = false;
		}

		private function p2p_replay():void {
		 if (!videoUrlArr || videoUrlArr.length == 0)
			{
				return;
			}
			
			JTracer.sendMessage("Player -> replay");
			if (myTimer)
			{
				myTimer.start();
			}
			_status = 3;
			ExternalInterface.call("flv_playerEvent","onPlayStatusChanged");
			initialDownLoadTimer();
			
			if (main_mc._ctrBar._timerBP && main_mc._ctrBar._timerBP.running == false) 
			{
				main_mc._ctrBar._timerBP.start();
			}
			
			videoUrlArr[0].start = 0;
			_isResetStart = true;
			_streamStartByte = 0;
			connectStream();
			
			isStop = false;
			isPause = false;
			isStartPause = false;
			main_mc.isStopNormal = false;
		}

		private function replay():void {
		 if(GlobalVars.instance.isXLNetStreamValid == 1)
			{
				p2p_replay()
				return;
			}
			if (!videoUrlArr || videoUrlArr.length == 0)
			{
				return;
			}
			
			JTracer.sendMessage("Player -> replay");
			if (myTimer)
			{
				myTimer.start();
			}
			_status = 3;
			ExternalInterface.call("flv_playerEvent","onPlayStatusChanged");
			initialDownLoadTimer();
			initialAppendTimer();
			
			if (main_mc._ctrBar._timerBP && main_mc._ctrBar._timerBP.running == false) 
			{
				main_mc._ctrBar._timerBP.start();
			}
			
			videoUrlArr[0].start = 0;
			_isResetStart = true;
			_streamStartByte = 0;
			connectStream();
			
			isStop = false;
			isPause = false;
			isStartPause = false;
			main_mc.isStopNormal = false;
		}
		public function p2p_stop():void {
			JTracer.sendMessage("Player -> p2p_stop");
			_status = 2;
			if (myTimer)
			{
				myTimer.stop();
			}
			if (streamInPlay)
			{
				streamInPlay.seek(0);
				streamInPlay.close();
			}
			if (classicVideo)
			{
				classicVideo.clear();
				//10.0版本的flashplayer无法clear，导致重播时有之前的画画，所以要remove
				if(contains(classicVideo))
				{
					removeChild(classicVideo);
				}
				classicVideo = null;
			}
			
			this.visible = false;
			//影片停止播放了，或者切换不同清晰度的影片，停止_timerBP，播放后再开始
			if (main_mc._ctrBar._timerBP && main_mc._ctrBar._timerBP.running) 
			{
				main_mc._ctrBar._timerBP.stop();
			}
			isStop = true;
			isStartPause = false;
			bufferStart = 0;
			bufferStartTime = 0;
			fixedByte = 0;
			_streamStartByte = 0;
			_streamEndByte = 0;
			_progressCacheTime = 0;
			if (_streamMetaData)
			{
				_streamMetaData.clear();
			}
			if (_sliceStream)
			{
				_sliceStream.clear();
			}
			//停止影片时重置videoUrlArr[0].start=0，重播时从0点播放
			if (videoUrlArr && videoUrlArr.length > 0)
			{
				videoUrlArr[0].start = 0;
				_isResetStart = true;
			}
			ExternalInterface.call("flv_playerEvent", "onPlayStatusChanged");
		}
		public function stop():void {
			if(GlobalVars.instance.isXLNetStreamValid == 1){
				p2p_stop();
				return;
			}
			JTracer.sendMessage("Player -> stop");
			_status = 2;
			if (myTimer)
			{
				myTimer.stop();
			}
			if (streamInPlay)
			{
				streamInPlay.seek(0);
				streamInPlay.close();
			}
			if (classicVideo)
			{
				classicVideo.clear();
				//10.0版本的flashplayer无法clear，导致重播时有之前的画画，所以要remove
				if(contains(classicVideo))
				{
					removeChild(classicVideo);
				}
				classicVideo = null;
			}
			closeNetConnection();
			clearSocket();
			this.visible = false;
			//影片停止播放了，或者切换不同清晰度的影片，停止_timerBP，播放后再开始
			if (main_mc._ctrBar._timerBP && main_mc._ctrBar._timerBP.running) 
			{
				main_mc._ctrBar._timerBP.stop();
			}
			isStop = true;
			isStartPause = false;
			bufferStart = 0;
			bufferStartTime = 0;
			fixedByte = 0;
			_streamStartByte = 0;
			_streamEndByte = 0;
			_progressCacheTime = 0;
			if (_streamMetaData)
			{
				_streamMetaData.clear();
			}
			if (_sliceStream)
			{
				_sliceStream.clear();
			}
			//停止影片时重置videoUrlArr[0].start=0，重播时从0点播放
			if (videoUrlArr && videoUrlArr.length > 0)
			{
				videoUrlArr[0].start = 0;
				_isResetStart = true;
			}
			ExternalInterface.call("flv_playerEvent", "onPlayStatusChanged");
		}
		
		public function stopError():void {
			JTracer.sendMessage("Player -> stopError");
			_status = 2;
			if (myTimer)
			{
				myTimer.stop();
			}
			if (streamInPlay)
			{
				streamInPlay.seek(0);
				streamInPlay.close();
			}
			if (classicVideo)
			{
				classicVideo.clear();
				//10.0版本的flashplayer无法clear，导致重播时有之前的画画，所以要remove
				if(contains(classicVideo))
				{
					removeChild(classicVideo);
				}
				classicVideo = null;
			}
			closeNetConnection();
			clearSocket();
			this.visible = false;
			//影片停止播放了，或者切换不同清晰度的影片，停止_timerBP，播放后再开始
			if (main_mc._ctrBar._timerBP && main_mc._ctrBar._timerBP.running) 
			{
				main_mc._ctrBar._timerBP.stop();
			}
			isStop = true;
			isStartPause = false;
			bufferStart = 0;
			bufferStartTime = 0;
			fixedByte = 0;
			_streamStartByte = 0;
			_streamEndByte = 0;
			_progressCacheTime = 0;
			if (_streamMetaData)
			{
				_streamMetaData.clear();
			}
			if (_sliceStream)
			{
				_sliceStream.clear();
			}
			ExternalInterface.call("flv_playerEvent", "onPlayStatusChanged");
		}
		
		public function get volum():Number
		{
			return _currVolum;
		}
		
		public function set volum(vol:Number):void 
		{
			_currVolum = vol;
			if(streamInPlay){
				streamInPlay.soundTransform = new SoundTransform(_currVolum);
			}
		}
		
		public function get totalByte():Number
		{
			var _totalByte:Number = 0;
			
			var tmpArr:Array = [];
			if (dragPosition && dragPosition.length > 0 && dragPosition[dragPosition.length - 1] > 0)
			{
				tmpArr.push(dragPosition[dragPosition.length - 1]);
			}
			if (videoUrlArr && videoUrlArr.length > 0 && videoUrlArr[0].totalByte > 0)
			{
				tmpArr.push(videoUrlArr[0].totalByte);
			}
			if (tmpArr.length > 0)
			{
				tmpArr = tmpArr.sort(Array.NUMERIC);
				_totalByte = tmpArr[tmpArr.length - 1];
				//JTracer.sendMessage('get totalByte:[' + tmpArr.join(',')+']')
			}
			
			return _totalByte;
		}
		
		public function get vduration():Number
		{
			return totalTime <= 0 ? videoUrlArr[0].totalTime : totalTime;
		}
		
		public function get totalTime():Number
		{
			return _totalTime;
		}
		
		public function get time():Number
		{
			if (!streamInPlay) return -1;
			if (GlobalVars.instance.isUseHttpSocket)
			{
				return streamInPlay.time + bufferStart;
			}
			
			if (_progressCacheTime != 0)
			{
				return _progressCacheTime;
			} else {
				return streamInPlay.time;
			}
		}
		
		public function get playStatus():Number
		{
			return _status;
		}
		
		public function get playProgress():Number
		{
			return Math.floor(time * 100 / totalTime);
		}
		
		public function get downloadProgress():Number
		{	
			// 正在下载下一个分片
			if (_sliceStream && _sliceStream.nextStream && _sliceStream.isReloadNext)//已经在缓冲下一个切片了
			{
				bufferEndTime = _sliceStream.sliceEndTime + _sliceStream.bytesLoaded * (_sliceStream.sliceEnd2Time - _sliceStream.sliceEndTime) / _sliceStream.bytesTotal;
				//JTracer.sendMessage("0 _sliceStream.sliceEnd2Time:" + _sliceStream.sliceEnd2Time + ", _sliceStream.sliceEndTime:" + _sliceStream.sliceEndTime + ", _sliceStream.bytesLoaded:" + _sliceStream.bytesLoaded + ", _sliceStream.bytesTotal:" + _sliceStream.bytesTotal);
			}

			// 正在下当前分片
			else if(_sliceStream)
			{
				if (_sliceStream.isReplaceNext && GlobalVars.instance.isUseHttpSocket)
				{
					bufferEndTime = bufferStartTime + _sliceStream.bytesLoaded * (_sliceStream.sliceEndTime - bufferStartTime) / _sliceStream.bytesTotal;
				}
				else
				{
					bufferEndTime = bufferStartTime + this.bytesLoaded * (_sliceStream.sliceEndTime - bufferStartTime) / this.bytesTotal;
				}
				//JTracer.sendMessage("1 streamInPlay.bytesLoaded:" + this.bytesLoaded + ", streamInPlay.bytesTotal:" + this.bytesTotal + ", _sliceStream.sliceEndTime:" + _sliceStream.sliceEndTime + ", time:" + time + ", bufferStartTime:" + bufferStartTime);
			}

			// 多链
			if (GlobalVars.instance.isUseHttpSocket)
			{
				bufferEndTime = bufferStartTime + (totalTime - socketStartDownloadTime) * this.bytesLoaded / _preloadBytesTotal;
				//JTracer.sendMessage('sliceEndTime:'+_sliceStream.sliceEndTime+' loaded:'+this.bytesLoaded+' total:'+this.bytesTotal)
			}

			// p2p
			else if(GlobalVars.instance.isXLNetStreamValid == 1){
				//JTracer.sendMessage('bytesLoaded:'+streamInPlay.bytesLoaded + 'bytesTotal:'+streamInPlay.bytesTotal);
				bufferEndTime = streamInPlay.bytesLoaded * totalTime / streamInPlay.bytesTotal;
			}

			return bufferEndTime / totalTime;
		}
		
		public function get downloadSpeed():Number
		{
			return Math.round(mySpeed);
		}
		
		public function get timePlayed():Number
		{
			return _timePlayed;
		}
		
		private function __old__statPlayTime():void
		{
			var userid:String = Tools.getUserInfo("userid");
			var gcid:String = Tools.getUserInfo("ygcid");
			var du:String = totalTime.toString();
			var long:String = (_timePlayed / 1000).toString();
			var seq:int = __old__currentSeq;
			var from:String = Tools.getUserInfo("from");
			
			var req:URLRequest;
			if (__old__currentSeq > 1)
			{
				req = new URLRequest("http://act.vod.xunlei.com/act/report_play_info?id=" + _currentPlayID + "&userid=" + userid + "&gcid=" + gcid + "&du=" + du + "&long=" + long + "&seq=" + seq + "&from=" + from);
			}
			else
			{
				req = new URLRequest("http://act.vod.xunlei.com/act/report_play_info?userid=" + userid + "&gcid=" + gcid + "&du=" + du + "&long=" + long + "&seq=" + seq + "&from=" + from);
			}
			
			if (!__old__statLoader)
			{
				__old__statLoader = new URLLoader();
				__old__statLoader.addEventListener(Event.COMPLETE, __old__onStatLoaded);
				__old__statLoader.addEventListener(IOErrorEvent.IO_ERROR, __old__onStatIOError);
				__old__statLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, __old__onStatSecurityError);
			}
			__old__statLoader.load(req);
			
			__old__currentSeq += 1;
		}
		
		private function __old__onStatLoaded(evt:Event):void
		{
			var jsonStr:String = String(evt.target.data);
			JTracer.sendMessage("Player -> __old__onStatLoaded, 上报后的返回值:" + jsonStr);
			var jsonObj:Object = com.serialization.json.JSON.deserialize(jsonStr) || { };
			if (jsonObj && jsonObj.resp && String(jsonObj.resp.ret) == "0")
			{
				_currentPlayID = jsonObj.resp.id;
			}
		}
		
		private function __old__onStatIOError(evt:IOErrorEvent):void
		{
			JTracer.sendMessage("Player -> __old__onStatIOError");
		}
		
		private function __old__onStatSecurityError(evt:SecurityErrorEvent):void
		{
			JTracer.sendMessage("Player -> __old__onStatSecurityError");
		}
		
		public function get bytesLoaded():Number
		{
			if (GlobalVars.instance.isUseHttpSocket)
			{
				var loaded_lenght:uint;
				var i:uint;
				var socket:SingleSocket;
				for (i = 0; i < socket_array.length; i++)
				{
					socket = socket_array[i];
					loaded_lenght += socket.bytesLoaded;
				}
				
				return loaded_lenght;
			}
			if(streamInPlay){
				return streamInPlay.bytesLoaded;
			}
			else{
				return 0;
			}
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
			
			return streamInPlay.bytesTotal;
		}
		
		private function handleDoanLoadTimer(event:TimerEvent):void {
			//检查是否登陆有效
			_timeDownload++;
			if (_timeDownload > 5 * 60 * 60)
			{
				_timeDownload = 0;
				main_mc.isValid = false;
			}
			
			//系统时间
			main_mc.setSystemTime();

			//实际播放时长
			if (!isPause && !isStop && !main_mc.isBuffering)
			{
				_timePlayed += downLoadTimer.delay;
			}
			
			var bytesLoaded:Number = 0;
			var bytesTotal:Number = 0;
			if (streamInPlay) {
				if ((_sliceStream.nextStream && _sliceStream.bytesLoaded > 0) || (_sliceStream.isReplaceNext && GlobalVars.instance.isUseHttpSocket))
				{
					bytesLoaded = _sliceStream.bytesLoaded;
					bytesTotal = _sliceStream.bytesTotal;
					
					if (_isLoadedNextStream)
					{
						preBufferLoaded = 0;
						_isLoadedNextStream = false;
					}
					mySpeed = (_sliceStream.bytesLoaded - preBufferLoaded) / 1024;
					if (mySpeed <= 0)
					{
						mySpeed = 0;
					}
					preBufferLoaded = _sliceStream.bytesLoaded;
				}
				else
				{
					bytesLoaded = this.bytesLoaded;
					bytesTotal = this.bytesTotal;
					
					_isLoadedNextStream = true;
					mySpeed = (this.bytesLoaded - preBufferLoaded) / 1024;						
					
					if (mySpeed <= 0)
					{
						mySpeed = 0;
					}
					preBufferLoaded = this.bytesLoaded;
				}
			} else {
				mySpeed = 0;
			}
			
			_totalSpeedArray.push(mySpeed);
			//20次（秒）上报一次;
			var times2StatPeriod:int = 20;
			//平均速度
			if (_avarageSpeedArray.length < times2StatPeriod)
			{
				_avarageSpeedArray.push(mySpeed);
			}
			else
			{
				if (!_isSubmitSpeed)
				{
					_isSubmitSpeed = true;
					
					var totalSpeed:Number = 0;
					var i:*;
					for (i in _avarageSpeedArray)
					{
						totalSpeed += _avarageSpeedArray[i];
					}
					var len:uint = times2StatPeriod - getZeroSpeedNum(_avarageSpeedArray);
					if (len > 0)
					{
						var avaSpeed:Number = totalSpeed / len;
						
						JTracer.sendMessage("平均速度:" + avaSpeed);
						Tools.stat("f=playspeed&gcid=" + Tools.getUserInfo("ygcid") + "&s=" + avaSpeed + "&vod=" + encodeURIComponent(this.vodUrl) + "&format=" + GlobalVars.instance.movieFormat);
					}
				}
			}
			
			var globalVars:GlobalVars = GlobalVars.instance;
			
			//if (!globalVars.isHasShowLowSpeedTips && main_mc.isHasLowerFormat)
			if (!globalVars.isHasShowLowSpeedTips)
			{
				//网速较慢提示
				globalVars.curLowSpeedTipsTime++;
				
				if (globalVars.showLowSpeedTimeArray.length >= globalVars.showBufferMax)
				{
					//5分钟内出现3次缓冲时，出现网速较慢提示
					if (globalVars.showLowSpeedTimeArray[2] - globalVars.showLowSpeedTimeArray[0] <= globalVars.showLowSpeedTipsInterval * 1000)
					{
						//已经显示了网速较慢提示，如果显示多次提示，去掉此行
						globalVars.isHasShowLowSpeedTips = true;
						
						//删除前面3个时间，下次重新计算
						globalVars.showLowSpeedTimeArray.splice(0, 3);
						//显示网速较慢提示
						main_mc.showLowSpeedTips();
						
						JTracer.sendMessage("Player -> showLowSpeedTips");
					}
					else
					{
						//删除第一个时间，从第2个时间开始计算
						globalVars.showLowSpeedTimeArray.splice(0, 1);
					}
				}
			}
			
			if (!globalVars.isHasShowHighSpeedTips && main_mc.isHasHigherFormat)
			{
				//网速较快有更高清晰度提示
				if (_highSpeedSpeedArray.length >= globalVars.showHighSpeedTipsAverageSpeedInterval)
				{
					_highSpeedSpeedArray.shift();
				}
				_highSpeedSpeedArray.push(mySpeed);
				
				if (_highSpeedSpeedArray.length >= globalVars.showHighSpeedTipsAverageSpeedInterval)
				{
					//计算平均速度
					var total:Number = 0;
					var j:*;
					for (j in _highSpeedSpeedArray)
					{
						total += _highSpeedSpeedArray[j];
					}
					var average:Number = total / (globalVars.showHighSpeedTipsAverageSpeedInterval);
					
					if (_isStartHighSpeedTimer)
					{
						globalVars.curHighSpeedTipsTime++;
						if (globalVars.curHighSpeedTipsTime >= globalVars.showHighSpeedTipsInterval)
						{
							if (globalVars.movieFormat == "p" && average >= globalVars.showGaoQingTipsSpeed)
							{
								//重置当前时间
								globalVars.curHighSpeedTipsTime = 0;
								//显示有高清提示
								main_mc.showHighSpeedTips("g", average);
							}
							else if (globalVars.movieFormat == "g" && average >= globalVars.showChaoQingTipsSpeed)
							{
								//重置当前时间
								globalVars.curHighSpeedTipsTime = 0;
								//显示有超清提示
								main_mc.showHighSpeedTips("c", average);
							}
						}
					}
					
					if (!_isStartHighSpeedTimer)
					{
						if (globalVars.movieFormat == "p" && average >= globalVars.showGaoQingTipsSpeed)
						{
							//已经显示了有更高清晰度提示，如果显示多次提示，去掉此行
							globalVars.isHasShowHighSpeedTips = true;
							
							//第一次显示后，开始计时
							_isStartHighSpeedTimer = true;
							//显示有高清提示
							main_mc.showHighSpeedTips("g", average);
							
							JTracer.sendMessage("Player -> showHighSpeedTips, higher format:g");
						}
						else if (globalVars.movieFormat == "g" && average >= globalVars.showChaoQingTipsSpeed)
						{
							//已经显示了有更高清晰度提示，如果显示多次提示，去掉此行
							globalVars.isHasShowHighSpeedTips = true;
							
							//第一次显示后，开始计时
							_isStartHighSpeedTimer = true;
							//显示有超清提示
							main_mc.showHighSpeedTips("c", average);
							
							JTracer.sendMessage("Player -> showHighSpeedTips, higher format:c");
						}
					}
				}
			}
		}
		
		private function getZeroSpeedNum(arr:Array):uint
		{
			var i:uint = 0;
			var j:*;
			for (j in arr)
			{
				if (arr[j] <= 0)
				{
					i++;
				}
			}
			
			return i;
		}
		
		public function get currentQuality():int { return _currentQuality; }
		public function get currentQulityStr():String { return _currentQulityStr; }
		public function get currentQualityType():Number { return _currentQuityType; }
		
		public function getNearIndex(arr:Array, num:Number, min:Number, max:Number):int
		{
			var t1:int = 0;
			var headIndex:int = 0;
			var haveMatched:Boolean = false;
			while (t1 < arr.length - 1) {
				var t2:int = t1 + 1;
				if (arr[t1] <= num && arr[t2] > num) {
					headIndex = t1;
					haveMatched = true;
					break;
				}
				t1++;
			}
			if (headIndex == 0)
			{
				headIndex = haveMatched ? min : max;
			}
			headIndex = Math.max(min, Math.min(headIndex, max));
			return headIndex;
		}
		
		public function set hasNextStream(value:Boolean):void
		{
			//拖动到未缓冲区，设置还有下一切片，观看时按正常切片逻辑下载，只在暂停时把剩下的影片当作一个切片来下载
			if (_sliceStream)
			{
				_sliceStream.hasNextStream = true;
			}
		}
		public function p2p_seek(time):void{
			isSpliceUpdate = false;
			preBufferLoaded = uint.MAX_VALUE;
			streamInPlay.seek(time);
			dispatchEvent(new PlayEvent(PlayEvent.SEEK));
			dispatchEvent(new PlayEvent(PlayEvent.BUFFER_START));
			streamInPlay.resume();
			isPause = false;
			main_mc._ctrBar._btnPause.visible = true;
			main_mc._ctrBar._btnPlay.visible = false;
			main_mc._ctrBar._btnPauseBig.visible = false;
		}

		public function seek(time:Number, isKey:Boolean = false):void
		{
			var tmp_bytes:ByteArray;
			var pos_obj:Object;
			var cur_bytes:ByteArray;
			
			//防止拖动到终点时，影片停止不动
			_seekTime = time >= totalTime && totalTime > 0 ? totalTime - 0.001 : time;
			if(GlobalVars.instance.isXLNetStreamValid == 1){
				p2p_seek(_seekTime);
				return;
			}
			_isInBuffer = isInBuffer(_seekTime);
			JTracer.sendMessage('Player -> seek, time:' + _seekTime + ', _isInBuffer:' + _isInBuffer + ", isKey:" + isKey);
			if (!_isInBuffer)
			{
				//拖动到未缓冲区，重置为未替换下一链接
				//GlobalVars.instance.isReplaceURL = false;
				
				hasNextStream = true;
			}
			dispatchEvent(new PlayEvent(PlayEvent.SEEK));
			if (dragTime.length > 1)
			{
				playTimeHeadIndex = getNearIndex(dragTime, _seekTime, 0, dragTime.length - 2);
				if ( !isKey && _isInBuffer || GlobalVars.instance.isUseHttpSocket)
				{
					var isBoolean:Boolean = isSeekOnNextStream(_seekTime);//是否seek到了下一个切片
					var nextVideo:Video;
					JTracer.sendMessage("Player -> seek, is seek to next stream:" + isBoolean);
					if (isBoolean &&  !GlobalVars.instance.isUseHttpSocket)
					{
						if (_sliceStream.huanNextStream != null)
						{
							if (GlobalVars.instance.isUseHttpSocket)
							{
								StreamList.clearCurList();
								_sliceStream.changeByteType();
								StreamList.replaceList();
								
								fixedTime = dragTime[playTimeHeadIndex];
								fixedByte = playTimeHeadIndex == 0 ? StreamList.getHeader().length : dragPosition[playTimeHeadIndex];
								bufferStart = _seekTime;
								bufferStartTime = _sliceStream.loadingTime;
								//_progressCacheTime = _seekTime;
								isSpliceUpdate = false;
								JTracer.sendMessage("Player -> seek, use socket, nextStream is not null, replace next stream, bufferStart:" + bufferStart + ", playTimeHeadIndex:" + playTimeHeadIndex + ", fixedTime:" + fixedTime + ", fixedByte:" + fixedByte);
								
								is_seek_finish = false;
								//streamInPlay.seek(0);
								
								seekInBuffer();
								
								_sliceStream.replaceCompeleteHandler();
							}
							else
							{
								JTracer.sendMessage("Player -> seek, nextStream is not null, replace next stream.");
								
								bufferStartTime = _sliceStream.loadingTime;
								isSpliceUpdate = false;
								
								streamInPlay.close();
								streamInPlay = null;
								streamInPlay = _sliceStream.huanNextStream;
								streamInPlay.bufferTime = _bufferTime;
								streamInPlay.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
								streamInPlay.seek(_seekTime);
								
								nextVideo = _sliceStream.nextVideo;
								nextVideo.width = classicVideo.width;
								nextVideo.height = classicVideo.height;
								nextVideo.visible = true;
								addChild(nextVideo);
								
								classicVideo.visible = false;
								classicVideo.clear();
								classicVideo = null;
								classicVideo = nextVideo;
								classicVideo.visible = true;
								
								_sliceStream.replaceCompeleteHandler();
							}
						} else {
							seekOutBuffer();
						}
					} else {
						if (GlobalVars.instance.isUseHttpSocket)
						{
							fixedTime = dragTime[playTimeHeadIndex];
							fixedByte = playTimeHeadIndex == 0 ? StreamList.getHeader().length : dragPosition[playTimeHeadIndex];
							bufferStart = _seekTime;
							//bufferStartTime = _seekTime;
							//_progressCacheTime = _seekTime;
							isSpliceUpdate = true;
							JTracer.sendMessage("Player -> seek, use socket, bufferStart:" + bufferStart + ", playTimeHeadIndex:" + playTimeHeadIndex + ", fixedTime:" + fixedTime + ", fixedByte:" + fixedByte);
							
							is_seek_finish = false;
							//streamInPlay.seek(0);
							
							seekInBuffer();
						}
						else
						{
							isSpliceUpdate = false;
							streamInPlay.seek(_seekTime);
						}
					}
					streamInPlay.resume();
					isPause = false;
					main_mc._ctrBar._btnPauseBig.visible = false;
					dispatchEvent(new PlayEvent(PlayEvent.BUFFER_START));
				}
				else
				{
					seekOutBuffer();
				}
			} else {
				isSpliceUpdate = false;
				streamInPlay.seek(_seekTime);
			}
		}
		
		private function playStream():void
		{
			if (GlobalVars.instance.isUseHttpSocket)
			{
				JTracer.sendMessage("Player -> playStream, use socket, connect socket");
				
				var start_pos:Number = fixedByte;
				if (start_pos == 0)
				{
					start_pos = StreamList.getHeader().length;
				}
				//var end_pos:Number = isNaN(_sliceStream.spliceGetEndByte(start_pos)) ? totalByte : _sliceStream.spliceGetEndByte(start_pos);
				var end_pos:Number = totalByte;
				current_pos = start_pos;
				query_pos = start_pos + socket_count * block_size;
				
				GetVodSocket.instance.connect(playUrl, function(vod_url:String, utype:String, status_code:String, cost_time:int)
				{
					if (!vod_url)
					{
						_vodUrl = null;
						JTracer.sendMessage("Player -> playStream, use socket, get vod url fail.");
					}
					else
					{
						_vodUrl = replaceVideoUrl(vod_url) + _suffixUrl;
						JTracer.sendMessage("Player -> playStream, use socket, get vod url success, vod url:" + vod_url + ", start_pos:" + start_pos + ", end_pos:" + end_pos + ", next_pos:" + query_pos);
						
						if (streamInPlay)
						{
							streamInPlay.close();
							streamInPlay.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
							streamInPlay = null;
						}
						streamInPlay = new NetStream(myConnection);
						streamInPlay.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
						streamInPlay.client = customClient;
						streamInPlay.bufferTime = _bufferTime;
						
						downloadStream(vod_url, start_pos, end_pos);
					}
												
					dispatchEvent(new PlayEvent(PlayEvent.BUFFER_START));
				});
			}
			else
			{
				if (GlobalVars.instance.isUseSocket)
				{
					JTracer.sendMessage("Player -> playStream, connect socket");
					
					GetVodSocket.instance.connect(playUrl, function(vod_url:String, utype:String, status_code:String, cost_time:int)
					{
						GlobalVars.instance.isChangeURL = false;
						
						if (!vod_url)
						{
							_vodUrl = null;
							JTracer.sendMessage("Player -> playStream, get vod url fail, gdl url:" + _gdlUrl);
							streamInPlay.play(_gdlUrl);
						}
						else
						{
							_vodUrl = replaceVideoUrl(vod_url) + _suffixUrl;
							JTracer.sendMessage("Player -> playStream, get vod url success, vod url:" + _vodUrl);
							streamInPlay.play(_vodUrl);
						}
													
						dispatchEvent(new PlayEvent(PlayEvent.BUFFER_START));
					});
				}
				else
				{
					GlobalVars.instance.isChangeURL = false;
					
					streamInPlay.play(_gdlUrl);
					
					JTracer.sendMessage('Player -> playStream, gdl url=' + _gdlUrl);
					dispatchEvent(new PlayEvent(PlayEvent.BUFFER_START));
				}
			}
		}

		private function startControllerTimer():void{
			if (main_mc._ctrBar._timerBP && main_mc._ctrBar._timerBP.running == false)
			{
				JTracer.sendMessage('NetStream.Play.Start _timerBP start.')
				main_mc._ctrBar._timerBP.reset();
				main_mc._ctrBar._timerBP.start();
			}
		}
		
		private function netStatusHandler(event:NetStatusEvent):void
		{
			_isInvalidTime = false;
			
			JTracer.sendMessage('Player -> netStatusHandler, ' + event.info.code);
			switch(event.info.code) {
				case 'NetStream.Buffer.Empty':
					JTracer.sendMessage("Player -> netStatusHandler, NetStream.Buffer.Empty, streamInPlay.time:" + streamInPlay.time + ", streamInPlay.bufferLenght:" + streamInPlay.bufferLength + ", streamInPlay.bufferTime:" + streamInPlay.bufferTime);
					/*
					if (GlobalVars.instance.isUseHttpSocket)
					{
						var seek_time:Number = this.time >= totalTime && totalTime > 0 ? totalTime - 0.001 : this.time;
						var playTimeHeadIndex:uint = getNearIndex(dragTime, seek_time, 0, dragTime.length - 2);
						
						fixedTime = dragTime[playTimeHeadIndex];
						fixedByte = playTimeHeadIndex == 0 ? StreamList.getHeader().length : dragPosition[playTimeHeadIndex];
						bufferStart = seek_time;
						//bufferStartTime = seek_time;
						//_progressCacheTime = seek_time;
						JTracer.sendMessage("Player -> netStatusHandler, NetStream.Buffer.Empty, bufferStart:" + bufferStart + ", playTimeHeadIndex:" + playTimeHeadIndex + ", fixedTime:" + fixedTime + ", fixedByte:" + fixedByte);
						
						is_seek_finish = false;
						//streamInPlay.seek(0);
						
						seekInBuffer();
					}
					*/
					dispatchEvent(new PlayEvent(PlayEvent.BUFFER_START));
					break;
				case 'NetStream.Play.Start':
					// hwh
					if(!GlobalVars.instance.isXLNetStreamValid == 1)
					streamInPlay.pause();
					startControllerTimer();
					break;
				case 'NetStream.Play.Stop':
					checkIsNormalStop();
					break;
				case "NetStream.Buffer.Full":
					if(!streamInPlay)return;
					startControllerTimer();
					JTracer.sendMessage("Player -> netStatusHandler, NetStream.Buffer.Full, streamInPlay.time:" + streamInPlay.time + ", bufferStartTime:" + bufferStartTime + ", _progressCacheTime:" + _progressCacheTime + ", streamInPlay.bufferLenght:" + streamInPlay.bufferLength + ", streamInPlay.bufferTime:" + streamInPlay.bufferTime);
					this.visible = true;
					fnOnEnterFrame();
					dispatchEvent(new PlayEvent(PlayEvent.PLAY_START));
					_progressCacheTime = 0;
					//JTracer.sendLoaclMsg('stream_Inplay.bufferTime:' + streamInPlay.bufferTime+',stream_Inplay.bufferLength'+streamInPlay.bufferLength + ',stream_Inplay.bytes:' + streamInPlay.bytesLoaded);
					fixedTime = -1;
					main_mc._ctrBar._btnPause.visible = true;
					main_mc._ctrBar._btnPlay.visible = false;
					break;	
				case "NetStream.Play.StreamNotFound":
					/*_errorInfo = "302";
					JTracer.sendMessage("Player -> onErrorInfo, code:" + _errorInfo);
					Tools.stat("f=playerror&e=" + _errorInfo + "&gcid=" + Tools.getUserInfo("ygcid"));*/
					
					var codeUrl:String = _vodUrl ? _vodUrl : _gdlUrl;
					GetGdlCodeSocket.instance.connect(codeUrl, "302", onVodGetted);
					
					var nextUrl:String = getNextUrl();
					if (nextUrl)
					{
						playUrl = nextUrl;
						GlobalVars.instance.isVodGetted = false;
						//缓冲时上报为首缓冲
						GlobalVars.instance.bufferType = GlobalVars.instance.bufferTypeFirstBuffer;
						GlobalVars.instance.isChangeURL = false;
						JTracer.sendMessage("netStatusHandler -> has next, get next play url:" + playUrl + "\n,bufferType:" + GlobalVars.instance.bufferType);
						
						main_mc._bufferTip.clearBreakCount();
						
						if (GlobalVars.instance.isFirstBuffer302)
						{
							JTracer.sendMessage("netStatusHandler -> is first buffer 302");
							play();
						}
						else
						{
							JTracer.sendMessage("netStatusHandler -> is not first buffer 302");
							main_mc.flv_seek(this.time);
						}
						return;
					}
					JTracer.sendMessage("netStatusHandler -> no next, get next play url:" + playUrl);
					
					ExternalInterface.call("flv_playerEvent", "onErrorInfo", _errorInfo);
					main_mc.showPlayError(_errorInfo);
					break;
				case "NetStream.Seek.InvalidTime":
					if (is_invalid_time)
					{
						is_invalid_time = false;
						
						try {
							JTracer.sendMessage('NetStream.Seek.InvalidTime:totalTime=' + totalTime +', startPosition=' + dragTime[0] +', lastPostion=' + dragTime[dragTime.length - 1] + ', details=' + event.info.details + ', bufferEndTime=' + bufferEndTime + ', bufferLength=' + streamInPlay.bufferLength);
							//_isInBuffer = false;
							
							_isInvalidTime = true;
							
							main_mc._bufferTip.clearBreakCount();
							GlobalVars.instance.bufferType = GlobalVars.instance.bufferTypeError;
							
							JTracer.sendMessage("Player -> netStatusHandler, NetStream.Seek.InvalidTime, set bufferType:" + GlobalVars.instance.bufferType);
							
							seek( _seekTime, true );
						} catch (e:Error) {
							_errorInfo = "202";
							JTracer.sendMessage("Player -> onErrorInfo, code:" + _errorInfo);
							Tools.stat("f=playerror&e=" + _errorInfo + "&gcid=" + Tools.getUserInfo("ygcid") + this.retryLastTimeStat);
							ExternalInterface.call("flv_playerEvent", "onErrorInfo", _errorInfo);
						}
					}
					break;	
				case "NetStream.Play.Failed":
					_errorInfo = "203";
					JTracer.sendMessage("Player -> onErrorInfo, code:" + _errorInfo);
					main_mc.showPlayError(_errorInfo);
					Tools.stat("f=playerror&e=" + _errorInfo + "&gcid=" + Tools.getUserInfo("ygcid") + this.retryLastTimeStat);
					ExternalInterface.call("flv_playerEvent", "onErrorInfo", _errorInfo);
					break;
			}
		}
		
		private function seekInBuffer():void
		{
			var pos_obj:Object = StreamList.findBytesRange(fixedByte);
			var tmp_bytes:ByteArray = StreamList.getBytes(GlobalVars.instance.type_curstream, pos_obj.start, pos_obj.start + block_size - 1) as ByteArray;
			if (tmp_bytes)
			{
				tmp_bytes.position = 0;
				var cur_bytes:ByteArray = new ByteArray();
				cur_bytes.writeBytes(tmp_bytes, fixedByte - pos_obj.start, tmp_bytes.length - (fixedByte - pos_obj.start));
				
				JTracer.sendMessage("Player -> seekInBuffer, found block, pos_obj.start:" + pos_obj.start + ", pos_obj.end:" + pos_obj.end + ", fixedByte:" + fixedByte + ", cur_bytes.length:" + cur_bytes.length);
				
				if (streamInPlay)
				{
					streamInPlay.close();
					streamInPlay.removeEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
					streamInPlay = null;
				}
				streamInPlay = new NetStream(myConnection);
				streamInPlay.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				streamInPlay.client = customClient;
				streamInPlay.bufferTime = _bufferTime;
				trace(getTime()+'new streamIn_Play')
				streamInPlay.play(null);
				streamInPlay.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
				streamInPlay.appendBytes(StreamList.getHeader());
				streamInPlay.appendBytesAction(NetStreamAppendBytesAction.RESET_SEEK);
				streamInPlay.appendBytes(cur_bytes);
				
				classicVideo.attachNetStream(streamInPlay);
				
				current_pos = pos_obj.start + block_size;
				is_seek_finish = true;
			}
			else
			{
				StreamList.clearCurList();
				JTracer.sendMessage("Player -> seekInBuffer, not found block, pos_obj.start:" + pos_obj.start + ", pos_obj.end:" + pos_obj.end + ", fixedByte:" + fixedByte);
				
				_seekTime = time;
				playTimeHeadIndex = getNearIndex(dragTime, _seekTime, 0, dragTime.length - 2);
				
				seekOutBuffer();
			}
		}
		
		private function seekOutBuffer():void
		{
			var fixedByteEnd:String;
			fixedTime = dragTime[playTimeHeadIndex];
			fixedByte = playTimeHeadIndex == 0 ? 0 : dragPosition[playTimeHeadIndex];
			fixedByteEnd = isNaN(_sliceStream.spliceGetEndByte(fixedByte)) ? '' : String('&end=' + _sliceStream.spliceGetEndByte(fixedByte));
			sliceStart = fixedByte;
			sliceSize = getFixedByteEnd(fixedByteEnd) - fixedByte;
			_nextDownLoadTime = fixedTime;
			bufferStart = _seekTime;
			bufferStartTime = _seekTime;
			_progressCacheTime = _seekTime;
			isSpliceUpdate = false;
			JTracer.sendMessage("Player -> seekOutBuffer, bufferStartTime:" + bufferStartTime + ", playTimeHeadIndex:" + playTimeHeadIndex + ", fixedTime:" + fixedTime + ", fixedByte:" + fixedByte);
			
			_suffixUrl = 'start=' + fixedByte + fixedByteEnd + "&id=sotester&client=FLASH%20WIN%2010,0,45,2&version=4.1.60" + "&type=normal&du=" + vduration;
			_gdlUrl = replaceVideoUrl(playUrl) + _suffixUrl;
			JTracer.sendMessage("Player -> seekOutBuffer, start=" + fixedByte + fixedByteEnd);
			
			isPause = false;
			main_mc._ctrBar._btnPause.visible = true;
			main_mc._ctrBar._btnPlay.visible = false;
			main_mc._ctrBar._btnPauseBig.visible = false;
			
			JTracer.sendMessage("Player -> seekOutBuffer, start spliceUpdate");
			_sliceStream.spliceUpdate(fixedTime);
			playStream();
		}
		
		public function getCurLink():int
		{
			//取当前链路
			var i:*;
			for (i in GlobalVars.instance.allURLList)
			{
				if (GlobalVars.instance.allURLList[i].url == lastUrl)
				{
					return GlobalVars.instance.allURLList[i].link;
				}
			}
			
			return 1;
		}
		
		public function nextIsDL():Boolean
		{
			var i:*;
			for (i in GlobalVars.instance.allURLList)
			{
				if (GlobalVars.instance.allURLList[i].url == lastUrl && i < GlobalVars.instance.allURLList.length - 1)
				{
					var next_url:String = GlobalVars.instance.allURLList[i + 1].url;
					var next_is_dl:Boolean = isDL(next_url);
					
					return next_is_dl;
				}
			}
			
			return false;
		}
		
		public function isDL(url:String):Boolean
		{
			var dl_url:String = getFormatURL(url);
			if (dl_url.indexOf("dl") == 0)
			{
				return true;
			}
			return false;
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
		
		/**
		 * @param obj {url:"", origin_url:"", url_type:"", status_code:"", error_code:""}
		 */
		private function onVodGetted(obj:Object):void
		{
			if (!obj.url)
			{
				if (obj.url_type == "gdl" || obj.url_type == "dl")
				{
					onCodeGetted(obj);
					return;
				}
			}
			
			GetVodCodeSocket.instance.connect(obj, onCodeGetted);
		}
		
		/**
		 * @param obj {origin_url:"", url_type:"", status_code:"", error_code:""}
		 */
		private function onCodeGetted(obj:Object):void
		{
			var origin_url:String = getRealURL(obj.origin_url);
			var host:String = "http://" + origin_url.substr(0, origin_url.indexOf("/"));
			var status_code:String = obj.status_code;
			var url_type:String = obj.url_type;
			var error_code:String = obj.error_code;
			//使用_retryLastTimeStat值，不重置_retryLastTimeStat;
			JTracer.sendMessage('onCodeGetted code:'+status_code + ' retryLastTimeStat:'+this._retryLastTimeStat)
			if(status_code == '403' && this._retryLastTimeStat != ''){
				main_mc._videoMask.showErrorNotice(VideoMask.noPrivilege);
				playEnd = true;
			}
			JTracer.sendMessage("Player -> onErrorInfo, code:" + error_code + ", utype:" + url_type + ", status:" + status_code);
			Tools.stat("f=playerror&e=" + error_code + "&gcid=" + Tools.getUserInfo("ygcid") + "&utype=" + url_type + "&status=" + status_code + "&host=" + host + this.retryLastTimeStat);
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
		
		public function connectStream():void {
			if (streamInPlay) {
				streamInPlay.close();
				streamInPlay = null;
			}
			var start:Number = videoUrlArr[0].start || 0;
			_currentQuality = videoUrlArr[0].quality;
			_currentQulityStr = videoUrlArr[0].qualitystr;
			_currentQuityType = videoUrlArr[0].qualitytype || 0;
			dispatchEvent(new SetQulityEvent(SetQulityEvent.INIT_QULITY));
			
			initialConnection();
			initialStream();
			initialVideo();
			classicVideo.attachNetStream(streamInPlay);
			addChildAt(classicVideo, 0);
			JTracer.sendMessage('Player -> setPlayUrl, initClassicVideo');
			
			bufferStart = start;
			bufferStartTime = start;
			_progressCacheTime = start;
			_nextDownLoadTime = 0;
			isSpliceUpdate = false;
			sliceStart = Number(getFirstStartByte());
			sliceSize = getFixedByteEnd(getFirstEndByte()) - Number(getFirstStartByte());
			_suffixUrl = 'start=' + getFirstStartByte() + getFirstEndByte() + "&id=sotester&client=FLASH%20WIN%2010,0,45,2&version=4.1.60" + "&type=" + _urlType + "&du=" + vduration;
			_gdlUrl = replaceVideoUrl(playUrl) + _suffixUrl;
			JTracer.sendMessage("Player -> connectStream, url=" + playUrl + "&" + _suffixUrl);
			
			/**
			 *  播放逻辑;
			 *	if--使用socket							then-- 用socket链接去取vod链接
			 *		if--取得vod链接						then-- 
			 *			if--使用多链						then-- 
			 * 				if--取得header				then-- downloadStream
			 *				el-- 									then-- streamMetaData.loadMetaData
			 *			el-- 											then-- 直接播放vod链接
			 *	el-- 												then-- 直接播放gdl连接
			 */
			if (GlobalVars.instance.isUseSocket)
			{
				JTracer.sendMessage("Player -> connectStream, connect socket");
				
				GetVodSocket.instance.connect(playUrl, function(vod_url:String, utype:String, status_code:String, cost_time:int)
				{
					if (GlobalVars.instance.getVodTime == 0)
					{
						GlobalVars.instance.getVodTime = cost_time;
					}
					
					if (!vod_url)
					{
						GlobalVars.instance.isUseHttpSocket = false;
						
						_vodUrl = null;
						JTracer.sendMessage("Player -> connectStream, get vod url fail, gdl url:" + _gdlUrl);
						streamInPlay.play(_gdlUrl);
					}
					else
					{
						_vodUrl = replaceVideoUrl(vod_url) + _suffixUrl;
						
						GlobalVars.instance.isUseHttpSocket = checkIsUseHttpSocket(vod_url);
						if (GlobalVars.instance.isUseHttpSocket)
						{
							if (GlobalVars.instance.isHeaderGetted)
							{
								var start_pos:Number;
								if (Number(videoUrlArr[0].start) == 0)
								{
									start_pos = StreamList.getHeader().length;
								}
								else
								{
									var nearestIdx:uint = getNearIndex(_streamMetaData.timeArr, Number(videoUrlArr[0].start), 0, _streamMetaData.timeArr.length - 2);
									start_pos = _streamMetaData.byteArr[nearestIdx];
								}
								//var end_pos:Number = getFirstEndByte().substr(5) == "" ? totalByte : Number(getFirstEndByte().substr(5));
								var end_pos:Number = totalByte;
								current_pos = start_pos;
								query_pos = start_pos + socket_count * block_size;
								
								JTracer.sendMessage("Player -> connectStream, use socket, get vod url success, vod url:" + vod_url + ", start_pos:" + start_pos + ", end_pos:" + end_pos + ", next_pos:" + query_pos);
								downloadStream(vod_url, start_pos, end_pos);
							}
							else
							{
								_streamMetaData.loadMetaData(playUrl, vduration);
							}
						}
						else
						{
							JTracer.sendMessage("Player -> connectStream, get vod url success, vod url:" + _vodUrl);
							streamInPlay.play(_vodUrl);
						}
					}
					
					if (isChangeQuality == false)
					{
						JTracer.sendMessage('Player -> dispatch playevent.bufferStart.')
						dispatchEvent(new PlayEvent(PlayEvent.BUFFER_START));
					}
				});
			}
			else
			{
				streamInPlay.play(_gdlUrl);
				
				if (isChangeQuality == false)
				{
					JTracer.sendMessage('Player -> dispatch playevent.bufferStart. not isChangeQuality')
					dispatchEvent(new PlayEvent(PlayEvent.BUFFER_START));
				}
			}
			
			_urlType = "normal";
			
			ExternalInterface.call("flv_playerEvent", "onopen");
			
			dispatchEvent(new sizeEvent(sizeEvent.CHANGETITLE, videoUrlArr[0].title));
			dispatchEvent(new Event(SET_QUALITY));
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
				socket.clear();
				socket = null;
			}
			socket_array = [];
		}
		
		private function downloadStream(url:String, start_pos:uint, end_pos:uint):void
		{
			if (main_mc._ctrBar._timerBP && main_mc._ctrBar._timerBP.running == false)
			{
				main_mc._ctrBar._timerBP.reset();
				main_mc._ctrBar._timerBP.start();
			}
			
			StreamList.clearCurList();
			//StreamList.clearNextList();
			//_sliceStream.clearSocket();
			_sliceStream.isReplaceNext = false;
			socketStartDownloadTime = _nextDownLoadTime;
			is_append_header = false;
			is_seek_finish = true;
			_preloadBytesTotal = end_pos - start_pos;
			clearSocket();
			
			var i:uint;
			var socket:SingleSocket;
			if (socket_array.length == 0)
			{
				for(i = 0; i < socket_count; i++)
				{
					socket = new SingleSocket(this, url, block_size, socket_count, start_pos + i * block_size, end_pos, end_pos - start_pos, GlobalVars.instance.type_curstream, videoUrlArr[0].totalByte);
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
					socket.setQueryRange(start_pos + i * block_size, end_pos, end_pos - start_pos, videoUrlArr[0].totalByte);
					socket.connectSocket();
				}
			}
		}
		
		private function handleAppendTimer(evt:TimerEvent):void
		{
			block_complete(null);
		}
		
		private function all_block_complete(evt:Event):void
		{
			var socket:SingleSocket = evt.currentTarget as SingleSocket;
			socket.clearSocket();
			var pos_obj:Object = socket.getCompletePos();
			JTracer.sendMessage("Player -> all_block_complete, start_pos:" + pos_obj.start_pos + ", end_pos:" + pos_obj.end_pos + ", next_pos:" + query_pos);
		}
		
		private function block_complete(evt:Event):void
		{
			if (!GlobalVars.instance.isUseHttpSocket || !is_seek_finish || !GlobalVars.instance.isHeaderGetted || !streamInPlay)
			{
				return;
			}
			trace(getTime()+'bufferLength:'+streamInPlay.bufferLength)
			/*
			if(streamInPlay.bufferLength > 120 && loadNextSocketsData){
				JTracer.sendMessage('streamInPlay.bufferLength:'+streamInPlay.bufferLength)
				loadNextSocketsData = false;
			}
			if(streamInPlay.bufferLength < 60 && !loadNextSocketsData){
				loadNextSocketsData = true;
			}
			*/
			if (!is_append_header)
			{
				is_append_header = true;
				
				streamInPlay.play(null);
				streamInPlay.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
				streamInPlay.appendBytes(StreamList.getHeader());
				streamInPlay.appendBytesAction(NetStreamAppendBytesAction.RESET_SEEK);
				JTracer.sendMessage('Player block_complete appendBytes')
				classicVideo.attachNetStream(streamInPlay);
				
				//fileBytes.writeBytes(StreamList.getHeader());
			}
			trace('block_complete____appendBytes  ' + current_pos)
			var bl:Number = streamInPlay.bufferLength;
			var append_end_pos:Number = Math.min(current_pos + block_size - 1, videoUrlArr[0].totalByte-1);
			var cur_bytes:ByteArray = StreamList.getBytes(GlobalVars.instance.type_curstream, current_pos, append_end_pos) as ByteArray;
			if (cur_bytes)
			{
				//JTracer.sendMessage("Player -> block_complete, start_pos:" + current_pos + ", end_pos:" + (current_pos + block_size - 1) + " -> length:" + cur_bytes.length + ", this.time:" + this.time);
				streamInPlay.appendBytes(cur_bytes);
				if(streamInPlay.bufferLength == bl && hh && cur_bytes.length >0){
					trace('current_pos '+current_pos+' ok');
					//fileBytes.writeBytes(cur_bytes);
					hh = false;
				}
				//fileBytes.writeBytes(cur_bytes);
				trace(getTime() + 'cur bytes Size:' + cur_bytes.length + ' old_bufferLength:'+bl + 'bufferLength:'+streamInPlay.bufferLength);
				current_pos += block_size;
			}
			trace('block_complete____appendBytes___end');
		}
		private var hh:Boolean = true;
		/*public function saveFile():void
		{
			fileRef.save(fileBytes, "视频文件.flv");
		}*/
		
		private function block_error(evt:Event):void
		{
			var socket:SingleSocket = evt.currentTarget as SingleSocket;
			JTracer.sendMessage("Player -> block_error, error_info:" + socket.getErrorInfo());
		}
		
		private function metaDataHandler(playObj:Player):Function 
		{	
			var fun:Function = function(infoObject:Object):void
			{
				v_w = isNaN(infoObject.width) ? swf_width : infoObject.width;
				v_h = isNaN(infoObject.height) ? swf_height : infoObject.height;
				var real_width:int = 0;
				var real_height:int = 0;
				
				JTracer.sendMessage("Player -> metaDataHandler, video.width:" + v_w + ", video.height:" + v_h);
				
				GlobalVars.instance.videoRealSize = { width:v_w, height:v_h };
				if (v_w / v_h > swf_width / swf_height)
				{
					real_width = swf_width;
					real_height = real_width*v_h/v_w;
				} else {
					real_height = swf_height;
					real_width = real_height * v_w / v_h;
				}
				nomarl_width = v_w;
				nomarl_height = v_h;
				main_mc.resizePlayerSize();
				
				nomarl_x = x;
				nomarl_y = y;
				
				_totalTime = infoObject.duration;
				JTracer.sendMessage('Player -> metaDataHandler, bufferStartTime:' + bufferStartTime +', bytesTotal:' + streamInPlay.bytesTotal + ', duration:' + infoObject.duration);
				
				try {
					if (infoObject.keyframes)
					{
						dragTime = String(infoObject.keyframes.times).split(",");
						dragPosition = String(infoObject.keyframes.filepositions).split(",");
					} else if (infoObject.seekpoints) {
						var arr:Array = infoObject.seekpoints;
						dragTime = [];
						dragPosition = [];
						var j:uint;
						var len:uint = arr.length;
						for ( j = 0; j < len; j++ ) {
							dragTime.push(arr[j].time);
							dragPosition.push(arr[j].time);
						}
					}
				} catch (e:Error) {
					dragTime = new Array();
					dragPosition = new Array();
				}
				
				seekBeforePlay();
				
				playObj._sliceStream.totalByte = playObj.totalByte;
				playObj._sliceStream.totalTime = playObj.totalTime;
				
				if (_sliceStream.spliceInit && !isSpliceUpdate)
				{
					isSpliceUpdate = true;
					playObj._sliceStream.spliceUpdateArray(dragTime, dragPosition);
					JTracer.sendMessage("Player -> metaDataHandler, start spliceUpdate");
					playObj._sliceStream.spliceUpdate(playObj.time);
					playObj._sliceStream.spliceStartCheckTimer();
				}
			}
			return fun;
		}
		
		private function isInBuffer(seconds:Number):Boolean {
			var start:Number = 0;
			var end:Number = 0;
			if (_sliceStream.spliceInit == true) {
				start = Math.max(_sliceStream.bufferStartTime, bufferStartTime);
				end = bufferEndTime;
				JTracer.sendMessage('Player -> isInBuffer, _sliceStream.bufferStartTime:' + _sliceStream.bufferStartTime + ', bufferStartTime:' + bufferStartTime + ', _sliceStream.bufferEndTime:' + _sliceStream.bufferEndTime + ", bufferEndTime:" + bufferEndTime);
				JTracer.sendMessage("Player -> isInBuffer, streamInPlay.bytesLoaded:" + this.bytesLoaded + ", streamInPlay.bytesTotal:" + this.bytesTotal + ", _sliceStream.sliceEndTime:" + _sliceStream.sliceEndTime + ", time:" + time);
			}else {
				start = bufferStartTime;
				end = bufferEndTime;
				JTracer.sendMessage('Player -> isInBuffer, bufferStartTime:' + bufferStartTime + ', bufferEndTime:' + bufferEndTime);
			}
			var isIn:Boolean = (( start ) <= seconds && seconds <= ( end ));
			JTracer.sendMessage('Player -> isInBuffer, start:' + start + ', end:' + end + ', time:' + seconds + ' isIn:'+isIn);
			return isIn;
		}
		
		private function isSeekOnNextStream(seconds:Number):Boolean
		{
			var result:Boolean = false;
			if (seconds <= _sliceStream.bufferEndTime && seconds >= bufferEndTime)
			{
				result = true;
			}
			if (seconds <= bufferEndTime && seconds >= _sliceStream.bufferEndTime)
			{
				result = true;
			}
			JTracer.sendMessage('_sliceStream.bufferEndTime:' + _sliceStream.bufferEndTime + ',bufferEndTime:' + bufferEndTime + ",seconds:" + seconds);
			return result;
		}
		
		public function get errorInfo():String
		{
			return _errorInfo;
		}
		
		public function clearUp():void
		{
			if (streamInPlay)
			{
				streamInPlay.close();
				streamInPlay = null;
				trace(getTime()+'clearUp streamInPlay is null')
			}
		}
		
		public function set bufferTime(time:Number):void
		{
			_bufferTime = time;
		}
		
		public function get bufferTime():Number
		{
			return _bufferTime;
		}
		
		public function get isBuffer():Boolean
		{
			return _isInBuffer;
		}
		
		public function set isBuffer(boo:Boolean):void
		{
			_isInBuffer = boo;
		}
		
		private function numToStrByDecimal(num:Number):String
		{
			var numArr:Array = num.toString().split('.');
			if (numArr.length == 1) {
				return numArr[0] + '.' + '00';
			}else if (numArr[1].length >= 2) {
				return num.toString();
			}else if(numArr[1].length == 1){
				return numArr[0] + '.' + numArr[1] + '0';
			}else {
				return 'error';
			}
		}
		
		public function get onSeekTime():Number
		{
			return _seekTime;
		}
		
		public function resizePlayerSize(r_width:Number,r_height:Number):void
		{
			swf_width = r_width;
			swf_height = r_height;
		}
		
		private function seekBeforePlay():void
		{
			if (_js_seekPos == -1) {
				return;
			}else {
				var _jsSeekTime:Number = _js_seekPos;
				_js_seekPos = -1;
				seek(_jsSeekTime);
			}
		}
		
		public function setSeekPos(_time:Number):void
		{
			if (this.time > 0 ) {
				_js_seekPos = -1;
				seek(_time);
			}else if (_time >= 0){
				_js_seekPos = _time;
			}
		}
		
		public function get streamBufferTime():Number
		{
			var loadTime:Number = 0;
			if(streamInPlay && dragPosition.length > 0){
				var loadByte:Number = streamInPlay.bytesLoaded + fixedByte - dragPosition[0];
				var p1:int=0;
				var loadByteIndex:uint = 0;
				while (p1 < dragTime.length) {
					var p2:int = p1 + 1;
					if (dragPosition[p1] <= loadByte && dragPosition[p2] > loadByte) {
						loadByteIndex = p1;
						break;
					}
					p1++;
				}
				loadTime = dragTime[loadByteIndex] - this.time;
				JTracer.sendLoaclMsg('loadbyte:' + loadByte + ',loadbyteindex:' + loadByteIndex);
			}
			return loadTime;
		}
		/**
		 * 自动重连
		 */
		private function checkIsNormalStop():void
		{
			JTracer.sendMessage("Player -> checkIsNormalStop");
			if (this.totalTime - this.time < 25 && this.totalTime - this.time > 0) {
				JTracer.sendMessage('this is stop normal! this.totalTime - this.time:' + (this.totalTime - this.time).toString() + ', this.time:' + this.time +', streamBytesLoaded:' + streamInPlay.bytesLoaded + ', streamBytesTotal:' + streamInPlay.bytesTotal);
				//ExternalInterface.call("flv_playerEvent", "onEnd");
				
				var codeUrl:String = _vodUrl ? _vodUrl : _gdlUrl;
				GetGdlCodeSocket.instance.connect(codeUrl, "204", onVodGetted);
				
				/*_errorInfo = "204";
				JTracer.sendMessage("Player -> onErrorInfo, code:" + _errorInfo);
				Tools.stat("f=playerror&e=" + _errorInfo + "&gcid=" + Tools.getUserInfo("ygcid"));*/
				
				ExternalInterface.call("flv_playerEvent", "onErrorInfo", _errorInfo);
				//dispatchEvent(new PlayEvent(PlayEvent.STOP));
			} else {
				JTracer.sendMessage('abstract stop sliceStram.spliceReplaceRightNow');
				_sliceStream.spliceReplaceRightNow(this.time);
			}
		}
		
		/*变量接口区域*/
		public function set isChangeQuality(boo:Boolean):void
		{
			_isChangeQuality = boo;
		}
		
		public function get isChangeQuality():Boolean
		{
			return _isChangeQuality;
		}
		
		public function get nsCurrentFps():Number
		{
			var fps:Number = 0;
			if (streamInPlay != null) {
				fps = streamInPlay.currentFPS;
			}
			return fps;
		}
		
		private function replaceVideoUrl(url:String):String
		{
			var qM:String = '?';
			var qMResult:int = url.indexOf('?');
			if (qMResult != -1){
				qM = '&';
			}
			return url + qM;
		}
		
		/**
		 * slice
		 */
		private function playStart():void
		{
			JTracer.sendMessage("Player -> PlayStart, time:" + this.time + ", _progressCacheTime:" + _progressCacheTime);
			if (_sliceStream.spliceInit == false) { return; }
			
			//不在缓冲区中
			if (!isInBuffer(this.time))
			{
				_sliceStream.spliceUpdateArray(dragTime, dragPosition);
				_sliceStream.spliceUpdate(this.time);
			}
			_sliceStream.spliceStartCheckTimer();
		}
		
		public function replaceNextStream(nextStream:NetStream,nextVideo:Video,compelete:Function,onerror:String=null):void
		{
			if (nextStream == null || nextVideo == null ) { 
				if (onerror) {
					this._errorInfo = onerror;
					JTracer.sendMessage("Player -> onErrorInfo, code:" + _errorInfo);
					main_mc.showPlayError(_errorInfo);
					Tools.stat("f=playerror&e=" + _errorInfo + "&gcid=" + Tools.getUserInfo("ygcid") + this.retryLastTimeStat);
					ExternalInterface.call("flv_playerEvent", "onErrorInfo", _errorInfo);
				}
				return;
			}
			
			var time:Number = this.time;
			if (GlobalVars.instance.isUseHttpSocket)
			{
				StreamList.clearCurList();
				_sliceStream.changeByteType();
				StreamList.replaceList();
				
				fixedTime = _sliceStream.loadingTime;
				fixedByte = _sliceStream.loadingPos;
				//bufferStart = fixedTime;
				bufferStartTime = _sliceStream.loadingTime;
				//_progressCacheTime = _seekTime;
				JTracer.sendMessage("Player -> replaceNextStream, bufferStart:" + bufferStart + ", fixedTime:" + fixedTime + ", fixedByte:" + fixedByte);
				
				//is_seek_finish = false;
				//streamInPlay.seek(0);
			}
			else
			{
				nextVideo.width = classicVideo.width;
				nextVideo.height = classicVideo.height;
				nextVideo.visible = true;
				addChild(nextVideo);
				
				JTracer.sendMessage('Player -> replaceNextStream front, streamInPlay.time:' + streamInPlay.time + ", nextStream.time:" + nextStream.time);
				
				streamInPlay.close();
				streamInPlay = null;
				streamInPlay = nextStream;
				streamInPlay.bufferTime = _bufferTime;
				streamInPlay.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				streamInPlay.resume();
				fnOnEnterFrame();
				classicVideo.visible = false;
				classicVideo.clear();
				classicVideo = null;
				classicVideo = nextVideo;
				classicVideo.visible = true;
			}
			
			if (_sliceStream.buffer) {
				JTracer.sendMessage("Player -> replaceNextStream, _sliceStream.buffer:true, streamInPlay.bufferLenght:" + streamInPlay.bufferLength);
				//替换切片时，不发送PlayEvent.BUFFER_START，可以防止在缓冲完的区域播放出现缓冲
				//dispatchEvent(new PlayEvent(PlayEvent.BUFFER_START));
				_progressCacheTime = time;
			}
			(compelete as Function)();
			
			JTracer.sendMessage('Player -> replaceNextStream end, streamInPlay.time:' + streamInPlay.time + 
			", nextStream.time:" + nextStream.time + 
			", streamInPlay.bufferLenght:" + streamInPlay.bufferLength + 
			", streamInPlay.bufferTime:" + streamInPlay.bufferTime);
			
			if (time == 0 && streamInPlay.bufferLength > streamInPlay.bufferTime) {
				main_mc._bufferTip.clearBreakCount();
				GlobalVars.instance.bufferType = GlobalVars.instance.bufferTypeError;
				
				JTracer.sendMessage("Player -> replaceNextStream, set bufferType:" + GlobalVars.instance.bufferType);
				
				seek(time, true);
				_errorInfo = "205";
				JTracer.sendMessage("Player -> onErrorInfo, code:" + _errorInfo);
				Tools.stat("f=playerror&e=" + _errorInfo + "&gcid=" + Tools.getUserInfo("ygcid") + this.retryLastTimeStat);
				ExternalInterface.call("flv_playerEvent", "onErrorInfo", _errorInfo);
			}
		}
		
		private function getFixedByteEnd(str:String):Number
		{
			if (!str)
			{
				return 0;
			}
			
			return Number(str.substr(5));
		}
		
		public function getFirstEndByte():String
		{
			var endNumber:Number = 0;
			var end:String = '';
			var endByte:Number = 0;
			if (videoUrlArr[0].totalTime && videoUrlArr[0].totalByte && videoUrlArr[0].sliceTime) {
				endByte = Math.round(videoUrlArr[0].sliceTime * videoUrlArr[0].totalByte / videoUrlArr[0].totalTime);
				if (videoUrlArr[0].start > 0) {
					//endNumber = Math.min((_streamStartByte + _streamEndByte), videoUrlArr[0].totalByte);
					endNumber = Math.min(_streamEndByte, videoUrlArr[0].totalByte);
					end = '&end=' + endNumber;
					
					JTracer.sendMessage("Player -> getFirstEndByte, byte end1:" + endNumber + ", _streamStartByte:" + _streamStartByte + ", _streamEndByte:" + _streamEndByte);
				} else {
					//endNumber = Math.min((_streamStartByte + endByte), videoUrlArr[0].totalByte);
					endNumber = Math.min(endByte, videoUrlArr[0].totalByte);
					end = '&end=' + endNumber;
					
					JTracer.sendMessage("Player -> getFirstEndByte, byte end2:" + endNumber + ", _streamStartByte:" + _streamStartByte + ", endByte:" + endByte);
				}
				_sliceStream.firstByteEnd = endByte;
				_sliceStream.sliceTime = videoUrlArr[0].sliceTime;
				//_sliceStream.totalByte = videoUrlArr[0].totalByte;
				//_sliceStream.totalTime = videoUrlArr[0].totalTime;
				JTracer.sendMessage('影片的分段时间sliceTime:' + videoUrlArr[0].sliceTime + ', 总字节totalByte:' + videoUrlArr[0].totalByte + ', 总时长totalTime:' + videoUrlArr[0].totalTime + ", firstByteEnd:" + endByte);
			}
			return end;
		}
		
		public function getFirstStartTime():Number
		{
			return _streamStartTime;
		}
		
		public function getFirstStartByte():String
		{
			return _streamStartByte.toString();
		}
		
		override public function set width(_w:Number):void
		{
			swf_width = _w;
			if (classicVideo != null) {
				classicVideo.width = _w;
			}
		}
		
		override public function get width():Number
		{
			return swf_width;
		}
		
		override public function set height(_h:Number):void
		{
			swf_height = _h;
			if (classicVideo != null) {
				classicVideo.height = _h;
			}
		}
		override public function get height():Number
		{
			return swf_height;
		}
		
		public function get lastUrl():String
		{
			return _lastUrl;
		}
		
		public function set lastUrl(url:String):void
		{
			_lastUrl = url;
		}
		
		public function get playUrl():String
		{
			return _playUrl;
		}
		
		public function set playUrl(url:String):void
		{
			_playUrl = url;
		}
		
		public function getNextUrl():String
		{
			if (GlobalVars.instance.vodURLList.length > 0)
			{
				var obj:Object = GlobalVars.instance.vodURLList.shift();
				return obj.url;
			}
			
			return null;
		}
		
		public function get vodUrl():String
		{
			return _vodUrl;
		}
		
		public function set vodUrl(url:String):void
		{
			_vodUrl = url;
		}
		
		public function get gdlUrl():String
		{
			return _gdlUrl;
		}
		
		public function get originGdlUrl():String
		{
			return _originGdlUrl;
		}
		
		public function set originGdlUrl(url:String):void
		{
			_originGdlUrl = url;
		}
		
		public function closeNetConnection():void
		{
			if (myConnection) {
				myConnection.close();
			}
		}
		
		//总下载字节数
		public function get downloadBytes():Number
		{
			var bytes:Number = 0;
			var i:*;
			for (i in _totalSpeedArray)
			{
				bytes += _totalSpeedArray[i];
			}
			
			return bytes * 1024;
		}
		
		//是否重置过videoUrlArr[0].start = 0
		public function get isResetStart():Boolean
		{
			return _isResetStart;
		}
		
		public function get isInvalidTime():Boolean
		{
			return _isInvalidTime;
		}
		
		public function get getVideoUrlArr():Array
		{
			return videoUrlArr;
		}
		
		public function set startPosition(pos:Number):void
		{
			videoUrlArr[0].start = pos;
		}

		private var _loadNextSocketsData:Boolean = true;
		public function set loadNextSocketsData(flag:Boolean):void{
			_loadNextSocketsData = flag;
			if(!flag)return;
			trace(flag)
			var e:Event = new Event(SingleSocket.SocketReStartToQueryDataEvent)
			var s:SingleSocket;
			for(var i:int = 0; i< socket_count; i++){
				s = socket_array[i] as SingleSocket;
				s.dispatchEvent(e);
			}

		}
		public function get loadNextSocketsData():Boolean{
			return _loadNextSocketsData;
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

		private var _currVolum:Number = 0;
		private var videoUrlArr:Array = [];//每个flv视频的播放地址
		private var myConnection:NetConnection;
		private var classicVideo:Video;
		private var mySpeed:Number = 0;
		private var _status:Number = -1;
		private var _currentQuality:int;
		private var _errorInfo:String;	
		private var preBufferLoaded:uint = 0;//计算下载速度用
		private var _bufferTime:Number = 10;
		private var _isInBuffer:Boolean = false;
		private var _progressCacheTime:Number = 0;//拖动到未加载区域时记录一个时间，playstart后销毁
		private var _seekTime:Number = 0;//每次seek的时间值，供playerctrl获取
		private var _currentQuityType:Number = 0;
		private var _currentQulityStr:String = null;
		private var _isChangeQuality:Boolean = false;
		private var _js_seekPos:Number = -1;
		
		//luoyuqiang
		private var _isLoadedNextStream:Boolean = true;
	}
}