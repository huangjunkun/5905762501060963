package zuffy.ctr.manager
{
	import com.common.Cookies;
	import com.greensock.TweenLite;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.net.SharedObject;
	import flash.system.Capabilities;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.ui.Mouse;
	import flash.utils.Timer;
	import com.common.Tools;
	import com.global.GlobalVars;
	import zuffy.display.format.CurrentFormatBtn;
	import zuffy.display.tip.TimeTipsArrow;
	import zuffy.events.EventSet;
	import flash.utils.setTimeout;
	import flash.utils.clearTimeout;
	
	import com.common.JTracer;
	import zuffy.display.fullScreen.FullScreenButton;
	import zuffy.display.tip.BtnTip;
	import zuffy.display.tip.McTimeTip;
	import zuffy.display.tip.Volume100Tips;
	import zuffy.display.tip.VolumeTips;
	import zuffy.display.volume.McVolume;
	import zuffy.display.format.FormatBtn;
	import zuffy.events.*;
	import zuffy.core.PlayerCtrl;
	import com.Player;
	
	public class CtrBarManager {
	
		public const NORMAL_PROGRESSBAR_HEIGTH:uint = 7;
		public const SMALL_PROGRESSBAR_HEIGTH:uint = 3;

		public var _barBg:DefaultBar;          //控制条的背景
		public var _barBuff:LoadingBar;	     //缓冲进度条
		public var _barPlay:PlayBar;	     //已播放进度条
		public var _barPreDown:PreDownBar;	  //本地已加载的数据进度条
		public var _barSlider:Scroll; //指示当前播放位置的滑动条(圆点)
		public var _btnPause:PauseButton;      //暂停按钮
		public var _btnPlay:PlayButton;        //播放按钮
		public var _btnStop:StopButton;        //停止按钮
		public var _btnUnmute:VolumeButton;    //取消静音按钮
		public var _btnMute:VolumeButton;        //静音按钮
		public var _btnFullscreen:FullScreenButton;  //全屏按钮
		private var _btnFilelist:FilelistButton;//文件列表按钮
		private var _filelistTips:FilelistTips;//文件列表提示
		public var _barBorder:Sprite;		
		public var _timerBP:Timer;
		public var playWidth:Number;
		public var playHeight:Number;				
		public var _btnPlayBig:GoOnButtonLa;
		public var _btnPauseBig:GoOnButtonLa;
		public var playctrlHandler:PlayerCtrl;
		public var _beFullscreen:Boolean = false;
		public var hidden:Boolean;
		private var _ctrBarBg:CtrBarBg;
		private var _beMouseOn:Boolean = false;
		private var _beMouseOnFormat:Boolean = false;
		private var _formatBtn:FormatBtn;
		private var _curFormatBtn:CurrentFormatBtn;
		private var _noticeText:TextField;
		//hwh
		private var _isClickBarSeek:Boolean;//是否单击拖动条seek;
		private var _lastStartIdx:int = -1;	//前一个开始点
		private var _captionBtn:MovieClip;
		private var _captionBtnTips:MovieClip;
		
		private var _container:Sprite;
		
		private static var _instance:CtrBarManager;

		public static function get instance(): CtrBarManager {
			
			if (!_instance) {
				_instance = new CtrBarManager ();
			}
			
			return _instance;
		}
		public function CtrBarManager() {
			_container = new Sprite();
		}

		public function makeInstance(playctrlhandler:PlayerCtrl, w:Number = 352, h:Number = 293 , has_fullscreen = 0, _player:Player=null):void {
			this._player = _player
			_stageInfo = { 'WIDTH':w, 'HEIGHT':h };
			
			playWidth = w;
			playHeight = h;

			_container.addEventListener(Event.ADDED_TO_STAGE, handleAddedToStage);
			_container.addEventListener(MouseEvent.MOUSE_OVER, handleMouseOver);
			_container.addEventListener(MouseEvent.MOUSE_OUT, handleMouseOut);
			playctrlhandler.addEventListener(ControlEvent.SHOW_CTRBAR, controlEventHandler);
			
			playctrlHandler = playctrlhandler;
			playctrlHandler.addEventListener(MouseEvent.ROLL_OUT, handleMouseOutPlayer);
			playctrlHandler.addChild(_container);
			fixedY = _container.stage.stageHeight - 33
			faceLifting(_container.stage.stageWidth);
		}

		public function playEventHandler(type:String):void {
			
			switch(type) {
				
				case 'Stop':
					if (_isChangeQuality == false) {
						onStop();
					}
					
					//停止后，不处理为点击拖动条和使用按键进退产生的缓冲，使用bufferLength / bufferTime计算缓冲
					_isClickBarSeek = false;
					
					//播放完后，显示工具条
					show(true);
					
					break;
				case 'PlayForStage':
					dispatchPlay();
					break;
				case 'PauseForStage':
					dispatchPause();
					break;
				case 'BufferStart':
					if( !playctrlHandler.isFirstLoad )
						normalPlayProgressBar();//遇到缓冲，进度条变大
					break;
				case 'BufferEnd':
					isClickBarSeek = false;
					break;
				case 'OpenWindow':
					dispatchStop();
					break;
			}
		}

		public function keySeekByTime(seekTime:Number):void {
			_barSlider.x = (_barWidth - 16) * seekTime / _player.totalTime;
			if( _barSlider.x < 0 )
				_barSlider.x = 0;
			else if( _barSlider.x > _barWidth - 16 )
				_barSlider.x = _barWidth - 16;
			_barPlay.width = _barSlider.x - _barPlay.x + 6;
		}

		private function controlEventHandler(e:ControlEvent):void
		{
			if (e.info == 'hidden') {
				_barSlider.visible = false;
				_seekEnable = false;
			}else {
				_seekEnable = true;
			}
		}

		public function toggleCaptionBtn(isShow:Boolean):void {
			if (isShow) {
				showCaptionBtn();
			}
			else {
				hideCaptionBtn();
			}
		}

		public function showCaptionBtn():void
		{
			var tf:TextFormat = new TextFormat();
			tf.font = "宋体";
			if(GlobalVars.instance.isZXThunder){
				setPosition();
				return;
			}
			if (!_captionBtn)
			{
				_captionBtn = new CaptionButton();
				_captionBtn.txt.defaultTextFormat = tf;
				_captionBtn.txt.setTextFormat(tf);
				_captionBtn.x = _curFormatBtn.x - 45 - 8;
				_captionBtn.y = 7;
				_captionBtn.buttonMode = true;
				_captionBtn.mouseChildren = false;
				_captionBtn.addEventListener(MouseEvent.CLICK, showCaptionFace);
				barBox.addChild(_captionBtn);
			}
			
			var isHideTips:Boolean = Cookies.getCookie('hideCaptionButtonTips');
			if (!isHideTips)
			{
				if (!_captionBtnTips)
				{
					_captionBtnTips = new CaptionBtnTips();
					_captionBtnTips.txt.defaultTextFormat = tf;
					_captionBtnTips.txt.setTextFormat(tf);
					_captionBtnTips.x = _captionBtn.x - 19;
					_captionBtnTips.y = -59;
					_captionBtnTips.close_btn.addEventListener(MouseEvent.CLICK, hideCaptionBtnTips);
					barBox.addChild(_captionBtnTips);
				}
			}
			
			setPosition();
		}
		
		public function hideCaptionBtn():void
		{
			if (_captionBtn)
			{
				_captionBtn.removeEventListener(MouseEvent.CLICK, showCaptionFace);
				barBox.removeChild(_captionBtn);
				_captionBtn = null;
			}
			
			if (_captionBtnTips)
			{
				_captionBtnTips.close_btn.removeEventListener(MouseEvent.CLICK, hideCaptionBtnTips);
				barBox.removeChild(_captionBtnTips);
				_captionBtnTips = null;
			}
			
			setPosition();
		}
		
		public function showFilelistTips(fileNum:Number):void
		{
			if (!_filelistTips)
			{
				var style:StyleSheet = new StyleSheet();
				style.setStyle('a', { textDecoration:'underline', fontFamily:'宋体' } );
				
				var tf:TextFormat = new TextFormat("宋体");
				
				_filelistTips = new FilelistTips();
				_filelistTips.info_txt.text = "共" + fileNum + "个视频，点击可切换";
				_filelistTips.info_txt.setTextFormat(tf);
				_filelistTips.know_txt.styleSheet = style;
				_filelistTips.know_txt.htmlText = " <a href='event:hide'>我知道了</a>";
				_filelistTips.know_txt.addEventListener(TextEvent.LINK, clickFilelistTips);
				_filelistTips.x = _btnFilelist.x - 24;
				_filelistTips.y = -51;
				barBox.addChild(_filelistTips);
				
				setTimeout(hideFilelistTips, 5000);
			}
		}
		
		public function showBarNotice(str:String, showTime:uint = 0):void
		{
			if (str)
			{
				if (!_noticeText)
				{
					var tf:TextFormat = new TextFormat('宋体', 12, 0x555555);
					
					_noticeText = new TextField();
					_noticeText.selectable = false;
					_noticeText.text = str;
					_noticeText.setTextFormat(tf);
					_noticeText.width = _noticeText.textWidth + 4;
					_noticeText.height = _noticeText.textHeight + 4;
					_noticeText.x = _btnUnmute.x - _noticeText.width - 10;
					_noticeText.y = 9;
					_container.addChild(_noticeText);
				}
				
				_txtDownloadSpeed.x = _noticeText.x - 50 - 40;
				
				if (showTime > 0)
				{
					setTimeout(showBarNotice, showTime, null);
				}
				else
				{
					setTimeout(showBarNotice, 10, null);
				}
			}
			else
			{
				if (_noticeText)
				{
					_container.removeChild(_noticeText);
					_noticeText = null;
				}
				
				_txtDownloadSpeed.x = _btnUnmute.x - 50 - 40;
			}
			_txtDownloadSpeed.visible = (_txtDownloadSpeed.x > _txtPlayTime.x + _txtPlayTime.width);
		}
		
		private function showCaptionFace(evt:MouseEvent):void
		{
			_container.dispatchEvent(new EventSet(EventSet.SHOW_FACE, "caption"));
			
			if (_captionBtnTips)
			{
				_captionBtnTips.removeEventListener(MouseEvent.CLICK, hideCaptionBtnTips);
				barBox.removeChild(_captionBtnTips);
				_captionBtnTips = null;
			}
		}
		
		private function hideCaptionBtnTips(evt:MouseEvent):void
		{
			Cookies.setCookie("hideCaptionButtonTips", true);
			
			if (_captionBtnTips)
			{
				_captionBtnTips.removeEventListener(MouseEvent.CLICK, hideCaptionBtnTips);
				barBox.removeChild(_captionBtnTips);
				_captionBtnTips = null;
			}
		}
		
		private function clickFilelistTips(evt:TextEvent):void
		{
			Cookies.setCookie('isNoticeList', false);
			
			hideFilelistTips();
		}
		
		private function hideFilelistTips():void
		{
			if (_filelistTips)
			{
				barBox.removeChild(_filelistTips);
				_filelistTips = null;
			}
		}
		
		private function handleAddedToStage(e:Event):void 
		{
			_container.removeEventListener(Event.ADDED_TO_STAGE, handleAddedToStage);
			
			addCtr();
			_btnPlayBig.y = (_container.stage.stageHeight - 60);
			_btnPauseBig.y = (_container.stage.stageHeight - 60);
			addEventHandler();
		}
		
		private function handleMouseOver(e:MouseEvent):void
		{
			_beMouseOn = true;
		}
		
		private function handleMouseOut(e:MouseEvent):void
		{
			_beMouseOn = false;
		}
		
		public function get beMouseOn():Boolean
		{
			return _beMouseOn;
		}
		/* 添加控件 */
		private function addCtr(){
			
			barBox = new Sprite();
			_container.addChild(barBox);			
			barBox.graphics.beginFill(0x181818,1);
			barBox.graphics.drawRect(0, 0, Capabilities.screenResolutionY + 1000, 33);
			
			_ctrBarBg = new CtrBarBg();
			_barBg=new DefaultBar();
			_barBuff=new LoadingBar();
			_barPlay = new PlayBar();
			_barPreDown = new PreDownBar();
			_barSlider=new Scroll();
			
			_btnPause=new PauseButton();
			_btnPlay=new PlayButton();
			_btnStop = new StopButton();
			_btnFilelist = new FilelistButton();
			_mcTimeTip = new McTimeTip();
			_mcTimeTipArrow = new TimeTipsArrow();
			_mcVolume = new McVolume(this);
			_btnFullscreen = new FullScreenButton();
			_btnTips = new BtnTip();			
			_volumeTips = new VolumeTips();
			_volume100Tips = new Volume100Tips();
			_formatBtn = new FormatBtn();
			_curFormatBtn = new CurrentFormatBtn();
			_btnUnmute = new VolumeButton();
			_btnMute = new VolumeButton();
			_btnMute.buttonMode = true;
			_btnUnmute.visible = false;
			_barBg.buttonMode=true;
			_barBuff.buttonMode=true;
			_barPlay.buttonMode = true;
			_barPreDown.buttonMode = true;
			_btnPause.visible=false;
			_mcTimeTip.visible = false;
			_mcTimeTipArrow.visible = false;
			_btnTips.visible = false;
			_volumeTips.visible = false;
			_volume100Tips.visible = false;
			
			_barBorder = new Sprite();
			_barBorder.graphics.beginFill(0x000000, 0);
			_barBorder.graphics.lineStyle(1, 0xe1e1e1);
			_barBorder.graphics.drawRect(0, 0, playWidth, 32);
			
			_so = SharedObject.getLocal("kkV");
			_mcVolume.buttonMode = true;
			//_mcVolume.visible = true;
			
			_cacheVolume = _so.data.v ? _so.data.v : 0.5;
			
			_txtPlayTime=new TextField();
			_txtPlayTime.autoSize=TextFormatAlign.LEFT;
			_txtPlayTime.selectable=false;
			setPlayTimeText('00:00/00:00');
			
			_txtDownloadSpeed=new TextField();
			_txtDownloadSpeed.autoSize = TextFormatAlign.RIGHT;
			_txtDownloadSpeed.selectable = false;
			setDownloadSpeedText(0);
			
			barBox.addChild(_ctrBarBg);
			barBox.addChild(_btnPause);
			barBox.addChild(_btnPlay);
			barBox.addChild(_btnStop);
			_btnStop.visible = false;
			barBox.addChild(_btnFilelist);
			barBox.addChild(_btnUnmute);
			barBox.addChild(_btnMute);
			barBox.addChild(_btnFullscreen);
			barBox.addChild(_txtPlayTime);
			barBox.addChild(_txtDownloadSpeed);
			_formatBtn.visible = false;
			
			barBox.addChild(_barBg);
			barBox.addChild(_barBuff);
			barBox.addChild(_barPreDown);
			barBox.addChild(_barPlay);
			barBox.addChild(_barSlider);
			
			barBox.addChild(_mcTimeTip);
			barBox.addChild(_mcTimeTipArrow);
			barBox.addChild(_btnTips);
			barBox.addChild(_mcVolume);
			barBox.addChild( _volumeTips );
			barBox.addChild( _volume100Tips );
			barBox.addChild(_formatBtn);
			barBox.addChild(_curFormatBtn);
			_btnPlayBig = new GoOnButtonLa();
			_btnPauseBig = new GoOnButtonLa();		
			_container.addChild(_btnPlayBig);
			_container.addChild(_btnPauseBig);
			
			_btnPauseBig.visible = false;
			_btnPlayBig.visible = false;
			_btnPlayBig.addEventListener(MouseEvent.CLICK, dispatchPlay);
			_btnPauseBig.addEventListener(MouseEvent.CLICK, dispatchPlay);
			
			_tipsTimer = new Timer( 2000 , 1 );
			_tipsTimer.addEventListener(TimerEvent.TIMER_COMPLETE , onTipsTimerComplete );
			volumeTipsTimer = new Timer( 2000 , 1 );
			volumeTipsTimer.addEventListener( TimerEvent.TIMER_COMPLETE , onVolumeKeyChangeTimer );
			
			faceLifting(_stageInfo.WIDTH);
			_barPlay.width=0;
			_barBuff.width = 0;
			_barPreDown.width = 0;
			_barSlider.x = 0;
			
			_barBg.y=-6;
			_barBuff.y=-6;
			_barPlay.y = -6;
			_barPreDown.y = -6;
		}
		
		public function faceLifting(w) {
			var dex:Number = _beFullscreen ? 26 : 0;
			
			_stageInfo.CURR_WIDTH = w;
			_barBorder.width = w;
			_ctrBarBg.width = w;
			_ctrBarBg.x = 0;
			_ctrBarBg.y = 0;
			
/*			_barBg.y=-6;
			_barBuff.y=-6;
			_barPlay.y = -6;
			_barPreDown.y = -6;*/
			_barBg.x= 0;
			_barBuff.x= 0;
			_barPlay.x = 0;
			_barPreDown.x = 0;
			_barBg.width = w ;
			
			_btnPlay.y = 0;
			_btnPause.y = 0;
			_btnStop.y = 0;
			_btnFilelist.y = 0;
			_txtPlayTime.y = 7;
			
			_btnPlay.x = 0;
			_btnPause.x = 0;
			//_btnStop.x = 38;
			//_btnFilelist.x = 38;
			_txtPlayTime.x = 78;
			//客户端显示停止按钮
			if (GlobalVars.instance.platform == "client")
			{
				showStopButton(true);
			}
			else
			{
				showStopButton(false);
			}
			
			_barSlider.y = -8;
			
			//_barWidth = _barBg.width - 16;
			_barWidth = _barBg.width;
			JTracer.sendMessage("faceLifting._preBarWidth:" + _preBarWidth);
			if (_preBarWidth != 0) {
				var _differ:Number = _barWidth / _preBarWidth;
				_barPlay.width = _differ * _barPlay.width;
				_barBuff.width = _differ * _barBuff.width;
				_barPreDown.width = _differ * _barPreDown.width;
				_barSlider.x = _barPlay.width + _barPlay.x - 6;
				if (_barSlider.x < 0)
				{
					_barSlider.x = 0;
				}
				JTracer.sendMessage('faceLifting._differ='+_differ+',_barPlay.width='+_barPlay.width+',_barBuff.width='+_barBuff.width);
			}
			timerBuffHandler(null); //立刻刷新进度条到正确位置;
			
			_preBarWidth = _barWidth;//记录上次宽度
			
			_btnFullscreen.x = w - 36;
			_btnFullscreen.y = 0;
			
			_formatBtn.x = _btnFullscreen.x - 55 - 3;
			_formatBtn.y = 7;
			
			_curFormatBtn.x = _btnFullscreen.x - 55 - 3;
			_curFormatBtn.y = 7;
			
			//_mcVolume.x = _curFormatBtn.x - 53 - 18;
			_mcVolume.y = 11;
			
			//_btnMute.x = _mcVolume.x - 17 - 22;
			_btnMute.y= 1;
			
			//_btnUnmute.x = _mcVolume.x - 17 - 22;
			_btnUnmute.y = 1;
			
			//_txtDownloadSpeed.x = _btnUnmute.x - 50 - 40;
			_txtDownloadSpeed.y = 7;
			_txtDownloadSpeed.width = 50;
			
			//_volumeTips.x = _mcVolume.x + (_mcVolume.width - _volumeTips.width) / 2 - 2;
			_volumeTips.y = -36;
			
			//_volume100Tips.x = _mcVolume.x + (_mcVolume.width - _volume100Tips.width) / 2 - 2;
			_volume100Tips.y = -36;
			
			setPosition();
			
			_btnPlayBig.x = 50-20;
			_btnPauseBig.x = 50-20;
			var bigPauseY:Number = (_container.stage? _container.stage.stageHeight:playHeight);
			_btnPlayBig.y = (bigPauseY - 120);
			_btnPauseBig.y = (bigPauseY - 120);
			if (_container.stage)
			{
				_container.parent.addChild(_btnPlayBig);
				_container.parent.addChild(_btnPauseBig);
			}
		}
		
		private function setPosition():void
		{
			var startPos:Number;
			if (_captionBtn)
			{
				_captionBtn.x = _curFormatBtn.x - 45 - 8;
				if (_captionBtnTips)
				{
					_captionBtnTips.x = _captionBtn.x - 19;
				}
				startPos = _captionBtn.x - 53 - 18;
			}
			else
			{
				startPos = _curFormatBtn.x - 53 - 18;
			}
			_mcVolume.x = startPos;
			_btnMute.x = _mcVolume.x - 17 - 22;
			_btnUnmute.x = _mcVolume.x - 17 - 22;
			_txtDownloadSpeed.x = _btnUnmute.x - 50 - 40;
			_txtDownloadSpeed.visible = (_txtDownloadSpeed.x > _txtPlayTime.x + _txtPlayTime.width);
			_volumeTips.x = _mcVolume.x + (_mcVolume.width - _volumeTips.width) / 2 - 2;
			_volume100Tips.x = _mcVolume.x + (_mcVolume.width - _volume100Tips.width) / 2 - 2;
		}
		
		/* 为添加控件事件响应函数 */
		private function addEventHandler() 
		{
			_player.addEventListener(PlayEvent.STOP,handlePlayStop);
			_btnFullscreen.addEventListener(MouseEvent.CLICK, fullscreen_CLICK_handler);
			
			_btnMute.addEventListener(MouseEvent.MOUSE_OVER, volumeBtnEventHandler);
			_btnMute.addEventListener(MouseEvent.CLICK, volumeBtnEventHandler);
			_btnMute.addEventListener(MouseEvent.MOUSE_OUT, volumeBtnEventHandler);
			
			_btnPlay.addEventListener(MouseEvent.CLICK, dispatchPlay);
			_btnFilelist.addEventListener(MouseEvent.CLICK, showFilelist);
			
			_timerBP=new Timer(500,0);
			_timerBP.addEventListener('timer', timerBuffHandler);
			
			_btnPlay.addEventListener(MouseEvent.MOUSE_OVER, btnTipsHandler);
			_btnPause.addEventListener(MouseEvent.MOUSE_OVER, btnTipsHandler);
			_btnStop.addEventListener(MouseEvent.MOUSE_OVER, btnTipsHandler);
			_btnFilelist.addEventListener(MouseEvent.MOUSE_OVER, btnTipsHandler);
			_btnFullscreen.addEventListener(MouseEvent.MOUSE_OVER, btnTipsHandler);
			
			_btnPlay.addEventListener(MouseEvent.MOUSE_OUT, btnTipsHandler);
			_btnPause.addEventListener(MouseEvent.MOUSE_OUT, btnTipsHandler);
			_btnStop.addEventListener(MouseEvent.MOUSE_OUT, btnTipsHandler);
			_btnFilelist.addEventListener(MouseEvent.MOUSE_OUT, btnTipsHandler);
			_btnFullscreen.addEventListener(MouseEvent.MOUSE_OUT, btnTipsHandler);
			
			_curFormatBtn.addEventListener("clickCurrentFormat", clickCurrentFormatBtn);
		}
		
		private function clickCurrentFormatBtn(evt:Event):void
		{
			if (!_formatBtn.visible)
			{
				_curFormatBtn.isClicked = true;
				
				_formatBtn.visible = true;
				_formatBtn.addEventListener("clickFormat", hideFormatSelector);
				_formatBtn.addEventListener(MouseEvent.ROLL_OVER, showFormatSelector);
				_formatBtn.addEventListener(MouseEvent.ROLL_OUT, hideFormatSelector);
			}
			else
			{
				hideFormatSelector();
			}
		}
		
		private function showFormatSelector(evt:MouseEvent):void
		{
			_curFormatBtn.isClicked = true;
			
			_beMouseOnFormat = true;
			
			_formatBtn.visible = true;
		}
		
		public function hideFormatSelector(evt:Event = null):void
		{
			_curFormatBtn.isClicked = false;
			
			_beMouseOnFormat = false;
			
			_formatBtn.visible = false;
			_formatBtn.removeEventListener("clickFormat", hideFormatSelector);
			_formatBtn.removeEventListener(MouseEvent.ROLL_OVER, showFormatSelector);
			_formatBtn.removeEventListener(MouseEvent.ROLL_OUT, hideFormatSelector);
		}
		
		public function get beMouseOnFormat():Boolean
		{
			return _beMouseOnFormat;
		}
		
		private function handlePlayStop(event:PlayEvent):void {
			_btnPlay.visible=true;
			_btnPause.visible = false;	
			_barBuff.width = 0;			
			_barPlay.width = 0;
			_barPreDown.width = 0;
			
			
			_barSlider.x = 0;
		}
		/* 全屏按钮点击处理函数 */
		private function fullscreen_CLICK_handler(e) 
		{
			if(_beFullscreen){
				playctrlHandler.stage.displayState = StageDisplayState.NORMAL;
			}else{
				playctrlHandler.stage.displayState = StageDisplayState.FULL_SCREEN;
			}
		}
		
		/* 控制条点击处理函数 */
		private function bar_CLICK_handler(e:MouseEvent):void
		{
			var seek_time:Number = (e.stageX - getStagePosition(e.target).x - 1) / _barWidth * _player.totalTime;
			
			seekToTime(seek_time, e.stageX, "bar");
		}
		
		private function videoTip_CLICK_handler(evt:MouseEvent):void
		{
			//点击视频提示，隐藏视频提示
			hideVideoTips();
			
			seekToTime(_mcTimeTip.curTime, _mcTimeTip.curStageX, "preview");
		}
		
		private function seekToTime(_time:Number, _stageX:Number, type:String):void
		{
			//流量不足
			if (playctrlHandler.isNoEnoughBytes)
			{
				return;
			}
			
			if(!CheckUserManager.instance.isValid){
				CheckUserManager.instance.checkIsValid();
				return;
			}
			
			if(!playctrlHandler.isPlayStart) {
				return;
			} else if (!this._seekEnable) {
				playctrlHandler.flv_setNoticeMsg('数据准备中，暂不支持拖动');
				return;
			}
			
			var slider_transform_x:Number = _stageX - getStagePosition(_barSlider).x;
			var slider_current_x:Number = _barSlider.x + slider_transform_x;
			if( slider_current_x < 8 )
				_barSlider.x = 0;
			else if( slider_current_x > _barWidth - 16 )
				_barSlider.x = _barWidth - 16;
			else
				_barSlider.x = slider_current_x - 8;
			_barPlay.width = _barSlider.x - _barPlay.x + 6;
			
			var seek_time:Number = _time;
			var total_time:Number = _player.totalTime;
			if( seek_time <= 0 )
				seek_time = 0.1;
			else if( seek_time >= total_time )
				seek_time = total_time - 0.1;
			if (seek_time > 0 && seek_time < total_time) {
				JTracer.sendMessage("bar_CLICK_handler.total_time:" + total_time);
			    JTracer.sendMessage("bar_CLICK_handler.seek_time:" + seek_time);
				
				if (type == "bar")
				{
					playctrlHandler._bufferTip.clearBreakCount();
					GlobalVars.instance.bufferType = GlobalVars.instance.bufferTypeDrag;
					
					JTracer.sendMessage("CtrBar -> seekToTime, bar, set bufferType:" + GlobalVars.instance.bufferType);
				}
				else if (type == "preview")
				{
					playctrlHandler._bufferTip.clearBreakCount();
					GlobalVars.instance.bufferType = GlobalVars.instance.bufferTypePreview;
					
					JTracer.sendMessage("CtrBar -> seekToTime, preview, set bufferType:" + GlobalVars.instance.bufferType);
				}
				
				_isClickBarSeek = true;
				_player.seek(seek_time);
			}
		}
		
		private function showStopButton(flag:Boolean):void
		{
			if (flag)
			{
				_btnStop.visible = true;
				_btnStop.x = 38;
				_btnFilelist.x = 76;
				_txtPlayTime.x = 116;
			}
			else
			{
				_btnStop.visible = false;
				_btnStop.x = 38;
				_btnFilelist.x = 38;
				_txtPlayTime.x = 78;
			}
		}
		
		//hwh
		public function set isClickBarSeek(value:Boolean):void
		{
			_isClickBarSeek = value;
		}
		
		public function get isClickBarSeek():Boolean
		{
			if (GlobalVars.instance.isUseHttpSocket)
			{
				return false;
			}
			return _isClickBarSeek;
		}
		
		/* 控制条移动处理函数 */
		private function bar_MOUSE_OVER_handler(e:MouseEvent):void
		{
			if (!_barSlider.visible || !playctrlHandler.isPlayStart)
			{
				return;
			}
			
			_mcTimeTip.visible = true;
			_mcTimeTipArrow.visible = _mcTimeTip.visible;
			
			var total_time:Number = _player.totalTime;
			var seek_time:Number = _container.stage.mouseX / _barWidth * total_time;
			seek_time = (seek_time > total_time ? total_time : seek_time);
			seek_time = (seek_time < 0 ? 0 : seek_time);
			
			var globalVars:GlobalVars = GlobalVars.instance;
			var startIdx:uint = _player.getNearIndex(_player.dragTime, seek_time, 0, _player.dragTime.length - 2);
			var totalSnpt:uint = playctrlHandler.snptBmdArray.length * globalVars.iframeRow * globalVars.iframeCol;
			_mcTimeTip.hasSnapShot = startIdx < totalSnpt;
			
			if (_mcTimeTip.scaleType != 1 && !_mcTimeTip.hasSnapShot)
			{
				_container.removeEventListener(Event.ENTER_FRAME, onVideoTipEnter);
				
				clearTimeout(_videoTipID);
				
				_mcTimeTip.isScale = false;
				_mcTimeTip.scaleType = 1;
				_mcTimeTip.scaleDefault();
				_mcTimeTip.buttonMode = false;
				_mcTimeTip.removeEventListener(MouseEvent.CLICK, videoTip_CLICK_handler);
				_mcTimeTipArrow.buttonMode = false;
				_mcTimeTipArrow.hideBg();
				_mcTimeTipArrow.removeEventListener(MouseEvent.CLICK, videoTip_CLICK_handler);
			}
			
			_mcTimeTip.text = formatTime(seek_time);
			_mcTimeTip.curMouseX = _container.stage.mouseX;
			setTimeTipPos(_mcTimeTip.curMouseX);
			
			_container..addEventListener(Event.ENTER_FRAME, onVideoTipEnter);
			
			if (_mcTimeTip.hasSnapShot)
			{
				if (startIdx != _lastStartIdx)
				{
					_lastStartIdx = startIdx;
					
					_mcTimeTip.clear();
					_mcTimeTip.showLoading(false);
					_mcTimeTip.initDisplay();
					_mcTimeTip.setDisplayAlpha(1);
					
					if (_isFirstShowTips)
					{
						clearTimeout(_timeOutID);
						_timeOutID = setTimeout(showVideoTips, 200, seek_time, _container.stage.mouseX, e.stageX);
					}
					else
					{
						showVideoTips(seek_time, _container.stage.mouseX, e.stageX);
					}
					
					clearTimeout(_videoTipID);
					_videoTipID = setTimeout(showVideoTipsFromSnap, 3000, seek_time,_container. stage.mouseX, e.stageX);
				}
			}
			else
			{
				if (startIdx != _lastStartIdx)
				{
					_lastStartIdx = startIdx;
					
					clearTimeout(_videoTipID);
					_videoTipID = setTimeout(showVideoTipsFromTips, 3000, seek_time, _container.stage.mouseX, e.stageX);
				}
			}
		}
		
		private function bar_MOUSE_OUT_handler(e:MouseEvent):void
		{
		}
		
		private function handleMouseOutPlayer(e:MouseEvent):void
		{
			//鼠标移出舞台，隐藏视频提示
			hideVideoTips();
		}
		
		private function showVideoTipsFromSnap(_time:Number, _mouseX:Number, _stageX:Number):void
		{
			_mcTimeTip.hasSnapShot = false;
			
			showVideoTips(_time, _mouseX, _stageX);
		}
		
		private function showVideoTipsFromTips(_time:Number, _mouseX:Number, _stageX:Number):void
		{
			_mcTimeTip.clear();
			_mcTimeTip.showLoading(true);
			_mcTimeTip.initDisplay();
			_mcTimeTip.setDisplayAlpha(0);
			
			showVideoTips(_time, _mouseX, _stageX);
		}
		
		//显示视频提示
		private function showVideoTips(_time:Number, _mouseX:Number, _stageX:Number):void
		{
			_isFirstShowTips = false;
			
			var startIdx:uint = _player.getNearIndex(_player.dragTime, _time, 0, _player.dragTime.length - 2);
			var endIdx:uint = _player.getNearIndex(_player.dragTime, _time + 5, 1, _player.dragTime.length - 1);
			if (endIdx <= startIdx)
			{
				endIdx = startIdx + 1;
			}
			
			if (_mcTimeTip.hasSnapShot)
			{
				//有视频截图
				var globalVars:GlobalVars = GlobalVars.instance;
				var perPageNum:uint = globalVars.iframeRow * globalVars.iframeCol;
				var curPageNum:uint = Math.floor(startIdx / perPageNum);
				var remainNum:Number = startIdx - curPageNum * perPageNum;
				
				var xPos:uint = remainNum % globalVars.iframeCol;
				var yPos:uint = Math.floor(remainNum / globalVars.iframeCol);
				
				JTracer.sendMessage("CtrBar -> showVideoTips, 显示i帧截图, startIdx:" + startIdx + ", endIdx:" + endIdx + ", perPageNum:" + perPageNum + ", curPageNum:" + curPageNum + ", remainNum:" + remainNum + ", xPos:" + xPos + ", yPos:" + yPos + ", url:" + playctrlHandler.snptBmdArray[curPageNum].url);
				
				_mcTimeTip.showSnap(Tools.cutScreenShot(playctrlHandler.snptBmdArray[curPageNum].bmd, new Point(xPos * globalVars.iframeWidth, yPos * globalVars.iframeHeight)));
				
				//Tools.statToJS({f:"previewSnapShot", gdl:encodeURIComponent(_player.playUrl)});
				//Tools.stat("f=previewSnapShot&gdl=" + encodeURIComponent(_player.playUrl));
			}
			else
			{
				//无视频截图
				var start:Number = startIdx == 0 ? 0 :_player.dragPosition[startIdx];
				//处理影片时长小于10秒且只有两个关键帧的影片，计算影片总大小返回videoUrlArr[0].totalByte
				var end:Number = (endIdx == 1 && _player.dragTime[1] == 0 && _player.dragTime.length == 2) ? _player.getVideoUrlArr[0].totalByte : _player.dragPosition[endIdx];
				var suffix:String = '&start=' + start + "&end=" + end + "&type=preview&du=" + _player.vduration;
				JTracer.sendMessage("CtrBar -> showVideoTips, 显示视频预览, startIdx:" + startIdx + ", endIdx:" + endIdx + ", gdl url:" + _player.playUrl + suffix);
				
				_mcTimeTip.playStream(_player.playUrl, suffix);
				
				if (GlobalVars.instance.isStat)
				{
					Tools.stat("f=previewVideo&gdl=" + encodeURIComponent(_player.playUrl));
				}
			}
			
			_mcTimeTip.isScale = true;
			_mcTimeTip.curTime = _time;
			_mcTimeTip.curMouseX = _mouseX;
			_mcTimeTip.curStageX = _stageX;
			if (_mcTimeTip.scaleType == 2)
			{
				_mcTimeTip.scaleNormal(true);
				_mcTimeTipArrow.showBg();
			}
			else if (_mcTimeTip.scaleType == 3)
			{
				_mcTimeTip.scaleBig(true);
				_mcTimeTipArrow.showBg();
			}
			else
			{
				_mcTimeTip.scaleType = 2;
				_mcTimeTip.scaleNormal();
				_mcTimeTipArrow.showBg();
				//i帧只上报一次
				if (_mcTimeTip.hasSnapShot)
				{
					if (GlobalVars.instance.isStat)
					{
						Tools.stat("f=previewSnapShot&gdl=" + encodeURIComponent(_player.playUrl));
					}
				}
			}
			_mcTimeTip.buttonMode = true;
			_mcTimeTip.addEventListener(MouseEvent.CLICK, videoTip_CLICK_handler);
			_mcTimeTipArrow.buttonMode = true;
			_mcTimeTipArrow.addEventListener(MouseEvent.CLICK, videoTip_CLICK_handler);
		}
		
		private function onVideoTipEnter(evt:Event):void
		{
			setTimeTipPos(_mcTimeTip.curMouseX);
			
			var videoLeft:Number = _mcTimeTip.x - _mcTimeTip.width / 2;			//视频提示左边端点
			var videoRight:Number = _mcTimeTip.x + _mcTimeTip.width / 2;		//视频提示右边端点
			var videoTop:Number = _container.stage.stageHeight - 43 - _mcTimeTip.height;	//视频提示上边端点
			var videoBottom:Number = _container.stage.stageHeight - 43;					//视频提示下边端点
			var barTop:Number = _container.stage.stageHeight - 32 - _barBg.height;			//进度条上边端点
			var barBottom:Number = _container.stage.stageHeight - 32;						//进度条下边端点
			
			//未放大视频提示时
			if (!_mcTimeTip.isScale)
			{
				if (_container.stage.mouseY < barTop || _container.stage.mouseY > barBottom)
				{
					//超出进度条范围，隐藏时间提示
					hideVideoTips();
				}
				return;
			}
			var mx:Number = _container.stage.mouseX;
			var my:Number = _container.stage.mouseY;
			if ( mx < videoLeft || mx > videoRight || my < videoTop || my > barBottom)
			{
				//超出视频提示范围，隐藏视频提示
				hideVideoTips();
			}
			else
			{
				if (my <= videoBottom)
				{
					//移动到视频提示范围，放大视频提示
					if (_mcTimeTip.scaleType != 3)
					{
						_mcTimeTip.scaleType = 3;
						_mcTimeTip.scaleBig();
						_mcTimeTipArrow.showBg();
					}
				}
				else
				{
					if (_mcTimeTip.scaleType != 2)
					{
						_mcTimeTip.scaleType = 2;
						_mcTimeTip.scaleNormal();
						_mcTimeTipArrow.showBg();
					}
				}
			}
		}
		
		//隐藏视频提示
		private function hideVideoTips():void
		{
			_container..removeEventListener(Event.ENTER_FRAME, onVideoTipEnter);
			
			clearTimeout(_videoTipID);
			clearTimeout(_timeOutID);
			
			_mcTimeTip.visible = false;
			_mcTimeTip.init();
			_mcTimeTip.isScale = false;
			_mcTimeTip.scaleType = 1;
			_mcTimeTip.buttonMode = false;
			_mcTimeTip.removeEventListener(MouseEvent.CLICK, videoTip_CLICK_handler);
			_mcTimeTipArrow.visible = false;
			_mcTimeTipArrow.buttonMode = false;
			_mcTimeTipArrow.hideBg();
			_mcTimeTipArrow.removeEventListener(MouseEvent.CLICK, videoTip_CLICK_handler);
			
			_lastStartIdx = -1;
			_isFirstShowTips = true;
		}
		
		private function setTimeTipPos(xPos:Number):void
		{
			_mcTimeTipArrow.x = xPos - 4;
			if (_mcTimeTipArrow.x < 2)
			{
				_mcTimeTipArrow.x = 2;
			}
			else if (_mcTimeTipArrow.x > _container.stage.stageWidth - _mcTimeTipArrow.width - 2)
			{
				_mcTimeTipArrow.x = _container.stage.stageWidth - _mcTimeTipArrow.width - 2;
			}
			_mcTimeTipArrow.y = -12;
			
			_mcTimeTip.x = _mcTimeTipArrow.x + 4;
			if (_mcTimeTip.x < _mcTimeTip.width / 2)
			{
				_mcTimeTip.x = _mcTimeTip.width / 2;
			}
			else if (_mcTimeTip.x > _container.stage.stageWidth - _mcTimeTip.width / 2)
			{
				_mcTimeTip.x = _container.stage.stageWidth - _mcTimeTip.width / 2;
			}
			_mcTimeTip.y = -10;
		}
		
		private function barSliderRemoveEvent()
		{
			_barSlider.enabled=false;
		}
		
		private function barSliderAddEvent()
		{
			_barSlider.enabled=true;
		}
		
		/* 控制条拖动按钮处理函数 */
		private function barslider_MOUSE_DOWN_handler(e:MouseEvent):void {
			//流量不足
			if (playctrlHandler.isNoEnoughBytes)
			{
				return;
			}
			
			if(!CheckUserManager.instance.isValid){
				CheckUserManager.instance.checkIsValid();
				return;
			}
			
			if(!playctrlHandler.isPlayStart) {
				return;
			}
			_timerBP.stop();
			ExternalInterface.call("flv_playerEvent", "onDragSeekStart");
			_barSlider.stage.addEventListener(MouseEvent.MOUSE_MOVE, barslider_MOUSE_MOVE_handler);
			_barSlider.stage.addEventListener(MouseEvent.MOUSE_UP, barslider_MOUSE_UP_handler);
		}
		
		private function barslider_MOUSE_UP_handler(e:MouseEvent):void {
			//流量不足
			if (playctrlHandler.isNoEnoughBytes)
			{
				return;
			}
			
			if(!CheckUserManager.instance.isValid){
				CheckUserManager.instance.checkIsValid();
				return;
			}
			
			if(!playctrlHandler.isPlayStart) {
				return;
			}
			_barSlider.stage.removeEventListener(MouseEvent.MOUSE_MOVE, barslider_MOUSE_MOVE_handler);
			_barSlider.stage.removeEventListener(MouseEvent.MOUSE_UP, barslider_MOUSE_UP_handler);
			
			playctrlHandler._bufferTip.clearBreakCount();
			GlobalVars.instance.bufferType = GlobalVars.instance.bufferTypeDrag;
			
			JTracer.sendMessage("CtrBar -> barslider_MOUSE_UP_handler, set bufferType:" + GlobalVars.instance.bufferType);
			
			var total_time=_player.totalTime;
			var seek_time = (_barPlay.width - 6  ) / (_barWidth ) * total_time; 
			if (seek_time <= 0)
			{
				_isClickBarSeek = true;
				_player.seek(0);
			}
			if (seek_time >= total_time)
			{
				_isClickBarSeek = true;
				_player.seek(total_time);
			}
			
			if (seek_time > 0 && seek_time < total_time)
			{
				_isClickBarSeek = true;
				_player.seek(seek_time);
			}
			_timerBP.start();
			
			setBarPos(e.stageX);
			
			ExternalInterface.call("flv_playerEvent", "onDragSeekEnd");
		}
		
		private function barslider_MOUSE_MOVE_handler(e:MouseEvent):void {
			//流量不足
			if (playctrlHandler.isNoEnoughBytes)
			{
				return;
			}
			
			if(!CheckUserManager.instance.isValid){
				CheckUserManager.instance.checkIsValid();
				return;
			}
			
			if( !playctrlHandler.isPlayStart) {
				return;
			}
			setBarPos(e.stageX);
		}
		
		private function setBarPos(pos:Number):void
		{
			var slider_current_x=pos;
			var bar_play_width:int=0;
			if (slider_current_x > _barPlay.x && slider_current_x < _barBg.x + _barBg.width - 4)
			{
				if( slider_current_x < 8 )
					_barSlider.x = 0;
				else if( slider_current_x > _barWidth - 16 )
					_barSlider.x = _barWidth - 16;
				else
					_barSlider.x = slider_current_x - 8;
				_barPlay.width=_barSlider.x-_barPlay.x+6;
				var total_time=_player.totalTime;
				var seek_time = (_barPlay.width - 6  ) / (_barWidth ) * total_time; 
				if(seek_time>=0&&seek_time<=total_time){
					setPlayTimeText(formatTime(seek_time)+'/'+_txtPlayTime.text.split('/')[1]);
				}
			}
		}
		
		/* 控制条与播放时间显示计时器处理函数 */
		private function timerBuffHandler(e):void {
			if ( !_player ) return;
			this.setDownloadSpeedText(_player.downloadSpeed);
			if (_player.time == -1 || _player.time == 0 || _player.fixedTime == 0) {
				setPlayTimeText(formatTime(0) + '/' + formatTime(_player.totalTime));
				return;
			}
			
			var total_time:Number = _player.totalTime;
			var curr_time:Number = _player.time;
			if (curr_time <= 0) return;
			if (curr_time > total_time)
			{
				curr_time = total_time;
			}
			var dp:Number = _player.downloadProgress;
			var t = (_player.time / total_time * ( _barWidth - 16 ));
			if (isNaN(t))
			{
				_barSlider.x = 0;
			}else
			{
				_barSlider.x = t;
			}
			//trace("timerBuffHandler._player.time:" + _player.time);
			//trace("timerBuffHandler._barSlider.x:" + _barSlider.x);
			_barPlay.width = _barSlider.x - _barPlay.x + 6;
			if( _barPlay.width > _barWidth)
				_barPlay.width = _barWidth;
			
			_barBuff.width = dp * _barWidth;
			if (_barBuff.width > _barWidth) {
				_barBuff.width = _barWidth;
			}
			if (_barBuff.width < 0) {
				_barBuff.width = 0;
			}
			
			setPlayTimeText(formatTime(curr_time)+'/'+formatTime(total_time));
			if (Math.abs(_player.totalTime - _player.time) < 1 && _player.time > (_player.totalTime - 1) && _player.totalTime != 0) {
				JTracer.sendMessage('_player.time > _player.totalTime, and call playerEvent end! _player.time=' + _player.time + ', _player.totalTime=' + _player.totalTime);
				//判断是否有下一集
				var isHasNext:Boolean = playctrlHandler.isHasNext;
				JTracer.sendMessage("CtrBar -> 是否有下一集, isHasNext:" + isHasNext);
				//正常停止
				playctrlHandler.isStopNormal = true;
				if (!isHasNext)
				{
					//没有下一集，显示播放完界面
					playctrlHandler.isShowStopFace = true;
				}
				this.dispatchStop();
				ExternalInterface.call("flv_playerEvent", "onEnd");
				//播放下一集
				if (isHasNext)
				{
					playctrlHandler.playNext();
				}
			}
		}
		
		private function setPlayTimeText( t:String ) {
			if (playctrlHandler.isChangeQuality == true) {
				return;//阻止切换清晰度时的时间清0
			}
			if(t.length == 14 )// 00:00/00:00:00
				t = '00:' + t;
			var arr:Array = t.split("/");
			t = "<font color='#9f9f9f'>" + arr[0] + "</font>" + "<font color='#555555'>" + "/" + arr[1] + "</font>";
			_txtPlayTime.htmlText = t;
			_txtPlayTime.setTextFormat(new TextFormat('Arial', 12));
		}
		
		private function setDownloadSpeedText(t:Number):void {
			if (t == 0) {
				_txtDownloadSpeed.text = '';
			}else{
				var s:String = "";
				if (t >= 1024)
				{
					t = Math.round(t / 1024 * 10) / 10;
					s = t.toString() + "MB/s";
				}
				else
				{
					s = t.toString() + "KB/s";
				}
				_txtDownloadSpeed.text = s;
				_txtDownloadSpeed.setTextFormat(new TextFormat('Arial', 12, 0x555555));
			}
		}
		
		/*静音按钮处理函数*/
		function mute_CLICK_handler(e){
			if(e.target==_btnUnmute){
				_btnUnmute.visible = false;
				_btnMute.visible = true;
				_mcVolume.buttonMode = true;
				setVolume(_mcVolume.currentVolume);
			}else{
				_btnUnmute.visible = true;
				_btnMute.visible = false;
				_mcVolume.buttonMode = false;
				setVolume(0);
			}
		}
		
		private function onVolumeKeyChangeTimer( event:TimerEvent ):void
		{
			this._volumeTips.visible = false;
			this._volume100Tips.visible = false;
		}
		function saveV(v){
			_so.data.v=v;
			_so.flush();
		}		
		
		public function handleVolumeFromKey( isUp:Boolean ):void
		{
			if( !_player.volum )
			{
				_btnUnmute.visible = false;
				_btnMute.visible = true;
				_btnMute.gotoAndStop(1);
				_isVolume = true;
				setVolume(_mcVolume.currentVolume);
			}
			volumeTipsTimer.reset();
			volumeTipsTimer.start();
			if( isUp ) //增大音量
			{				
				if(  _mcVolume.currentVolume  > 0.999 )
				{
					_cacheVolume = _player.volum + 0.5 > 5 ? 5:_player.volum + 0.5;
					if( _volume100Tips.visible )
						_volume100Tips.visible = false;
					_volumeTips.visible = true;
					_volumeTips.text =  int( Number( _cacheVolume )*100 )  + '%' ;
					_mcVolume.handleVolumeBar( _cacheVolume );
				}
				else
				{	
					_cacheVolume = _mcVolume.currentVolume + 1/10 > 1.0 ? 1.0 : _mcVolume.currentVolume + 1/10;
					
					if( _cacheVolume >= 1 )
					{
						if( _volumeTips.visible)
							_volumeTips.visible = false;
						_volume100Tips.visible = true;
						_volume100Tips.text = "100%(按↑键继续放大音量)";
						_mcVolume.handleVolumeBar( _cacheVolume );
					}
					else
					{
						if( _volume100Tips.visible )
							_volume100Tips.visible = false;
						_volumeTips.visible = true;
						_volumeTips.text =  int( Number( _cacheVolume )*100 )  + '%' ;
						_mcVolume.handleVolumeBar( _cacheVolume );
					}
				}
			}
			else //减少音量
			{
				if(  _player.volum  > 1 )
				{
					_cacheVolume = _player.volum - 0.5 < 1 ? 1:_player.volum - 0.5;					
					if( _volume100Tips.visible )
						_volume100Tips.visible = false;
					_volumeTips.visible = true;
					_volumeTips.text =  int( Number( _cacheVolume )*100 )  + '%' ;
					_mcVolume.handleVolumeBar( _cacheVolume );
				}
				else
				{	
					_cacheVolume = _mcVolume.currentVolume - 1/10 < 0 ? 0:_mcVolume.currentVolume - 1/10;
					if( _volume100Tips.visible )
						_volume100Tips.visible = false;
					_volumeTips.visible = true;
					_volumeTips.text =  int( Number( _cacheVolume )*100 )  + '%' ;	
					_mcVolume.handleVolumeBar( _cacheVolume );
				}
			}
			if (_isVolume)
			{
				_player.volum = _cacheVolume;
			}
		}
		
		/* 音量调节处理函数 */
		private function handleVolumeChanged(e:VolumeEvent):void
		{
			if (Number(e.volume) > 0)
			{
				_isVolume = true;
				_btnMute.gotoAndStop(1);
			}
			
			if( volumeTipsTimer )
			{
				volumeTipsTimer.reset();
				volumeTipsTimer.start();
			}
			_volumeTips.text =  int(( Number( e.volume ) *100 ) )   + '%' ;
			
			_volumeTips.visible = true;
			_volume100Tips.visible = false;
			_cacheVolume = _mcVolume.currentVolume;
			if (_isVolume)
			{
				setVolume(_cacheVolume);
			}
			if( _volumeTips.text == "100%" )
			{
				_volume100Tips.text = "100%(按↑键继续放大音量)";
				_volume100Tips.visible = true;
				this._tipsTimer.reset();
				this._tipsTimer.start();
			}
		}
	
		private function onTipsTimerComplete( e:TimerEvent ):void
		{
			_tipsTimer.reset();
			this._volume100Tips.visible = false;
		}
		
		private function handleVolumeMouseOut( e:MouseEvent ):void
		{
			this._volumeTips.visible = false;
		}
		
		private function showFilelist(e:MouseEvent):void
		{
			_btnTips.visible = false;
			hideFilelistTips();
			
			_container.dispatchEvent(new EventSet(EventSet.SHOW_FACE, "filelist"));
		}
		
		public function get cacheVolume():Number
		{
			return _cacheVolume;
		}
		
		public function get isVolume():Boolean
		{
			return _isVolume;
		}
		
		/* 控制按钮处理函数 */
		public function dispatchPlay(e:Event = null) 
		{
			//流量不足
			if (playctrlHandler.isNoEnoughBytes)
			{
				return;
			}
			
			//切换失败
			if (GlobalVars.instance.isExchangeError)
			{
				return;
			}
			
			if(!CheckUserManager.instance.isValid){
				CheckUserManager.instance.checkIsValid();
				return;
			}
			
			setPlayStatus();
			if (_player.isStop) {
				ExternalInterface.call("flv_playerEvent", "onRePlay");//播放完后再播放
			}else {
				ExternalInterface.call("flv_playerEvent", "onStartPlay");
				_container.dispatchEvent(new PlayEvent(PlayEvent.PLAY));
			}
		}
		
		public function setPlayStatus():void
		{
			_btnPause.visible = true;
			_btnPlayBig.visible = false;
			_btnPauseBig.visible = false;
			_btnPlay.visible=false;
		}
		
		public function dispatchPause(e:Event = null) {
			_container.dispatchEvent(new PlayEvent(PlayEvent.PAUSE));
			_btnPauseBig.visible = true;
			_btnPlay.visible=true;
			_btnPause.visible = false;
			ExternalInterface.call("flv_playerEvent", "onPause");
		}
		
		public function dispatchStop() {
			ExternalInterface.call("flv_playerEvent", "onStop");
			
			if(_player.streamInPlay){
				if ( (Math.abs(_player.streamInPlay.time - _player.totalTime) < 0.5)) 
				{
					_barSlider.x = 0;
					_barPlay.width = _barSlider.x - _barPlay.x + 6;
					setPlayTimeText(formatTime(0)+'/'+formatTime(_player.totalTime));
				}
			}
			_btnUnmute.visible=false;
			_btnMute.visible=true;
			_btnPlay.visible = true;
			_btnPause.visible = false;
			
			_btnPlayBig.visible = false;
			_btnPauseBig.visible = false;			
			_barBuff.width = 0;
			_barPreDown.width = 0;
			
			_player.fixedTime = 0;
			setDownloadSpeedText(0);
			_container.dispatchEvent(new PlayEvent(PlayEvent.STOP));
			if (_isChangeQuality == false) {
				setPlayTimeText('00:00/00:00');
			}
		}
		
		private function dispatchStopBtn(e:MouseEvent):void
		{
			ExternalInterface.call("flv_playerEvent", "onStop");
			
			playctrlHandler.hideNoticeBar();
			playctrlHandler._videoMask.showInputFace();
						
			if (_player.time <= 0 || _player.fixedTime == 0)
			{
				return;
			}
			_barSlider.x = 0;
			_barPlay.width = _barSlider.x - _barPlay.x + 6;
			
			_btnUnmute.visible = false;
			_btnMute.visible = true;
			_btnPlay.visible = true;
			_btnPause.visible = false;
			
			_btnPlayBig.visible = false;
			_btnPauseBig.visible = false;
			_barBuff.width = 0;
			_barPreDown.width = 0;
			
			_player.fixedTime = 0;
			setDownloadSpeedText(0);
			
			playctrlHandler.isStopNormal = true;
			playctrlHandler.isShowStopFace = false;
			
			_container..dispatchEvent(new PlayEvent(PlayEvent.STOP, true));
			
			playctrlHandler.hideNoticeBar();
			playctrlHandler._videoMask.showInputFace();
			
			if (_isChangeQuality == false) {
				setPlayTimeText('00:00/00:00');
			}
			
			Tools.stat("b=stopButtonFromClient");
		}
		
		public function errorInit():void
		{
			_barSlider.x=0;
			_barPlay.width = 0;
			setPlayTimeText(formatTime(0) + '/' + formatTime(_player.totalTime));
			_btnUnmute.visible=false;
			_btnMute.visible=true;
			_btnPlay.visible = true;
			_btnPause.visible = false;	
			_btnPauseBig.visible = false;			
			_barBuff.width = 0;
			_barPreDown.width = 0;
			_player.fixedTime = 0;
			ExternalInterface.call("flv_playerEvent", "onStop");
			setDownloadSpeedText(0);
		}
		
		/* 全屏时鼠标移动处理函数 */
		private function _MOUSE_MOVE_handler(e):void
		{
			_container.visible=true;
			if(_timerHide){
				_timerHide.stop();
			}
			_timerHide=new Timer(2000,1);
			_timerHide.addEventListener('timer',function(e){_container.visible=false;});
			_timerHide.start();
		}
		
		/* 全局函数 */
		private function getStagePosition(o:Object){
			var x=o.x,y=o.y;
			var p=o.parent;
			while(p){
				x+=p.x;
				y+=p.y;
				p=p.parent;
			}
			return {'x':x,'y':y};
		}
		private function formatTime(s:Number)
		{	
			s = Math.floor(s);
			var h:Number=0;
			var m:Number=0;
			if(isNaN(s)){
				s=0;
			}
			if( s/3600 >= 1)
			{
				h = Math.floor( s/3600 );
				s -= h*3600;
			}
			if(s/60>=1){
				m=Math.floor(s/60);
				s-=m*60;
			}
			if( h > 0 )
			{
				return (h<10?'0'+h:h) + ':' + (m<10?'0'+m:m)+':'+(s<10?'0'+s:s);
			}
			else				
				return (m<10?'0'+m:m)+':'+(s<10?'0'+s:s);
		}
		
		public function set barEnabled(b):void
		{
			if (b)
			{
				_btnPause.addEventListener(MouseEvent.CLICK, dispatchPause);
				_btnStop.addEventListener(MouseEvent.CLICK, dispatchStopBtn);
				_btnPlay.addEventListener(MouseEvent.CLICK, dispatchPlay);
				_btnFilelist.addEventListener(MouseEvent.CLICK, showFilelist);
				
				_barBg.addEventListener(MouseEvent.CLICK, bar_CLICK_handler);
				_barBuff.addEventListener(MouseEvent.CLICK, bar_CLICK_handler);
				_barPlay.addEventListener(MouseEvent.CLICK, bar_CLICK_handler);
				_barPreDown.addEventListener(MouseEvent.CLICK, bar_CLICK_handler);
				
				_barBg.addEventListener(MouseEvent.MOUSE_MOVE, bar_MOUSE_OVER_handler);
				_barBuff.addEventListener(MouseEvent.MOUSE_MOVE, bar_MOUSE_OVER_handler);
				_barPlay.addEventListener(MouseEvent.MOUSE_MOVE, bar_MOUSE_OVER_handler);
				_barPreDown.addEventListener(MouseEvent.MOUSE_MOVE, bar_MOUSE_OVER_handler);
				
				_barBg.addEventListener(MouseEvent.MOUSE_OUT, bar_MOUSE_OUT_handler);
				_barBuff.addEventListener(MouseEvent.MOUSE_OUT, bar_MOUSE_OUT_handler);
				_barPlay.addEventListener(MouseEvent.MOUSE_OUT, bar_MOUSE_OUT_handler);
				_barPreDown.addEventListener(MouseEvent.MOUSE_OUT, bar_MOUSE_OUT_handler);
				
				_barSlider.addEventListener(MouseEvent.MOUSE_DOWN, barslider_MOUSE_DOWN_handler);
			}
			else
			{
				_btnPause.removeEventListener(MouseEvent.CLICK, dispatchPause);
				_btnStop.removeEventListener(MouseEvent.CLICK, dispatchStopBtn);
				_btnPlay.removeEventListener(MouseEvent.CLICK, dispatchPlay);
				_btnFilelist.removeEventListener(MouseEvent.CLICK, showFilelist);
				
				_barBg.removeEventListener(MouseEvent.CLICK, bar_CLICK_handler);
				_barBuff.removeEventListener(MouseEvent.CLICK, bar_CLICK_handler);
				_barPlay.removeEventListener(MouseEvent.CLICK, bar_CLICK_handler);
				_barPreDown.removeEventListener(MouseEvent.CLICK, bar_CLICK_handler);
				
				_barBg.removeEventListener(MouseEvent.MOUSE_MOVE, bar_MOUSE_OVER_handler);
				_barBuff.removeEventListener(MouseEvent.MOUSE_MOVE, bar_MOUSE_OVER_handler);
				_barPlay.removeEventListener(MouseEvent.MOUSE_MOVE, bar_MOUSE_OVER_handler);
				_barPreDown.removeEventListener(MouseEvent.MOUSE_MOVE, bar_MOUSE_OVER_handler);
				
				_barBg.removeEventListener(MouseEvent.MOUSE_OUT, bar_MOUSE_OUT_handler);
				_barBuff.removeEventListener(MouseEvent.MOUSE_OUT, bar_MOUSE_OUT_handler);
				_barPlay.removeEventListener(MouseEvent.MOUSE_OUT, bar_MOUSE_OUT_handler);
				_barPreDown.removeEventListener(MouseEvent.MOUSE_OUT, bar_MOUSE_OUT_handler);
				
				_barSlider.removeEventListener(MouseEvent.MOUSE_DOWN, barslider_MOUSE_DOWN_handler);
			}
		}
		
		/* 操作是否有效 */
		public function set available(b) {
			_beAvailable = b;
			barEnabled = b;
			if (b) {
				/* 音量调节 */
				_mcVolume.addEventListener(VolumeEvent.VOLUME_CHANGE, handleVolumeChanged);
				_mcVolume.addEventListener(MouseEvent.ROLL_OUT, handleVolumeMouseOut);
				_timerBP.start();
			}else{
				/* 音量调节 */
				_mcVolume.removeEventListener(VolumeEvent.VOLUME_CHANGE, handleVolumeChanged);
				_mcVolume.removeEventListener(MouseEvent.ROLL_OUT, handleVolumeMouseOut);
				
				_timerBP.stop();
				
				_barBuff.width = 0;
				_barPlay.width = 0;
				_barPreDown.width = 0;
				_barSlider.x = 0;
				
				setDownloadSpeedText(0);
				setPlayTimeText('00:00/00:00');
			}
		}
		
		/* flvplayer引用 */
		public function set flvPlayer(o){
			_player = o;
			if(!_timerBP){
				addEventHandler();
			}
		}
		
		/* 全屏处理 */
		public function set fullscreen(b){
			setFullScreen(b);
		}
		
		/* 是否可用 */
		public function get available(){
			return _beAvailable;
		}
		
		public function setFullScreen(beFullsreen)
		{
			var screenHeight= _container.stage.stageHeight;	
			var screenWidth = _container.stage.stageWidth;
			_beFullscreen=beFullsreen;
			if (beFullsreen) {
				playWidth = screenWidth;
				playHeight = screenHeight;
				_container.y = screenHeight-33;
				faceLifting(screenWidth);
			}else {
				playWidth = _container.stage.stageWidth;
				playHeight = _container.stage.stageHeight;	
				_container.y = playHeight - 33;
				faceLifting(playWidth);				
			}
		}
		
		private function on_stage_FULLSCREEN(e:FullScreenEvent):void {
			setFullScreen(e.fullScreen);
		}
		
		/* 播放按钮控制 */
		public function set showPlayOrPauseButton(str) {
			switch(str){
				case 'PLAY':
					_btnPause.visible=false;
					_btnPlay.visible=true;
					break;
				case 'PAUSE':
					_btnPauseBig.visible = true;
					_btnPause.visible=true;
					_btnPlay.visible=false;
					break;
			}
		}
		
		/* 全屏操作回调函数句柄 */
		public function onStop() 
		{
			_barSlider.stage.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP));
			_player.fixedTime = 0;
			_barSlider.x=0;
			_barPlay.width = 0;
			setPlayTimeText(formatTime(0)+'/'+formatTime(_player.totalTime));
		}
		
		public function hide(rightNow:Boolean = false) {
			Mouse.hide();
			if (rightNow) {
				TweenLite.killTweensOf(barBox);
				barBox.y = 40;
			}else {
				TweenLite.to(barBox, 0.3, { y:40 } );
			}
			hidden = true;
		}
		
		public function show(rightNow:Boolean = false) {
			Mouse.show();
			if (rightNow) {
				TweenLite.killTweensOf(barBox);
				barBox.y = 0;
			}else{
				TweenLite.to(barBox, 0.3, { y:0 } );
			}
			hidden = false;
		}
		
		public function getVolume():Number
		{
			return _player.volum;
		}
		public function setVolume(value:Number):void
		{
			_player.volum = value;
		}
		public function getBufferProgress():Number
		{
			return _player.downloadProgress * 100;
		}
		public function getPlayProgress(isTime:Boolean):Number
		{
			if (isTime)
			{
				return _player.time;
			}else {
				return _player.playProgress;
			}
			return "";
		}
		public function getPlayStatus():Number
		{
			return _player.playStatus;
		}
		public function errorInfo():String
		{
			return _errorInfo;
		}
		public function stopTimer():void
		{
			if ( _timerBP && _timerBP.running )
			{
				_timerBP.stop();
			}
		}
		public function startTimer():void
		{
			if ( _timerBP)
			{
				_timerBP.start();
			}
		}

		private function volumeBtnEventHandler(e:MouseEvent):void
		{
			switch(e.type) {
				case 'mouseOver':
					setVolumeBtn(2);
					//_mcVolume.visible = true;
					if (volumeTimer) {
						volumeTimer.stop();
					}
					break;
				case 'mouseOut':
					setVolumeBtn(1);
					if (volumeTimer) {
						volumeTimer.reset();
					}else {
						volumeTimer = new Timer(120, 1);
						volumeTimer.addEventListener(TimerEvent.TIMER_COMPLETE, showVolumeTimerHandler);
					}
					volumeTimer.start();
					break;
				case 'click':
					setVolumeBtn(3);
					break;
			}
		}
		
		private function showVolumeTimerHandler(e:TimerEvent):void
		{
			//_mcVolume.visible = _mcVolume.show;
		}
		
		public function setVolumeBtn(value:Number):void //value:2---mouseover,1---mouseout,3---click
		{
			if (_isVolume)
			{
				if (value == 3)
				{
					value = 4;
					setVolume(0);
					_mcVolume.handleVolumeBar(0);
					_isVolume = false;
				}
				_btnMute.gotoAndStop(value);
				return;
			}else {
				if (value == 3)
				{
					value = 0;
					setVolume(_cacheVolume);
					_mcVolume.handleVolumeBar(_cacheVolume);
					_isVolume = true;
				}
				_btnMute.gotoAndStop(value + 2);
				return;
			}
		}
		
		private function btnTipsHandler(e:MouseEvent):void
		{
			if (e.type == 'mouseOut')
			{
				_btnTips.visible = false;
				return;
			}
			switch(e.currentTarget)
			{
				case _btnPlay:
					_btnTips.x = -3;
					_btnTips.bgWidth = 44;
					_btnTips.text = '播放';
					break;
				case _btnPause:
					_btnTips.x = -3;
					_btnTips.bgWidth = 44;
					_btnTips.text = '暂停';
					break;
				case _btnStop:
					_btnTips.x = _btnStop.x - 3;
					_btnTips.bgWidth = 44;
					_btnTips.text = '停止';
					break;
				case _btnFilelist:
					_btnTips.x = _btnFilelist.x - 3;
					_btnTips.bgWidth = 44;
					_btnTips.text = '列表';
					break;
				case _btnFullscreen:
					if (_container.stage.displayState == StageDisplayState.NORMAL)
					{
						_btnTips.x = _container.stage.stageWidth - 41;
						_btnTips.bgWidth = 44;
						_btnTips.text = '全屏';
					}
					else
					{
						_btnTips.x = _container.stage.stageWidth - 67;
						_btnTips.bgWidth = 70;
						_btnTips.text = '退出全屏';
					}
					break;
				default:
					return;
					break;
			}
			
			_btnTips.y = -35;
			_btnTips.visible = true;
		}
		
		public function set isChangeQuality(boo:Boolean):void
		{
			_isChangeQuality = boo;
		}
		
		public function showFormatLayer(formats:Object):void
		{
			_formatBtn.showLayer(formats);
			_curFormatBtn.showLayer(formats);
		}
		
		public function set formatShowBtn(str:String):void
		{
			_formatBtn.showBtn = str;
			_curFormatBtn.showBtn = str;
		}
		
		public function changeToNextFormat():void
		{
			_formatBtn.changeToNextFormat();
		}

		public function normalPlayProgressBar():void
		{
			if( _barBg.height == this.SMALL_PROGRESSBAR_HEIGTH )
			{
				if(this._seekEnable){
					_barSlider.visible = true;
				}
				_barBg.height = this.NORMAL_PROGRESSBAR_HEIGTH;
				_barBuff.height = this.NORMAL_PROGRESSBAR_HEIGTH;
				_barPlay.height = this.NORMAL_PROGRESSBAR_HEIGTH;
				_barPreDown.height = this.NORMAL_PROGRESSBAR_HEIGTH;
				
				_barBg.y = -6 ;
				_barBuff.y = -6;
				_barPlay.y = -6;
				_barPreDown.y = -6 ;
			}
		}

		public function smallPlayProgressBar(isVideoPlaying:Boolean):void
		{
			if( _barBg.height ==  NORMAL_PROGRESSBAR_HEIGTH )
			{
				if( isVideoPlaying || _btnPauseBig.visible )
				{
					_barSlider.visible =false;
					_barBg.height = this.SMALL_PROGRESSBAR_HEIGTH;
					_barBg.y = -2;
					_barBuff.height = this.SMALL_PROGRESSBAR_HEIGTH;
					_barBuff.y = -2;
					_barPlay.height = this.SMALL_PROGRESSBAR_HEIGTH;
					_barPlay.y  = -2;
					_barPreDown.height = this.SMALL_PROGRESSBAR_HEIGTH;
					_barPreDown.y = -2;									
				}
			}
		}

		public function get isProgressBarNormal():Boolean {
			return _barBg.height == NORMAL_PROGRESSBAR_HEIGTH;
		}
				
		public function set enableFileList(v:Boolean):void
		{
			_btnFilelist.mouseEnabled = v;
			_btnFilelist.alpha = v ? 1: 0.5;
		}

		public function set fixedY(value:Number):void {
			_container.y = value;
			faceLifting(_container.stage.stageWidth);
		}
		
		public function set visible(value:Boolean):void {
			_container.visible = value;
		}

		private var _txtPlayTime:TextField;        		//播放时间文字区
		private var _txtDownloadSpeed:TextField;   		//下载速度文字区
		private var _mcVolume:McVolume;            
		private var _mcTimeTip:McTimeTip;         		//鼠标所在的进度条的位置处的时间提示
		private var _mcTimeTipArrow:TimeTipsArrow;
		private var _videoTipID:uint;					//视频提示id
		private var _timeOutID:int;						//延迟显示视频提示id
		private var _isFirstShowTips:Boolean = true;	//是否第一次显示视频提示
		private var _player:Player;     
		public var _barWidth:Number;
		private var _timerHide:Timer;
		private var _stageInfo:Object;
		private var _beAvailable:Boolean=true;
		private var _so:SharedObject;
		private var barBox:Sprite;
		private var _cacheVolume:Number = 0.5;
		private var _errorInfo:String;
		private var _isVolume:Boolean = true;
		private var _btnTips:BtnTip;
		private var _preBarWidth:Number = 0;
		private var spolierPointArr:Array = [];
		private var _isChangeQuality:Boolean = false;
		private var _volumeTips:VolumeTips;
		private var _tipsTimer:Timer;
		private var volumeTipsTimer:Timer;
		private var _volume100Tips:Volume100Tips;
		private var volumeTimer:Timer;
		private var _seekEnable:Boolean = true;
	}	
}