package zuffy.display.toolBarRight 
{
	import com.greensock.TweenLite;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import zuffy.core.PlayerCtrl;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class ToolBarRightArrow extends MovieClip
	{
		public var hidden:Boolean;
		private var _target:PlayerCtrl;
		private var _beMouseOn:Boolean;
		
		public function ToolBarRightArrow(target:PlayerCtrl) 
		{
			_target = target;
			_target.addChild(this);
			this.visible = false;
		}
		
		public function setPosition():void
		{
			this.x = stage.stageWidth;
			this.y = int((stage.stageHeight - this.height - 36) / 2);
			stage.addEventListener(Event.RESIZE, resizeHandler);
		}
		
		public function show(rightNow:Boolean = false):void
		{
			if (rightNow) {
				TweenLite.killTweensOf(this);
				this.x = stage.stageWidth - this.width - 5;
			}else{
				TweenLite.to(this, 0.5, { x:stage.stageWidth - this.width - 5 } );
			}
			
			hidden = false;
		}
		
		public function hide(rightNow:Boolean = false):void
		{
			if (rightNow) {
				TweenLite.killTweensOf(this);
				this.x = stage.stageWidth;
			}else {
				TweenLite.to(this, 0.5, { x:stage.stageWidth } );
			}
			
			hidden = true;
		}
		
		private function resizeHandler(e:Event):void
		{
			this.x = stage.stageWidth - this.width - 5;
			this.y = int((stage.stageHeight - this.height - 36) / 2);
		}
	}
}