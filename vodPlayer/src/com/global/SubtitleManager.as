package com.global{
	import zuffy.core.PlayerCtrl;
	import zuffy.display.subtitle.Subtitle;
	import zuffy.events.CaptionEvent;
	import com.common.JTracer;
	
	public class SubtitleManager {
		private var _subTitle:Subtitle;					//字幕条
		private var mainCtrl:PlayerCtrl;

		public function SubtitleManager (){

		}
		private static var _instance:SubtitleManager;
		public static function get instance():SubtitleManager
		{
			if (!_instance)
			{
				
				_instance = new SubtitleManager();
			}
			
			return _instance;
		}

		public function CSubtitleMake(p:PlayerCtrl, w:Number, h:Number):Subtitle {
			mainCtrl = p;

			_subTitle = new Subtitle(w, h);
			_subTitle.timerHandler = function handlGetTitleTimer():void{
				if(mainCtrl.videoIsPlaying)
				_subTitle.setPlayerTime(mainCtrl.videoTime, mainCtrl.isStartPlayLoading);
			} 
			mainCtrl.addEventListener(CaptionEvent.SET_STYLE, setCaptionStyle);
			mainCtrl.addEventListener(CaptionEvent.LOAD_CONTENT, loadCaptionContent);
			mainCtrl.addEventListener(CaptionEvent.HIDE_CAPTION, hideCaption);
			mainCtrl.addEventListener(CaptionEvent.SET_CONTENT, setCaptionContent);
			mainCtrl.addEventListener(CaptionEvent.SET_TIME, setCaptionTime);

			p.addChild(_subTitle);
			
			return _subTitle;
		}

		/**
		 * 设置字幕的样式;
		 */
		private function setCaptionStyle(evt:CaptionEvent):void
		{
			_subTitle.setStyle(evt.info);
		}

		private function hideCaption(evt:CaptionEvent):void
		{
			_subTitle.hideCaption(evt.info);
		}

		private function loadCaptionContent(evt:CaptionEvent):void
		{
			_subTitle.loadContent(evt.info);
			
			mainCtrl.showAutoloadTips();
		}

		private function setCaptionContent(evt:CaptionEvent):void
		{
			_subTitle.setContent(evt.info.toString());
		}
		
		private function setCaptionTime(evt:CaptionEvent):void
		{
			if (evt.info.type == "key")
			{
				if (_subTitle.hasSubtitle)
				{
					if (Number(evt.info.time) <= 0)
					{
						mainCtrl.showPlayerTxtTips("字幕提前" + Math.abs(evt.info.time) / 1000 + "秒", 3000);
					}
					else
					{
						mainCtrl.showPlayerTxtTips("字幕推迟" + Math.abs(evt.info.time) / 1000 + "秒", 3000);
					}
				}
			}
			
			_subTitle.setTimeDelta(Number(evt.info.time));
		}

		public function exchangeVideo():void
		{
			//切换后，取消之前的字幕
			_subTitle.hideCaption({surl:null, scid:null});
		}

		public function saveTimeDelta():void{
				_subTitle.saveTimeDelta();
		}

		public function saveStyle():void{
			_subTitle.saveStyle();
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

		public function handleStageResize(isFullScreen:Boolean):void {
			_subTitle.handleStageResize(isFullScreen);
		}
	}
}