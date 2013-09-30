package zuffy.display.format 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class CurrentFormatBtn extends MovieClip 
	{
		private var _showText:TextField;
		private var _selectFormat:TextFormat;
		private var _disableFormat:TextFormat;
		private var _curFormat:String;
		private var _isEnabled:Boolean;
		
		public function CurrentFormatBtn() 
		{
			_selectFormat = new TextFormat('宋体', 12, 0x0E90D9, false);
			_disableFormat = new TextFormat('宋体', 12, 0x444444, false);
			
			_showText = new TextField();
			_showText.width = 45;
			_showText.height = 18;
			_showText.x = 7;
			_showText.y = 4;
			addChild(_showText);
			
			_curFormat = "流畅";
			_showText.text = _curFormat;
			isEnabled = false;
		}
		
		public function set isClicked(boo:Boolean):void
		{
			if (boo)
			{
				if (_isEnabled)
				{
					arrow_mc.gotoAndStop(4);
				}
				else
				{
					arrow_mc.gotoAndStop(3);
				}
			}
			else
			{
				if (_isEnabled)
				{
					arrow_mc.gotoAndStop(4);
				}
				else
				{
					arrow_mc.gotoAndStop(3);
				}
			}
		}
		
		public function showLayer(formats:Object):void
		{
			_curFormat = "";
			if (formats && formats.g && formats.g.checked == true) {
				_curFormat = '高清';
			} else if (formats && formats.p && formats.p.checked == true) {
				_curFormat = '流畅';
			} else if (formats && formats.y && formats.y.checked == true) {
				_curFormat = '原始';
			} else if (formats && formats.c && formats.c.checked == true) {
				_curFormat = '超清';
			}
			
			if (_curFormat == "")
			{
				_curFormat = "流畅";
				_showText.text = _curFormat;
				isEnabled = false;
				return;
			}
			
			_showText.text = _curFormat;
			isEnabled = true;
		}
		
		public function set showBtn(str:String):void
		{
			_curFormat = "";
			switch(str)
			{
				case "y":
					_curFormat = "原始";
					break;
				case "p":
					_curFormat = "流畅";
					break;
				case "g":
					_curFormat = "高清";
					break;
				case "c":
					_curFormat = "超清";
					break;
			}
			
			if (_curFormat == "")
			{
				_curFormat = "流畅";
				_showText.text = _curFormat;
				isEnabled = false;
				return;
			}
			
			_showText.text = _curFormat;
			isEnabled = true;
		}
		
		private function get isEnabled():Boolean
		{
			return _isEnabled;
		}
		
		private function set isEnabled(boo:Boolean):void
		{
			_isEnabled = boo;
			
			if (boo)
			{
				this.mouseChildren = false;
				this.buttonMode = true;
				this.mouseEnabled = true;
				
				_showText.setTextFormat(_selectFormat);
				arrow_mc.gotoAndStop(4);
				
				this.addEventListener(MouseEvent.CLICK, clickFormatBtn);
			}
			else
			{
				this.mouseChildren = false;
				this.buttonMode = false;
				this.mouseEnabled = false;
				
				_showText.setTextFormat(_disableFormat);
				arrow_mc.gotoAndStop(3);
				
				this.removeEventListener(MouseEvent.CLICK, clickFormatBtn);
			}
		}
		
		private function clickFormatBtn(evt:MouseEvent):void
		{
			dispatchEvent(new Event("clickCurrentFormat"));
		}
	}
}