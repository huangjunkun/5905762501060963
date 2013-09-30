package zuffy.display.addBytes 
{
	import com.global.GlobalVars;
	import zuffy.events.TryPlayEvent;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.StyleSheet;
	import zuffy.events.EventSet;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class NoEnoughBytesFace extends MovieClip 
	{
		private var _style:StyleSheet;
		public var close_btn:SimpleButton;
		public var know_btn:SimpleButton;
		public var info_txt:TextField;
		
		public function NoEnoughBytesFace() 
		{
			_style = new StyleSheet();
			_style.setStyle('.style', { color:'#ffffff', fontSize:'14', textAlign:'center', fontFamily :'宋体'} );
			_style.setStyle('a', { color:'#097BB3', fontSize:'14', textAlign:'center', fontFamily :'宋体', textDecoration:'underline'});
			
			close_btn.addEventListener(MouseEvent.CLICK, onCloseClick);
			
			know_btn.addEventListener(MouseEvent.CLICK, onCloseClick);
			
			info_txt.styleSheet = _style;
			info_txt.htmlText = "<span class='style'>您的播放时长剩余0，迅雷白金会员不限时长，</span><a href='event:th'>加5元升级为白金</a>";
			info_txt.addEventListener(MouseEvent.CLICK, onAddBytes);
		}
		
		public function setPosition():void
		{
			this.x = (stage.stageWidth - 358) / 2;
			this.y = (stage.stageHeight - 173 - 33) / 2;
		}
		
		private function onCloseClick(evt:MouseEvent):void
		{
			dispatchEvent(new Event("CloseNoEnoughFace"));
		}
		
		private function onAddBytes(evt:MouseEvent):void
		{
			var paypos:String = GlobalVars.instance.paypos_tryfinish;
			dispatchEvent(new TryPlayEvent(TryPlayEvent.BuyVIP, {refer:"XV_13", paypos:paypos, hasBytes:false}));
		}
	}
}