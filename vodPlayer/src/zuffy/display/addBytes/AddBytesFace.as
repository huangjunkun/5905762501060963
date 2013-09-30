package zuffy.display.addBytes 
{
	import com.global.GlobalVars;
	import zuffy.events.TryPlayEvent;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import zuffy.events.EventSet;
	import flash.display.SimpleButton;
	import flash.text.TextField;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class AddBytesFace extends MovieClip 
	{
		public var close_btn:SimpleButton;
		public var addBytes_btn:SimpleButton;
		public var info_txt:TextField;
		public var remind_txt:TextField;
		public var progress_mc:MovieClip;
		
		public function AddBytesFace() 
		{
			close_btn.addEventListener(MouseEvent.CLICK, onCloseClick);
			
			addBytes_btn.addEventListener(MouseEvent.CLICK, onAddBytes);
		}
		
		public function setInfo(needs:String, reminds:String, progress:Number):void
		{
			info_txt.text = "播放本次视频需流量" + needs + "，扩充流量即可观看。";
			remind_txt.text = "剩余" + reminds;
			progress_mc.mask_mc.width = 234 * progress;
		}
		
		public function setPosition():void
		{
			this.x = (stage.stageWidth - 358) / 2;
			this.y = (stage.stageHeight - 218 - 33) / 2;
		}
		
		private function onCloseClick(evt:MouseEvent):void
		{
			dispatchEvent(new Event("CloseAddBytesFace"));
		}
		
		private function onAddBytes(evt:MouseEvent):void
		{
			var paypos:String = GlobalVars.instance.paypos_trystop;
			dispatchEvent(new TryPlayEvent(TryPlayEvent.BuyVIP, {refer:"XV_13", paypos:paypos, hasBytes:true}));
		}
	}
}