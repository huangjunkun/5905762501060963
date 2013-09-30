package zuffy.display.notice 
{
	import com.common.Cookies;
	import com.common.Tools;
	import com.global.GlobalVars;
	import zuffy.events.TryPlayEvent;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.events.TextEvent;
	import flash.events.EventDispatcher;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import com.common.JTracer;
	import zuffy.events.*;
	
	/**
	 * ...
	 * @author Drgon.S
	 */
	public class NoticeText extends Sprite
	{
		private var _text:TextField;
		private var _style:StyleSheet;
		private var _callBackFun:String;
		private var _start:int;
		private var _length:int;
		private var _noticeBar:NoticeBar;
		
		public function NoticeText(noticeBar:NoticeBar)
		{
			_noticeBar = noticeBar;
			
			init();
		}
		
		private function init():void
		{
			if (_text == null) {
				_text = new TextField();
				_text.selectable = false;
				_text.height = 23;
				_text.addEventListener(TextEvent.LINK, linkEventHandler);
				_text.addEventListener(MouseEvent.CLICK, mouseClickHandler);
				addChild(_text);
				initStyle();
			}
		}
		
		public function set content(str:String):void
		{
			_text.styleSheet = _style;
			_text.htmlText = '<span class="style">' + str + '</span>';
		}
		
		public function set callBackFun(fun:String):void
		{
			_callBackFun = fun;
		}
		
		public function setCallBackFunLocation(start:int,length:int):void
		{
			_start = start;
			_length = length;
		}
		
		private function initStyle():void
		{
			_style = new StyleSheet();
			_style.setStyle('.style', { color:'#ffffff', fontSize:'15', textAlign:'left', fontFamily :'微软雅黑'} );
			_style.setStyle('a', { color:'#097BB3', fontSize:'15', textDecoration:'underline', fontFamily :'微软雅黑' } );
			_style.setStyle('.redStyle', { color:'#ff0000', fontSize:'15', textDecoration:'underline', fontFamily :'微软雅黑' } );
		}
		
		public function set tWidth(num:Number):void
		{
			_text.width = num;
		}
		
		public function get tWidth():Number
		{
			return _text.textWidth;
		}
		
		private function checkMousePosition(index:int):Boolean
		{
			if (index >= _start && index <= (_start + _length)) {
				return true;
			}else {
				return false;
			}
		}
		
		private function mouseClickHandler(e:MouseEvent):void
		{
			var index:int = _text.getCharIndexAtPoint(mouseX, mouseY);
			if (checkMousePosition(index) == false) {
				return;
			}
			if (_callBackFun != null) {
				ExternalInterface.call(_callBackFun);
			}
		}
		
		private function linkEventHandler(e:TextEvent):void
		{
			var referfrom:String = Tools.getReferfrom();
			var paypos:String = GlobalVars.instance.paypos_tips_time;
			switch(e.text) {
				case 'pause':
					dispatchEvent(new PlayEvent(PlayEvent.PAUSE_4_STAGE));
					dispatchEvent(new SetQulityEvent(SetQulityEvent.PAUSE_FOR_QUALITY_TIP));
					break;
				case 'changeLowerQulity':
					dispatchEvent(new SetQulityEvent(SetQulityEvent.LOWER_QULITY));
					break;
				case 'showAutoQualityFace':
					dispatchEvent(new EventSet(EventSet.SHOW_AUTOQUALITY_FACE));
					break;
				case 'showSkipMovieFace':
					dispatchEvent(new EventSet(EventSet.SHOW_SKIPMOVIE_FACE));
					break;
				case 'showStageVideo':
					dispatchEvent(new EventSet(EventSet.SHOW_STAGE_VIDEO));
					break;
				case 'replay':
					dispatchEvent(new PlayEvent(PlayEvent.REPLAY));
					break;
				case 'dontNotice':
					dispatchEvent(new TryPlayEvent(TryPlayEvent.DontNoticeBytes));
					break;
				case 'buyVIP13':
					dispatchEvent(new TryPlayEvent(TryPlayEvent.BuyVIP, {refer:referfrom, paypos:paypos, hasBytes:true}));
					break;
				case 'buyVIP13FluxOut':
					dispatchEvent(new TryPlayEvent(TryPlayEvent.BuyVIP, {refer:referfrom, paypos:paypos, hasBytes:false}));
					break;
				case 'buyVIP11':
					dispatchEvent(new TryPlayEvent(TryPlayEvent.BuyVIP, {refer:referfrom, paypos:paypos, hasBytes:false}));
					break;
				case 'getBytes':
					dispatchEvent(new TryPlayEvent(TryPlayEvent.GetBytes));
					break;
				case 'showCaptionFace':
					_noticeBar.hideNoticeBar();
					dispatchEvent(new EventSet(EventSet.SHOW_FACE, 'captionFromTips'));
					Tools.stat("b=showSubtitleList");
					break;
				case 'hideNoCaptionTips':
					Cookies.setCookie('hideNoCaptionTips', true);
					_noticeBar.hideNoticeBar();
					break;
				case 'hideAutoCaptionTips':
					Cookies.setCookie('hideAutoCaptionTips', true);
					_noticeBar.hideNoticeBar();
					break;
				case 'backToLiuChang':
					Tools.setFormatCallBack("p", true);
					if (GlobalVars.instance.isStat)
					{
						Tools.stat("b=changeToLowerFormat");
					}
					break;
				case 'backToGaoQing':
					Tools.setFormatCallBack("g", true);
					if (GlobalVars.instance.isStat)
					{
						Tools.stat("b=changeToLowerFormat");
					}
					break;
				case 'goToGaoQing':
					Tools.setFormatCallBack("g", true);
					if (GlobalVars.instance.isStat)
					{
						Tools.stat("b=changeToHigherFormat");
					}
					break;
				case 'goToChaoQing':
					Tools.setFormatCallBack("c", true);
					if (GlobalVars.instance.isStat)
					{
						Tools.stat("b=changeToHigherFormat");
					}
					break;
				case 'hideLowSpeedTips':
					GlobalVars.instance.isHideLowSpeedTips = true;
					Cookies.setCookie('hideLowSpeedTips', true);
					Tools.stat("b=hideLowSpeedTips");
					_noticeBar.hideNoticeBar();
					break;
				case 'hideHighSpeedTips':
					GlobalVars.instance.isHideHighSpeedTips = true;
					Cookies.setCookie('hideHighSpeedTips', true);
					Tools.stat("b=hideHighSpeedTips");
					_noticeBar.hideNoticeBar();
					break;
				default:
					break;
			}
		}
	}

}