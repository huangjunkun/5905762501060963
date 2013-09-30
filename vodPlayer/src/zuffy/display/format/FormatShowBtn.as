package zuffy.display.format 
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldType;
	import flash.events.MouseEvent;
	import zuffy.events.SetQulityEvent;
	import com.common.JTracer;
	import zuffy.display.format.FormatShowDetailBtn;
	
	/**
	 * ...
	 * @author dds
	 */
	public class FormatShowBtn extends Sprite 
	{
		public static const TEXT_CLICK:String = 'text click';
		private var _biaoqingdetail:FormatShowDetailBtn;
		private var _gaoqingdetail:FormatShowDetailBtn;
		private var _chaoqingdetail:FormatShowDetailBtn;
		private var _bg:FormatBg;
		
		public function FormatShowBtn() 
		{
			_bg = new FormatBg();
			addChild(_bg);
			
			_biaoqingdetail = new FormatShowDetailBtn("流畅");
			_biaoqingdetail.x = 7;
			_biaoqingdetail.y = -60;
			_biaoqingdetail.addEventListener(MouseEvent.CLICK, mouseClickHandler);
			addChild(_biaoqingdetail);		
			
			_gaoqingdetail = new FormatShowDetailBtn("高清");
			_gaoqingdetail.x = 7;
			_gaoqingdetail.y = -40;
			_gaoqingdetail.addEventListener(MouseEvent.CLICK, mouseClickHandler);
			addChild(_gaoqingdetail);
			
			_chaoqingdetail = new FormatShowDetailBtn("超清");
			_chaoqingdetail.x = 7;
			_chaoqingdetail.y = -20;
			_chaoqingdetail.addEventListener(MouseEvent.CLICK, mouseClickHandler);
			addChild(_chaoqingdetail);
		}
		
		private function mouseClickHandler(e:MouseEvent):void
		{
			var clickQulityEvent:SetQulityEvent = new SetQulityEvent(SetQulityEvent.CLICK_QULITY);
			dispatchEvent(clickQulityEvent);
			
			var changeto:String = SetQulityEvent.NORMAL_QULITY;
			if (e.target == _biaoqingdetail) {
				if (!_biaoqingdetail.isEnable) return;
				JTracer.sendMessage("mouseClickHandler点到标清了...");
				_biaoqingdetail.setSelected(true);
				_gaoqingdetail.setSelected(false);
				_chaoqingdetail.setSelected(false);
				changeto = SetQulityEvent.STANDARD_QULITY;
			} else if (e.target == _gaoqingdetail) {
				if (!_gaoqingdetail.isEnable) return;
				JTracer.sendMessage("mouseClickHandler点到高清了...");
				_biaoqingdetail.setSelected(false);
				_gaoqingdetail.setSelected(true);
				_chaoqingdetail.setSelected(false);
				changeto = SetQulityEvent.HEIGH_QULITY;
			} else if (e.target == _chaoqingdetail) {
				if (!_chaoqingdetail.isEnable) return;
				JTracer.sendMessage("mouseClickHandler点到超清了...");
				_biaoqingdetail.setSelected(false);
				_gaoqingdetail.setSelected(false);
				_chaoqingdetail.setSelected(true);
				changeto = SetQulityEvent.SUPERHEIGH_QULITY;
			}
			var setQulityEvent:SetQulityEvent = new SetQulityEvent(SetQulityEvent.CHANGE_QUILTY,changeto);
			dispatchEvent(setQulityEvent);
		}
		
		public function showLayer(formats:Object):void
		{
			for (var item:* in formats)
			{
				trace("item:" + item + "---" + formats[item]);
			}
			
			if (formats && formats.p && formats.p.enable)
			{
				_biaoqingdetail.setEnable(true);
			}else {
				_biaoqingdetail.setEnable(false);
			}
			
			if (formats && formats.g && formats.g.enable)
			{
				_gaoqingdetail.setEnable(true);
			}else {
				_gaoqingdetail.setEnable(false);
			}
			
			if (formats && formats.c && formats.c.enable)
			{
				_chaoqingdetail.setEnable(true);
			}else {
				_chaoqingdetail.setEnable(false);
			}
		}
		
		public function set detail(str:String):void
		{
			if (str == 'p') {
				_biaoqingdetail.setSelected(true);
				_biaoqingdetail.setCurrentEnable(false);
				_gaoqingdetail.setSelected(false);
				_chaoqingdetail.setSelected(false);
			} else if (str == 'g') {
				_biaoqingdetail.setSelected(false);
				_gaoqingdetail.setSelected(true);
				_gaoqingdetail.setCurrentEnable(false);
				_chaoqingdetail.setSelected(false);
			} else if (str == "c") {
				_biaoqingdetail.setSelected(false);
				_gaoqingdetail.setSelected(false);
				_chaoqingdetail.setSelected(true);
				_chaoqingdetail.setCurrentEnable(false);
			} else {
				_biaoqingdetail.setSelected(false);
				_gaoqingdetail.setSelected(false);
				_chaoqingdetail.setSelected(false);
			}
		}
	}
}