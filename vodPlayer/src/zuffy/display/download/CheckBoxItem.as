package zuffy.display.download 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextFormat;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class CheckBoxItem extends MovieClip 
	{
		private var _normalFormat:TextFormat;
		private var _disableFormat:TextFormat;
		private var _selected:Boolean;
		private var _enable:Boolean;
		private var _format:String;
		
		public function CheckBoxItem() 
		{
			_normalFormat = new TextFormat();
			_normalFormat.color = 0xFFFFFF;
			_normalFormat.size = 12;
			_normalFormat.font = "宋体";
			
			_disableFormat = new TextFormat();
			_disableFormat.color = 0x353535;
			_disableFormat.size = 12;
			_disableFormat.font = "宋体";
			
			select_btn.mouseEnabled = false;
			select_btn.addEventListener(MouseEvent.MOUSE_OVER, onOver);
			select_btn.addEventListener(MouseEvent.MOUSE_OUT, onOut);
			select_btn.addEventListener(MouseEvent.CLICK, onClick);
		}
		
		public function set formatText(str:String):void
		{
			format_txt.defaultTextFormat = _disableFormat;
			format_txt.selectable = false;
			format_txt.text = str;
			format_txt.width = format_txt.textWidth + 10;
			
			select_btn.width = format_txt.x + format_txt.textWidth;
		}
		
		public function set tipsText(str:String):void
		{
			tips_txt.defaultTextFormat = _disableFormat;
			tips_txt.selectable = false;
			tips_txt.text = str;
			tips_txt.width = tips_txt.textWidth + 10;
			tips_txt.x = 110;
		}
		
		override public function set enabled(boo:Boolean):void
		{
			_enable = boo;
			
			if (boo)
			{
				select_btn.mouseEnabled = true;
				check_mc.gotoAndStop(1);
				format_txt.setTextFormat(_normalFormat);
			}
			else
			{
				select_btn.mouseEnabled = false;
				check_mc.gotoAndStop(3);
				format_txt.setTextFormat(_disableFormat);
			}
		}
		
		override public function get enabled():Boolean
		{
			return _enable;
		}
		
		public function set selected(boo:Boolean):void
		{
			_selected = boo;
			
			if (boo)
			{
				check_mc.gotoAndStop(2);
			}
			else
			{
				check_mc.gotoAndStop(1);
			}
		}
		
		public function get selected():Boolean
		{
			return _selected;
		}
		
		public function set format(str:String):void
		{
			_format = str;
		}
		
		public function get format():String
		{
			return _format;
		}
		
		private function onOver(evt:MouseEvent):void
		{
			/*
			if (!_selected && _enable)
			{
				check_mc.gotoAndStop(2);
			}
			*/
		}
		
		private function onOut(evt:MouseEvent):void
		{
			/*
			if (!_selected && _enable)
			{
				check_mc.gotoAndStop(1);
			}
			*/
		}
		
		private function onClick(evt:MouseEvent):void
		{
			dispatchEvent(new Event("SelectItem"));
		}
	}

}