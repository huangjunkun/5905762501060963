package zuffy.core
{
	import zuffy.ctr.contextMenu.CreateContextMenu;
	import zuffy.display.addBytes.NoEnoughBytesFace;
	import zuffy.display.CtrBar;
	import zuffy.display.MouseControl;
	import zuffy.display.addBytes.AddBytesFace;
	import zuffy.display.addBytes.NoEnoughBytesFace;
	import zuffy.display.download.DownloadFace;
	import zuffy.display.fileList.FileListFace;
	import zuffy.display.notice.NoticeBar;
	import zuffy.display.notice.bufferTip;
	import zuffy.display.question.FeedbackFace;
	import zuffy.display.tryplay.TryEndFace;
	import zuffy.display.setting.SettingSpace;
	import zuffy.display.share.ShareFace;
	import zuffy.display.subtitle.Subtitle;
	import zuffy.display.statuMenu.VideoMask;
	import zuffy.display.tryplay.TryEndFace;
	import zuffy.display.subtitle.CaptionFace;
	import zuffy.display.subtitle.Subtitle;
	import zuffy.display.tip.ToolTip;
	import zuffy.display.toolBarRight.ToolBarRight;
	import zuffy.display.toolBarRight.ToolBarRightArrow;
	import zuffy.display.toolBarTop.ToolBarTop;
	import zuffy.display.tryplay.TryEndFace;
	import zuffy.events.CaptionEvent;
	import zuffy.events.ControlEvent;
	import zuffy.events.EventSet;
	import zuffy.events.PlayEvent;
	import zuffy.events.SetQulityEvent;
	import zuffy.events.TryPlayEvent;

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

		private var _isNoEnoughBytes:Boolean;				//是否流量不足
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


		private var _keyDeltaID:int;

		public function PanelPlayerCtrl()
		{
			super();
		}

		override function initializeUI(tWidth:int, tHeight:int):void{
			super();
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
		}
		//显示系统时间
		public function setSystemTime():void
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
		override function on_stage_RESIZE(e:Event):void{
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
			_videoMask.setPosition();
			_downloadFace.setPosition();
		}

		// 切换视频
		override function exchangeVideo():void
		{
			// 清除全部字幕
			_captionFace.clearCaption();

			// 下载面板重置
			_downloadFace.setAllDisabled();
		}
		
		// 播放下一集视频
		public function playNext():void
		{
			_fileListFace.playNext();
		}
		
		// 显示流量充值面板
		private function tryPlayAddBytesHandler(e:TryPlayEvent):void
		{
			var need:Number = e.need;
			var remind:Number = e.remind;
			var total:Number = e.total;
			var isStop:Boolean = e.isStop;
			var index:int;
			if (remind <= 0)
			{
				//流量不足
				_isNoEnoughBytes = true;
				
				//弹框时暂停
				if (!isStop)
				{
					_ctrBar.dispatchPause();
				}
				if (!_noEnoughFace)
				{
					index = this.getChildIndex(_captionFace);
					
					_noEnoughFace = new NoEnoughBytesFace();
					_noEnoughFace.addEventListener("CloseNoEnoughFace", onCloseNoEnoughFace);
					addChildAt(_noEnoughFace, index);
					_noEnoughFace.setPosition();
				}
				return;
			}
		}

		// 关闭流量充值面板
		private function onCloseNoEnoughFace(evt:Event):void
		{
			if (_noEnoughFace)
			{
				removeChild(_noEnoughFace);
				_noEnoughFace = null;
			}
			_isStopNormal = false;
			_isShowStopFace = false;
			
			_ctrBar.dispatchStop();
			_videoMask.showErrorNotice(VideoMask.noEnoughBytes);
		}
		
		override function onCloseAddBytesFace(evt:Event):void{
			super();
			if (_addBytesFace)
			{
				removeChild(_addBytesFace);
				_addBytesFace = null;
			}
		}
		
		override function pauseForever(tips:String):void
		{
			//流量不足
			_isNoEnoughBytes = true;
			super(tips);
		}
		
		//试播结束
		override function tryPlayEnded(time:Number):void
		{
			if (!_isPauseForever)
			{
				_isPauseForever = true;
				
				super();

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
		
		override function tryPlayEventHandler(evt:TryPlayEvent):void
		{
			super(evt);

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
			}
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
		
		override function initOther():void{
			super();
			loadPanel(null)
		}
		private var _isXLNetStreamValid:Boolean = false;
		private function initXLPlugins(flag:Boolean = false):void{
			
		}
		
		/**
		 * 监听各个控制器及自身发出的信息、事件;
		 */
		protected function initStageEvent():void
		{
			super();

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
			this.addEventListener(TryPlayEvent.TRY_PLAY_ENDED_ADDBYTE, tryPlayAddBytesHandler)
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
				
//				_subTitle.saveStyle();
			}
			
			//关闭面板后，如调节了时间轴，保存时间轴信息和上报
			if (GlobalVars.instance.captionTimeChanged)
			{
				GlobalVars.instance.captionTimeChanged = false;
				
				if (GlobalVars.instance.isStat)
				{
					Tools.stat("b=changeSubtitleTime");
				}
				
//				_subTitle.saveTimeDelta();
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
		
		private function loadCaptionStyle(evt:EventSet):void
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
		
		override function playEventHandler(e:PlayEvent):void
		{
			super(e);
			
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
			
			if( _isFullScreen )
			{
				if( event.delta > 0 )
					_ctrBar.handleVolumeFromKey( true );
				else
					_ctrBar.handleVolumeFromKey( false );
			}
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
				_subTitle.saveTimeDelta();
				
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
		
		override function keyUpFunc(e:KeyboardEvent):void
		{
			super(e);
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
				_subTitle.saveTimeDelta();
				
				if (GlobalVars.instance.isStat)
				{
					Tools.stat("f=changeSubtitleTimeByKey");
				}
			}
		}
		
		override function keyDownFunc(event:KeyboardEvent):void
		{
			super(event);
		}
		
		override function handleMouseHide():void
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
		
		protected function handleMouseShowAndMove():void
		{
			super();

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
		
		protected function addJustStageFullScreen(player:Player, isFullScreen:Boolean):void{
			super(player,isFullScreen);
			_toolRightFace.hide(true);
			_toolTopFace.hide(true);
			//未开播时不显示
			if (_player.time > 0)
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
			
			_isPauseForever = false;
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
			_isError = false;
			_ctrBar.visible = true;
			//重置宽高比例
			//_setSizeInfo['ratio'] = 'common';
			//去掉filter
			//_player.filters = [];
			_player.retryLastTimeStat = arr[0].isRetryLastTime ? "&errorRetry=end" : "";
			_player.hasNextStream = true;
			Tools.getFormat();

			var isUseP2P:Boolean =  checkIsUseP2P(arr[0].url);		

			JTracer.sendMessage('is ios page :' + GlobalVars.instance.isMacWebPage)
			if(Player.p2p_type == 'p2s' || GlobalVars.instance.isMacWebPage || !isUseP2P){
				GlobalVars.instance.isXLNetStreamValid = 0;
				_player.setPlayUrl(arr);
				return;
			}

			// 未初始化的情况
			if(!isXLNetStreamAfterInited){

				JTracer.sendMessage("PlayerCtrl -> setPlayUrl in p2p");
				if(_isXLNetStreamValid){
					JTracer.sendMessage('play other in p2p')
					GlobalVars.instance.isXLNetStreamValid = 1;
					_player.setPlayUrl(arr);
				}else{
					xlPluginCallBackArgs = arr;
					execFuncWhenXLPluginInit();
				}

			}else{

				JTracer.sendMessage('b:'+_isXLNetStreamValid + ' c:'+isUseP2P)
				// 点播另一个视频
				if(_isXLNetStreamValid && isUseP2P){
					JTracer.sendMessage('play other in p2p')
					GlobalVars.instance.isXLNetStreamValid = 1;
				}else{
					GlobalVars.instance.isXLNetStreamValid = 0;
				}
				_player.setPlayUrl(arr);
			}
			
		}

		private function execFuncWhenXLPluginInit():void{
			JTracer.sendMessage('PlayerCtrl -> execFuncWhenXLPluginInit')
			if(xlPluginCallBackFunc){
				xlPluginCallBackFunc();
			}
			else{
				xlPluginCallBackFunc = function _xlPluginCallBackFunc():void{
					_player && _player.setPlayUrl(xlPluginCallBackArgs);
					isXLNetStreamAfterInited = true;
				}
			}
		}
		private function notValidPlayer():Boolean{
			var vodPermit:Number = Number(Tools.getUserInfo("vodPermit"));
			var ret = ((vodPermit == 6 || vodPermit == 8 || vodPermit == 10) && Tools.getUserInfo("from") != GlobalVars.instance.fromXLPan);
			JTracer.sendMessage('扣费用户:'+ret)
			GlobalVars.instance.feeUser = ret;
			return ret;
		}
		private function checkIsUseP2P(url:String):Boolean
		{
			if(notValidPlayer())return false;
			var hostObj:Object = StringUtil.getHostPort(url);
			var hostUrl:String = hostObj.host;
			var machines:Array = GlobalVars.instance.httpSocketMachines['p2p'] || [];
			JTracer.sendMessage('checkIsUseP2P...')
			for (var k:* in machines)
			{
			JTracer.sendMessage('checkIsUseP2P from:'+machines[k]['from'])
				if (machines[k]['from'] && hostUrl.indexOf(machines[k]['from']) > -1)
				{
					GlobalVars.instance.p2p_config_dl_link = machines[k]['to'];
					GlobalVars.instance.p2p_config_fix_port = machines[k]['port'];
					return true;
				}
			}
			
			return false;
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
		
		private function initJsInterface():void{
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
				ExternalInterface.addCallback('flv_setCaptionParam', flv_setCaptionParam);
				ExternalInterface.addCallback('flv_getTimePlayed', flv_getTimePlayed);
				ExternalInterface.addCallback('flv_setFeeParam', flv_setFeeParam);
				ExternalInterface.addCallback('flv_playOtherFail', flv_playOtherFail);
				ExternalInterface.addCallback('flv_setShareLink', flv_setShareLink);
				ExternalInterface.addCallback('flv_showBarNotice', flv_showBarNotice);
				ExternalInterface.addCallback('flv_setToolBarEnable', flv_setToolBarEnable);
				ExternalInterface.addCallback('flv_showFeedbackFace', flv_showFeedbackFace);
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
		
		public function flv_showFeedbackFace():void
		{
			var urlStr:String = "PlayerCtrl -> js回调flv_showFeedbackFace, 显示问题反馈面板";
			JTracer.sendMessage(urlStr);
			
			_feedbackFace.visible = false;
			showFeedbackFace("webpage");
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
		
		public function flv_setShareLink(title:String, url:String):void
		{
			var urlStr:String = "PlayerCtrl -> js回调flv_setShareLink, 设置分享地址, title:" + title + ", url:" + url;
			JTracer.sendMessage(urlStr);
			
			var tf:TextFormat = new TextFormat("宋体");
			
//			_shareFace.url_txt.text = url;
//			_shareFace.url_txt.setTextFormat(tf);
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
			
			_toolTopFace.infoObj = obj;
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
			if (_toolRightFace)
			{
				_toolRightFace.enableObj = obj;
			}
			if (_ctrBar)
			{
				_ctrBar.enableFileList = obj.enableFileList || false;
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
		
		private function hideSideChangeQuilty():void
		{
			if (_ctrBar._beFullscreen)
			{
				_ctrBar.hide();
				_noticeBar.hide();
			}
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
		
		protected function hideAllLayer():void
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
		
		protected function setObjectLayer():void
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
			var urlStr:String = "PlayerCtrl -> js回调flv_showFormats, 设置formats:";
			urlStr += "\n" + com.serialization.json.JSON.serialize(formats);
			JTracer.sendMessage(urlStr);
			
			_formatsObj = formats;
			_ctrBar.showFormatLayer(formats);
			_downloadFace.setDownloadFormat(formats);
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
		
		//是否有下一集
		public function get isHasNext():Boolean
		{
			var _isHasNext:Boolean = _fileListFace.isHasNext;
			return _isHasNext;
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