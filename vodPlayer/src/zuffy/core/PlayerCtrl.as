﻿package zuffy.core
{
	import com.Player;
	import com.common.Cookies;
	import zuffy.ctr.manager.CheckUserManager;
	import com.global.GlobalVars;
	import com.serialization.json.JSON;
	import com.slice.StreamList;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.system.Capabilities;
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

	import zuffy.ctr.contextMenu.CreateContextMenu;
	import zuffy.display.CtrBar;
	import zuffy.display.MouseControl;
	import zuffy.display.notice.NoticeBar;
	import zuffy.display.notice.bufferTip;
	import zuffy.display.statuMenu.VideoMask;
	import zuffy.events.CaptionEvent;
	import zuffy.events.ControlEvent;
	import zuffy.events.PlayEvent;
	import zuffy.events.SetQulityEvent;
	import zuffy.utils.Tools;
	import zuffy.utils.JTracer;
	import zuffy.ctr.manager.SubtitleManager;
	import zuffy.ctr.manager.CtrBarManager;
	import zuffy.net.VodRequestManager;
	
	// 字幕接口
	import zuffy.interfaces.ICaption;

	// 请求代理接口
	import zuffy.interfaces.IVodRequester;
	import zuffy.ctr.module.VODReqBackDataModule;

	public class PlayerCtrl extends Sprite implements ICaption, IVodRequester {
		
		protected var _setSizeInfo:Object = { 'ratio':'common', 'size':'100', 'ratioValue':0, 'sizeValue':1 };
		
		//private var _ctrBar:CtrBar;							// 控制栏
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
		
		private var _isPressKeySeek:Boolean;//是否按住键盘左右键seek
		private var _isNoEnoughBytes:Boolean;				//是否流量不足
		private var _videoUrlArray:Array;
		private var _isFirstTips:Boolean = true;			//是否第一次提示上次播放时间点或字幕提示
		private var _isFirstRemainTips:Boolean = true;		//是否第一次提示时长
		private var _isStopNormal:Boolean;					//是否正常停止
		private var _isFirstOnplaying:Boolean = true;		//是否第一次触发onplaying
		private var _isReported:Boolean = false;			//是否已经上报版本号或用户域名
		private var _playerTxtTipsID:uint;
		private var _remainTimes:Number;					//剩余时长
		private var _expiresTime:Number;					//过期时间
		private var _isFlowChecked:Boolean;					//是否已经查询完流量
		private var _isPlayStart:Boolean;					//影片是否已经开播
		private var _isShowStopFace:Boolean;				//是否显示播放完界面
		
		private var _formatsObj:Object;
		private var _isShowAutoloadTips:Boolean;

		private var _curPlayUrl:String;		// 当前页面播放视频的 原始地址.

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
			var infos:Object = {
				'sessionid': '3E48EB981408678B35469D19D3CA22A8467944A15ACDA6C2BD2C801221EEDC2520EDCFF0506D1503101927C69A817497B1BA1AF13CA6D6CC333F528E116611B1',
				'userid': '217800687',
				'userType': '0',
				'vodPermit': '0',
				'isvip': '1',
				'gcid': '5B3021B9EFF927534B28DB8E71C2F1BED6AFB76E',
				'cid': 'C6C8EF20EF5CB039ECE58DF7229F5AF57C12A407',
				'name': '[阳光电影www.ygdy8.com].怪兽大学.HD.1024x548.中文字幕.rmvb',
				'url_hash': '4580522841734408672',
				'from': 'vlist',
				'url': 'thunder://QUFmdHA6Ly9keWdvZDE6ZHlnb2QxQGQwNzAuZHlnb2Qub3JnOjEwOTEvWyVFOSU5OCVCMyVFNSU4NSU4OSVFNyU5NCVCNSVFNSVCRCVCMXd3dy55Z2R5OC5jb21dLiVFNiU4MCVBQSVFNSU4NSVCRCVFNSVBNCVBNyVFNSVBRCVBNi5IRC4xMDI0eDU0OC4lRTQlQjglQUQlRTYlOTYlODclRTUlQUQlOTclRTUlQjklOTUucm12Ylpa',
				'index': 'QUFmdHA6Ly9keWdvZDE6ZHlnb2QxQGQwNzAuZHlnb2Qub3JnOjEwOTEvWyVFOSU5OCVCMyVFNSU4NSU4OSVFNyU5NCVCNSVFNSVCRCVCMXd3dy55Z2R5OC5jb21dLiVFNiU4MCVBQSVFNSU4NSVCRCVFNSVBNCVBNyVFNSVBRCVBNi5IRC4xMDI0eDU0OC4lRTQlQjglQUQlRTYlOTYlODclRTUlQUQlOTclRTUlQjklOTUucm12Ylpaa',
				'ygcid': '46DF0A5789E7A70AEEC5B635FD2F01722D2E415A',
				'ycid': 'C6C8EF20EF5CB039ECE58DF7229F5AF57C12A407',
				'filesize': '898963093',
				'info_hash': '',
				'subtitle': 1
			}
			flv_setFeeParam(infos)
			VodRequestManager.instance.setup(this);
			VodRequestManager.instance.query(Tools.getUserInfo('url'), Tools.getUserInfo('name'), Tools.getUserInfo('gcid'), Tools.getUserInfo('cid'), Tools.getUserInfo('filesize'));
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
			
			// stage 事件
			initStageEvent();
			
			// 与js通信接口
			initJsInterface();

			// 初始化其他;
			initOther();
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

			SubtitleManager.instance.makeInstance(this, tWidth, tHeight);
			
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
			
			CtrBarManager.instance.makeInstance(this, tWidth, tHeight, _has_fullscreen, _player);
			CtrBarManager.instance.available =  true;
			CtrBarManager.instance.showPlayOrPauseButton = 'PLAY';

			_mouseControl = new MouseControl(this);
			_mouseControl.addEventListener("MOUSE_SHOWED", handleMouseInside);
			_mouseControl.addEventListener("MOUSE_HIDED", handleMouseOutSide);	
			_mouseControl.addEventListener("MOUSE_MOVEED", handleMouseInside);
			_mouseControl.addEventListener("MOUSE_MOVEOUT", handleMouseMoveOut);
			_mouseControl.addEventListener("SMALL_PLAY_PROGRESS_BAR", handleMouseHide2 );//缩小播放进度条;
		}
		
		protected function on_stage_RESIZE(e:Event):void{
			
			CtrBarManager.instance.fixedY = stage.stageHeight - 33;

			_player.resizePlayerSize(stage.stageWidth,stage.stageHeight );

			_eventCaptureScreen.width = stage.stageWidth;
			_eventCaptureScreen.height = stage.stageHeight;
			changePlayerSize();
			_videoMask.setPosition();
			SubtitleManager.instance.handleStageResize(_isFullScreen);
		}
		
		//切换视频
		public function exchangeVideo():void
		{
			SubtitleManager.instance.exchangeVideo();
			//清除i帧数据
			// clearSnpt();
		}

		
		
		//播放异常
		public function showPlayError(errorCode:String):void {
			_isStopNormal = false;
			_isShowStopFace = false;
			
			CtrBarManager.instance.dispatchStop();
			_videoMask.showErrorNotice(VideoMask.playError, errorCode);
		}
		
		
		
		protected function onCloseAddBytesFace(evt:Event):void{
			if (!_player.isStop)
			{
				CtrBarManager.instance.dispatchPlay();
			}
		}

		protected function pauseForever(tips:String):void{
			//流量不足
			_isNoEnoughBytes = true;
			//暂停
			if (!_player.isStop)
			{
				CtrBarManager.instance.dispatchPause();
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



		// 登陆异常回调函数
		public function showInvalidLoginLogo():void {
			CheckUserManager.instance.isValid = false;
			_isStopNormal = false;
			_isShowStopFace = false;
			
			// 登陆异常时，设置开播时间为当前时间，刷新页面时从当前点开播
			_player.startPosition = _player.time;
			
			CtrBarManager.instance.dispatchStop();
			_videoMask.showErrorNotice(VideoMask.invalidLogin);
		}

		// 监测播放权限
		private function checkIsShouldPause():void {
			
			if (Tools.normalUser()) {
				if (_isPlayStart && _isFlowChecked && _isFirstRemainTips)
				{
					_isFirstRemainTips = false;
					//显示了时长提示，不再显示上次播放时间点和字幕提示
					_isFirstTips = false;
					JTracer.sendMessage('PlayerCtrl -> check Is Should Pause _remainTimes:'+_remainTimes);
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
							
							JTracer.sendMessage("PlayerCtrl -> check Is Should Pause, 时长不足的提醒, ygcid:" + Tools.getUserInfo("ygcid") + ", userid:" + Tools.getUserInfo("userid") + ", remain:" + _remainTimes + ", need:" + needTimes);
							Tools.stat("f=fluxlacktips&gcid=" + Tools.getUserInfo("ygcid") + "&left=" + _remainTimes + "&need=" + needTimes);
						}
						else
						{
							//时长充足，提示用户
							_noticeBar.setContent("您的可播放时长剩余" + timesStr + expireStr + "，迅雷白金会员不限时长，<a href='event:buyVIP13'>立即开通</a>", false, 12);
							
							JTracer.sendMessage("PlayerCtrl -> check Is Should Pause, 时长充足的提醒, ygcid:" + Tools.getUserInfo("ygcid") + ", userid:" + Tools.getUserInfo("userid") + ", remain:" + _remainTimes + ", need:" + needTimes);
						}
					}
				}
			}
		}
		protected function initOther():void {

			CheckUserManager.instance.checkUserCompleteHandler = function checkUserCompleteHandler(resultStr:String):void {
				// 4-sessionid已失效, 5-sessionid与userid不对应
				var resultObj:Object = JSON.deserialize(resultStr);
				var result:Number = resultObj.result;
				JTracer.sendMessage("PlayerCtrl -> onCheckUserComplete, check is valid complete, result:" + result);
			
				if (result == 4 || result == 5)
				{
					showInvalidLoginLogo();
				}
				else
				{
					CheckUserManager.instance.isValid = true;
					CtrBarManager.instance.dispatchPlay();
				}
			}

			CheckUserManager.instance.checkUserErrorHandler = function checkUserErrorHandler():void {
				JTracer.sendMessage("PlayerCtrl -> onCheckUserIOError, check is valid IOError");
				CtrBarManager.instance.dispatchPlay();
			}

			CheckUserManager.instance.checkFlowCompleteHandler = function checkFlowCompleteHandler(resultStr:String):void {
				JTracer.sendMessage("PlayerCtrl -> onCheckFlowComplete, jsonStr:" + resultStr);
				var jsonObj:Object = com.serialization.json.JSON.deserialize(resultStr);
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

			CheckUserManager.instance.checkSuccess = function checkSuccess():void {
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
				});
				_time.start();
			}

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
					CtrBarManager.instance.changeToNextFormat();
					CtrBarManager.instance.isClickBarSeek = false;
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
					CtrBarManager.instance.isClickBarSeek = false;
					_isPressKeySeek = false;
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
			CtrBarManager.instance.playEventHandler(e.type);

			switch(e.type) {
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
					break;
				case 'Stop':
					hideNoticeBar();

					if (isChangeQuality == false) {
						isFirstLoad = true;
						_videoMask.bufferHandle('Stop');
					}
					
					_isBuffering = false;
					_player.isBuffer = false;
					//停止后，不处理为点击拖动条和使用按键进退产生的缓冲，使用bufferLength / bufferTime计算缓冲
					_isPressKeySeek = false;
					//播放完后，显示工具条
					_noticeBar.show(true);
					//停止后，第一次提示重置为true
					_isFirstTips = true;
					_isFirstRemainTips = true;
					_isPlayStart = false;
					break;
				case 'PlayNewUrl':
					JTracer.sendMessage('in play new');
					if (isChangeQuality == true) {
						_videoMask.showLoadingQuality();
					}else{
						_videoMask.showProcessLoading();
					}
					JTracer.sendMessage("PlayerCtrl -> playEventHandler, isChangeQuality:" + isChangeQuality);
					break;
				case 'PlayForStage':
					break;
				case 'PauseForStage':
					break;
				case 'PlayStart':
					_isPlayStart = true;
					_bufferTip.clearBreakCount();
					
					GlobalVars.instance.isFirstBuffer302 = false;
					GlobalVars.instance.bufferType = GlobalVars.instance.bufferTypeCustom;
					
					JTracer.sendMessage("PlayerCtrl -> playEventHandler, PlayEvent.PlayStart, set bufferType:" + GlobalVars.instance.bufferType);
					
					//没流量的用户，网盘用户不检测					
					if(Tools.noflux_notfromXLPan_user()){
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
						if ( !(GlobalVars.instance.isXLNetStreamValid == 1) && (CtrBarManager.instance.isClickBarSeek || _isPressKeySeek))
						{
							var preloaderDeler:Number = _player.streamInPlay.bufferTime / _player.totalTime * _player.totalByte;
							preloaderDeler = _player.streamInPlay.bytesTotal == 0 || _player.streamInPlay.bytesTotal > preloaderDeler ? preloaderDeler : _player.streamInPlay.bytesTotal;
							numProgress = _player.streamInPlay.bytesLoaded / preloaderDeler;
							
						}
						else
						{
							numProgress = _player.streamInPlay.bufferLength / _player.streamInPlay.bufferTime;
							
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
					break;
				case 'BufferEnd':
					_isPressKeySeek = false;
					_player.streamInPlay.resume();
					if (_player.isPause)
					{
						_player.streamInPlay.pause();
					}
					JTracer.sendMessage('get bufferend.')
					break;
				case 'OpenWindow':
					//弹出窗口
					_isStopNormal = false;
					_isShowStopFace = false;
					
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
			CheckUserManager.instance.checkIsValid();
		}
		
		private function onClickHandle(e:MouseEvent):void
		{
			CheckUserManager.instance.checkIsValid();
			
		}
		
		protected function keyUpFunc(e:KeyboardEvent):void
		{
		}
		
		protected function keyDownFunc(event:KeyboardEvent):void {
			var seekTime:Number;
			var idx:int;

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
					if( !CtrBarManager.instance.isProgressBarNormal && !_isFullScreen )
						CtrBarManager.instance.normalPlayProgressBar();
					if (_player.streamInPlay)
					{
						_player.streamInPlay.pause();
					}
					CtrBarManager.instance._timerBP.stop();
					_mouseControl.Timer2.stop();
					
					seekTime = _player.time - 5;
					if (seekTime < 0)
					{
						seekTime = 0;
					}
					
					idx = _player.getNearIndex(_player.dragTime, seekTime, 1, _player.dragTime.length - 1) - 1;
					
					seekTime = _player.dragTime[idx];
					
					CtrBarManager.instance.keySeekByTime(seekTime);

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
							CtrBarManager.instance._timerBP.start();
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
					if( !CtrBarManager.instance.isProgressBarNormal && !_isFullScreen )
						CtrBarManager.instance.normalPlayProgressBar();
					if (_player.streamInPlay)
					{
						_player.streamInPlay.pause();
					}
					CtrBarManager.instance._timerBP.stop();
					_mouseControl.Timer2.stop();
					
					seekTime = _player.time + 5;
					if (seekTime > _player.totalTime)
					{
						seekTime = _player.totalTime;
					}
					
					idx = _player.getNearIndex(_player.dragTime, seekTime, 0, _player.dragTime.length - 2) + 1;
					
					seekTime = _player.dragTime[idx];
					
					CtrBarManager.instance.keySeekByTime(seekTime);

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
							CtrBarManager.instance._timerBP.start();
						});
						_seekDelayTimer.start();
					}
					_mouseControl.Timer2.start();
					break;
				case 38: //up
					if( _player.isStop )
						return;
					CtrBarManager.instance.handleVolumeFromKey( true );
					break;
				case 40: //down
					if( _player.isStop )
						return;
					CtrBarManager.instance.handleVolumeFromKey( false );
					break;
				case 107: //+
					if( _player.isStop )
						return;
					CtrBarManager.instance.handleVolumeFromKey( true );
					break;
				case 109: //-
					if( _player.isStop )
						return;
					CtrBarManager.instance.handleVolumeFromKey( false );
					break;
				
			}
		}
		
		private function handleAutoPlay(e:Event):void 
		{
			CtrBarManager.instance.setPlayStatus();
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
			CtrBarManager.instance.normalPlayProgressBar();
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
			var videoPlaying:Boolean = !_isBuffering || isFirstLoad
			CtrBarManager.instance.smallPlayProgressBar(videoPlaying);
		}
		
		protected function handleMouseShowAndMove():void
		{
			if (CtrBarManager.instance._beFullscreen && CtrBarManager.instance.hidden)
			{
				CtrBarManager.instance.show();
				_noticeBar.show();
			}
		}
		protected function handleMouseHide():void{
			if (!CtrBarManager.instance.beMouseOnFormat)
			{
				CtrBarManager.instance.hideFormatSelector();
			}

			if (_player.isStartPause || _isStopNormal || _player.time <= 0)
			{
				return;
			}
			
			if (CtrBarManager.instance._beFullscreen && !CtrBarManager.instance.beMouseOn)
			{
				CtrBarManager.instance.hide();
				_noticeBar.hide();
			}
			if (CtrBarManager.instance.beMouseOn)
			{
				Mouse.show();
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
			CtrBarManager.instance.fullscreen = e.fullScreen;
			CtrBarManager.instance.show(true);
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
				CtrBarManager.instance.fixedY = stage.stageHeight - 33;
			}else {
				ExternalInterface.call("flv_playerEvent", "onExitFullScreen");
				_isFullScreen = false;
				changePlayerSize();
			}
		}
		
		public function flv_play() :void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_play, 播放影片");
			CtrBarManager.instance.available = true;
			CtrBarManager.instance.visible = true;
			CtrBarManager.instance.dispatchPlay();
		}
		public function flv_pause():void 
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_pause, 暂停影片");
			if (!_player.isPause && !_player.isStartPause)
			{
				CtrBarManager.instance.dispatchPause();
			}
		}
		
		public function flv_stop():void 
		{
			JTracer.sendMessage('PlayerCtrl -> js回调flv_stop, 停止影片');
			CtrBarManager.instance.dispatchStop();
			_videoMask.bufferHandle('Stop');
		}
		public function flv_close() :void
		{
			JTracer.sendMessage('PlayerCtrl -> js回调flv_close, 停止影片并且关闭流');
			_player.clearUp();
		}
		
		public function flv_setPlayeUrl(arr:Array):void{}
		
		public function setPlayeUrl(arr:Array):void
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

			// 发出检测流量的请求
			_isFlowChecked = false;			
			CheckUserManager.instance.checkFlow();
			
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
			CtrBarManager.instance.visible = true;
			//重置宽高比例
			//_setSizeInfo['ratio'] = 'common';
			//去掉filter
			//_player.filters = [];
			_player.retryLastTimeStat = arr[0].isRetryLastTime ? "&errorRetry=end" : "";
			_player.hasNextStream = true;
			Tools.getFormat();

			GlobalVars.instance.isXLNetStreamValid = 0;
			_player.setPlayUrl(arr);
			
			
		}

		public function initSnpt():void
		{
			// unimplemented
			// 初始化截图
		}
		
		public function flv_getNsCurrentFps():Number
		{
			var fps:Number = _player.nsCurrentFps;
			JTracer.sendMessage("PlayerCtrl -> js回调flv_getNsCurrentFps, 返回影片帧率:" + fps);
			return fps;
		}
				
		public function flv_changeStageVideoToVideo():void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_changeStageVideoToVideo, stageVideo to video");
		}

		public function setBufferTime(time:Number):void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调setBufferTime, 设置缓冲时间_player.bufferTime:" + time);
			_player.bufferTime = time;
		}
						
		public function flv_setNoticeMsg(str:String, count:Boolean = false, showTime:int = 15, type:int = 1, callBackFun:String = null, start:int = 0, length:int = 0):void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_setNoticeMsg, 设置提示文字:" + str + ", 是否一直显示:" + count + ", 不是一直显示时自动关闭时间:" + showTime);
			_noticeBar.setContent(str, count, showTime, type, callBackFun, start, length);
		}
				
		public function hideNoticeBar():void
		{
			_noticeBar.hideNoticeBar();
		}

		private function flv_setIsChangeQuality(ischange:Boolean):void
		{
			JTracer.sendMessage("PlayerCtrl -> js回调flv_setIsChangeQuality, 设置是否切换清晰度:" + ischange);
			isChangeQuality = ischange;
		}
		
		protected function initJsInterface():void{
			if (ExternalInterface.available)
			{
				ExternalInterface.addCallback('flv_play', flv_play);
				ExternalInterface.addCallback('flv_pause', flv_pause);
				ExternalInterface.addCallback('flv_stop', flv_stop);
				ExternalInterface.addCallback('flv_close', flv_close);

				ExternalInterface.addCallback('flv_setPlayeUrl', flv_setPlayeUrl);
				ExternalInterface.addCallback('getPlayProgress', getPlayProgress);

				ExternalInterface.addCallback('setBufferTime', setBufferTime);
				ExternalInterface.addCallback('flv_setNoticeMsg', flv_setNoticeMsg);

				ExternalInterface.addCallback('flv_setIsChangeQuality', flv_setIsChangeQuality);
				ExternalInterface.addCallback('flv_closeNetConnection', flv_closeNetConnection);
				ExternalInterface.addCallback('flv_showFormats', flv_showFormats);
				ExternalInterface.addCallback('flv_seek', flv_seek);
			
				ExternalInterface.addCallback('flv_getTimePlayed', flv_getTimePlayed);
				ExternalInterface.addCallback('flv_setFeeParam', flv_setFeeParam);
				ExternalInterface.addCallback('flv_playOtherFail', flv_playOtherFail);
				ExternalInterface.addCallback('flv_setToolBarEnable', flv_setToolBarEnable);
				ExternalInterface.addCallback('flv_ready', flv_ready);
			}
		}

		public function flv_ready():Boolean{return true;}
		
		public function flv_playOtherFail(boo:Boolean, tips:String = ""):void {
			playOtherFail(boo, tips);
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
			CtrBarManager.instance.toggleCaptionBtn(!GlobalVars.instance.hasSubtitle);
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
			
			if (CtrBarManager.instance) {
				CtrBarManager.instance.enableFileList = obj.enableFileList || false;
			}
		}
										
		private function getPlayProgress(isTime:Boolean):Number
		{
			var result:Number = CtrBarManager.instance.getPlayProgress(isTime);
			JTracer.sendMessage("PlayerCtrl -> js回调getPlayProgress, 设置是否返回播放时间(false返回播放百分比):" + isTime + ", 返回的播放时间或播放百分比为:" + result);
			return result;
		}
		
		protected function hideSideChangeQuilty():void
		{
			if (CtrBarManager.instance._beFullscreen)
			{
				CtrBarManager.instance.hide();
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
			CtrBarManager.instance.isChangeQuality = boo;
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
			CtrBarManager.instance.showFormatLayer(formats);
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
//		unimplemented		
			return []; // 新i帧截图
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
		}
		protected function mouseWheel(delta:Number):void{
			if( _isFullScreen )
			{
				if( delta > 0 )
					CtrBarManager.instance.handleVolumeFromKey( true );
				else
					CtrBarManager.instance.handleVolumeFromKey( false );
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
		

		/*==============================================
			implements IVodRequester method.
		==============================================*/
		public function playOtherFail(boo:Boolean, tips:String = ""):void {
			var urlStr:String = "PlayerCtrl -> js回调flv_playOtherFail, 切换新视频, 是否切换成功:" + boo + ", tips:" + tips;
			JTracer.sendMessage(urlStr);
			
			GlobalVars.instance.isExchangeError = !boo;
			
			//取消字幕
			SubtitleManager.instance.cancelSubTitle();
			
			if (!boo)
			{
				_isStopNormal = false;
				_isShowStopFace = false;
				
				CtrBarManager.instance.dispatchStop();
				_videoMask.showErrorNotice(VideoMask.exchangeError, null, tips);
				
				var formatObj:Object = { "y": { "checked":false, "enable":false }, "c": { "checked":false, "enable":false }, "p": { "checked":false, "enable":false }, "g": { "checked":false, "enable":false }};
				CtrBarManager.instance.showFormatLayer(formatObj);
			}
		}

		private var _curPlay:Object;
		private var _fileType:String;
		private var _curName:String;
		private var _lastPos:Number;
		private var _reqData:VODReqBackDataModule;
		public function queryBack(req:Object):void {
			_reqData = new VODReqBackDataModule(req);
			// 不能播放时调用flash接口
			var tellFlashFail = function(){
			/*_INSTANCE.attachEvent(_INSTANCE,'onload',function(_o,_e){
			that.playerInstance = _INSTANCE.playerInstance;
			if(DEBUG)
			that.playerInstance.showDebug();
			that.initEvent();
			that.playerInstance.playOtherFail(false,_genErrorMsg(req,1));
			var param = {
			"description":"请选择字幕文件(*.srt、*.ass)",
			"extension":"*.srt;*.ass",
			"limitSize":6*1024*1024,
			"uploadURL":DYSERVER+"interface/upload_file/?cid="+cid,
			"timeOut":"30"
			};
			that.playerInstance.setCaptionParam(param);

			that.playerInstance.setToolBarEnable({enableShare:false,enableFileList:playerFunSettings.enableFileList,enableDownload:false,enableSet:false,enableCaption:false,enableOpenWindow:playerFunSettings.enableOpenWindow,enableTopBar:playerFunSettings.enableTopBar,enableFeedback:true});
			that.setFeeParam(0);
			that.setShareParam();
			});
			var id = box_obj.getAttribute('id');
			_INSTANCE.printObject(id,false,'100%','100%','',flashvars);
			try{window[success].call();}catch(e){}*/
			};

			//不能播放的逻辑
			if( typeof req.status == 'undefined' || req.status != 0 ) {
				try {
					// 资源不能秒播则上报
					if(req.ret == 0){

						var errGcid = Tools.getUserInfo('gcid') || "";

						var errUrl = !errGcid ? _curPlayUrl : "";

						Tools.stat([
						'f=playAtOnceFail', 
						'&gid=' + errGcid, 
						'&url=' + errUrl, 
						'&isTryPlay=false', 
						'&status='+ req.status, 
						'&transWait=' + req.trans_wait 
						].join(''));

					}

				}catch(e){}

				if(req.ret == 11){

					_showErrorTip(_genErrorMsg(req));
					// sessionid过期，跳去中间页登录
					if(int(Tools.getUserInfo('vodPermit')) == 4){
						var search:String = ExternalInterface.call('function(){return location.search;}');
						var goUrl = "http://vod.xunlei.com/play.html"+ search +"#action=sidExpired";
						Tools.windowOpen(goUrl, "_self");
					}

				}
				// 含多视频BT文件的在bt中提示
				else{
					tellFlashFail();
				}
			}
			else{
				
				_getFormats(_reqData.curFormat);
					
				flv_playOtherFail(true);
				_player.clearUp();
				_startPlay(true,false,true,0,false);

			}

		}

		private function _startPlay(isServer:Boolean, urlObj:Boolean, autoplay:Boolean, ischange:Boolean, isRetryUrlAtLimit:Boolean):void {
			
			var url:String = _reqData.curUrl;
			var paramobj = [{url:"",start:0,autoplay:1,quality:0,qualitystr:"000",qualitytype:0,subStart:0,subEnd:0,title:"",vcut:0,submovieid:0,skipMovieHeadTime:0,skipMovieEndTime:0,streamtype:0,posterUrl:"",totalByte:0,totalTime:0,sliceTime:0}];
			
			paramobj[0].url = url;
			paramobj[0].urls = _reqData.curUrls;
			paramobj[0].vod_url_dt17 = 0//param.vod_url_dt17;
			paramobj[0].autoplay = autoplay;
			paramobj[0].quality = 0;
			paramobj[0].qualitystr = '000';
			
			paramobj[0].totalByte = _reqData.totalByte;//150523213;//this.totalByte;
			paramobj[0].totalTime = int(_reqData.totalTimeInMs/1000000);//5530;//1646;//this.totalTime;
			paramobj[0].sliceTime = 720;    // 切片时间
			paramobj[0].sliceType = 0;//0字节拼接 转码完成  1时间拼接 转码中
			paramobj[0].start = 0;
			paramobj[0].format = _reqData.curFormat;//g 高清 p普请
			
			if(urlObj){
				paramobj[0].jsonObj = urlObj;
				if(autoplay){
					paramobj[0].autoplay = autoplay;
				}else{
					paramobj[0].autoplay = 2;
				}
			}

			if(isServer){
				paramobj[0].streamtype = 1;
				paramobj[0].packageUrl = '___';
			}else{
				paramobj[0].streamtype = 0;
			}
			paramobj[0].isRetryLastTime = false;
			paramobj[0].skipMovieHeadTime = 0;
			paramobj[0].skipMovieEndTime = 0;
			

			if(paramobj.totalTime<5)
				setBufferTime(paramobj.totalTime);

			setPlayeUrl(paramobj);
		}
		
		private function _getFormats(tformat:String = null):void {
			var format:String = tformat || 'p';
			var norms:Object = {
				c:{checked: false, enable: false},
				g:{checked: false, enable: false},
				p:{checked: false, enable: false},
				y:{checked: false, enable: false}
			};

			norms.g.enable = typeof(_reqData.info_list[1]) != 'undefined';
			norms.c.enable = typeof(_reqData.info_list[2]) != 'undefined';
			norms.p.enable = true;
			norms[format].checked = true;
			flv_showFormats(norms);
		}

		// 显示错误提示  
		private function _showErrorTip(msg:String):void {
		//
		}

		// 过滤错误信息
		private function _genErrorMsg(req, inPlayer:Boolean = false):String {
			return ''
		}

		/*==============================================
			implements icaption method.
		==============================================*/

		private var _playerTxtTips:TextField;	//左上角影片正在播放提示文字

		public function get isStartPlayLoading():Boolean {
			return _videoMask.isStartPlayLoading;
		}

		public function get videoIsPlaying():Boolean {
			return !(_player.isPause || _player.isStop || isBuffering);
		}
		
		public function get videoTime():Number {
			return _player.time;
		}
		/**
		 * 显示自动加载字幕的信息.
		 */
		public function showAutoloadTips():void
		{
			if (!_isShowAutoloadTips && _isPlayStart && !isChangeQuality && !_player.isResetStart && GlobalVars.instance.isHasAutoloadCaption)
			{
				_isShowAutoloadTips = true;
				
				showPlayerTxtTips("已自动加载在线字幕", 5000);
			}
		}

		/**
		 * 生成 player txt tip.
		 */
		public function showPlayerTxtTips(tips:String, time:Number):void {
			if (!_playerTxtTips) {
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
			_playerTxtTipsID = setTimeout(__hidePlayerTxtTips, time);
		}

		/**
		 * 私有方法
		 * 移除 player txt tip.
		 */
		private function __hidePlayerTxtTips():void
		{
			if (_playerTxtTips)
			{
				removeChild(_playerTxtTips);
				_playerTxtTips = null;
			}
			clearTimeout(_playerTxtTipsID);
		}
	}
}