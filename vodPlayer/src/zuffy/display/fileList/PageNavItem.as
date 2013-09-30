package zuffy.display.fileList 
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.engine.EastAsianJustifier;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class PageNavItem extends Sprite 
	{
		private var _pageText:TextField;
		private var _pageNum:uint;
		private var _selected:Boolean;
		private var _enabled:Boolean;
		private var _disabledTF:TextFormat;
		private var _overTF:TextFormat;
		private var _outTF:TextFormat;
		private var _width:Number;
		
		public function PageNavItem(w:Number) 
		{
			_width = w;
			
			_pageText = new TextField();
			_pageText.width = _width;
			addChild(_pageText);
			
			this.buttonMode = true;
			this.mouseChildren = false;
			this.mouseEnabled = false;
			this.addEventListener(MouseEvent.MOUSE_OVER, onOver);
			this.addEventListener(MouseEvent.MOUSE_OUT, onOut);
			this.addEventListener(MouseEvent.CLICK, onClick);
			
			_overTF = new TextFormat();
			_overTF.color = 0x3990DF;
			_overTF.underline = true;
			_overTF.size = 13;
			_overTF.align = TextFieldAutoSize.CENTER;
			_overTF.font = "宋体";
			
			_outTF = new TextFormat();
			_outTF.color = 0xeeeeee;
			_outTF.underline = false;
			_outTF.size = 13;
			_outTF.align = TextFieldAutoSize.CENTER;
			_outTF.font = "宋体";
			
			_disabledTF = new TextFormat();
			_disabledTF.color = 0x666666;
			_disabledTF.underline = false;
			_disabledTF.size = 13;
			_disabledTF.bold = true;
			_disabledTF.align = TextFieldAutoSize.CENTER;
			_disabledTF.font = "宋体";
		}
		
		public function setLabel(str:String):void
		{
			_pageText.defaultTextFormat = _outTF;
			_pageText.selectable = false;
			_pageText.text = str;
			_pageText.height = _pageText.textHeight + 5;
			_pageText.x = (_width - _pageText.width) / 2;
			
			drawBackground(0xffffff, 0);
		}
		
		public function set selected(boo:Boolean):void
		{
			_selected = boo;
			this.mouseEnabled = !boo;
			
			if (boo)
			{
				_pageText.setTextFormat(_disabledTF);
			}
			else
			{
				_pageText.setTextFormat(_outTF);
			}
		}
		
		public function get selected():Boolean
		{
			return _selected;
		}
		
		public function set enabled(boo:Boolean):void
		{
			_enabled = boo;
			this.mouseEnabled = boo;
			_pageText.setTextFormat(_outTF);
		}
		
		public function get enabled():Boolean
		{
			return _enabled;
		}
		
		public function set pageNum(num:uint):void
		{
			_pageNum = num;
		}
		
		public function get pageNum():uint
		{
			return _pageNum;
		}
		
		private function onOver(evt:MouseEvent):void
		{
			if (!_selected && _enabled)
			{
				_pageText.setTextFormat(_overTF);
			}
		}
		
		private function onOut(evt:MouseEvent):void
		{
			if (!_selected && _enabled)
			{
				_pageText.setTextFormat(_outTF);
			}
		}
		
		private function onClick(evt:MouseEvent):void
		{
			dispatchEvent(new Event("SelectPageItem"));
		}
		
		private function drawBackground(color:uint, alpha:Number):void
		{
			this.graphics.clear();
			this.graphics.beginFill(color, alpha);
			this.graphics.drawRect(0, 0, _width, 20);
			this.graphics.endFill();
		}
	}

}