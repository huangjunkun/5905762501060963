package zuffy.display.tryplay 
{
	import eve.TryPlayEvent;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.text.StyleSheet;
	import flash.text.TextFormat;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class ViewListFace extends MovieClip 
	{
		
		public function ViewListFace() 
		{
			var style:StyleSheet = new StyleSheet();
			style.setStyle('a', {textDecoration:'underline'});
			
			buy_txt.styleSheet = style;
			buy_txt.htmlText = "<a href='event:login'>会员登录</a>";
			buy_txt.addEventListener(TextEvent.LINK, clickText);
			
			more_mc.more_txt.htmlText = "更多云播放功能尽在<font color='#3B8FE0'><a href='event:home'>vod.xunlei.com</a></font>";
			more_mc.more_txt.addEventListener(TextEvent.LINK, clickText)
			
			view_btn.addEventListener(MouseEvent.CLICK, onViewClick);
			close_btn.visible = false;
			close_btn.addEventListener(MouseEvent.CLICK, onCloseClick);
		}
		
		public function setPosition():void
		{
			this.x = int((stage.stageWidth - 373) / 2);
			this.y = int((stage.stageHeight - 195 - 33) / 2);
		}
		
		private function clickText(evt:TextEvent):void
		{
			switch(evt.text)
			{
				case "login":
					dispatchEvent(new TryPlayEvent(TryPlayEvent.Login));
					break;
				case "home":
					dispatchEvent(new TryPlayEvent(TryPlayEvent.GoHome));
					break;
			}
		}
		
		private function onViewClick(evt:MouseEvent):void
		{
			dispatchEvent(new TryPlayEvent(TryPlayEvent.ViewList));
		}
		
		private function onCloseClick(evt:MouseEvent):void
		{
			dispatchEvent(new TryPlayEvent(TryPlayEvent.HidePanel));
		}
	}

}