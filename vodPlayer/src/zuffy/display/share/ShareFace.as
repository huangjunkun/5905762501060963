package zuffy.display.share 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.system.System;
	import flash.utils.setTimeout;
	import com.common.Tools;
	import zuffy.events.EventSet;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class ShareFace extends MovieClip 
	{
		
		public function ShareFace() 
		{
			this.visible = false;
			
			close_btn.addEventListener(MouseEvent.CLICK, onCloseClick);
			copy_btn.addEventListener(MouseEvent.CLICK, onCopyClick);
		}
		
		public function showFace(boo:Boolean):void
		{
			this.visible = boo;
		}
		
		public function setPosition():void
		{
			this.x = int((stage.stageWidth - 460) / 2);
			this.y = int((stage.stageHeight - 228 - 33) / 2);
		}
		
		private function onCloseClick(evt:MouseEvent):void
		{
			dispatchEvent(new EventSet(EventSet.SHOW_FACE, "share"));
		}
		
		private function onCopyClick(evt:MouseEvent):void
		{
			if (url_txt.text.length > 0)
			{
				System.setClipboard(url_txt.text);
				tips_txt.text = "复制成功";
				setTimeout(clearTips, 1000);
				
				Tools.stat('b=share');
			}
		}
		
		private function clearTips():void
		{
			tips_txt.text = "";
		}
	}

}