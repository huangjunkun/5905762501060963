package zuffy.display.notice 
{
	import com.greensock.TweenLite;
	import flash.display.Shape;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.external.ExternalInterface;
	import com.common.JTracer;
	import flash.events.MouseEvent;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.events.FullScreenEvent;
	import flash.events.Event;
	import zuffy.core.PlayerCtrl;

	/**
	 * ...
	 * @author Drgon.S
	 */
	public class NoticeBar extends Sprite
	{
		private var _noticeText:NoticeText;
		private var _dontNoticeText:NoticeText;
		private var _noticeCloseBtn:SimpleButton;
		private var _noticeBarBg:Sprite;
		private var _isInit:Boolean = false;
		private var _showTimer:Timer;
		private var _countTimer:Timer;
		private var _content:String = "";
		private var _mainMc:PlayerCtrl;
		
		public function NoticeBar(main_mc:PlayerCtrl) 
		{
			_mainMc = main_mc;
		}
		
		private function init():void
		{
			_noticeBarBg = createNoticeBg();
			_noticeCloseBtn = createNoticeCloseBtn();
			_noticeText = new NoticeText(this);
			_dontNoticeText = new NoticeText(this);
			
			addChild(_noticeBarBg);
			addChild(_noticeText);
			addChild(_dontNoticeText);
			addChild(_noticeCloseBtn);
			
			resizePos();
			
			_noticeCloseBtn.addEventListener(MouseEvent.CLICK, hideNoticeHandler);
			stage.addEventListener(Event.RESIZE, resizeHandler);
			_isInit = true;
		}
		
		private function createNoticeBg():Sprite
		{
			var sp:Sprite = new Sprite();
			sp.graphics.beginFill(0x181818, 0.9);
			sp.graphics.drawRect(0, 0, 35, 35);
			sp.graphics.endFill();
			return sp;
		}
		
		private function createNoticeCloseBtn():SimpleButton
		{
			var sb:SimpleButton = new SimpleButton();
			sb.upState = sb.downState = sb.overState = sb.hitTestState = createNoticeCloseBtnState();
			return sb;
		}
		
		private function createNoticeCloseBtnState():Shape
		{
			var sp:Shape = new Shape();
			sp.graphics.beginFill(0xffffff, 0);
			sp.graphics.drawRect(0, 0, 14, 14);
			sp.graphics.lineStyle(1, 0xffffff);
			sp.graphics.moveTo(0, 0);
			sp.graphics.lineTo( 14, 14);
			sp.graphics.moveTo(14, 0);
			sp.graphics.lineTo( 0, 14);
			sp.graphics.endFill();
			return sp;
		}
		
		private function resizePos():void
		{
			_noticeBarBg.width = stage.stageWidth;
			_noticeCloseBtn.x = stage.stageWidth - _noticeCloseBtn.width - 12;
			_noticeCloseBtn.y = 10;
			_noticeText.x = 8;
			_noticeText.y = 6;
			_noticeText.tWidth = stage.stageWidth - 73;
			_dontNoticeText.x = _noticeCloseBtn.x - _dontNoticeText.tWidth - 20;
			_dontNoticeText.y = 6;
			
			if (_mainMc._ctrBar.hidden)
			{
				this.y = stage.stageHeight - 35;
			}
			else
			{
				this.y = stage.stageHeight - 70;
			}
		}
		
		private function hideNoticeHandler(e:MouseEvent):void
		{
			if (ExternalInterface.available)
			{
				ExternalInterface.call("G_PLAYER_INSTANCE.closeNoticeCallback");
			}
			hideNoticeBar();
		}
		
		private function resizeHandler(e:Event):void
		{
			resizePos();
		}
		
		private function timeOutHandler(e:TimerEvent):void
		{
			this.visible = false;
			_showTimer.stop();
		}
		
		private function countDownHandler(evt:TimerEvent):void
		{
			setCountTime(_countTimer.repeatCount - _countTimer.currentCount);
		}
		
		private function setCountTime(time:Number):void
		{
			if (time < 0)
			{
				if (_content)
				{
					_noticeText.content = _content;
				}
				return;
			}
			_noticeText.content = "正在试播中(" + digits(time) + "), " + _content;
		}
		
		private function digits(nbr:Number):String
		{
			var min:Number = Math.floor(nbr / 60);
			var sec:Number = Math.floor(nbr % 60);
			var str:String = zero(min) + ':' + zero(sec);
			return str;
		}
		
		private function zero(nbr:Number):String
		{
			if (nbr < 10)
			{
				return '0' + nbr;
			}
			else
			{
				return '' + nbr;
			}
		}
		
		private function timerStart(showTime:int):void
		{
			if (_showTimer) {
				_showTimer.reset();
				_showTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, timeOutHandler);
				_showTimer = null;
			}
			_showTimer = new Timer(1000, showTime);
			_showTimer.addEventListener(TimerEvent.TIMER_COMPLETE, timeOutHandler);
		}
		
		public function setContent(str:String,isNoTimer:Boolean = false,showTime:int = 15,type:int = 1,callBackFun:String = null,start:int = 0, length:int = 0):void
		{
			_content = str;
			
			if (_isInit == false) init();
			_noticeText.content = str;
			_noticeText.callBackFun = callBackFun;
			_noticeText.setCallBackFunLocation(start, length);
			_dontNoticeText.content = "";
			timerStart(showTime <= 0 ? 15 : showTime);
			if(isNoTimer == false) _showTimer.start();
			this.visible = true;
			if (type < 1 || type > 8) {
				type = 1;
			}
			
			resizePos();
		}
		
		public function setRightContent(str:String):void
		{
			_dontNoticeText.content = str;
			resizePos();
		}
		
		/**
		 * 试播倒计时
		 * @param	time	倒计时，秒
		 */
		public function setCountDown(time:Number):void
		{
			if (_countTimer)
			{
				_countTimer.stop();
				_countTimer.removeEventListener(TimerEvent.TIMER, countDownHandler);
				_countTimer = null;
			}
			
			if (time > 0)
			{
				_countTimer = new Timer(1000, time);
				_countTimer.addEventListener(TimerEvent.TIMER, countDownHandler);
				_countTimer.start();
			}
			
			setCountTime(time);
			resizePos();
		}
		
		public function hideNoticeBar():void
		{
			this.visible = false;
			if (_showTimer)_showTimer.stop();
			if (_countTimer)_countTimer.stop();
		}
		
		public function showCloseBtn(flag:Boolean):void
		{
			_noticeCloseBtn.visible = flag;
		}
		
		public function hide(rightNow:Boolean = false):void
		{
			if (rightNow) {
				TweenLite.killTweensOf(this);
				this.y = stage.stageHeight - 35;
			} else {
				TweenLite.to(this, 0.3, { y:stage.stageHeight - 35 } );
			}
		}
		
		public function show(rightNow:Boolean = false):void
		{
			if (rightNow) {
				TweenLite.killTweensOf(this);
				this.y = stage.stageHeight - 70;
			} else {
				TweenLite.to(this, 0.3, { y:stage.stageHeight - 70 } );
			}
		}
	}

}