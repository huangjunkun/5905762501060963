package zuffy.ctr.manager{
	import com.common.JTracer;
	import zuffy.core.PlayerCtrl;
	import zuffy.display.subtitle.Subtitle;
	import zuffy.events.CaptionEvent;
	import zuffy.interfaces.ICaption;
	
	public class SubtitleManager {
		private var _subTitle:Subtitle;					//字幕条
		private var mainCtrl:ICaption;
		private static var _instance:SubtitleManager;

		public static function get instance(): SubtitleManager {
			
			if (!_instance) {
				_instance = new SubtitleManager ();
			}
			
			return _instance;
		}

		public function SubtitleManager() {

		}
		
		public function makeInstance(p:ICaption, w:Number, h:Number):Subtitle {
			mainCtrl = p;
			var mc:PlayerCtrl = p as PlayerCtrl;
			
			_subTitle = new Subtitle(w, h);
			_subTitle.timerHandler = function handlGetTitleTimer():void {
				if(mainCtrl.videoIsPlaying)
				_subTitle.setPlayerTime(mainCtrl.videoTime, mainCtrl.isStartPlayLoading);
			} 
			mc.addEventListener(CaptionEvent.SET_STYLE, setCaptionStyle);
			mc.addEventListener(CaptionEvent.LOAD_CONTENT, loadCaptionContent);
			mc.addEventListener(CaptionEvent.HIDE_CAPTION, hideCaption);
			mc.addEventListener(CaptionEvent.SET_CONTENT, setCaptionContent);
			mc.addEventListener(CaptionEvent.SET_TIME, setCaptionTime);

			mc.addChild(_subTitle);
			
			return _subTitle;
		}

		/**
		 * 设置字幕的样式;
		 */
		private function setCaptionStyle(evt:CaptionEvent):void {
			_subTitle.setStyle(evt.info);
		}

		private function hideCaption(evt:CaptionEvent):void {
			_subTitle.hideCaption(evt.info);
		}

		private function loadCaptionContent(evt:CaptionEvent):void {
			_subTitle.loadContent(evt.info);
			
			mainCtrl.showAutoloadTips();
		}

		private function setCaptionContent(evt:CaptionEvent):void {
			_subTitle.setContent(evt.info.toString());
		}
		
		private function setCaptionTime(evt:CaptionEvent):void {
			if (evt.info.type == "key") {
				if (_subTitle.hasSubtitle) {
					if (Number(evt.info.time) <= 0) {
						mainCtrl.showPlayerTxtTips("字幕提前" + Math.abs(evt.info.time) / 1000 + "秒", 3000);
					}
					else {
						mainCtrl.showPlayerTxtTips("字幕推迟" + Math.abs(evt.info.time) / 1000 + "秒", 3000);
					}
				}
			}
			
			_subTitle.setTimeDelta(Number(evt.info.time));
		}

		public function exchangeVideo():void {
			//切换后，取消之前的字幕
			_subTitle.hideCaption({surl:null, scid:null});
		}

		public function saveTimeDelta():void {
				_subTitle.saveTimeDelta();
		}

		public function saveStyle():void {
			_subTitle.saveStyle();
		}
		
		public function cancelSubTitle():void {
			_subTitle.hideCaption({surl:null, scid:null});
		}

		public function handleStageResize(isFullScreen:Boolean):void {
			_subTitle.handleStageResize(isFullScreen);
		}
	}
}