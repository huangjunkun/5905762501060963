package zuffy.display.statuMenu 
{
	import com.global.GlobalVars;
	import com.greensock.TweenLite;
	
	import flash.accessibility.Accessibility;
	import flash.display.InterpolationMethod;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.system.Capabilities;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import eve.EventSet;
	import eve.PlayEvent;
	import eve.TryPlayEvent;
	
	import zuffy.core.PlayerCtrl;
	import zuffy.utils.Tools;
	import zuffy.utils.JTracer;
	
	/**
	 * ...
	 * @author chnzbq
	 */
	
	public class VideoMask extends Sprite
	{
		private var _qualityLoading:Sprite;
		private var _processLoading:Sprite;
		private var _bufferLoading:Sprite;
		private var _startPlayBtn:Sprite;
		private var _isBuffer:Boolean = false;
		private var _isFirstLoading:Boolean = true;
		private var _isQualityLoading:Boolean = false;
		private var _movieType:String;
		private var _mask:Sprite;
		private var _delayTimer:Timer = new Timer(800, 0);
		private var _cacheStreamPercent:Number = 0;
		private var _isFirstInit:Boolean = true;
//		private var _logoEnd:LogoEnd;
		private var _invalidText:TextField;
		private var _mainMc:PlayerCtrl;
		private var _style:StyleSheet;
		
		public static var noEnoughBytes:String = "noEnoughBytes";
		public static var invalidLogin:String = "invalidLogin";
		public static var refreshPage:String = "refreshPage";
		public static var exchangeError:String = "exchangeError";
		public static var playError:String = "playError";
		public static var noPrivilege:String = 'noPrivilege';

		private var  _currentInfo:String = '';
		public function get currentInfo():String {
			var ret:String = _currentInfo;
			_currentInfo = '';
			return ret;
		};
		
		public function VideoMask(mainMc:PlayerCtrl, movieType:String = 'movie') 
		{
			_mainMc = mainMc;
			_movieType = movieType;
			
			_style = new StyleSheet();
			_style.setStyle('.style', { color:'#ffffff', fontSize:'14', textAlign:'center', fontFamily :'宋体'} );
			_style.setStyle('a', { color:'#097BB3', fontSize:'14', textAlign:'center', fontFamily :'宋体', textDecoration:'underline' } );
			
			_mainMc.addChild(this);
			setPosition();
		}
		
		public function bufferHandle(type:String, info:String = null):void
		{
			switch(type)
			{
				case 'PlayStart':
					onplay();
					break;
				case 'BufferStart':
					if (_isQualityLoading == false && _isFirstLoading == false) {
						showLoadingBuffer();
					}
					break;
				case 'Stop':
					if (!_isFirstInit)
					{
						showStopLogo();
					}
					break;
				case 'Error':
				case 'BufferEnd':
					hideAll();
					break;
			}
		}
		
		public function showErrorNotice(type:String = "", errorCode:String = "", otherTips:String = ""):void
		{
			var tips:String;
			switch(type)
			{
				case noEnoughBytes:
					tips = "<span class='style'>您的播放时长剩余0，迅雷白金会员不限时长，</span><a href='event:buyVIP13FluxOut'>加5元升级为白金</a>";
					break;
				case invalidLogin:
					tips = "<span class='style'>检测到您未登录或登录异常，请重新登录后从列表页点播</span>";
					break;
				case refreshPage:
					tips = "<span class='style'>检测到您未登录或登录异常，请</span> <a href='event:login'>" + "重新登录" + "</a> <span class='style'>后刷新此页面</span>\n\n<a href='event:refresh'>" + "刷新页面" + "</a>";
					break;
				case exchangeError:
					//tips = "<span class='style'>服务器正忙，请稍后再试</span>";
					tips = "<span class='style'>" + otherTips + "</span>";
					break;
				case playError:
					if (errorCode)
					{
						tips = "<span class='style'>播放异常，错误代码：" + errorCode + "</span>\n\n<span class='style'>请检查网络连接或重试！</span> <a href='event:feedback'>问题反馈</a>";
					}
					else
					{
						tips = "<span class='style'>播放异常，请检查网络连接或重试！</span> <a href='event:feedback'>问题反馈</a>";
					}
					break;
				case noPrivilege:
					tips = "<span class='style'>播放连接超时，已</span><a href='event:buyVIP11'>开通迅雷云播</a><span class='style'>用户请点击</span><a href='event:refreshWholePage'>重新获取</a>";
					break;
				default:
					tips = "";
					break;
			}
			
			hideAll();
			drawMask();
			
			if (!_invalidText) {
				_invalidText = new TextField();
			} else {
				_invalidText.visible = true;
			}
			_invalidText.selectable = false;
			_invalidText.styleSheet = _style;
			_invalidText.htmlText = tips;
			_invalidText.width = _invalidText.textWidth + 4;
			_invalidText.height = _invalidText.textHeight + 4;
			_invalidText.addEventListener(TextEvent.LINK, onTextLink);
			this.addChild(_invalidText);
			setPosition();
		}
		
		public function showInputFace():void
		{
			if (stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				stage.displayState = StageDisplayState.NORMAL;
			}
			hideAll();
			drawMask();
			Tools.windowOpen(GlobalVars.instance.url_chome, "_self");
			/*
			hideAll();
			drawMask();
			if(_inputFace == null){
				_inputFace = new InputFace();
			}else {
				_inputFace.visible = true;
			}
			this.addChild(_inputFace);
			setPosition();
			*/
		}
		
		public function initInputFace():void
		{
			/*
			if (_inputFace)
			{
				_inputFace.init();
			}
			*/
		}
		
		public function showInitPauseLogo():void
		{
			hideAll();
			if(_startPlayBtn == null){
//				_startPlayBtn = new StartPlayButton();
//				_startPlayBtn.gotoAndStop(1);
				_startPlayBtn.buttonMode = true;
				_startPlayBtn.mouseChildren = false;
				_startPlayBtn.addEventListener(MouseEvent.CLICK, onStartPlayClick);
				_startPlayBtn.addEventListener(MouseEvent.MOUSE_OVER, onStartPlayOver);
				_startPlayBtn.addEventListener(MouseEvent.MOUSE_OUT, onStartPlayOut);
			}else {
				_startPlayBtn.visible = true;
			}
			this.addChild(_startPlayBtn);
			setPosition();
		}
		
		private function onTextLink(evt:TextEvent):void
		{
			switch(evt.text) {
				case "login":
					login();
					break;
				case "refresh":
					refresh(1);
					break;
				case "refreshWholePage":
					refresh(2);
					break;
				case "buyVIP11":
//mzh					dispatchEvent(new TryPlayEvent(TryPlayEvent.BuyVIP, {refer:"XV_34"}));
					break;
				case "buyVIP13FluxOut":
					buyVIP13FluxOut();
					break;
				case "feedback":
					feedback();
					break;
			}
		}
		
		private function login():void
		{
			if (stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				stage.displayState = StageDisplayState.NORMAL;
			}
			if (GlobalVars.instance.platform == "client")
			{
				Tools.windowOpen(GlobalVars.instance.url_login, "_blank", "jump");
			}
			else
			{
				Tools.windowOpen(GlobalVars.instance.url_login);
			}
			
			//不出现刷新按钮
			//showErrorNotice(refreshPage);
		}
		
		private function refresh(type:int):void
		{
			var evt:Event = new Event("Refresh");
			switch(type){
				case 1:
					break;
				case 2:
					_currentInfo = 'refreshPage';
					break;
				default:
					break;
			}
			dispatchEvent(evt);
		}
		
		private function buyVIP13FluxOut():void
		{
			var paypos:String = GlobalVars.instance.paypos_tryfinish;
//			dispatchEvent(new TryPlayEvent(TryPlayEvent.BuyVIP, {refer:"XV_13", paypos:paypos, hasBytes:false}));
		}
		
		private function feedback():void
		{
//			dispatchEvent(new EventSet(EventSet.SHOW_FACE, "feedbackFromTips"));
		}
		
		private function onStartPlayClick(evt:MouseEvent):void
		{
			dispatchEvent(new Event("StartPlayClick"));
		}
		
		private function onStartPlayOver(evt:MouseEvent):void
		{
//			_startPlayBtn.gotoAndStop(2);
		}
		
		private function onStartPlayOut(evt:MouseEvent):void
		{
//			_startPlayBtn.gotoAndStop(1);
		}
		
		public function get isStartPlayLoading():Boolean
		{
			if (_processLoading && _processLoading.visible)
			{
				return true;
			}
			
			if (_qualityLoading && _qualityLoading.visible)
			{
				return true;
			}
			
			return false;
		}
		
		public function showProcessLoading():void
		{
			hideAll();
			if (_processLoading){
				_processLoading.visible = true;
			} else {
//				_processLoading = new ProcessLoading();
			}
//			_processLoading.changeTips();
//			_processLoading.progress = 0;
			this.addChild(_processLoading);
			this.addEventListener(Event.ENTER_FRAME, fnEnterFrameBytesLoaded);
			setPosition();
			if (_isFirstInit)
			{
				_isFirstInit = false;
			}
			else
			{
				this.graphics.clear();
				this.graphics.beginFill(0x000000);
				this.graphics.drawRect(0, 0, this.stage.stageWidth, this.stage.stageHeight);
				this.graphics.endFill();
			}
		}
		
		private function showStopLogo():void
		{
//			hideAll();
//			if (_isQualityLoading == true || !_mainMc.isShowStopFace) { return; }
//			drawMask();
//			if (_logoEnd){
//				_logoEnd.visible = true;
//			} else {
//				_logoEnd = new LogoEnd();
//				_logoEnd.replay_btn.buttonMode = true;
//				_logoEnd.replay_btn.mouseChildren = false;
//				_logoEnd.replay_btn.addEventListener(MouseEvent.CLICK, onReplayClick);
//				_logoEnd.replay_btn.addEventListener(MouseEvent.MOUSE_OVER, onBtnOver);
//				_logoEnd.replay_btn.addEventListener(MouseEvent.MOUSE_OUT, onBtnOut);
//				
//				if (GlobalVars.instance.platform == "client" || GlobalVars.instance.isZXThunder)
//				{
//					_logoEnd.removeChild(_logoEnd.share_btn);
//				}
//				else
//				{
//					if (GlobalVars.instance.enableShare)
//					{
//						_logoEnd.share_btn.gotoAndStop(1);
//						_logoEnd.share_btn.buttonMode = true;
//						_logoEnd.share_btn.mouseChildren = false;
//						_logoEnd.share_btn.addEventListener(MouseEvent.CLICK, onShareClick);
//						_logoEnd.share_btn.addEventListener(MouseEvent.MOUSE_OVER, onBtnOver);
//						_logoEnd.share_btn.addEventListener(MouseEvent.MOUSE_OUT, onBtnOut);
//					}
//					else
//					{
//						_logoEnd.share_btn.gotoAndStop(2);
//					}
//				}
//			}
//			this.addChild(_logoEnd);
//			
			setPosition();
		}
		
		private function onBtnOver(evt:MouseEvent):void
		{
			var t_mc:MovieClip = evt.target as MovieClip;
//			TweenLite.to(t_mc.bg_mc, 0.2, {width:85, height:85});
		}
		
		private function onBtnOut(evt:MouseEvent):void
		{
			var t_mc:MovieClip = evt.target as MovieClip;
//			TweenLite.to(t_mc.bg_mc, 0.2, {width:78.75, height:78.75});
		}
		
		private function onReplayClick(evt:MouseEvent):void
		{
			//dispatchEvent(new PlayEvent(PlayEvent.PLAY));
			ExternalInterface.call("flv_playerEvent", "onRePlay");
		}
		
		private function onShareClick(evt:MouseEvent):void
		{
//			dispatchEvent(new EventSet(EventSet.SHOW_FACE, "share"));
		}
		
		private function showLoadingBuffer():void	//Buffer
		{
			hideAll();
			_cacheStreamPercent = 0;
			if (!_bufferLoading){
				var tf:TextFormat = new TextFormat("微软雅黑");
				
//				_bufferLoading = new BufferLoading();
//				_bufferLoading.loadingtext.defaultTextFormat = tf;
//				_bufferLoading.loadingtext.setTextFormat(tf);
			}
			_bufferLoading.visible = false;
			this.addChild( _bufferLoading );
			
			this.addEventListener(Event.ENTER_FRAME, fnEnterFrameBytesLoaded);
			setPosition();
			/*
			if(!_isBuffer){
				ExternalInterface.call("flv_playerEvent", "onbuffering");
				JTracer.sendMessage("VideoMask -> onbuffering");
			}
			*/
		}
		
		public function showLoadingQuality():void //changeQuality
		{
			hideAll();
			if (_qualityLoading){
				_qualityLoading.visible = true;
			}else{
				var tf:TextFormat = new TextFormat("微软雅黑");
				
//				_qualityLoading = new QualityLoading();
//				_qualityLoading.change_txt.defaultTextFormat = tf;
//				_qualityLoading.change_txt.setTextFormat(tf);
			}
			addChild( _qualityLoading );
			this.addEventListener(Event.ENTER_FRAME, fnEnterFrameBytesLoaded);
			setPosition();
		}
		
		private function drawMask():void
		{
			_mask = new Sprite();
			_mask.graphics.beginFill(0xffffff, 0);
			_mask.graphics.drawRect(0, 0, this.stage.stageWidth, this.stage.stageHeight);
			addChild(_mask);
		}
		
		private function fnEnterFrameBytesLoaded(e:Event):void
		{
//			dispatchEvent(new PlayEvent(PlayEvent.PROGRESS));
		}
		
		public function updateProgress(num:Number):void
		{
			var streamPercent:Number = num;
			if (streamPercent >= 1){
				streamPercent = 1;
			}
			/*if (Math.floor(streamPercent*100) == 0) {
				if(!_delayTimer.running){
					_delayTimer.addEventListener(TimerEvent.TIMER, delayTimerHandler);
					_delayTimer.start();
				}
			}else {
				stopDelayTimer();
			}*/
			streamPercent = streamPercent > _cacheStreamPercent ? streamPercent : _cacheStreamPercent;
			if (_processLoading)
			{
//				_processLoading.progress = int(streamPercent * 100);
			}
			//只在小于100%的时候才显示缓冲
			if(_bufferLoading && streamPercent < 1){
				_bufferLoading.visible = true;
//				_bufferLoading.loadingtext.text = "" + int(streamPercent * 100) + "%";
			}
			
			if (streamPercent == 1){
				this.removeEventListener(Event.ENTER_FRAME, fnEnterFrameBytesLoaded);
				_cacheStreamPercent = 0;
				hideAll();
				JTracer.sendMessage("VideoMask -> updateProgress :" + num + " streamPercent:" + streamPercent)
				//hwh
//				dispatchEvent(new PlayEvent(PlayEvent.BUFFER_END));
			}
		}
		
		private function delayTimerHandler(e:TimerEvent):void
		{
			if(_delayTimer.currentCount > 1){
				_cacheStreamPercent += Math.random() * 6 / 100;
				_cacheStreamPercent = _cacheStreamPercent > 0.99 ? 0.99 : _cacheStreamPercent;
			}
		}
		
		private function stopDelayTimer():void
		{
			_delayTimer.stop();
			_delayTimer.reset();
			if(_delayTimer.hasEventListener(TimerEvent.TIMER)){
				_delayTimer.removeEventListener(TimerEvent.TIMER, delayTimerHandler);
			}
		}
		
		private function onplay():void
		{
//			hideAll();
//			this.removeEventListener(Event.ENTER_FRAME, fnEnterFrameBytesLoaded);
//			if(!_isBuffer || _isFirstLoading == true){
//				if (_mainMc.isFirstOnplaying)
//				{
//					_mainMc.isFirstOnplaying = false;
//					var gcid:String = Tools.getUserInfo("gcid");
//					var ygcid:String = Tools.getUserInfo("ygcid");
//					var usertype:Number = Number(Tools.getUserInfo("userType"));
//					var playtype:String;
//					if (usertype == 0 || usertype == 1 || usertype == 5)
//					{
//						//正常播放
//						playtype = "0";
//					}
//					else
//					{
//						//时长卡播放
//						playtype = "2";
//					}
//					//首缓冲时长上报
//					var load_time_str:String = "";
//					for (var i:* in GlobalVars.instance.loadTime)
//					{
//						load_time_str += "&" + i + "=" + GlobalVars.instance.loadTime[i];
//					}
//					// gdl 链接时间 
//					var gdlConnectTimeStr:String = "&gdlConnectTime=" + GlobalVars.instance.connectGldTime;
//					var vodAddr:String = GlobalVars.instance.vodAddr == '' ? '&vod=null' : '&vod=' + GlobalVars.instance.vodAddr;
//					var theCCStr:String = GlobalVars.instance.statCC;
//					JTracer.sendMessage("f=firstbuffer&gcid=" + gcid + "&ygcid=" + ygcid + "&time=" + (getTimer() - _mainMc._player.startTimer) + "&playtype=" + playtype + "&flashversion=" + Capabilities.version + "&getVodTime=" + GlobalVars.instance.getVodTime + load_time_str + gdlConnectTimeStr + vodAddr);
//					Tools.stat("f=firstbuffer&gcid=" + gcid + "&ygcid=" + ygcid + "&time=" + (getTimer() - _mainMc._player.startTimer) + "&playtype=" + playtype + "&flashversion=" + Capabilities.version + "&getVodTime=" + GlobalVars.instance.getVodTime + load_time_str + gdlConnectTimeStr + vodAddr);					
//				}
//				ExternalInterface.call("flv_playerEvent", "onplaying");
//				JTracer.sendMessage('VideoMask -> onplaying');
//			}
//			JTracer.sendMessage('isBuffer:'+_isBuffer);
		}
		
		private function hideAll():void
		{
			this.graphics.clear();
			stopDelayTimer();
			while (numChildren > 0) {
				getChildAt(numChildren - 1).visible = false;
				removeChild(getChildAt(numChildren - 1));
			}
			_cacheStreamPercent = 0;
		}
		
		public function setPosition():void
		{
			if (_mask)
			{
				_mask.width = this.width;
				_mask.height = this.height;
			}
			
			if (_processLoading && _processLoading.visible && !_isFirstInit)
			{
				this.graphics.clear();
				this.graphics.beginFill(0x000000);
				this.graphics.drawRect(0, 0, this.stage.stageWidth, this.stage.stageHeight);
				this.graphics.endFill();
			}
			
			var numChild:int = this.numChildren;
			for (var i:int = 0; i < numChild; i++) {
				if (getChildAt(i) === _qualityLoading)
				{
					getChildAt(i).x = int((this.stage.stageWidth - 315) / 2);
					getChildAt(i).y = int((this.stage.stageHeight - 41 - 33) / 2);
				}
				else
				{
					getChildAt(i).x = int((this.stage.stageWidth - getChildAt(i).width) / 2);
					getChildAt(i).y = int((this.stage.stageHeight - getChildAt(i).height - 33) / 2);
				}
			}
		}
		
		public function set isBuffer(boo:Boolean):void
		{
			_isBuffer = boo;
		}
		
		public function set isQualityLoading(boo:Boolean):void
		{
			_isQualityLoading = boo;
		}
		
		public function set isFirstLoading(boo:Boolean):void
		{
			_isFirstLoading = boo;
		}
	}

}