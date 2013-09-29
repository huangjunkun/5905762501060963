package zuffy.core
{
	import com.global.GlobalVars;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.system.Security;
	
	import zuffy.ctr.contextMenu.CreateContextMenu;
	import zuffy.display.statuMenu.VideoMask;
	import zuffy.display.subtitle.Subtitle;
	
	public class PlayerCtrl extends Sprite
	{
		protected var _params:Object;
		protected var _movieType:String;
		
		
		private var _subTitle:Subtitle;
		private var _videoMask:VideoMask;
		
		public function PlayerCtrl()
		{
			Security.allowDomain("*");
			
			if(stage){
				init();
			}else{
				//侦听该类是否被添加到了舞台显示列表
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
			
			initializePlayCtrl();			
		}
		
		private function initializePlayCtrl():void 
		{
			stage.addEventListener(Event.RESIZE, on_stage_RESIZE);

			var _w:int = int(_params["width"]) ? int(_params["width"]) : stage.stageWidth;
			var _h:int = int(_params["height"]) ? int(_params["height"]) : stage.stageHeight;
			var _has_fullscreen:int = int(_params["fullscreenbtn"]) || 1;
			
			GlobalVars.instance.movieType = _movieType;
			GlobalVars.instance.windowMode = _params['windowMode'] || 'browser';
			GlobalVars.instance.platform = _params['platform'] || 'webpage';
			GlobalVars.instance.isMacWebPage = ((typeof _params['isMacWebPage'] != "undefined") && _params['isMacWebPage'] != 'false');
			GlobalVars.instance.isZXThunder = int(_params["isZXThunder"]) == 1;
			GlobalVars.instance.isStat = _params['defStatLevel'] == 2 ? true : false;	//0-不上报，1-只上报重要的，2-全部上报

			_subTitle = new Subtitle(this, _w, _h);
			_subTitle.handleStageResize(stage.stageWidth, stage.stageHeight);
			
			var _screenEvent:Sprite = new Sprite();
			_screenEvent.graphics.clear();
			_screenEvent.graphics.beginFill(0xffffff, 0);
			_screenEvent.graphics.drawRect(0, 0, _w, _h);
			_screenEvent.graphics.endFill();
			_screenEvent.doubleClickEnabled = true;
			_screenEvent.mouseEnabled = true;
			
			this.addChild(_screenEvent);
//			_screenEvent.addEventListener(MouseEvent.DOUBLE_CLICK, onDoubleClickHandle);
//			_screenEvent.addEventListener(MouseEvent.CLICK, onClickHandle);
			
			_videoMask = new VideoMask(this, _movieType);
//			_videoMask.addEventListener("StartPlayClick", onStartPlayClick);
//			_videoMask.addEventListener("Refresh", onRefresh);
			
			/*
			_ctrBar = new CtrBar(this, _w, _h, _has_fullscreen);
			this.addChild(_ctrBar);
			_ctrBar.showPlayOrPauseButton='PLAY';
			_ctrBar.flvPlayer=_player;
			_ctrBar.available = true;
			_ctrBar.faceLifting(stage.stageWidth);
			
			_mouseControl = new MouseControl(this);
			_mouseControl.addEventListener("MOUSE_SHOWED", handleMouseShow);
			_mouseControl.addEventListener("MOUSE_HIDED", handleMouseHide);	
			_mouseControl.addEventListener("MOUSE_MOVEED", handleMouseMove);
			_mouseControl.addEventListener("MOUSE_MOVEOUT", handleMouseMoveOut);
			_mouseControl.addEventListener("SMALL_PLAY_PROGRESS_BAR", handleMouseHide2 );//缩小播放进度条;
			
			_bufferTip = new bufferTip(_player);
			_bufferTip.name = "_bufferTip";
			this.addChild(_bufferTip);
			this.swapChildren(_ctrBar, _bufferTip);
			
			_toolRightArrow = new ToolBarRightArrow(this);
			_toolRightArrow.setPosition();
			
			_toolRightFace = new ToolBarRight(this);
			_toolRightFace.setPosition();
			
			_fileListFace = new FileListFace(this);
			addChild(_fileListFace);
			_fileListFace.setPosition();
			
			_ctrBar.y = stage.stageHeight - 33;
			_ctrBar.faceLifting(stage.stageWidth);
			
			_noticeBar = new NoticeBar(this);
			addChild(_noticeBar);
			swapChildren(_ctrBar, _noticeBar);
			
			_settingSpace = new SettingSpace(_player);
			_settingSpace.addEventListener(EventSet.SET_AUTOCHANGE, settingSpaceEventHandler);
			_settingSpace.addEventListener(EventSet.SET_SIZE, settingSpaceEventHandler);
			_settingSpace.addEventListener(EventSet.SET_CHANGED, settingSpaceEventHandler);
			addChild(_settingSpace);
			_settingSpace.setPosition();
			
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
			*/
		}
		protected function on_stage_RESIZE(e:Event):void{
			
			var _w:int = int(_params["width"]) ? int(_params["width"]) : stage.stageWidth;
			var _h:int = int(_params["height"]) ? int(_params["height"]) : stage.stageHeight;
			var _has_fullscreen:int = int(_params["fullscreenbtn"]) || 1;
			
		}
		
	}
}