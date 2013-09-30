package zuffy.display 
{
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.ui.Mouse;
	import flash.utils.Timer;
	
	/**
	 * ...
	 * @author han
	 */
	public class MouseControl extends EventDispatcher
	{
		private var _listener:InteractiveObject;    //监听鼠标移进、移出、移动的显示对象
		private var _timer:Timer;                   //鼠标在画面中停留5秒的计时器
		private var _timer2:Timer;					//鼠标在画面中停留3秒的计时器，缩小播放进度条用
		private var _state:Boolean = false;         //鼠标的状态：出现或隐藏
		private var _lastPosition:Point = new Point();
		
		public function MouseControl(listener:InteractiveObject) 
		{
			_listener = listener;
			_listener.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);  //监听鼠标移动
			_listener.addEventListener(MouseEvent.ROLL_OUT, handleMouseRollOut);
			_listener.addEventListener(MouseEvent.ROLL_OVER, handleMouseRollOver);
			_timer = new Timer(6000);     //鼠标在画面中停留5秒后自动隐藏，晃动鼠标后出来
			_timer2 = new Timer(3000);
			_timer.addEventListener(TimerEvent.TIMER, handleTimer);
			_timer.start();
			_timer2.addEventListener(TimerEvent.TIMER, handleTimer);
			_timer2.start();
			_lastPosition.x = _listener.mouseX;
			_lastPosition.y = _listener.mouseY;
		}
		
		private function handleMouseRollOver(e:MouseEvent):void
		{
			_state = true;
			this.dispatchEvent(new Event("MOUSE_SHOWED"));
		}
		
		private function handleMouseRollOut(e:MouseEvent):void
		{
			_state = false;
			this.dispatchEvent(new Event("MOUSE_HIDED"));
			_timer.stop();
		}
		
		private function handleMouseMove(e:MouseEvent):void 
		{
			if (_state == false)
			{
				Mouse.show();
				_state = true;
				this.dispatchEvent(new Event("MOUSE_SHOWED"));
			} else {
				this.dispatchEvent(new Event("MOUSE_MOVEED"));
			}
			_timer.reset();
			_timer.start();
			_timer2.reset();
			_timer2.start();
			_lastPosition.x = _listener.mouseX;
			_lastPosition.y = _listener.mouseY;
		}
		
		//五秒钟后,鼠标隐藏，侧边栏隐藏，三秒钟后，播放进度条变小
		private function handleTimer(e:TimerEvent):void
		{
			//if (_lastPosition.x == _listener.mouseX && _lastPosition.y == _listener.mouseY)
			if(e.currentTarget == _timer)
			{
				if(_listener.parent.stage.displayState == "fullScreen") //chnzbq，修改鼠标在非全屏下五秒后也会hide()
				{
					Mouse.hide();
				}
				_state = false;
				this.dispatchEvent(new Event("MOUSE_HIDED"));
				_timer.stop();
			}
			else
			{
				this.dispatchEvent(new Event("SMALL_PLAY_PROGRESS_BAR"));
				_timer2.stop();
			}
		}
		public function get Timer2():Timer
		{
			return _timer2;
		}
		
		public function set fullscreen(value:Boolean):void
		{
			_timer.delay = value ? 2000 : 6000;
		}
	}
}