package zuffy.core
{
	import zuffy.ctr.contextMenu.CreateContextMenu;
	import zuffy.display.addBytes.NoEnoughBytesFace;
	import zuffy.display.CtrBar;
	import zuffy.display.MouseControl;
	import zuffy.display.setting.SettingSpace;
	import zuffy.display.addBytes.AddBytesFace;
	import zuffy.display.download.DownloadFace;
	import zuffy.display.fileList.FileListFace;
	import zuffy.display.question.FeedbackFace;
	import zuffy.display.notice.NoticeBar;
	import zuffy.display.notice.bufferTip;
	import zuffy.display.tryplay.TryEndFace;
	import zuffy.display.share.ShareFace;
	import zuffy.display.subtitle.Subtitle;
	import zuffy.display.statuMenu.VideoMask;
	import zuffy.display.subtitle.CaptionFace;
	import zuffy.display.subtitle.Subtitle;
	import zuffy.display.toolBarRight.ToolBarRight;
	import zuffy.display.toolBarRight.ToolBarRightArrow;
	import zuffy.display.toolBarTop.ToolBarTop;
	import zuffy.events.CaptionEvent;
	import zuffy.events.ControlEvent;
	import zuffy.events.EventSet;
	import zuffy.events.PlayEvent;
	import zuffy.events.SetQulityEvent;
	import zuffy.events.TryPlayEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import flash.display.MovieClip;
	import flash.display.Loader;
	import com.common.Tools;
	import com.global.GlobalVars;
	import com.common.JTracer;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.ApplicationDomain;
	import flash.display.StageDisplayState;
	import com.common.Cookies;
	import flash.utils.*
	import flash.ui.Mouse;
	import flash.external.ExternalInterface;
	import flash.text.TextFormat;
	import com.serialization.json.JSON;

	public class PanelPlayerCtrl extends PlayerCtrl
	{
		// 弹出面板
		private var _settingSpace:SettingSpace;
		private var _captionFace:CaptionFace;
		private var _fileListFace:FileListFace;
		private var _downloadFace:DownloadFace;
		private var _feedbackFace:FeedbackFace;
		private var _shareFace:ShareFace;
		private var _noEnoughFace:NoEnoughBytesFace;
		private var _addBytesFace:AddBytesFace;

		private var _tryEndFace:MovieClip;

		private var _isPauseForever:Boolean;				//无时长普通会员是否已经暂停播放

		// 侧边栏按钮面板部分
		private var _toolRightFace:ToolBarRight;
		private var _toolRightArrow:ToolBarRightArrow;
		private var _toolTopFace:ToolBarTop


		private var _isPanelLoaded:Boolean;
		private var _panelLoader:Loader;
		private var _completeFunc:Function;


		private var _lastMouseDelta:Number = 0;
		private var _curMouseDelta:Number = 0;
		private var _timeIntervalID:int;
		private var _filterIntervalID:int;
		private var _curKeyDelta:Number = 0;
		private var _lastKeyDelta:Number = 0;
		private var _isFirstListTips:Boolean = true;		//是否第一次提示文件列表

		private var _keyDeltaID:int;

		public function PanelPlayerCtrl()
		{
			super();
		}

		override protected function initializeUI(tWidth:int, tHeight:int):void{
			super.initializeUI(tWidth,tHeight);
			_settingSpace = new SettingSpace(_player);
			_settingSpace.addEventListener(EventSet.SET_SIZE, settingSpaceEventHandler);
			addChild(_settingSpace);
			_settingSpace.setPosition();
			

			_toolRightArrow = new ToolBarRightArrow(this);
			_toolRightArrow.setPosition();
			
			_toolRightFace = new ToolBarRight(this);
			_toolRightFace.setPosition();
			

			_fileListFace = new FileListFace(this);
			addChild(_fileListFace);
			_fileListFace.setPosition();

			_captionFace = new CaptionFace();
			addChild(_captionFace);
			_captionFace.setPosition();
			
			_toolTopFace = new ToolBarTop(this);
			_toolTopFace.addEventListener("ShowPlayingTips", showPlayingTips);
			_toolTopFace.setPosition();
			
			_downloadFace = new DownloadFace();
			addChild(_downloadFace);
			_downloadFace.setPosition();
			
			_feedbackFace = new FeedbackFace(this);
			addChild(_feedbackFace);
			_feedbackFace.setPosition();
			
			_shareFace = new ShareFace();
			addChild(_shareFace);
			_shareFace.setPosition();
			
			//使tooltip显示在最上层
			Tools.registerToolTip(this);
			setObjectLayer();
		}

		private function setObjectLayer():void
		{
			var layerIndexArr:Array = [];
			layerIndexArr.push(getChildIndex(_settingSpace));
			layerIndexArr.push(getChildIndex(_ctrBar));
			layerIndexArr.sort(orderArrFun);
			if (getChildIndex(_ctrBar) != layerIndexArr[0]) {
				setChildIndex(_ctrBar, layerIndexArr[0]);
			}
			if (getChildIndex(_settingSpace) != layerIndexArr[1]) {
				setChildIndex(_settingSpace, layerIndexArr[1]);
			}
		}

		//显示系统时间
		override public function setSystemTime():void
		{
			var date:Date = new Date();
			var hours:Number = date.getHours();
			var minutes:Number = date.getMinutes();
			var hoursStr:String = hours >= 10 ? hours.toString() : "0" + hours.toString();
			var minutesStr:String = minutes >= 10 ? minutes.toString() : "0" + minutes.toString();
			_toolTopFace.setSystemTime(hoursStr + ":" + minutesStr);
		}
		private function settingSpaceEventHandler(e:EventSet):void
		{
			switch(e.type) {
				case 'set_size':
					var sizeInfo:Object = _settingSpace.videoSize;
					if (sizeInfo['ratio'] != _setSizeInfo['ratio'] || sizeInfo['size'] != _setSizeInfo['size'] || true) {
						_setSizeInfo['ratio'] = sizeInfo['ratio'];
						_setSizeInfo['size'] = sizeInfo['size'];
						updateVideoSizeFun();
					}
					break;
			}
		}
		override protected function on_stage_RESIZE(e:Event):void{
			super.on_stage_RESIZE(e);
			if (_toolRightArrow)
			{
				_toolRightArrow.setPosition();
			}
			if (_toolRightFace)
			{
				_toolRightFace.setPosition();
				_toolRightFace.hide(true);
			}

			_captionFace.setPosition();
			_fileListFace.setPosition();
			if (_addBytesFace)
			{
				_addBytesFace.setPosition();
			}
			if (_noEnoughFace)
			{
				_noEnoughFace.setPosition();
			}
			if (_tryEndFace)
			{
				_tryEndFace.setPosition();
			}
			_shareFace.setPosition();
			_feedbackFace.setPosition();
			_downloadFace.setPosition();
		}

		// 切换视频
		override public function exchangeVideo():void
		{
			// 清除全部字幕
			_captionFace.clearCaption();

			// 下载面板重置
			_downloadFace.setAllDisabled();
		}
		
		// 播放下一集视频
		override public function playNext():void
		{
			_fileListFace.playNext();
		}
	
		// 关闭流量充值面板
		private function onCloseNoEnoughFace(evt:Event):void
		{
			if (_noEnoughFace)
			{
				removeChild(_noEnoughFace);
				_noEnoughFace = null;
			}
			isStopNormal = false;
			isShowStopFace = false;
			
			_ctrBar.dispatchStop();
			_videoMask.showErrorNotice(VideoMask.noEnoughBytes);
		}
		
		override protected function onCloseAddBytesFace(evt:Event):void{
			super.onCloseAddBytesFace(evt);
			if (_addBytesFace)
			{
				removeChild(_addBytesFace);
				_addBytesFace = null;
			}
		}
				
		//试播结束
		override protected function tryPlayEnded(time:Number):void
		{
			if (!_isPauseForever)
			{
				_isPauseForever = true;
				
				super.tryPlayEnded(time);

				pauseForever("");
				showTryEndFace(time);
			}
		}

		private function showTryEndFace(time:Number):void
		{
			var comFunc:Function = function():void
			{
				var tryEndCls:Class = getPanelClass("ctr.tryplay.TryEndFace");
				
				if (!_tryEndFace)
				{
					_tryEndFace = new tryEndCls();
					_tryEndFace.setTime(time);
					_tryEndFace.isTrial = false;
					if(GlobalVars.instance.isZXThunder){
						_tryEndFace.gotoAndStop(2);
					}
					addChild(_tryEndFace);
					_tryEndFace.setPosition();
				}
			}
			
			loadPanel(comFunc);
		}
		
		private function tryPlayEventHandler(evt:TryPlayEvent):void
		{
			switch(evt.type)
			{
				case TryPlayEvent.BuyVIP:
					buyVIP(evt.info);
					break;
				case TryPlayEvent.BuyTime:
					buyTime(evt.info);
					break;
				case TryPlayEvent.GoHome:
					gotoHome();
					break;
				case TryPlayEvent.HidePanel:
					hideTryPanel();
					break;
				case TryPlayEvent.GetBytes:
					getBytes();
					break;
				case TryPlayEvent.DontNoticeBytes:
					dontNoticeBytes();
					break;
			}
		}
		private function onFeeSuccessHandler(evt:TryPlayEvent):void{
			var info:Object = evt.info;
			var _remainTimes = info.remainTimes;
			tryPlayEnded(_remainTimes);
			isNoEnoughBytes = true;
		}
		
		private function hideTryPanel():void
		{
			hideTryEndFace();
		}

		private function hideTryEndFace():void
		{
			if (_tryEndFace)
			{
				removeChild(_tryEndFace);
				_tryEndFace = null;
			}
		}
		
		private function loadPanel(comFunc:Function):void
		{
			JTracer.sendMessage("PlayerCtrl -> loadPanel, panel loading");
			
			_completeFunc = comFunc;
			
			if (!_isPanelLoaded)
			{
				if (_panelLoader)
				{
					try
					{
						_panelLoader.unloadAndStop();
					}
					catch(e:Error)
					{
						
					}
					_panelLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onPanelLoaded);
					_panelLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onPanelIOError);
					_panelLoader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onPanelSecurityError);
					_panelLoader = null;
				}
				
				var url:String = this.loaderInfo.url;
				var prefixURL:String = url.substr(0, url.lastIndexOf("/") + 1);
				var req:URLRequest = new URLRequest(prefixURL + "tryPanel.swf?t=" + new Date().time);
				
				var context:LoaderContext = new LoaderContext();
				context.applicationDomain = ApplicationDomain.currentDomain;
				
				_panelLoader = new Loader();
				_panelLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onPanelLoaded);
				_panelLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onPanelIOError);
				_panelLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onPanelSecurityError);
				_panelLoader.load(req, context);
			}
			else
			{
				if (_completeFunc != null)
				{
					_completeFunc();
				}
			}
		}
		
		private function onPanelLoaded(evt:Event):void
		{
			JTracer.sendMessage("PlayerCtrl -> onPanelLoaded, panel loaded");
			
			_isPanelLoaded = true;
			
			if (_completeFunc != null)
			{
				_completeFunc();
			}
		}
		
		private function onPanelIOError(evt:IOErrorEvent):void
		{
			JTracer.sendMessage("PlayerCtrl -> onPanelIOError, panel io error");
			
			_isPanelLoaded = false;
		}
		
		private function onPanelSecurityError(evt:SecurityErrorEvent):void
		{
			JTracer.sendMessage("PlayerCtrl -> onPanelSecurityError, panel security error");
			
			_isPanelLoaded = false;
		}
		
		private function getPanelClass(className:String):Class
		{
			var cls:Class = _panelLoader.contentLoaderInfo.applicationDomain.getDefinition(className) as Class;
			return cls;
		}
		
		private function buyVIP(infoObj:Object):void
		{
			if (stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				stage.displayState = StageDisplayState.NORMAL;
			}
			
			var from:String = Tools.getUserInfo("from");
			if (from && from.substr(0, 3).toLowerCase() == "un_")
			{
				Tools.windowOpen(GlobalVars.instance.url_buy_flow + "&referfrom=UN_014&ucid=" + from.substr(3) + "&paypos=" + infoObj.paypos, "_blank", "jump");
				return;
			}
			
			var stat:String = "";
			if (infoObj.hasBytes)
			{
				stat = "HasFluxBuyVIP";
			}
			else
			{
				stat = "NoFluxBuyVIP";
			}
			
			var paypos:String = infoObj.paypos ? '_' + infoObj.paypos : '';
			if (GlobalVars.instance.platform == "client")
			{
				Tools.windowOpen(GlobalVars.instance.url_buy_flow + "&referfrom=" + infoObj.refer + paypos , "_blank", "jump");
				Tools.stat("b=client" + stat);
			}
			else
			{
				Tools.windowOpen(GlobalVars.instance.url_buy_flow + "&referfrom=" + infoObj.refer + paypos);
				Tools.stat("b=web" + stat);
			}
		}
		
		private function buyTime(infoObj:Object):void
		{
			if (stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				stage.displayState = StageDisplayState.NORMAL;
			}
			
			var from:String = Tools.getUserInfo("from");
			if (from && from.substr(0, 3).toLowerCase() == "un_")
			{
				Tools.windowOpen(GlobalVars.instance.url_buy_time + "?referfrom=UN_014&ucid=" + from.substr(3) + "&paypos=" + infoObj.paypos, "_blank", "jump");
				return;
			}
			
			var stat:String = "NoTimeBuyVIP";
			if (GlobalVars.instance.platform == "client")
			{
				Tools.windowOpen(GlobalVars.instance.url_buy_time + "?referfrom=" + infoObj.refer + "_" + infoObj.paypos, "_blank", "jump");
				Tools.stat("b=client" + stat);
			}
			else
			{
				Tools.windowOpen(GlobalVars.instance.url_buy_time + "?referfrom=" + infoObj.refer + "_" + infoObj.paypos);
				Tools.stat("b=web" + stat);
			}
		}
		
		private function gotoHome():void
		{
			if (stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				stage.displayState = StageDisplayState.NORMAL;
			}
			
			Tools.windowOpen(GlobalVars.instance.url_home, "_blank");
		}
		
		override protected function initOther():void{
			super.initOther();
			loadPanel(null)
		}
		private var _isXLNetStreamValid:Boolean = false;
		private function initXLPlugins(flag:Boolean = false):void{
			
		}
		
		/**
		 * 监听各个控制器及自身发出的信息、事件;
		 */
		override protected function initStageEvent():void
		{
			super.initStageEvent();

			stage.addEventListener(MouseEvent.MOUSE_WHEEL , onMouseWheel);
			this.addEventListener(EventSet.SHOW_FACE, showFaceHandler);

			this.addEventListener(CaptionEvent.APPLY_SUCCESS, applyCaptionSuccess);
			this.addEventListener(CaptionEvent.APPLY_ERROR, applyCaptionError);
			this.addEventListener(CaptionEvent.LOAD_STYLE, loadCaptionStyle);
			this.addEventListener(CaptionEvent.LOAD_TIME, loadCaptionTime);

			this.addEventListener(TryPlayEvent.BuyVIP, tryPlayEventHandler);
			this.addEventListener(TryPlayEvent.BuyTime, tryPlayEventHandler);
			this.addEventListener(TryPlayEvent.GoHome, tryPlayEventHandler);
			this.addEventListener(TryPlayEvent.HidePanel, tryPlayEventHandler);
			this.addEventListener(TryPlayEvent.GetBytes, tryPlayEventHandler);
			this.addEventListener(TryPlayEvent.DontNoticeBytes, tryPlayEventHandler);
			this.addEventListener(TryPlayEvent.FEE_SUCCESS, onFeeSuccessHandler)
		}

		/**
		 * 显示播放中的提示
		 */
		private function showPlayingTips(evt:Event):void
		{
			showPlayerTxtTips("该视频正在播放", 2000);
		}

		/**
		 * 显示设置面板
		 */
		public function showSetFace():void
		{
			if (_settingSpace.visible)
			{
				hideAllLayer();
				
				if (!_player.isStop)
				{
					_ctrBar.dispatchPlay();
				}
				
				reportSetStat();
			}
			else
			{
				if (GlobalVars.instance.isStat)
				{
					Tools.stat("b=setPanel");
				}
				
				hideAllLayer();
				_settingSpace.showSetFace();
				
				if (!_player.isStop)
				{
					_ctrBar.dispatchPause();
				}
			}
		}
		
		private function reportSetStat():void
		{
			if (!GlobalVars.instance.isStat)
			{
				return;
			}
			
			//关闭面板后，如调节了默认清晰度，由上报
			if (GlobalVars.instance.defaultFormatChanged)
			{
				GlobalVars.instance.defaultFormatChanged = false;
				
				Tools.stat("b=changeDefaultFormat");
			}
			
			//关闭面板后，如调节了画画比例，则上报
			if (GlobalVars.instance.ratioChanged)
			{
				GlobalVars.instance.ratioChanged = false;
				
				Tools.stat("b=changeRatio");
			}
			
			//关闭面板后，如调节了色彩，则上报
			if (GlobalVars.instance.colorChanged)
			{
				GlobalVars.instance.colorChanged = false;
				
				Tools.stat("b=changeColor");
			}
		}
		
		/**
		 * 显示分享面板
		 */
		private function showShareFace():void
		{
			if (_shareFace.visible)
			{
				hideAllLayer();
				
				if (!_player.isStop)
				{
					_ctrBar.dispatchPlay();
				}
			}
			else
			{
				if (GlobalVars.instance.isStat)
				{
					Tools.stat("b=sharePanel");
				}
				
				hideAllLayer();
				_shareFace.showFace(true);
				
				if (!_player.isStop)
				{
					_ctrBar.dispatchPause();
				}
			}
		}
		
		/**
		 * 显示字幕面板
		 */
		private function showCaptionFace(click:String = "tool"):void
		{
			if (_captionFace.visible)
			{
				hideAllLayer();
				
				if (!_player.isStop)
				{
					_ctrBar.dispatchPlay();
				}
				
				reportCaptionStat();
			}
			else
			{
				Tools.stat("b=captionPanel&click=" + click);
				
				hideAllLayer();
				_captionFace.showFace(true);
				
				if (!_player.isStop)
				{
					_ctrBar.dispatchPause();
				}
			}
		}
		
		private function reportCaptionStat():void
		{
			//关闭面板后，如调节了字幕颜色，字幕大小等，保存字幕信息和上报
			if (GlobalVars.instance.captionStyleChanged)
			{
				GlobalVars.instance.captionStyleChanged = false;
				
				if (GlobalVars.instance.isStat)
				{
					Tools.stat("b=changeSubtitle");
				}
				
				saveStyle();
			}
			
			//关闭面板后，如调节了时间轴，保存时间轴信息和上报
			if (GlobalVars.instance.captionTimeChanged)
			{
				GlobalVars.instance.captionTimeChanged = false;
				
				if (GlobalVars.instance.isStat)
				{
					Tools.stat("b=changeSubtitleTime");
				}
				
				saveTimeDelta();
			}
		}
		
		/**
		 * 显示文件列表
		 */
		private function showFileListFace():void
		{
			if (_fileListFace.visible)
			{
				hideAllLayer();
			}
			else
			{
				if (GlobalVars.instance.isStat)
				{
					Tools.stat("b=filelistPanel");
				}
				
				hideAllLayer();
				_fileListFace.showFace(true);
			}
		}
		
		/**
		 * 显示反馈面板
		 */
		private function showFeedbackFace(click:String = "tool"):void
		{
			if (_feedbackFace.visible)
			{
				hideAllLayer();
				
				if (!_player.isStop)
				{
					_ctrBar.dispatchPlay();
				}
			}
			else
			{
				if (GlobalVars.instance.isStat)
				{
					Tools.stat("b=feedbackPanel&click=" + click);
				}
				
				hideAllLayer();
				_feedbackFace.showFace(true);
				
				if (!_player.isStop)
				{
					_ctrBar.dispatchPause();
				}
			}
		}
		
		/**
		 * 显示下载面板
		 */
		private function showDownloadFace():void
		{
			if (_downloadFace.visible)
			{
				hideAllLayer();
				
				if (!_player.isStop)
				{
					_ctrBar.dispatchPlay();
				}
			}
			else
			{
				if (GlobalVars.instance.isStat)
				{
					Tools.stat("b=downloadPanel");
				}
				
				hideAllLayer();
				_downloadFace.showFace(true);
				
				if (!_player.isStop)
				{
					_ctrBar.dispatchPause();
				}
			}
		}
		
		private function closeDownloadFace(evt:Event):void
		{
			_downloadFace.showFace(false);
			
			_ctrBar.dispatchPlay();
		}

		private function applyCaptionSuccess(evt:CaptionEvent):void
		{
			_captionFace.showCompStatus();
		}
		
		private function applyCaptionError(evt:CaptionEvent):void
		{
			_captionFace.showErrorStatus();
		}
		
		private function loadCaptionStyle(evt:CaptionEvent):void
		{
			_captionFace.loadCaptionStyle();
		}
		
		private function loadCaptionTime(evt:CaptionEvent):void
		{
			_captionFace.loadCaptionTime(evt.info);
		}
		
		private function getBytes():void
		{
			if (stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				stage.displayState = StageDisplayState.NORMAL;
			}
			//免费获得流量
			if (GlobalVars.instance.platform == "client")
			{
				Tools.windowOpen(GlobalVars.instance.url_free_flow, "_blank", "jump");
			}
			else
			{
				Tools.windowOpen(GlobalVars.instance.url_free_flow);
			}
		}
		
		private function showFaceHandler(evt:EventSet):void
		{
			switch(evt.info) {
				case 'set':
					showSetFace();
					break;
				case 'share':
					showShareFace();
					break;
				case 'caption':
					showCaptionFace("tool");
					break;
				case 'captionFromTips':
					showCaptionFace("tips");
					break;
				case 'filelist':
					showFileListFace();
					break;
				case 'feedback':
					showFeedbackFace("tool");
					break;
				case 'feedbackFromTips':
					showFeedbackFace("tips");
					break;
				case 'download':
					showDownloadFace();
					break;
			}
		}
		
		override protected function playEventHandler(e:PlayEvent):void
		{
			super.playEventHandler(e);
			
			switch(e.type)
			{
				case 'Pause':
					//暂停时，显示上方地址输入栏
					if (_toolTopFace.hidden)
					{
						_toolTopFace.show();
					}
					break;
				case 'Play':
					//播放时，隐藏上方地址输入栏
					if (!_toolTopFace.hidden)
					{
						_toolTopFace.hide();
					}
					break;
				case 'Stop':
					_isFirstListTips = true;
					_settingSpace.visible = false;
					_toolRightArrow.x = stage.stageWidth;
					_toolRightArrow.hide(true);
					_toolRightFace.x = stage.stageWidth;
					_toolRightFace.hide(true);
					_toolTopFace.y = -25;
					_toolTopFace.hide(true);
					_captionFace.showFace(false);
					_fileListFace.showFace(false);
					break;
				case 'PlayStart':

					//文件列表提示
					if (_isFirstListTips)
					{
						_isFirstListTips = false;
						
						//切换清晰度时不提示
						if (!isChangeQuality)
						{
							//显示文件列表提示
							var isNoticeList:* = Cookies.getCookie('isNoticeList');
							if (Tools.getUserInfo("urlType") != "url" && _fileListFace.filelistLength > 1 && isNoticeList !== false)
							{
								_ctrBar.showFilelistTips(_fileListFace.filelistLength);
							}
						}
					}

					_toolRightArrow.hide(true);
					_toolRightFace.hide(true);
					_toolTopFace.hide(true);
					break;
				default :
					break;
			}
		}

		private function onMouseWheel( event:MouseEvent ):void
		{
			//鼠标滚轮控制字幕时间轴调整
			if (_captionFace.visible && _captionFace.isThumbIconActive)
			{
				if (event.delta > 0)
				{
					_captionFace.addDeltaByMouse(0.1);
					
					_curMouseDelta += event.delta;
				}
				else
				{
					_captionFace.subDeltaByMouse(0.1);
					
					_curMouseDelta -= event.delta;
				}
				
				clearInterval(_timeIntervalID);
				_timeIntervalID = setInterval(stopTimeMouseWheel, 2000);
				return;
			}
			
			//鼠标滚轮控制滤镜调整
			if (_settingSpace.visible && _settingSpace.isThumbIconActive)
			{
				if (event.delta > 0)
				{
					_settingSpace.addDeltaByMouse(1);
				}
				else
				{
					_settingSpace.subDeltaByMouse(1);
				}
				
				clearInterval(_filterIntervalID);
				_filterIntervalID = setInterval(stopFilterMouseWheel, 2000);
				return;
			}
			mouseWheel(event.delta);
		}
		
		/**
		 * 3秒内无鼠标滚动，保存时间轴调整
		 */
		private function stopTimeMouseWheel():void
		{
			if (_lastMouseDelta != _curMouseDelta)
			{
				_lastMouseDelta = _curMouseDelta;
				
				//隐藏提示
				Tools.hideToolTip();
				saveTimeDelta();
				
				if (GlobalVars.instance.isStat)
				{
					Tools.stat("f=changeSubtitleTimeByMouse");
				}
			}
		}
		
		/**
		 * 3秒内无鼠标滚动，隐藏提示
		 */
		private function stopFilterMouseWheel():void
		{
			//隐藏提示
			Tools.hideToolTip();
		}
		
		override protected function keyUpFunc(e:KeyboardEvent):void
		{
			super.keyUpFunc(e);
			if(e.shiftKey && e.keyCode == 219)
			{
				//提前时间
				trace("shift + [");
				_captionFace.subTimeDeltaByKey(0.5);
				
				_curKeyDelta++;
				clearInterval(_keyDeltaID);
				_keyDeltaID = setInterval(stopKeyPress, 3000);
			}
			
			if(e.shiftKey && e.keyCode == 221)
			{
				//推迟时间
				trace("shift + ]");
				_captionFace.addTimeDeltaByKey(0.5);
				
				_curKeyDelta--;
				clearInterval(_keyDeltaID);
				_keyDeltaID = setInterval(stopKeyPress, 3000);
			}
		}
		
		/**
		 * 3秒内无键盘按下，保存时间轴调整
		 */
		private function stopKeyPress():void
		{
			if (_lastKeyDelta != _curKeyDelta)
			{
				_lastKeyDelta = _curKeyDelta;
				
				//隐藏提示
				Tools.hideToolTip();
				saveTimeDelta();
				
				if (GlobalVars.instance.isStat)
				{
					Tools.stat("f=changeSubtitleTimeByKey");
				}
			}
		}
		
		override protected function keyDownFunc(event:KeyboardEvent):void
		{
			super.keyDownFunc(event);
		}
		
		override protected function handleMouseHide():void
		{
			/*
			if (!_toolTopFace.hidden && !_toolTopFace.beMouseOn && !_player.isPause)
			{
				_toolTopFace.hide();
			}
			if (_toolTopFace.beMouseOn)
			{
				Mouse.show();
			}
			*/
			
			if (!_toolRightFace.hidden && !_toolRightFace.beMouseOn)
			{
				_toolRightFace.hide();
			}
			if (_toolRightFace.beMouseOn)
			{
				Mouse.show();
			}
			if (!_toolRightArrow.hidden)
			{
				_toolRightArrow.hide();
			}
			
			//鼠标在设置面板，不隐藏鼠标
			if (_settingSpace.beMouseOn)
			{
				Mouse.show();
			}
		}
		
		override protected function handleMouseShowAndMove():void
		{
			super.handleMouseShowAndMove();

			/*                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             

			if (_toolTopFace.hidden)
			{
				_toolTopFace.show();
			}
			*/

			if (this.mouseX > stage.stageWidth - 150)
			{
				if (_toolRightFace.hidden)
				{
					_toolRightFace.show();
				}
				if (_toolRightArrow.visible)
				{
					_toolRightArrow.visible = false;
					_toolRightArrow.hide(true);
				}
			}
			else
			{
				if (!_toolRightFace.hidden)
				{
					_toolRightFace.hide();
				}
				if (!_toolRightArrow.visible)
				{
					_toolRightArrow.visible = true;
					_toolRightArrow.show();
				}
			}
			if (_toolRightArrow.hidden)
			{
				_toolRightArrow.show();
			}
		}
		
		override protected function addJustStageFullScreen(time:Number, isFullScreen:Boolean):void{
			super.addJustStageFullScreen(time, isFullScreen);
			_toolRightFace.hide(true);
			_toolTopFace.hide(true);
			//未开播时不显示
			if (time > 0)
			{
				_toolRightArrow.show(true);
			}
			else
			{
				_toolRightArrow.hide(true);
			}
			if (isFullScreen) {
				_toolTopFace.fullScreen();
			}else {
				_toolTopFace.normalScreen();
			}
		}
		
		override protected function initJsInterface():void{
			if (ExternalInterface.available)
			{
				ExternalInterface.addCallback('flv_showFormats', flv_showFormats);
				ExternalInterface.addCallback('flv_setCaptionParam', flv_setCaptionParam);
				ExternalInterface.addCallback('flv_setShareLink', flv_setShareLink);
				ExternalInterface.addCallback('flv_showFeedbackFace', flv_showFeedbackFace);
			}
			super.initJsInterface();
		}
		
		public function flv_showFeedbackFace():void
		{
			var urlStr:String = "PlayerCtrl -> js回调flv_showFeedbackFace, 显示问题反馈面板";
			JTracer.sendMessage(urlStr);
			
			_feedbackFace.visible = false;
			showFeedbackFace("webpage");
		}
		
		public function flv_setShareLink(title:String, url:String):void
		{
			var urlStr:String = "PlayerCtrl -> js回调flv_setShareLink, 设置分享地址, title:" + title + ", url:" + url;
			JTracer.sendMessage(urlStr);
			
			var tf:TextFormat = new TextFormat("宋体");
			
			_shareFace.url_txt.text = url;
			_shareFace.url_txt.setTextFormat(tf);
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
		override public function flv_setFeeParam(obj:Object):void
		{
			_toolTopFace.infoObj = obj;
			super.flv_setFeeParam(obj);

			//设置字幕列表为未加载状态
			GlobalVars.instance.isCaptionListLoaded = false;
			//设置字幕样式为未加载状态
			GlobalVars.instance.isCaptionStyleLoaded = false;
			//设置没有自动加载的字幕
			GlobalVars.instance.isHasAutoloadCaption = false;
			//加载上次加载的字幕
			_captionFace.loadLastload();
						
			//加载文件列表
			if (_fileListFace)
			{
				_fileListFace.resetReqOffset();
				_fileListFace.resetListArray();
				_fileListFace.loadFileList();
			}
		}
		
		override public function flv_setToolBarEnable(obj:Object):void
		{
			super.flv_setToolBarEnable(obj);
			if (_toolRightFace)
			{
				_toolRightFace.enableObj = obj;
			}
			if (_toolTopFace)
			{
				_toolTopFace.visible = obj.enableTopBar;
			}
		}
		
		/**
		 * 设置字幕上传参数
		 * @param	obj		字幕上传参数
		 * 
		 * obj.extension:*.srt;*.ass
		 * obj.limitSize:5242880	上限大小，单位字节
		 * obj.description:请选择字幕文件(*.srt、*.ass)
		 * obj.timeOut		超时时间
		 * obj.uploadURL	上传地址
		 */
		public function flv_setCaptionParam(obj:Object):void
		{
			var urlStr:String = "PlayerCtrl -> js回调flv_setCaptionParam, 设置字幕上传参数:";
			for (var i:* in obj)
			{
				urlStr += "\n" + "obj." + i + ":" + obj[i];
			}
			JTracer.sendMessage(urlStr);
			
			_captionFace.setOuterParam(obj);
		}
		
		override protected function hideSideChangeQuilty():void
		{
			super.hideSideChangeQuilty();
			if (!_toolTopFace.hidden)
			{
				_toolTopFace.hide();
			}
			if (!_toolRightFace.hidden)
			{
				_toolRightFace.hide();
			}
			if (!_toolRightArrow.hidden)
			{
				_toolRightArrow.hide();
			}
		}
		
		private function hideAllLayer():void
		{
			if (_settingSpace.visible) {
				_settingSpace.showSetFace();
				reportSetStat();
			}
			if (_captionFace.visible)
			{
				_captionFace.showFace(false);
			}
			if (_fileListFace.visible)
			{
				_fileListFace.showFace(false);
			}
			if (_shareFace)
			{
				_shareFace.showFace(false);
			}
			if (_feedbackFace)
			{
				_feedbackFace.showFace(false);
			}
			if (_downloadFace.visible)
			{
				_downloadFace.showFace(false);
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
		
		override public function flv_showFormats(formats:Object):void
		{
			var urlStr:String = "PlayerCtrl -> js回调flv_showFormats, 设置formats:";
			urlStr += "\n" + com.serialization.json.JSON.serialize(formats);
			JTracer.sendMessage(urlStr);
			
			super.flv_showFormats(formats)
			_downloadFace.setDownloadFormat(formats);
		}
				
		//是否有下一集
		override public function get isHasNext():Boolean
		{
			var _isHasNext:Boolean = _fileListFace.isHasNext;
			return _isHasNext;
		}
		
	}
}