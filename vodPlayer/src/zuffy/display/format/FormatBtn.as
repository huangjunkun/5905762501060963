package zuffy.display.format 
{
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import com.common.Tools;
	import com.global.GlobalVars;
	import com.Player;
	import zuffy.events.SetQulityEvent;
	import com.common.JTracer;
	
	/**
	 * ...
	 * @author dds
	 */
	public class FormatBtn extends Sprite 
	{
		private var _formatShowBtn:FormatShowBtn;
		private var _curFormat:String = '';
		
		public function FormatBtn() 
		{
			_formatShowBtn = new FormatShowBtn();
			_formatShowBtn.addEventListener(SetQulityEvent.CHANGE_QUILTY, formatShowBtnHandler);
			_formatShowBtn.addEventListener(SetQulityEvent.CLICK_QULITY, formatClickHandler);
			addChild(_formatShowBtn);
		}
		
		public function get curFormat():String
		{
			return _curFormat;
		}
		
		private function formatClickHandler(evt:SetQulityEvent):void
		{
			dispatchEvent(new Event("clickFormat"));
		}
		
		private function formatShowBtnHandler(e:SetQulityEvent):void
		{
			var format:Object = new Object();
			format.checked = true;
			var qulity:String = e.qulity;
			if (qulity == SetQulityEvent.NORMAL_QULITY)
			{
				format.format = "y";
			} else if (qulity == SetQulityEvent.STANDARD_QULITY) {
				format.format = "p";
			} else if (qulity == SetQulityEvent.HEIGH_QULITY) {
				format.format = "g";
			} else if (qulity == SetQulityEvent.SUPERHEIGH_QULITY) {
				format.format = "c";
			}
			
			if (GlobalVars.instance.isStat)
			{
				Tools.stat("b=changeformat&gcid=" + Tools.getUserInfo("ygcid") + "&format=" + format.format + "&lastformat=" + GlobalVars.instance.movieFormat);
			}
			
			Tools.setFormatCallBack(format.format, format.checked);
		}
		
		public function changeToNextFormat():void
		{
			var format:Object = new Object();
			format.checked = true;
			_formatShowBtn.detail = format.format = _curFormat = 'p';
			dispatchEvent(new SetQulityEvent(SetQulityEvent.CHANGE_QUILTY));
			Tools.setFormatCallBack(format.format, format.checked);
		}
		
		public function showLayer(formats:Object):void
		{
			JTracer.sendMessage('setFormats:' + formats);
			_formatShowBtn.showLayer(formats);
			
			_curFormat = "";
			if (formats && formats.g && formats.g.checked == true) {
				_curFormat = 'g';
			} else if (formats && formats.p && formats.p.checked == true) {
				_curFormat = 'p';
			} else if (formats && formats.y && formats.y.checked == true) {
				_curFormat = 'y';
			} else if (formats && formats.c && formats.c.checked == true) {
				_curFormat = 'c';
			}
			_formatShowBtn.detail = _curFormat;
			
			GlobalVars.instance.movieFormat = _curFormat;
		}
		
		public function set showBtn(str:String):void
		{
			_curFormat = str;
			_formatShowBtn.detail = _curFormat;
			
			GlobalVars.instance.movieFormat = _curFormat;
		}
	}

}