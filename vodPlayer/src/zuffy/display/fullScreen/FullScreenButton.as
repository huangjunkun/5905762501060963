package zuffy.display.fullScreen
{
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.events.FullScreenEvent;
	import flash.utils.Timer;
	import flash.display.Stage;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class FullScreenButton extends Sprite
	{
		private var _ctrBarFullScreenBtn:CtrBarFullScreenBtn;
		
		public function FullScreenButton() 
		{
			_ctrBarFullScreenBtn = new CtrBarFullScreenBtn();
			_ctrBarFullScreenBtn.gotoAndStop(1);
			addChild(_ctrBarFullScreenBtn);
			
			this.addEventListener(MouseEvent.ROLL_OVER, onMouseOverHandler);
			this.addEventListener(MouseEvent.ROLL_OUT, onMouseOutHandler);
			this.mouseChildren = false;
			this.buttonMode = true;
			
			var timer:Timer = new Timer(10, 1);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, initStageEventHandler);
			timer.start();
		}
		
		private function initStageEventHandler(e:TimerEvent = null):void
		{
			stage.addEventListener(FullScreenEvent.FULL_SCREEN, fullScreenEventHandler);
		}
		
		private function fullScreenEventHandler(e:FullScreenEvent):void
		{
			if (e.fullScreen)
			{
				_ctrBarFullScreenBtn.gotoAndStop(3);
			}
			else
			{
				_ctrBarFullScreenBtn.gotoAndStop(1);
			}
		}
		
		private function onMouseOutHandler(e:MouseEvent):void
		{
			if (stage.displayState == StageDisplayState.NORMAL)
			{
				_ctrBarFullScreenBtn.gotoAndStop(1);
			}
			else
			{
				_ctrBarFullScreenBtn.gotoAndStop(3);
			}
		}
		
		private function onMouseOverHandler(e:MouseEvent):void
		{
			if (stage.displayState == StageDisplayState.NORMAL)
			{
				_ctrBarFullScreenBtn.gotoAndStop(2);
			}
			else
			{
				_ctrBarFullScreenBtn.gotoAndStop(4);
			}
		}
		
		override public function get width():Number
		{
			return this._ctrBarFullScreenBtn.width;
		}
	}
}