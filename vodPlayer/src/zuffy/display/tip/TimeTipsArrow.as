package ctr.tip 
{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class TimeTipsArrow extends MovieClip 
	{
		public function TimeTipsArrow() 
		{
			
		}
		
		public function showBg():void
		{
			this.graphics.clear();
			this.graphics.beginFill(0xffffff, 0);
			this.graphics.drawRect(0, 1, 7, 12);
			this.graphics.endFill();
		}
		
		public function hideBg():void
		{
			this.graphics.clear();
		}
		
		override public function get width():Number
		{
			return 7;
		}
	}
}