package zuffy.core
{
	import com.Player;
	import com.common.Tools;
	import com.common.Cookies;
	import com.common.JTracer;
	import com.slice.StreamList;
	import com.global.GlobalVars;
	import com.common.StringUtil;
	import com.greensock.TweenLite;
	import com.serialization.json.JSON;

	import zuffy.display.CtrBar;
	import zuffy.display.MouseControl;
	import zuffy.display.notice.NoticeBar;
	import zuffy.display.notice.bufferTip;
	import zuffy.display.subtitle.Subtitle;
	import zuffy.display.statuMenu.VideoMask;
	import zuffy.ctr.contextMenu.CreateContextMenu;
	
	import zuffy.events.PlayEvent;
	import zuffy.events.CaptionEvent;
	import zuffy.events.ControlEvent;
	import zuffy.events.SetQulityEvent;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.sendToURL;
	import flash.system.ApplicationDomain;
	import flash.system.Capabilities;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Mouse;
	import flash.utils.Timer;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	
	public class PlayerCtrl extends Sprite
	{
		public var _ctrBar:CtrBar;							// 控制栏
		public var _player:Player;							// 播放对象
		public var _videoMask:VideoMask;				// 视频帷幕
		private var _eventCaptureScreen:Sprite;	// 触摸屏
		public  var _bufferTip:bufferTip;				// 缓冲提示
		private var _noticeBar:NoticeBar;				// 文字提示栏
		
		private var _mouseControl:MouseControl;	// 鼠标事件Controller


		private var _playFullWidth:Number;			// 全屏宽度
		private var _playFullHeight:Number;			// 全屏高度
		

		private var _playerSize:int = 0;				// 0全屏；1中屏；2小屏
		private var _playerRealWidth:Number;		// 视频实际显示宽度
		private var _playerRealHeight:Number;		// 视频实际显示高度

		private var _isDoubleClick:Boolean = false;
		private var _isFullScreen:Boolean = false;
		private var _isBuffering:Boolean;

		private var _seekDelayTimer:Timer;
		private var _seekDelayTimer2:Timer;

		private var _noticeMsgArr:Array = [
			'广告时间，请稍候，马上为您播放精彩节目!',
			'当前网速较慢，建议<a href="event:pause">暂停</a>缓冲几分钟',
			'当前网速较慢，建议<a href="event:pause">暂停</a>缓冲几分钟或切换成<a href="event:changeLowerQulity">标清模式</a>',
			'正在为您预下载数据，建议暂停 <font color="#ff0000">5分钟</font> 后再观看，播放会更流畅',
			'系统默认已经为您跳过片头',
			'您已设置启用硬件加速，刷新页面或下次打开页面时生效',
			'正在切换至传统播放模式，请稍候...'
		];
		private var _isFirstLoad:Boolean = true;//是否该影片第一次加载
		private var _isChangeQuality:Boolean = false;//是否影片清晰度切换
		private var _ratioVideo:Number = 0; //后台自动化预览页面浏览影片原始尺寸添加的参数
		protected var _setSizeInfo:Object = { 'ratio':'common', 'size':'100', 'ratioValue':0, 'sizeValue':1 };
		private const NORMAL_PROGRESSBAR_HEIGTH:uint = 7;
		private const SMALL_PROGRESSBAR_HEIGTH:uint = 3;

		private var _seekEnable:Boolean = true;
		private var _subTitle:Subtitle;//字幕条
		private var _isPressKeySeek:Boolean;//是否按住键盘左右键seek
		private var _checkUserLoader:URLLoader;
		private var _checkFlowLoader:URLLoader;
		private var _iframeLoader:URLLoader;
		private var _snptLoader:Loader;
		private var _isValid:Boolean = true;				//登陆是否有效，默认有效
		private var _isNoEnoughBytes:Boolean;				//是否流量不足
		private var _videoUrlArray:Array;
		private var _isFirstTips:Boolean = true;			//是否第一次提示上次播放时间点或字幕提示
		private var _isFirstRemainTips:Boolean = true;		//是否第一次提示时长
		private var _isStopNormal:Boolean;					//是否正常停止
		private var _isFirstOnplaying:Boolean = true;		//是否第一次触发onplaying
		private var _isReported:Boolean = false;			//是否已经上报版本号或用户域名
		private var _playerTxtTips:TextField;				//左上角影片正在播放提示文字
		private var _playerTxtTipsID:uint;
		private var _remainTimes:Number;					//剩余时长
		private var _expiresTime:Number;					//过期时间
		private var _isFlowChecked:Boolean;					//是否已经查询完流量
		private var _isPlayStart:Boolean;					//影片是否已经开播
		private var _isShowStopFace:Boolean;				//是否显示播放完界面
		private var _snptIndex:uint;						//i帧截图地址index
		private var _snptArray:Array = [];					//i帧截图地址数组
		private var _snptAllArray:Array = [];				//i帧截图全部地址数组
		private var _snptBmdArray:Array = [];				//i帧截图图片数组
		private var _isReportedScreenShotError:Boolean;		//是否已上报i帧截图跨域错误
		private var _formatsObj:Object;
		private var _isShowAutoloadTips:Boolean;
		private var _isSnptLoaded:Boolean;

		private var xlPluginCallBackFunc:Function;
		private var xlPluginCallBackArgs:Array;

		private var isXLNetStreamAfterInited:Boolean = false;
		


		private var _params:Object;

		public function PlayerCtrl()
		{
			Security.allowDomain("*");

			if(stage){
				init();
			}else{
				// 侦听该类是否被添加到了舞台显示列表
				addEventListener(Event.ADDED_TO_STAGE, init);
			}
			
		}

		private function init():void{
			// 右键菜单
			CreateContextMenu.createMenu(this);
			CreateContextMenu.addItem('播放特权播放器：2.9.20130513', false, false, null);

			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.tabChildren = false;

			_params = stage.loaderInfo.parameters;

			initGlobalData(_params);
			initializePlayCtrl(_params);
		}

		protected function initGlobalData(tParams:Object):void{
			GlobalVars.instance.movieType = tParams['movieType'] ? tParams['movieType'] : 'movie';
			GlobalVars.instance.windowMode = tParams['windowMode'] || 'browser';
			GlobalVars.instance.platform = tParams['platform'] || 'webpage';
			GlobalVars.instance.isMacWebPage = ((typeof tParams['isMacWebPage'] != "undefined") && tParams['isMacWebPage'] != 'false');
			GlobalVars.instance.isZXThunder = int(tParams["isZXThunder"]) == 1;
			GlobalVars.instance.isStat = tParams['defStatLevel'] == 2 ? true : false;	//0-不上报，1-只上报重要的，2-全部上报
		}
		
		protected function initializePlayCtrl(tParams:Object):void 
		{
			stage.addEventListener(Event.RESIZE, on_stage_RESIZE);

			var _w:int = int(tParams["width"]) ? int(tParams["width"]) : stage.stageWidth;
			var _h:int = int(tParams["height"]) ? int(tParams["height"]) : stage.stageHeight;
			
			// 初始化基本界面
			initializeUI(_w, _h);
			
			// 与js通信接口
			initJsInterface();

			// 初始化其他;
			initOther();
			
			initStageEvent();

			_checkUserLoader = new URLLoader();
			_checkUserLoader.addEventListener(Event.COMPLETE, onCheckUserComplete);
			_checkUserLoader.addEventListener(IOErrorEvent.IO_ERROR, onCheckUserIOError);
			_checkUserLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onCheckUserSecurityError);
			
			_checkFlowLoader = new URLLoader();
			_checkFlowLoader.addEventListener(Event.COMPLETE, onCheckFlowComplete);
			_checkFlowLoader.addEventListener(IOErrorEvent.IO_ERROR, onCheckFlowIOError);
			_checkFlowLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onCheckFlowSecurityError);

		}
		//显示系统时间
		public function setSystemTime():void
		{
		
		}

		protected function initializeUI(tWidth:int, tHeight:int):void{
			
			var _has_fullscreen:int = int(_params["fullscreenbtn"]) || 1;

			_player = new Player(tWidth, tHeight - 35, _has_fullscreen, this);
			_player.name="_player";
			_player.addEventListener(Player.SET_QUALITY, handleSetQuality);
			_player.addEventListener(Player.AUTO_PLAY, handleAutoPlay);
			_player.addEventListener(Player.INIT_PAUSE, handleInitPause);
			this.addChild(_player);

			_subTitle = new Subtitle(this, tWidth, tHeight);
			_subTitle.handleStageResize(stage.stageWidth, stage.stageHeight);
			
			_eventCaptureScreen = new Sprite();
			_eventCaptureScreen.graphics.clear();
			_eventCaptureScreen.graphics.beginFill(0xffffff, 0);
			_eventCaptureScreen.graphics.drawRect(0, 0, tWidth, tHeight);
			_eventCaptureScreen.graphics.endFill();
			_eventCaptureScreen.doubleClickEnabled = true;
			_eventCaptureScreen.mouseEnabled = true;
			_eventCaptureScreen.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClickHandle);
			_eventCaptureScreen.addEventListener(MouseEvent.CLICK, onClickHandle);
			this.addChild(_eventCaptureScreen);
			
			_videoMask = new VideoMask(this, GlobalVars.instance.movieType);
			_videoMask.addEventListener("StartPlayClick", onStartPlayClick);
			_videoMask.addEventListener("Refresh", onRefresh);
			this.addChild(_videoMask);
			_videoMask.setPosition();

			_bufferTip = new bufferTip(_player);
			_bufferTip.name = "_bufferTip";
			this.addChild(_bufferTip);
			
			_noticeBar = new NoticeBar(this);
			this.addChild(_noticeBar);
			
			_ctrBar = new CtrBar(tWidth,tHeight,_has_fullscreen, this);
			_ctrBar.showPlayOrPauseButton='PLAY';
			_ctrBar.flvPlayer=_player;
			_ctrBar.available = true;
			_ctrBar.faceLifting(stage.stageWidth);
			_ctrBar.y = stage.stageHeight - 33;
			_ctrBar.faceLifting(stage.stageWidth);
			this.addChild(_ctrBar);

			_mouseControl = new MouseControl(this);
			_mouseControl.addEventListener("MOUSE_SHOWED", handleMouseInside);
			_mouseControl.addEventListener("MOUSE_HIDED", handleMouseOutSide);	
			_mouseControl.addEventListener("MOUSE_MOVEED", handleMouseInside);
			_mouseControl.addEventListener("MOUSE_MOVEOUT", handleMouseMoveOut);
			_mouseControl.addEventListener("SMALL_PLAY_PROGRESS_BAR", handleMouseHide2 );//缩小播放进度条;
		}
		
		protected function on_stage_RESIZE(e:Event):void{
			_ctrBar.y = stage.stageHeight - 33;
			_ctrBar.faceLifting(stage.stageWidth);

			_player.resizePlayerSize(stage.stageWidth,stage.stageHeight );

			_eventCaptureScreen.width = stage.stageWidth;
			_eventCaptureScreen.height = stage.stageHeight;
			changePlayerSize();
			_videoMask.setPosition();
			_subTitle.handleStageResize(stage.stageWidth, stage.stageHeight, _isFullScreen);
		}
		
		//切换视频
		public function exchangeVideo():void
		{
			//切换后，取消之前的字幕
			_subTitle.hideCaption({surl:null, scid:null});
		}

		//登陆异常
		public function showInvalidLoginLogo():void
		{
			_isValid = false;
			_isStopNormal = false;
			_isShowStopFace = false;
			
			//登陆异常时，设置开播时间为当前时间，刷新页面时从当前点开播
			_player.startPosition = _player.time;
			
			_ctrBar.dispatchStop();
			_videoMask.showErrorNotice(VideoMask.invalidLogin);
		}
		
		//播放异常
		public function showPlayError(errorCode:String):void
		{
			_isStopNormal = false;
			_isShowStopFace = false;
			
			_ctrBar.dispatchStop();
			_videoMask.showErrorNotice(VideoMask.playError, errorCode);
		}
		
		public function checkIsValid():void
		{
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
		
		private function onCheckUserComplete(evt:Event):void
		{
			//4-sessionid已失效, 5-sessionid与userid不对应
			var resultStr:String = evt.target.data;
			var resultObj:Object = com.serialization.json.JSON.deserialize(resultStr);
			var result:Number = resultObj.result;
			JTracer.sendMessage("PlayerCtrl -> onCheckUserComplete, check is valid complete, result:" + result);
			
			if (result == 4 || result == 5)
			{
				showInvalidLoginLogo();
			}
			else
			{
				_isValid = true;
				_ctrBar.dispatchPlay();
			}
		}
		
		private function onCheckUserIOError(evt:IOErrorEvent):void
		{
			JTracer.sendMessage("PlayerCtrl -> onCheckUserIOError, check is valid IOError");
			_isValid = true;
			_ctrBar.dispatchPlay();
		}
		
		private function onCheckUserSecurityError(evt:SecurityErrorEvent):void
		{
			JTracer.sendMessage("PlayerCtrl -> onCheckUserSecurityError, check is valid SecurityError");
			_isValid = true;
			_ctrBar.dispatchPlay();
		}
		
		private function onIframeComplete(evt:Event):void
		{
			var jsonStr:String = evt.target.data;
			
			JTracer.sendMessage("PlayerCtrl -> iframe url load Complete, jsonStr:" + jsonStr);
			
			var jsonObj:Object = com.serialization.json.JSON.deserialize(jsonStr);
			if (jsonObj)
			{
				if (Number(jsonObj.ret) == 0)
				{
					_snptAllArray = jsonObj.res_list;
					_snptArray = getCurSnptArray();
					loadSnpt();
				}
				else
				{
					Tools.stat("f=iframeerror&gcid=" + Tools.getUserInfo("gcid") + "&code=" + jsonObj.ret);
				}
			}
		}
		
		private function getCurSnptArray():Array
		{
			var curArray:Array = [];
			for (var i:* in _snptAllArray)
			{
				if (_snptAllArray[i].gcid == Tools.getUserInfo("gcid"))
				{
					curArray = _snptAllArray[i].snpt_list;
				}
			}
			
			return curArray;
		}
		
		private function onIframeIOError(evt:IOErrorEvent):void
		{
			JTracer.sendMessage("PlayerCtrl -> iframe url load IOError");
		}
		
		private function onIframeSecurityError(evt:SecurityErrorEvent):void
		{
			JTracer.sendMessage("PlayerCtrl -> iframe url load SecurityError");
		}
		
		private function loadSnpt():void
		{
			if (!_snptArray || _snptArray.length == 0)
			{
				return;
			}
			
			var url:String = _snptArray[_snptIndex].snpt_url;
			var req:URLRequest = new URLRequest(url);
			
			JTracer.sendMessage("PlayerCtrl -> iframe loadSnpt index:" + _snptIndex + ", url:" + url);
			
			unloadSnpt();
			
			_snptLoader = new Loader();
			_snptLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onSnptLoaded);
			_snptLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onSnptIOError);
			_snptLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSnptSecurityError);
			_snptLoader.load(req, new LoaderContext(true));
		}
		
		private function unloadSnpt():void
		{
			if (_snptLoader)
			{
				_snptLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onSnptLoaded);
				_snptLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onSnptIOError);
				_snptLoader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSnptSecurityError);
				try
				{
					_snptLoader.unloadAndStop();
				}
				catch (e:Error)
				{
					
				}
				_snptLoader = null;
			}
		}
		
		private function onSnptLoaded(evt:Event):void
		{
			JTracer.sendMessage("PlayerCtrl -> iframe loadSnpt index:" + _snptIndex + " complete");
			try{
				var bm:Bitmap = _snptLoader.content as Bitmap;
				var bmd:BitmapData = bm.bitmapData;
				_snptBmdArray.push({bmd:bmd, url:_snptArray[_snptIndex].snpt_url});
			}catch(e:Error){
				JTracer.sendMessage('onSnptLoaded error--->' + e);
			}
			_snptIndex++;
			if (_snptIndex >= _snptArray.length)
			{
				//加载完成
				JTracer.sendMessage("PlayerCtrl -> iframe loadSnpt all complete");
				return;
			}
			
			loadSnpt();
		}
		
		private function onSnptIOError(evt:IOErrorEvent):void
		{
			JTracer.sendMessage("PlayerCtrl -> iframe loadSnpt IOError, index:" + _snptIndex);
			unloadSnpt();
		}
		
		private function onSnptSecurityError(evt:SecurityErrorEvent):void
		{
			JTracer.sendMessage("PlayerCtrl -> iframe loadSnpt SecurityError, index:" + _snptIndex);
			unloadSnpt();
			
			if (!_isReportedScreenShotError)
			{
				_isReportedScreenShotError = true;
				Tools.stat("f=iframeerror&gcid=" + Tools.getUserInfo("gcid") + "&code=3");
			}
		}
		
		private function onCheckFlowComplete(evt:Event):void
		{
			var jsonStr:String = evt.target.data;
			JTracer.sendMessage("PlayerCtrl -> onCheckFlowComplete, jsonStr:" + jsonStr);
			var jsonObj:Object = com.serialization.json.JSON.deserialize(jsonStr);
			switch(jsonObj.result)
			{
				case "0":
					//成功
					_remainTimes = jsonObj.remain;
					_expiresTime = jsonObj.vtime;
					_isFlowChecked = true;
					
					//检测是否应该暂停影片播放
					checkIsShouldPause();
					break;
				case "1":
					//请求参数错误
					break;
				case "2":
					//数据库异常
					showInvalidLoginLogo();
					break;
			}
		}
		
		private function onCheckFlowIOError(evt:IOErrorEvent):void
		{
			JTracer.sendMessage("PlayerCtrl -> onCheckFlowIOError");
		}
		
		private function onCheckFlowSecurityError(evt:SecurityErrorEvent):void
		{
			JTracer.sendMessage("PlayerCtrl -> onCheckFlowSecurityError");
		}
		
		private function checkIsShouldPause():void
		{
			var vodPermit:Number = Number(Tools.getUserInfo("vodPermit"));
			JTracer.sendMessage('PlayerCtrl -> checkIsShouldPause vodPermit:'+vodPermit);
			if ((vodPermit == 6 || vodPermit == 7 || vodPermit == 8 || vodPermit == 9 || vodPermit == 10 || vodPermit == 11) && Tools.getUserInfo("from") != GlobalVars.instance.fromXLPan)
			{
				if (_isPlayStart && _isFlowChecked && _isFirstRemainTips)
				{
					_isFirstRemainTips = false;
					//显示了时长提示，不再显示上次播放时间点和字幕提示
					_isFirstTips = false;
					JTracer.sendMessage('PlayerCtrl -> checkIsShouldPause _remainTimes:'+_remainTimes);
					if (_remainTimes <= 0)
					{
						//无时长普通会员开播1秒后停止
						setTimeout(tryPlayEnded, 1000, 0);
					}
					else
					{
						var needTimes:Number = _player.totalTime - _player.getFirstStartTime();
						var timesStr:String = Tools.calculateTimes(_remainTimes);
						var expireStr:String = _remainTimes == 0 ? "" : "（" + Tools.transDate(_expiresTime) + "前有效）";
						if (_remainTimes < needTimes)
						{
							//时长不足，提示用户
							_noticeBar.setContent("您的可播放时长剩余" + timesStr + expireStr + "，迅雷白金会员不限时长，<a href='event:buyVIP13'>立即开通</a>", false, 12);
							
							JTracer.sendMessage("PlayerCtrl -> checkIsShouldPause, 时长不足的提醒, ygcid:" + Tools.getUserInfo("ygcid") + ", userid:" + Tools.getUserInfo("userid") + ", remain:" + _remainTimes + ", need:" + needTimes);
							Tools.stat("f=fluxlacktips&gcid=" + Tools.getUserInfo("ygcid") + "&left=" + _remainTimes + "&need=" + needTimes);
						}
						else
						{
							//时长充足，提示用户
							_noticeBar.setContent("您的可播放时长剩余" + timesStr + expireStr + "，迅雷白金会员不限时长，<a href='event:buyVIP13'>立即开通</a>", false, 12);
							
							JTracer.sendMessage("PlayerCtrl -> checkIsShouldPause, 时长充足的提醒, ygcid:" + Tools.getUserInfo("ygcid") + ", userid:" + Tools.getUserInfo("userid") + ", remain:" + _remainTimes + ", need:" + needTimes);
						}
					}
				}
			}
		}
		
		protected function onCloseAddBytesFace(evt:Event):void{
			if (!_player.isStop)
			{
				_ctrBar.dispatchPlay();
			}
		}

		protected function pauseForever(tips:String):void{
			//流量不足
			_isNoEnoughBytes = true;
			//暂停
			if (!_player.isStop)
			{
				_ctrBar.dispatchPause();
			}
			
			_noticeBar.setContent(tips, true);
			_noticeBar.showCloseBtn(false);
		}
		
		//试播结束
		protected function tryPlayEnded(time:Number):void
		{
			JTracer.sendMessage("PlayerCtrl -> tryPlayEnded, pauseForever");
				
			var userType:Number = Number(Tools.getUserInfo("userType"));
			var playtype:String;
			if (userType == 0 || userType == 1 || userType == 5)
			{
				//正常播放
				playtype = "0";
			}
			else
			{
				//时长卡播放
				playtype = "2";
			}
			Tools.stat("f=show_play_end&playtype=" + playtype);
			_noticeBar.hideNoticeBar();
		}
		
		protected function initOther():void{
			
		}

		/**
		 * 监听各个控制器及自身发出的信息、事件;
		 */
		protected function initStageEvent():void
		{
			this.addEventListener(PlayEvent.INVALID, playEventHandler);
			this.addEventListener(PlayEvent.PLAY, playEventHandler);
			this.addEventListener(PlayEvent.REPLAY, playEventHandler);
			this.addEventListener(PlayEvent.PAUSE, playEventHandler);
			this.addEventListener(PlayEvent.STOP, playEventHandler);
			this.addEventListener(PlayEvent.PAUSE_4_STAGE, playEventHandler);
			this.addEventListener(PlayEvent.PLAY_4_STAGE, playEventHandler);
			this.addEventListener(PlayEvent.BUFFER_START, playEventHandler);
			this.addEventListener(PlayEvent.PLAY_START, playEventHandler);
			this.addEventListener(PlayEvent.BUFFER_END, playEventHandler);
			this.addEventListener(PlayEvent.SEEK, playEventHandler);
			this.addEventListener(PlayEvent.PROGRESS, playEventHandler);
			this.addEventListener(PlayEvent.PLAY_NEW_URL, playEventHandler);
			this.addEventListener(PlayEvent.INIT_STAGE_VIDEO, playEventHandler);
			this.addEventListener(PlayEvent.INSTALL, playEventHandler);
			this.addEventListener(PlayEvent.OPEN_WINDOW, playEventHandler);

			this.addEventListener(SetQulityEvent.CHANGE_QUILTY,changeQualityHandler)
			this.addEventListener(SetQulityEvent.INIT_QULITY, changeQualityHandler);
			this.addEventListener(SetQulityEvent.LOWER_QULITY, changeQualityHandler);
			this.addEventListener(SetQulityEvent.HAS_QULITY, changeQualityHandler);
			this.addEventListener(SetQulityEvent.NO_QULITY, changeQualityHandler);
			this.addEventListener(SetQulityEvent.PAUSE_FOR_QUALITY_TIP, changeQualityHandler);

			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownFunc);
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUpFunc);

			stage.addEventListener(FullScreenEvent.FULL_SCREEN, on_stage_FULLSCREEN);

			this.addEventListener(ControlEvent.SHOW_CTRBAR, controlEventHandler);
			this.addEventListener(CaptionEvent.SET_STYLE, setCaptionStyle);
			this.addEventListener(CaptionEvent.LOAD_CONTENT, loadCaptionContent);
			this.addEventListener(CaptionEvent.HIDE_CAPTION, hideCaption);
			this.addEventListener(CaptionEvent.SET_CONTENT, setCaptionContent);
			this.addEventListener(CaptionEvent.SET_TIME, setCaptionTime);
		}

		/**
		 * 设置字幕的样式;
		 */
		private function setCaptionStyle(evt:CaptionEvent):void
		{
			_subTitle.setStyle(evt.info);
		}

		protected function saveTimeDelta():void{
				_subTitle.saveTimeDelta();
		}
		protected function saveStyle():void{
			_subTitle.saveStyle();
		}
		/**
		 * 生成 player txt tip.
		 */
		protected function showPlayerTxtTips(tips:String, time:Number):void
		{
			if (!_playerTxtTips)
			{
				var filter:GlowFilter = new GlowFilter(0x000000, 1, 2, 2, 5, BitmapFilterQuality.HIGH);
				
				_playerTxtTips = new TextField();
				_playerTxtTips.selectable = false;
				_playerTxtTips.textColor = 0xFEFE01;
				_playerTxtTips.filters = [filter];
				_playerTxtTips.x = 15;
				_playerTxtTips.y = 25;
				addChild(_playerTxtTips);
			}
			
			var tf:TextFormat = new TextFormat("宋体");
			
			_playerTxtTips.text = tips;
			_playerTxtTips.width = _playerTxtTips.textWidth + 10;
			_playerTxtTips.setTextFormat(tf);
			
			clearTimeout(_playerTxtTipsID);
			_playerTxtTipsID = setTimeout(hidePlayerTxtTips, time);
		}
		
		/**
		 * 移除 player txt tip.
		 */
		protected function hidePlayerTxtTips():void
		{
			if (_playerTxtTips)
			{
				removeChild(_playerTxtTips);
				_playerTxtTips = null;
			}
		}
		
		private function setCaptionContent(evt:CaptionEvent):void
		{
			_subTitle.setContent(evt.info.toString());
		}
		
		private function loadCaptionContent(evt:CaptionEvent):void
		{
			_subTitle.loadContent(evt.info);
			
			showAutoloadTips();
		}
		
		private function showAutoloadTips():void
		{
			if (!_isShowAutoloadTips && _isPlayStart && !isChangeQuality && !_player.isResetStart && GlobalVars.instance.isHasAutoloadCaption)
			{
				_isShowAutoloadTips = true;
				
				showPlayerTxtTips("已自动加载在线字幕", 5000);
			}
		}
		
		private function hideCaption(evt:CaptionEvent):void
		{
			_subTitle.hideCaption(evt.info);
		}
		
		private function setCaptionTime(evt:CaptionEvent):void
		{
			if (evt.info.type == "key")
			{
				if (_subTitle.hasSubtitle)
				{
					if (Number(evt.info.time) <= 0)
					{
						showPlayerTxtTips("字幕提前" + Math.abs(evt.info.time) / 1000 + "秒", 3000);
					}
					else
					{
						showPlayerTxtTips("字幕推迟" + Math.abs(evt.info.time) / 1000 + "秒", 3000);
					}
				}
			}
			
			_subTitle.setTimeDelta(Number(evt.info.time));
		}
		
		private function set seekEnable(enable:Boolean):void
		{
			this._seekEnable = enable;
			this._ctrBar.seekEnable = enable;
		}
		
		private function controlEventHandler(e:ControlEvent):void
		{
			if (e.info == 'hidden') {
				this._ctrBar._barSlider.visible = false;
				this.seekEnable = false;
			}else {
				this.seekEnable = true;
			}
		}
		
		protected function dontNoticeBytes():void
		{
			hideNoticeBar();
			Cookies.setCookie('isNoticeBytes', false);
		}
		
		private function changeQualityHandler(e:SetQulityEvent):void
		{
			switch(e.type) {
				case 'lower_qulity':
					//_bufferTip.changeQulityHandler();
					_ctrBar.changeToNextFormat();
					_ctrBar.isClickBarSeek = false;
					_isPressKeySeek = false;
					break;
				case 'has_qulity':
					_noticeBar.setContent(_noticeMsgArr[2]);
					break;
				case 'no_qulity':
					_noticeBar.setContent(_noticeMsgArr[1]);
					break;
				case 'change_quilty':
					isChangeQuality = true;
					_ctrBar.isClickBarSeek = false;
					_isPressKeySeek = false;
					//this._ctrBar._isShowSpolier = true;
					break;
				case 'autio_qulity':
					_bufferTip.autioChangeQuality();
					break;
				case 'init_qulity':
					var currentQulity:int = _player.currentQuality;
					var currentQulityStr:String = _player.currentQulityStr;
					var currentQualityType:Number = _player.currentQualityType;
					_bufferTip.setQulityType(currentQulityStr, currentQulity);
					break;
				case 'pause_for_quality_tip':
					_noticeBar.setContent(_noticeMsgArr[3], false, 15, 3);
					break;
			}
			e.stopPropagation();
		}
		
		protected function playEventHandler(e:PlayEvent):void
		{
			if(e.type != 'Progress'){
				JTracer.sendMessage('PlayerCtrl -> playEventHandler, PlayEvent.' + e.type);
			}
			_videoMask.isBuffer = _player.isBuffer;
			_videoMask.bufferHandle(e.type, e.info);
			_player.playEventHandler(e);
			
			switch(e.type)
			{
				case 'Replay':
					hideNoticeBar();
					break;
				case 'Pause':
					break;
				case 'Play':
					break;
				case 'Seek':
					var seekTime:Number = _player.onSeekTime;
					var ygcid:String = Tools.getUserInfo("ygcid");
					Tools.stat("b=drag&gcid=" + ygcid + "&t=" + getPlayProgress(true));
					ExternalInterface.call("flv_playerEvent", "onSeek", seekTime);
					//_bufferTip.clearBreakCount();
					break;
				case 'Stop':
					hideNoticeBar();

					if (isChangeQuality == false) {
						_ctrBar.onStop();
						isFirstLoad = true;
						_videoMask.bufferHandle('Stop');
					}
					
					_isBuffering = false;
					_player.isBuffer = false;
					//停止后，不处理为点击拖动条和使用按键进退产生的缓冲，使用bufferLength / bufferTime计算缓冲
					_ctrBar.isClickBarSeek = false;
					_isPressKeySeek = false;
					//播放完后，显示工具条
					_ctrBar.show(true);
					_noticeBar.show(true);
					//停止后，第一次提示重置为true
					_isFirstTips = true;
					_isFirstRemainTips = true;
					_isPlayStart = false;
					break;
				case 'PlayNewUrl':
					if (isChangeQuality == true) {
						_videoMask.showLoadingQuality();
					}else{
						_videoMask.showProcessLoading();
					}
					JTracer.sendMessage("PlayerCtrl -> playEventHandler, isChangeQuality:" + isChangeQuality);
					break;
				case 'PlayForStage':
					_ctrBar.dispatchPlay();
					break;
				case 'PauseForStage':
					_ctrBar.dispatchPause();
					break;
				case 'PlayStart':
					_isPlayStart = true;
					_bufferTip.clearBreakCount();
					
					GlobalVars.instance.isFirstBuffer302 = false;
					GlobalVars.instance.bufferType = GlobalVars.instance.bufferTypeCustom;
					
					JTracer.sendMessage("PlayerCtrl -> playEventHandler, PlayEvent.PlayStart, set bufferType:" + GlobalVars.instance.bufferType);
					
					//没流量的用户，网盘用户不检测
					var vodPermit:Number = Number(Tools.getUserInfo("vodPermit"));
					if ((vodPermit == 7 || vodPermit == 9 || vodPermit == 11) && Tools.getUserInfo("from") != GlobalVars.instance.fromXLPan)
					{
						_remainTimes = 0;
						_isFlowChecked = true;
					}
					
					//检测是否应该暂停影片播放
					checkIsShouldPause();
										
					//开播时上次播放时间点和字幕提示
					if (_isFirstTips)
					{
						_isFirstTips = false;
						
						//切换清晰度时不提示
						if (!isChangeQuality)
						{
							var timeStr:String = Tools.formatTimes(_player.getFirstStartTime());
							if (timeStr != "00:00:00")
							{
								//开播时间等于0，显示上次观看时间点提示
								_noticeBar.setContent("已从上次观看时间点（" + timeStr + "）播放，<a href='event:replay'>我要从头看</a>", false, 5);
							}
						}
					}
					
					//左上角显示自动加载字幕的提示
					showAutoloadTips();
					
					//加载i帧截图
					initSnpt();
					
					if( !isFirstLoad )
					{
						this._mouseControl.Timer2.reset();
						this._mouseControl.Timer2.start();
					}
					
					isFirstLoad = false;
					isChangeQuality = false;
					_player.isBuffer = false;
					_isBuffering = false;
					break;
				case 'Progress':
					if (_player.streamInPlay) {
						//hwh
						var numProgress:Number;
						if ( !(GlobalVars.instance.isXLNetStreamValid == 1) && (_ctrBar.isClickBarSeek || _isPressKeySeek))
						{
							var preloaderDeler:Number = _player.streamInPlay.bufferTime / _player.totalTime * _player.totalByte;
							//JTracer.sendMessage("numProgress 1a:" + preloaderDeler);
							preloaderDeler = _player.streamInPlay.bytesTotal == 0 || _player.streamInPlay.bytesTotal > preloaderDeler ? preloaderDeler : _player.streamInPlay.bytesTotal;
							//JTracer.sendMessage("numProgress 1b:" + preloaderDeler);
							numProgress = _player.streamInPlay.bytesLoaded / preloaderDeler;
							/*JTracer.sendMessage("numProgress bytesLoaded:"+_player.streamInPlay.bytesLoaded +
							" bytesTotal:"+_player.streamInPlay.bytesTotal+
							" preloaderDeler:"+preloaderDeler+
							" 1c:" + numProgress);*/
						}
						else
						{
							numProgress = _player.streamInPlay.bufferLength / _player.streamInPlay.bufferTime;
							//JTracer.sendMessage("numProgress 2:" + numProgress + "bufferLength:" + _player.streamInPlay.bufferLength + " bufferTime:" + _player.streamInPlay.bufferTime);
						}
						
						_videoMask.updateProgress(numProgress < 0 ? 0 : numProgress);
					}
					break;
				case 'BufferStart':
					_player.is_invalid_time = true;
					_isBuffering = true;
					JTracer.sendMessage("PlayerCtrl -> playEventHandler, isBuffer:" + _player.isBuffer + ", isInvalidTime:" + _player.isInvalidTime);
					if (!_player.isBuffer || _player.isInvalidTime)
					{
						_bufferTip.addBreakCount(_player.time);
					}
					//stage.frameRate = 20;
					if( !isFirstLoad )
						this.normalPlayProgressBar();//遇到缓冲，进度条变大
					//trace("开始缓冲");
					break;
				case 'BufferEnd':
					_ctrBar.isClickBarSeek = false;
					_isPressKeySeek = false;
					_player.streamInPlay.resume();
					if (_player.isPause)
					{
						_player.streamInPlay.pause();
					}
					break;
				case 'OpenWindow':
					//弹出窗口
					_isStopNormal = false;
					_isShowStopFace = false;
					
					_ctrBar.dispatchStop();
					_videoMask.showErrorNotice();
					break;
			}
		}

		private function onDoubleClickHandle(e:MouseEvent):void
		{
			_isDoubleClick = true;
			ExternalInterface.call("flv_playerEvent","onDoubleClick");
			stage.displayState = stage.displayState == StageDisplayState.FULL_SCREEN?StageDisplayState.NORMAL:StageDisplayState.FULL_SCREEN;
			e.updateAfterEvent();
		}
		
		private function onStartPlayClick(evt:Event):void
		{
			onClickHandle(null);
		}
		
		private function onRefresh(evt:Event):void
		{
			// 点击刷新页面，检测是否登陆异常
			if( _videoMask.currentInfo == 'refreshPage' ){
				JTracer.sendMessage('refresh');
				ExternalInterface.call('function(){window.location.reload();}')
				return;
			}
			checkIsValid();
		}
		
		private function onClickHandle(e:MouseEvent):void
		{
			if (_isValid)
			{
				checkSuccess();
			}
			else
			{
				checkIsValid();
			}
		}
		
		private function checkSuccess():void
		{
			_isDoubleClick = false;
			var _time:Timer;
			if (stage.frameRate == 10) {
				_time = new Timer(700, 1);
			}else{
				_time = new Timer(260, 1);
			}
			_time.addEventListener(TimerEvent.TIMER, function(eve:TimerEvent):void {
				if (!_isDoubleClick) {
					ExternalInterface.call("flv_playerEvent", "onClick");
					if (!_player.isPause)
					{
						if (_player.isStartPause)
						{
							_player.isStartPause = false;
							_player.dispatchEvent(new PlayEvent(PlayEvent.PLAY_4_STAGE));
						}
						else
						{
							_player.dispatchEvent(new PlayEvent(PlayEvent.PAUSE_4_STAGE));
						}
					}else{
						_player.dispatchEvent(new PlayEvent(PlayEvent.PLAY_4_STAGE));
					}
				}
				//eve.updateAfterEvent();
			});
			_time.start();
		}
		
		protected function keyUpFunc(e:KeyboardEvent):void
		{
		}
		
		protected function keyDownFunc(event:KeyboardEvent):void
		{
			var seekTime:Number;
			var idx:int;
			trace( event.keyCode );
			switch( event.keyCode )
			{
				case 32:
					if (!_player.isPause){
						_player.dispatchEvent(new PlayEvent(PlayEvent.PAUSE_4_STAGE));
					}else{
						_player.dispatchEvent(new PlayEvent(PlayEvent.PLAY_4_STAGE));
					}
					break;
				case 37: //left
					//hwh
					if (GlobalVars.instance.isUseHttpSocket)
					{
						_isPressKeySeek = false;
					}
					else
					{
						_isPressKeySeek = true;
					}
					
					trace( "<-----" );
					if( _player.isStop || !_player.streamInPlay || _player.time <= 0 || _isNoEnoughBytes)
						return;
					if( _ctrBar._barBg.height == SMALL_PROGRESSBAR_HEIGTH && !_isFullScreen )
						normalPlayProgressBar();
					if (_player.streamInPlay)
					{
						_player.streamInPlay.pause();
					}
					_ctrBar._timerBP.stop();
					_mouseControl.Timer2.stop();
					
					seekTime = _player.time - 5;
					if (seekTime < 0)
					{
						seekTime = 0;
					}
					
					idx = _player.getNearIndex(_player.dragTime, seekTime, 1, _player.dragTime.length - 1) - 1;
					
					seekTime = _player.dragTime[idx];
					
					_ctrBar._barSlider.x = (_ctrBar._barWidth - 16) * seekTime / _player.totalTime;
					if( _ctrBar._barSlider.x < 0 )
						_ctrBar._barSlider.x = 0;
					else if( _ctrBar._barSlider.x > _ctrBar._barWidth - 16 )
						_ctrBar._barSlider.x = _ctrBar._barWidth - 16;
					_ctrBar._barPlay.width = _ctrBar._barSlider.x - _ctrBar._barPlay.x + 6;
					
					if( _seekDelayTimer )
					{
						_seekDelayTimer.reset();
						_seekDelayTimer.stop();
					}
					
					if( _seekDelayTimer2 && _seekDelayTimer2.running )
					{
						_seekDelayTimer2.reset();
						_seekDelayTimer2.start();
					}
					else
					{
						_seekDelayTimer2 = new Timer( 50 , 1 );
						_seekDelayTimer2.addEventListener(TimerEvent.TIMER_COMPLETE , function():void
						{
							_bufferTip.clearBreakCount();
							GlobalVars.instance.bufferType = GlobalVars.instance.bufferTypeKeyPress;
							
							JTracer.sendMessage("PlayerCtrl -> keyDownFunc, set bufferType:" + GlobalVars.instance.bufferType);
							
							_player.seek(seekTime);
							_ctrBar._timerBP.start();
						});
						_seekDelayTimer2.start();
					}
					_mouseControl.Timer2.start();
					break;
				case 39: //right
					//hwh
					if (GlobalVars.instance.isUseHttpSocket)
					{
						_isPressKeySeek = false;
					}
					else
					{
						_isPressKeySeek = true;
					}
					
					trace( "----->" );
					if( _player.isStop ||!_player.streamInPlay || _player.time <= 0 || _isNoEnoughBytes)
						return;
					if( _ctrBar._barBg.height == SMALL_PROGRESSBAR_HEIGTH && !_isFullScreen )
						normalPlayProgressBar();
					if (_player.streamInPlay)
					{
						_player.streamInPlay.pause();
					}
					_ctrBar._timerBP.stop();
					_mouseControl.Timer2.stop();
					
					seekTime = _player.time + 5;
					if (seekTime > _player.totalTime)
					{
						seekTime = _player.totalTime;
					}
					
					idx = _player.getNearIndex(_player.dragTime, seekTime, 0, _player.dragTime.length - 2) + 1;
					
					seekTime = _player.dragTime[idx];
					
					_ctrBar._barSlider.x = (_ctrBar._barWidth - 16) * seekTime / _player.totalTime;
					if( _ctrBar._barSlider.x < 0 )
						_ctrBar._barSlider.x = 0;
					else if( _ctrBar._barSlider.x > _ctrBar._barWidth - 16 )
						_ctrBar._barSlider.x = _ctrBar._barWidth - 16;
					_ctrBar._barPlay.width = _ctrBar._barSlider.x - _ctrBar._barPlay.x + 6;
					
					if( _seekDelayTimer2 )
					{
						_seekDelayTimer2.reset();
						_seekDelayTimer2.stop();
					}
					
					if( _seekDelayTimer && _seekDelayTimer.running )
					{
						_seekDelayTimer.reset();
						_seekDelayTimer.start();
					}
					else 
					{
						_seekDelayTimer = new Timer( 50 , 1 );
						_seekDelayTimer.addEventListener(TimerEvent.TIMER_COMPLETE , function():void
						{
							_bufferTip.clearBreakCount();
							GlobalVars.instance.bufferType = GlobalVars.instance.bufferTypeKeyPress;
							
							JTracer.sendMessage("PlayerCtrl -> keyDownFunc, set bufferType:" + GlobalVars.instance.bufferType);
							
							_player.seek(seekTime);
							_ctrBar._timerBP.start();
						});
						_seekDelayTimer.start();
					}
					_mouseControl.Timer2.start();
					break;
				case 38: //up
					if( _player.isStop )
						return;
					this._ctrBar.handleVolumeFromKey( true );
					break;
				case 40: //down
					if( _player.isStop )
						return;
					this._ctrBar.handleVolumeFromKey( false );
					break;
				case 107: //+
					if( _player.isStop )
						return;
					_ctrBar.handleVolumeFromKey( true );
					break;
				case 109: //-
					if( _player.isStop )
						return;
					_ctrBar.handleVolumeFromKey( false );
					break;
				
			}
		}
		
		private function handleAutoPlay(e:Event):void 
		{
			_ctrBar.setPlayStatus();
		}
		
		private function handleInitPause(e:Event):void
		{
			_videoMask.showInitPauseLogo();
		}
		
		private function handleSetQuality(e:Event):void 
		{
			var value:int = e.target.currentQuality;
			_player.visible = false;
			_bufferTip.visible = false;
		}
		
		private function handleMouseInside(e:Event):void
		{
			this.normalPlayProgressBar();
			//开播或正常停止不显示侧边栏
			if (_player.isStartPause || _isStopNormal || _player.time <= 0)
			{
				return;
			}
			handleMouseShowAndMove();
			
		}
		
		private function handleMouseMoveOut(e:Event):void
		{
			
		}
		
		private function handleMouseOutSide(e:Event):void
		{
			handleMouseHide();
		}
		
		private function handleMouseHide2( e:Event ):void
		{
			this.smallPlayProgressBar();
		}
		
		protected function handleMouseShowAndMove():void
		{
			if (_ctrBar._beFullscreen && _ctrBar.hidden)
			{
				_ctrBar.show();
				_noticeBar.show();
			}
		}
		protected function handleMouseHide():void{
			if (!_ctrBar.beMouseOnFormat)
			{
				_ctrBar.hideFormatSelector();
			}

			if (_player.isStartPause || _isStopNormal || _player.time <= 0)
			{
				return;
			}
			
			if (_ctrBar._beFullscreen && !_ctrBar.beMouseOn)
			{
				_ctrBar.hide();
				_noticeBar.hide();
			}
			if (_ctrBar.beMouseOn)
			{
				Mouse.show();
			}
		}

		private function normalPlayProgressBar():void
		{
			if( _ctrBar._barBg.height == this.SMALL_PROGRESSBAR_HEIGTH )
			{
				if(this._seekEnable){
					this._ctrBar._barSlider.visible = true;
				}
				this._ctrBar._barBg.height = this.NORMAL_PROGRESSBAR_HEIGTH;
				this._ctrBar._barBuff.height = this.NORMAL_PROGRESSBAR_HEIGTH;
				this._ctrBar._barPlay.height = this.NORMAL_PROGRESSBAR_HEIGTH;
				this._ctrBar._barPreDown.height = this.NORMAL_PROGRESSBAR_HEIGTH;
				
				_ctrBar._barBg.y = -6 ;
				_ctrBar._barBuff.y = -6;
				_ctrBar._barPlay.y = -6;
				_ctrBar._barPreDown.y = -6 ;
			}
		}
		private function smallPlayProgressBar():void
		{
			if( _ctrBar._barBg.height ==  NORMAL_PROGRESSBAR_HEIGTH )
			{
				if( !_isBuffering || isFirstLoad || _ctrBar._btnPauseBig.visible )
				{
					this._ctrBar._barSlider.visible =false;
					this._ctrBar._barBg.height = this.SMALL_PROGRESSBAR_HEIGTH;
					_ctrBar._barBg.y = -2;
					this._ctrBar._barBuff.height = this.SMALL_PROGRESSBAR_HEIGTH;
					_ctrBar._barBuff.y = -2;
					this._ctrBar._barPlay.height = this.SMALL_PROGRESSBAR_HEIGTH;
					_ctrBar._barPlay.y  = -2;
					this._ctrBar._barPreDown.height = this.SMALL_PROGRESSBAR_HEIGTH;
					_ctrBar._barPreDown.y = -2;									
				}
			}
		}
		
		private function adaptRealSize():void 
		{
			var _stageHeight:int = _isFullScreen ? stage.stageHeight : stage.stageHeight - 35;
			var _fullRatio:Number =  _stageHeight / stage.stageWidth;
			var _ratio:Number = _ratioVideo;
			var _cacheWidth:Number, _cacheHeight:Number;
			
			_cacheWidth = _player.nomarl_width;
			if (_setSizeInfo['ratio'] == '4_3')
			{
				_cacheHeight = 3 / 4 * _player.nomarl_width;
			} else if (_setSizeInfo['ratio'] == '16_9') {
				_cacheHeight = 9 / 16 * _player.nomarl_width;
			} else if (_setSizeInfo['ratio'] == 'full') {
				_cacheHeight = _fullRatio * _player.nomarl_width;
			} else {
				_cacheHeight = _player.nomarl_height;
			}
			
			if ((_cacheWidth / _cacheHeight) > (stage.stageWidth / _stageHeight)) {
				_ratio = _ratio == 0 ? stage.stageWidth / _cacheWidth : _ratio;
				_playerRealWidth = _cacheWidth * _ratio;
				_playerRealHeight = _cacheHeight * _ratio;
			}else {
				_ratio = _ratio == 0 ? _stageHeight / _cacheHeight : _ratio;
				_playerRealHeight = _cacheHeight * _ratio;
				_playerRealWidth = _cacheWidth * _ratio;
			}
			JTracer.sendMessage('_playerRealWidth:' + _playerRealWidth + ',_playerRealHeight:' + _playerRealHeight + ',_ratio:' + _ratio + ',_player.nomarl_width:' + _player.nomarl_width + ',_player.normal_height:' + _player.nomarl_height);
		}
		
		protected function updateVideoSizeFun():void
		{
			if (_setSizeInfo['size'] == '50'){
				_playerSize = 2;
			}else if (_setSizeInfo['size'] == '75') {
				_playerSize = 1;
			}else {
				_playerSize = 0;
			}
			changePlayerSize();
		}
		
		public function resizePlayerSize():void
		{
			var resizeTimer:Timer = new Timer(0, 1);
			resizeTimer.addEventListener(TimerEvent.TIMER, function():void {
				changePlayerSize();
			});
			resizeTimer.addEventListener(TimerEvent.TIMER_COMPLETE, function():void {
				resizeTimer.stop();
			});
			resizeTimer.start();
		}
		
		protected function changePlayerSize():void
		{
			adaptRealSize();
			var num:Number = 1 - _playerSize * 0.25;
			var rWidth:int = _playerRealWidth * num;
			var rHeight:int = _playerRealHeight * num;
			_player.width = rWidth;
			_player.height = rHeight;
			_player.x = (stage.stageWidth - rWidth) / 2;
			_player.y = ((_isFullScreen ? stage.stageHeight : stage.stageHeight - 35) - rHeight) / 2;
			JTracer.sendMessage('prWidth:' + rWidth + ',prHeight:' + rHeight + ',num:' + num + ',sWidth:' + stage.stageWidth + ',sHeight:' + stage.stageHeight + 'pWidth:' + _player.width + ',pHeight:' + _player.height);
		}
		
		private function on_stage_FULLSCREEN(e:FullScreenEvent):void 
		{
			JTracer.sendMessage('fullScreen=' + e.fullScreen + ',e.target='+e.currentTarget);
			_ctrBar.fullscreen = e.fullScreen;
			_ctrBar.show(true);
			_noticeBar.show(true);
			_mouseControl.fullscreen = e.fullScreen;
			addJustStageFullScreen(_player.time, e.fullScreen);
		}

		protected function addJustStageFullScreen(time:Number, isFullScreen:Boolean):void{
			_videoMask.setPosition();
			if (isFullScreen) {
				ExternalInterface.call("flv_playerEvent","onFullScreen");
				_isFullScreen = true;
				changePlayerSize();
				_playFullWidth = _player.width;
				_playFullHeight = _player.height;
				_ctrBar.y = stage.stageHeight - 33;
			}else {
				ExternalInterface.call("flv_playerEvent", "onExitFullScreen");
				_isFullScreen = false;
				changePlayerSize();
			}
		}
		
		public function flv_setFullScreen(b:*):void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_setFullScreen, 设置是否全屏:" + b);
			stage.displayState = b?StageDisplayState.FULL_SCREEN:StageDisplayState.NORMAL;
		}
		
		public function flv_play() :void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_play, 播放影片");
			_ctrBar.available = true;
			_ctrBar.visible = true;
			_ctrBar.dispatchPlay();
		}
		public function flv_pause():void 
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_pause, 暂停影片");
			if (!_player.isPause && !_player.isStartPause)
			{
				_ctrBar.dispatchPause();
			}
		}
		
		public function flv_stop():void 
		{
			JTracer.sendMessage('PlayerCtrl -> js回调flv_stop, 停止影片');
			_ctrBar.dispatchStop();
			_videoMask.bufferHandle('Stop');
		}
		public function flv_close() :void
		{
			JTracer.sendMessage('PlayerCtrl -> js回调flv_close, 停止影片并且关闭流');
			//isChangeQuality = false;
			//_ctrBar.dispatchStop();
			//_videoMask.bufferHandle('Stop');
			_player.clearUp();
		}
		
		public function clearSnpt():void
		{
			try
			{
				if (_iframeLoader)
				{
					_iframeLoader.removeEventListener(Event.COMPLETE, onIframeComplete);
					_iframeLoader.removeEventListener(IOErrorEvent.IO_ERROR, onIframeIOError);
					_iframeLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onIframeSecurityError);
					_iframeLoader = null;
				}
			}
			catch (e:Error)
			{
				
			}
			if (_snptLoader)
			{
				try
				{
					_snptLoader.unloadAndStop();
					
				}
				catch (e:Error)
				{
					
				}
				_snptLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onSnptLoaded);
				_snptLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onSnptIOError);
				_snptLoader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSnptSecurityError);
				_snptLoader = null;
			}
			_snptIndex = 0;
			_snptArray = [];
			_snptAllArray = [];
			_snptBmdArray = [];
		}
		
		public function flv_setPlayeUrl(arr:Array):void
		{
			var urlStr:String = "PlayerCtrl -> js回调flv_setPlayeUrl, 设置播放地址:";
			for (var i:* in arr[0])
			{
				if (i == "pageLoadTime")
				{
					var loadtime_str:String = "";
					for (var j:* in arr[0][i])
					{
						loadtime_str += "\n" + j + ":" + arr[0][i][j];
					}
					urlStr += "\n" + "arr[0]." + i + ":" + loadtime_str;
				}
				else
				{
					urlStr += "\n" + "arr[0]." + i + ":" + arr[0][i];
				}
			}
			JTracer.sendMessage(urlStr);
			_player.is_invalid_time = true;
			
			//是否已加载i帧截图
			_isSnptLoaded = false;
			
			GlobalVars.instance.loadTime = arr[0].pageLoadTime;
			GlobalVars.instance.getVodTime = 0;

			//bt列表截图使用xlpan地址
			GlobalVars.instance.isUseXlpanKanimg = int(arr[0].useXlpanKanimg) != -1;
			GlobalVars.instance.screenshot_size = arr[0].screenshot_size || GlobalVars.instance.screenshot_size;
			JTracer.sendMessage('useXlpanKanimg:'+GlobalVars.instance.isUseXlpanKanimg + ' screenSize:' + GlobalVars.instance.screenshot_size);
			
			//应用多链的机房
			arr[0].machines = arr[0].machines || {};
			GlobalVars.instance.httpSocketMachines = arr[0].machines;
			GlobalVars.instance.isUseHttpSocket = false;
			GlobalVars.instance.isHeaderGetted = false;
			
			//清空Socket数据
			StreamList.clearHeader();
			StreamList.clearCurList();
			StreamList.clearNextList();
			
			//2.8.45 多链接支持
			GlobalVars.instance.isFirstBuffer302 = true;
			GlobalVars.instance.isReplaceURL = false;
			GlobalVars.instance.isChangeURL = true;
			GlobalVars.instance.vodURLList = [];
			GlobalVars.instance.allURLList = [];
			GlobalVars.instance.isVodGetted = false;
			var listStr:String = "flv_setPlayeUrl -> play url list:\n";
			for (var j:* in arr[0].urls)
			{
				listStr += "link:" + (j + 1) + ", url:" + arr[0].urls[j] + "\n";
				GlobalVars.instance.vodURLList.push( { url:arr[0].urls[j], link:(j + 1), isdl:true } );
				GlobalVars.instance.allURLList.push( { url:arr[0].urls[j], link:(j + 1), isdl:true } );
			}
			listStr += "link:" + (GlobalVars.instance.vodURLList.length + 1) + ", url:" + arr[0].url;
			JTracer.sendMessage(listStr);
			
			var link:int = GlobalVars.instance.vodURLList.length + 1;
			GlobalVars.instance.vodURLList.push( { url:arr[0].url, link:link, isdl:false } );
			GlobalVars.instance.allURLList.push( { url:arr[0].url, link:link, isdl:false } );
			GlobalVars.instance.linkNum = arr[0].urls ? arr[0].urls.length : 0;
			_player.originGdlUrl = arr[0].url;
			
			_isPlayStart = false;
			_isFlowChecked = false;
			
			//有流量用户检测是否有足够时长，网盘用户不检测
			var vodPermit:Number = Number(Tools.getUserInfo("vodPermit"));
			if ((vodPermit == 6 || vodPermit == 8 || vodPermit == 10) && Tools.getUserInfo("from") != GlobalVars.instance.fromXLPan)
			{
				var req:URLRequest = new URLRequest(GlobalVars.instance.url_check_flow + "userid/" + Tools.getUserInfo("userid") + "?t=" + new Date().time);
				JTracer.sendMessage("PlayerCtrl -> flv_setPlayeUrl, 查询时长, url:" + req.url);
				_checkFlowLoader.load(req);
			}
			
			//播放新地址时，初始化输入地址播放面板
			if (!isChangeQuality)
			{
				//非切换清晰度
				_bufferTip.clearBreakCount();
				GlobalVars.instance.bufferType = GlobalVars.instance.bufferTypeFirstBuffer;
				
				JTracer.sendMessage("PlayerCtrl -> flv_setPlayeUrl, set bufferType:" + GlobalVars.instance.bufferType);
				
				_videoMask.initInputFace();
			}
			else
			{
				//切换清晰度
				_bufferTip.clearBreakCount();
				GlobalVars.instance.bufferType = GlobalVars.instance.bufferTypeChangeFormat;
				
				_bufferTip.addBreakCount(arr[0].start);
				
				JTracer.sendMessage("PlayerCtrl -> flv_setPlayeUrl, set bufferType:" + GlobalVars.instance.bufferType);
			}
			
			//点播时默认流量充足
			_isNoEnoughBytes = false;
			_videoUrlArray = arr;
			_ctrBar.visible = true;
			//重置宽高比例
			//_setSizeInfo['ratio'] = 'common';
			//去掉filter
			//_player.filters = [];
			_player.retryLastTimeStat = arr[0].isRetryLastTime ? "&errorRetry=end" : "";
			_player.hasNextStream = true;
			Tools.getFormat();

			var isUseP2P:Boolean =  false;		

			JTracer.sendMessage('is ios page :' + GlobalVars.instance.isMacWebPage)
			if(Player.p2p_type == 'p2s' || GlobalVars.instance.isMacWebPage || !isUseP2P){
				GlobalVars.instance.isXLNetStreamValid = 0;
				_player.setPlayUrl(arr);
				return;
			}
			
		}

		public function initSnpt():void
		{
			if (!_isSnptLoaded)
			{
				_isSnptLoaded = true;
				
				//加载i帧截图
				_snptIndex = 0;
				_snptBmdArray = [];
				_isReportedScreenShotError = false;
				if (_snptAllArray.length == 0)
				{
					clearSnpt();
					
					var iframeUrl:String = GlobalVars.instance.url_iframe + "?userid=" + Tools.getUserInfo("userid") + "&url=" + encodeURIComponent(Tools.getUserInfo("url"));
					JTracer.sendMessage("PlayerCtrl -> iframe url start load, url:" + iframeUrl);
					_iframeLoader = new URLLoader();
					_iframeLoader.addEventListener(Event.COMPLETE, onIframeComplete);
					_iframeLoader.addEventListener(IOErrorEvent.IO_ERROR, onIframeIOError);
					_iframeLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onIframeSecurityError);
					_iframeLoader.load(new URLRequest(iframeUrl + "&d=" + new Date().time));
				}
				else
				{
					_snptArray = getCurSnptArray();
					loadSnpt();
				}
			}
		}
		
		public function flv_stageVideoInfo():int
		{
			return 0;
		}
		
		public function flv_getNsCurrentFps():Number
		{
			var fps:Number = _player.nsCurrentFps;
			JTracer.sendMessage("PlayerCtrl -> js回调flv_getNsCurrentFps, 返回影片帧率:" + fps);
			return fps;
		}
		
		public function flv_getCurrentFps():Number
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_getCurrentFps, 返回swf帧率:" + stage.frameRate);
			return stage.frameRate;
		}
		
		public function flv_changeStageVideoToVideo():void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_changeStageVideoToVideo, stageVideo to video");
		}
		
		public function flv_getPlayUrl():String
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_getPlayUrl, 返回播放地址:" + _player.playUrl);
			return _player.playUrl;
		}
		
		public function flv_getStreamBytesLoaded():Number
		{
			var bytes:Number = 0;
			if (_player.streamInPlay) {
				bytes = _player.streamInPlay.bytesLoaded;
			}
			JTracer.sendMessage("PlayerCtrl -> js回调flv_getStreamBytesLoaded, 返回影片已下载数:" + bytes);
			return bytes;
		}
		//获取当前播放影片长度，返回数据单位为秒
		public function getDuration():int 
		{
			var total:Number = _player.totalTime;
			JTracer.sendMessage("PlayerCtrl -> js回调getDuration, 返回总时长:" + total);
			return total;
		}
		
		private function flv_getBufferBugInfo():String
		{
			var str:String = '';
			if (_player.streamInPlay) {
				str = String(_player.streamInPlay.bufferLength) + '_' + String(_player.streamInPlay.bufferTime);
			}
			JTracer.sendMessage("PlayerCtrl -> js回调flv_getBufferBugInfo, 返回:" + str);
			return str;
		}
		
		private function flv_getBufferLength():Number
		{
			var bt:Number = _player.streamBufferTime;
			JTracer.sendMessage("PlayerCtrl -> js回调flv_getBufferLength, 返回缓冲时长:" + bt);
			return  bt;
		}
		
		public function setBufferTime(time:Number):void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调setBufferTime, 设置缓冲时间_player.bufferTime:" + time);
			_player.bufferTime = time;
		}
		
		private function flv_changeBufferTime(time:Number):void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_changeBufferTime, 设置缓冲时间:" + time);
			_player.bufferTime = time;
		}
		
		public function flv_setSeekPos(time:Number):void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_setSeekPos, 设置拖动时间点:" + time);
			_player.setSeekPos(time);
		}
		
		public function flv_setNoticeMsg(str:String, count:Boolean = false, showTime:int = 15, type:int = 1, callBackFun:String = null, start:int = 0, length:int = 0):void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_setNoticeMsg, 设置提示文字:" + str + ", 是否一直显示:" + count + ", 不是一直显示时自动关闭时间:" + showTime);
			_noticeBar.setContent(str, count, showTime, type, callBackFun, start, length);
		}
		
		/**
		 * 试播倒计时
		 * @param	time	倒计时，秒
		 */
		public function flv_setNoticeCountDown(time:Number):void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_setNoticeCountDown, 设置试播倒计时:" + time);
			_noticeBar.setCountDown(time);
		}
		
		private function flv_closeNotice():void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_closeNotice, 关闭提示条");
			
			hideNoticeBar();
		}
		
		public function hideNoticeBar():void
		{
			_noticeBar.hideNoticeBar();
		}
		
		private function flv_setVideoSize(num:Number):void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_setVideoSize, 设置视频比例:" + num);
			if (num < 0) return;
			_ratioVideo = num;
			changePlayerSize();
		}
		
		private function flv_getRealVideoSize():Object
		{
			var sizeObject:Object = { 'realWidth':_player.nomarl_width, 'realHeight':_player.nomarl_height };
			JTracer.sendMessage("PlayerCtrl -> js回调flv_getRealVideoSize, 返回视频宽高object:{'realWidth':" + sizeObject['realWidth'] + ", 'realHeight':" + sizeObject['realHeight'] + "}");
			return sizeObject;
		}
		
		private function flv_setIsChangeQuality(ischange:Boolean):void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_setIsChangeQuality, 设置是否切换清晰度:" + ischange);
			isChangeQuality = ischange;
		}
		
		private function flv_getSetStatusInfo():Object
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_getSetStatusInfo");
			return {};
		}
		
		protected function initJsInterface():void{
			if (ExternalInterface.available)
			{
				ExternalInterface.addCallback('flv_getDefaultFormat', flv_getDefaultFormat);
				ExternalInterface.addCallback('getDownloadSpeed', getDownloadSpeed);//获取下载速度
				ExternalInterface.addCallback('getDuration', getDuration);
				ExternalInterface.addCallback('flv_play', flv_play);
				ExternalInterface.addCallback('flv_pause', flv_pause);
				ExternalInterface.addCallback('flv_stop', flv_stop);
				ExternalInterface.addCallback('flv_close', flv_close);
				ExternalInterface.addCallback('flv_setPlayeUrl', flv_setPlayeUrl);
				ExternalInterface.addCallback('getPlayProgress', getPlayProgress);
				ExternalInterface.addCallback('getBufferProgress', getBufferProgress);
				ExternalInterface.addCallback("setSubTitleUrl", setSubTitleUrl);
				ExternalInterface.addCallback("cancelSubTitle", cancelSubTitle);
				ExternalInterface.addCallback('getVolume', getVolume);
				ExternalInterface.addCallback('setVolume', setVolume);
				ExternalInterface.addCallback('getPlayStatus', getPlayStatus);
				ExternalInterface.addCallback('getPlaySize', getPlaySize);
				ExternalInterface.addCallback('setPlaySize', setPlaySize);
				ExternalInterface.addCallback('getErrorInfo', getErrorInfo);
				ExternalInterface.addCallback('flv_showErrorInfo', flv_showErrorInfo);
				ExternalInterface.addCallback('flv_setFullScreen', flv_setFullScreen);
				ExternalInterface.addCallback('setBufferTime', setBufferTime);
				ExternalInterface.addCallback('getBufferEnd', getBufferEnd);
				ExternalInterface.addCallback('flv_setSeekPos', flv_setSeekPos);
				ExternalInterface.addCallback('flv_setNoticeMsg', flv_setNoticeMsg);
				ExternalInterface.addCallback('flv_setNoticeCountDown', flv_setNoticeCountDown);
				ExternalInterface.addCallback('flv_closeNotice', flv_closeNotice);
				ExternalInterface.addCallback('flv_changeBufferTime', flv_changeBufferTime);
				ExternalInterface.addCallback('flv_setVideoSize', flv_setVideoSize);
				ExternalInterface.addCallback('flv_getRealVideoSize', flv_getRealVideoSize);
				ExternalInterface.addCallback('flv_setIsChangeQuality', flv_setIsChangeQuality);
				ExternalInterface.addCallback('flv_getSetStatusInfo', flv_getSetStatusInfo);
				ExternalInterface.addCallback('flv_getBufferLength', flv_getBufferLength);
				ExternalInterface.addCallback('flv_getBufferBugInfo', flv_getBufferBugInfo);
				ExternalInterface.addCallback('flv_stageVideoInfo', flv_stageVideoInfo);
				ExternalInterface.addCallback('flv_getNsCurrentFps', flv_getNsCurrentFps);
				ExternalInterface.addCallback('flv_getCurrentFps', flv_getCurrentFps);
				ExternalInterface.addCallback('flv_changeStageVideoToVideo', flv_changeStageVideoToVideo);
				ExternalInterface.addCallback('flv_getPlayUrl', flv_getPlayUrl);
				ExternalInterface.addCallback('flv_getStreamBytesLoaded', flv_getStreamBytesLoaded);
				ExternalInterface.addCallback('flv_closeNetConnection', flv_closeNetConnection);
				ExternalInterface.addCallback('flv_showFormats', flv_showFormats);
				ExternalInterface.addCallback('flv_seek', flv_seek);
				ExternalInterface.addCallback('flv_setBarAvailable', flv_setBarAvailable);
				ExternalInterface.addCallback('flv_setIsShowNoticeClose', flv_setIsShowNoticeClose);
				ExternalInterface.addCallback('flv_getFlashVersion', flv_getFlashVersion);
				ExternalInterface.addCallback('flv_getTimePlayed', flv_getTimePlayed);
				ExternalInterface.addCallback('flv_setFeeParam', flv_setFeeParam);
				ExternalInterface.addCallback('flv_playOtherFail', flv_playOtherFail);
				ExternalInterface.addCallback('flv_showBarNotice', flv_showBarNotice);
				ExternalInterface.addCallback('flv_setToolBarEnable', flv_setToolBarEnable);
				ExternalInterface.addCallback('flv_ready', flv_ready);
			}
		}

		public function flv_ready():Boolean{return true;}
		
		public function flv_getDefaultFormat():String
		{
			var defaultFormat:String = Cookies.getCookie('defaultFormat');
			if (!defaultFormat || defaultFormat === "")
			{
				defaultFormat = "p";
			}
			
			var urlStr:String = "PlayerCtrl -> js回调flv_getDefaultFormat, 取得默认清晰度:" + defaultFormat;
			JTracer.sendMessage(urlStr);
			
			return defaultFormat;
		}
				
		public function flv_showErrorInfo():void
		{
			var urlStr:String = "PlayerCtrl -> js回调flv_showErrorInfo, 显示204后三次重试失败界面";
			JTracer.sendMessage(urlStr);
			//非403显示一半错误信息;
			if(!_player.playEnd)
			showPlayError(null);
		}
		
		public function flv_showBarNotice(str:String, showTime:uint = 0):void
		{
			var urlStr:String = "PlayerCtrl -> js回调flv_showBarNotice, 显示ctrBar提示，提示文字:" + str + ", 显示时间:" + showTime;
			JTracer.sendMessage(urlStr);
			
			_ctrBar.showBarNotice(str, showTime);
		}
				
		public function flv_playOtherFail(boo:Boolean, tips:String = ""):void
		{
			var urlStr:String = "PlayerCtrl -> js回调flv_playOtherFail, 切换新视频, 是否切换成功:" + boo + ", tips:" + tips;
			JTracer.sendMessage(urlStr);
			
			GlobalVars.instance.isExchangeError = !boo;
			
			//取消字幕
			cancelSubTitle();
			
			if (!boo)
			{
				_isStopNormal = false;
				_isShowStopFace = false;
				
				_ctrBar.dispatchStop();
				_videoMask.showErrorNotice(VideoMask.exchangeError, null, tips);
				
				var formatObj:Object = { "y": { "checked":false, "enable":false }, "c": { "checked":false, "enable":false }, "p": { "checked":false, "enable":false }, "g": { "checked":false, "enable":false }};
				_ctrBar.showFormatLayer(formatObj);
			}
		}
		
		/**
		 * 设置扣费参数
		 * @param	obj		扣费参数
		 * 
		 * obj.gcid
		 * obj.ygcid
		 * obj.userid
		 * obj.cid
		 * obj.ycid
		 * obj.name
		 * obj.sessionid
		 * obj.url_hash
		 * obj.from
		 * obj.url 原始url
		 * obj.index
		 * obj.filesize
		 * obj.isvip
		 * obj.info_hash
		 * obj.userType
		 * obj.vodPermit
		 */
		public function flv_setFeeParam(obj:Object):void
		{
			var urlStr:String = "PlayerCtrl -> js回调flv_setFeeParam, 设置扣费参数:";
			for (var i:* in obj)
			{
				urlStr += "\n" + "obj." + i + ":" + obj[i];
			}
			JTracer.sendMessage(urlStr);
			
			GlobalVars.instance.curFileInfo = obj;
			if (obj.url.indexOf("bt://") == 0)
			{
				Tools.setUserInfo("urlType", "bt");
			}
			else if (obj.url.indexOf("magnet:?") == 0)
			{
				Tools.setUserInfo("urlType", "magnet");
				
				var info_hash_url:String = obj.url.substr(obj.url.indexOf("xt=urn:btih:"));
				var params_arr:Array = info_hash_url.split("&");
				var info_hash_arr:Array = params_arr[0].toString().split(":");
				Tools.setUserInfo("info_hash", info_hash_arr[info_hash_arr.length - 1].toUpperCase());
			}
			else
			{
				Tools.setUserInfo("urlType", "url");
			}
			
			if (!_isReported)
			{
				_isReported = true;
				
				//flash引用页地址
				var quoteURL:String = ExternalInterface.call("function(){return document.location.href;}");
				Tools.stat("f=quoteURL&url=" + quoteURL);
			}
			
			//字幕
			GlobalVars.instance.hasSubtitle = Number(obj.subtitle) == 1 ? true : false;
			
			//没有内嵌字幕时，底部显示字幕按钮
			if (_ctrBar)
			{
				if (!GlobalVars.instance.hasSubtitle)
				{
					_ctrBar.showCaptionBtn();
				}
				else
				{
					_ctrBar.hideCaptionBtn();
				}
			}
		}
		
		public function flv_getTimePlayed():Object
		{
			var timePlayed:Number = _player.timePlayed / 1000;
			var bytePlayed:Number = timePlayed * _player.totalByte / _player.totalTime || 0;
			var byteDownload:Number = _player.downloadBytes;
			JTracer.sendMessage("PlayerCtrl -> js回调flv_getTimePlayed, 获取播放时长, timePlayed:" + timePlayed + ", bytePlayed:" + bytePlayed + ", byteDownload:" + byteDownload);
			return {playedtime:timePlayed, playedbyte:bytePlayed, downloadbyte:byteDownload};
		}
		
		public function flv_setToolBarEnable(obj:Object):void
		{
			var urlStr:String = "PlayerCtrl -> js回调flv_setToolBarEnable, 设置工具栏按钮是否可点:";
			for (var i:* in obj)
			{
				urlStr += "\n" + "obj." + i + ":" + obj[i];
			}
			JTracer.sendMessage(urlStr);
			
			GlobalVars.instance.enableShare = obj.enableShare;
			
			if (_ctrBar)
			{
				_ctrBar.enableFileList = obj.enableFileList || false;
			}
		}
				
		public function flv_getFlashVersion():String
		{
			var ver:String = Capabilities.version;
			JTracer.sendMessage("PlayerCtrl -> js回调flv_getFlashVersion, 获取flashplayer版本号, 版本号为:" + ver);
			return ver;
		}
		
		public function flv_setIsShowNoticeClose(flag:Boolean):void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_setIsShowNoticeClose, 设置是否显示关闭按钮:" + flag);
			if (_noticeBar)
			{
				_noticeBar.showCloseBtn(flag);
			}
		}
		
		public function flv_setBarAvailable(flag:Boolean):void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_setBarAvailable, 设置控制条是否可拖动:" + flag);
			if (_ctrBar)
			{
				_ctrBar.barEnabled = flag;
			}
		}
		
		public function setSubTitleUrl(url:String):void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调setSubTitleUrl, 设置字幕url:" + url);
			_subTitle.loadContent({surl:url, scid:null, sname:null, isSaveAutoload:false, isRetry:false, gradeTime:180});
		}
		
		public function cancelSubTitle():void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调cancelSubTitle, 取消字幕");
			_subTitle.hideCaption({surl:null, scid:null});
		}
		
		public function getDownloadSpeed():Number
		{
			var speed:Number = _player.downloadSpeed;
			JTracer.sendMessage("PlayerCtrl -> js回调getDownloadSpeed, 返回下载速度:" + speed);
			return speed;
		}
		
		private function getErrorInfo():String
		{
			var result:String;
			result = _player.errorInfo;
			if (result == "")
			{
				result = _ctrBar.errorInfo();
			}
			JTracer.sendMessage("PlayerCtrl -> js回调getErrorInfo, 返回错误码:" + result);
			return result;
		}
		
		private function setPlaySize(width:Number, height:Number):void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调setPlaySize, 设置影片宽:" + width + ", 高:" + height);
			_player.width = width;
			_player.height = height;	
			_player.x = (stage.stageWidth-_player.width) / 2;
			if (stage.displayState == StageDisplayState.NORMAL)
			{
				_player.y = (stage.stageHeight - _player.height) / 2;	
			}else {
				_player.y = (stage.stageHeight - _player.height + 40) / 2;			
			}			
		}
		
		private function getPlaySize():String
		{
			var playWidth:Number;
			var playHeight:Number;
			if (stage.displayState == StageDisplayState.NORMAL)
			{
				playWidth = _player.nomarl_width;
				playHeight = _player.nomarl_height;
			}else {
				playWidth = _playFullWidth;
				playHeight = _playFullHeight;				
			}
			JTracer.sendMessage("PlayerCtrl -> js回调getPlaySize, 返回影片宽,高:" + playWidth + "," + playHeight);
			return playWidth + "," + playHeight;
		}
		
		private function getPlayStatus():Number
		{
			var status:Number = _ctrBar.getPlayStatus();
			JTracer.sendMessage("PlayerCtrl -> js回调getPlayStatus, 返回播放状态:" + status);
			return status;
		}
		
		private function setVolume(value:Number):void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调setVolume, 设置音量:" + value);
			_ctrBar.setVolume(value);
		}
		
		private function getVolume():Number
		{
			var vol:Number = _ctrBar.getVolume();
			JTracer.sendMessage("PlayerCtrl -> js回调getVolume, 返回音量:" + vol);
			return vol;
		}
		
		private function getBufferProgress():Number
		{
			var pgs:Number = _ctrBar.getBufferProgress();
			JTracer.sendMessage("PlayerCtrl -> js回调getBufferProgress, 返回缓冲进度为:" + pgs);
			return pgs;
		}
		
		private function getPlayProgress(isTime:Boolean):Number
		{
			var result:Number = _ctrBar.getPlayProgress(isTime);
			JTracer.sendMessage("PlayerCtrl -> js回调getPlayProgress, 设置是否返回播放时间(false返回播放百分比):" + isTime + ", 返回的播放时间或播放百分比为:" + result);
			return result;
		}
		
		private function getBufferEnd():Number
		{
			var bn:Number = _player.bufferEndTime;
			JTracer.sendMessage("PlayerCtrl -> js回调getBufferEnd, 返回_player.bufferEnd:" + bn);
			return bn;
		}
		
		protected function hideSideChangeQuilty():void
		{
			if (_ctrBar._beFullscreen)
			{
				_ctrBar.hide();
				_noticeBar.hide();
			}
		}
				
		private function orderArrFun(a:Number, b:Number):int
		{
			if (a > b) {
				return -1;
			}else if (b > a) {
				return 1;
			}else {
				return 0;
			}
		}
		
		/*以下是变量调用接口*/
		public function set isFirstLoad(boo:Boolean):void
		{
			_isFirstLoad = boo;
			_videoMask.isFirstLoading = boo;
		}
		
		public function get isFirstLoad():Boolean
		{
			return _isFirstLoad;
		}
		
		public function set isChangeQuality(boo:Boolean):void
		{
			_isChangeQuality = boo;
			_player.isChangeQuality = boo;
			_videoMask.isQualityLoading = boo;
			_ctrBar.isChangeQuality = boo;
		}
		
		public function get isChangeQuality():Boolean
		{
			return _isChangeQuality;
		}
		
		public function flv_closeNetConnection():void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_closeNetConnection, 关闭连接");
			_player.closeNetConnection();
		}
		
		public function flv_showFormats(formats:Object):void
		{
			_formatsObj = formats;
			_ctrBar.showFormatLayer(formats);
		}
		
		public function flv_seek(time:Number = 0):void
		{
			if (!_isNoEnoughBytes)
			{
				JTracer.sendMessage("PlayerCtrl -> js回调flv_seek, 设置拖动的时间点:" + time);
				
				//页面重连时重新请求socket
				GlobalVars.instance.isVodGetted = false;
				
				_bufferTip.clearBreakCount();
				GlobalVars.instance.bufferType = GlobalVars.instance.bufferTypeError;
				
				JTracer.sendMessage("PlayerCtrl -> flv_seek, set bufferType:" + GlobalVars.instance.bufferType);
				
				_player.seek(time, true);
			}
		}
		
		//是否正在缓冲
		public function get isBuffering():Boolean
		{
			return _isBuffering;
		}
		
		//是否有效账户
		public function get isValid():Boolean
		{
			return _isValid;
		}
		
		public function set isValid(value:Boolean):void
		{
			_isValid = value;
		}
		
		//是否流量不足
		public function get isNoEnoughBytes():Boolean
		{
			return _isNoEnoughBytes;
		}
		
		public function set isNoEnoughBytes(boo:Boolean):void
		{
			_isNoEnoughBytes = boo;
		}
		
		//是否正常停止
		public function get isStopNormal():Boolean
		{
			return _isStopNormal;
		}
		
		public function set isStopNormal(boo:Boolean):void
		{
			_isStopNormal = boo;
		}
		
		//影片是否已经开播
		public function get isPlayStart():Boolean
		{
			return _isPlayStart;
		}
		
		//是否显示播放完界面
		public function get isShowStopFace():Boolean
		{
			return _isShowStopFace;
		}
		
		public function set isShowStopFace(boo:Boolean):void
		{
			_isShowStopFace = boo;
		}

		// 播放下一集视频
		public function playNext():void
		{
			return;
		}

		//是否有下一集
		public function get isHasNext():Boolean
		{
			return false;
		}

		//i帧截图图片数据
		public function get snptBmdArray():Array
		{
			return _snptBmdArray;
		}
		
		public function get isFirstOnplaying():Boolean
		{
			return _isFirstOnplaying;
		}
		
		public function set isFirstOnplaying(v:Boolean):void
		{
			_isFirstOnplaying = v;
		}
		
		public function showLowSpeedTips():void
		{
			var globalVars:GlobalVars = GlobalVars.instance;
			globalVars.isHideLowSpeedTips = Cookies.getCookie('hideLowSpeedTips');
			if (globalVars.isHideLowSpeedTips)
			{
				return;
			}
			
			_noticeBar.setContent("当前网速较慢，建议暂停缓冲一会再播放", false, 12);
			_noticeBar.setRightContent("<a href='event:hideLowSpeedTips'>不再提示</a>");
			
			/*
			if (globalVars.movieFormat == "c")
			{
				//_noticeBar.setContent("当前网速较慢，建议您切换到 <a href='event:backToGaoQing'>高清</a>", false, 12);
				_noticeBar.setContent("当前网速较慢，建议暂停缓冲一会再播放", false, 12);
				_noticeBar.setRightContent("<a href='event:hideLowSpeedTips'>不再提示</a>");
			}
			else if (globalVars.movieFormat == "g")
			{
				//_noticeBar.setContent("当前网速较慢，建议您切换到 <a href='event:backToLiuChang'>流畅</a>", false, 12);
				_noticeBar.setContent("当前网速较慢，建议暂停缓冲一会再播放", false, 12);
				_noticeBar.setRightContent("<a href='event:hideLowSpeedTips'>不再提示</a>");
			}
			*/
		}
		protected function mouseWheel(delta:Number):void{
			if( _isFullScreen )
			{
				if( delta > 0 )
					_ctrBar.handleVolumeFromKey( true );
				else
					_ctrBar.handleVolumeFromKey( false );
			}
		}
		public function showHighSpeedTips(higherFormat:String, speed:Number):void
		{
			var globalVars:GlobalVars = GlobalVars.instance;
			globalVars.isHideHighSpeedTips = Cookies.getCookie('hideHighSpeedTips');
			if (globalVars.isHideHighSpeedTips)
			{
				return;
			}
			
			if (higherFormat == "g")
			{
				_noticeBar.setContent("该视频支持更高清晰度，切换到 <a href='event:goToGaoQing'>高清</a>", false, 12);
				_noticeBar.setRightContent("<a href='event:hideHighSpeedTips'>不再提示</a>");
			}
			else if (higherFormat == "c")
			{
				_noticeBar.setContent("该视频支持更高清晰度，切换到 <a href='event:goToChaoQing'>超清</a>", false, 12);
				_noticeBar.setRightContent("<a href='event:hideHighSpeedTips'>不再提示</a>");
			}
		}
		
		public function get isHasLowerFormat():Boolean
		{
			var globalVars:GlobalVars = GlobalVars.instance;
			if (globalVars.movieFormat == "c" || globalVars.movieFormat == "g")
			{
				return true;
			}
			
			return false;
		}
		
		public function get isHasHigherFormat():Boolean
		{
			var globalVars:GlobalVars = GlobalVars.instance;
			if (globalVars.movieFormat == "p" && _formatsObj && _formatsObj["g"] && _formatsObj["g"].enable)
			{
				return true;
			}
			else if (globalVars.movieFormat == "g" && _formatsObj && _formatsObj["c"] && _formatsObj["c"].enable)
			{
				return true;
			}
			
			return false;
		}
		
		public function get isStartPlayLoading():Boolean
		{
			return _videoMask.isStartPlayLoading;
		}
		
		// 字幕时间计算
		private function handlGetTitleTimer(e:CaptionEvent):void
		{
			var subtitle:Subtitle = e.target as Subtitle;
			var isvalid:Boolean = !(_player.isPause || _player.isStop || isBuffering);
			if(isvalid)
			subtitle.setPlayerTime(_player.time, isStartPlayLoading);
		}
	}
}