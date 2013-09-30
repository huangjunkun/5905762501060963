package zuffy.display.setting 
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.events.MouseEvent;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author Drgon.S
	 */
	public class SetDrawOption extends Sprite
	{
		public static const SELECTED:String = 'selected';
		private var _isFocus:Boolean = false;
		private var _optionFace:Sprite = new Sprite();
		private var _optionText:TextField = new TextField();
		private var _defaultBack:SetDefaultOptionBack = new SetDefaultOptionBack();
		private var _selectedBack:SetSelectedOptionBack = new SetSelectedOptionBack();
		
		public function SetDrawOption(str:String) 
		{
			_optionText.text = str;
			_optionText.setTextFormat(new TextFormat('宋体', 12, 0x444444, false));
			_optionText.width = 72;
			_optionText.height = 27;
			_optionText.x = 2;
			_optionText.y = 4;
			_optionText.autoSize = TextFieldAutoSize.CENTER;
			
			_optionFace.graphics.beginFill(0xffffff, 0);
			_optionFace.graphics.drawRect(0, 0, 72, 27);
			_optionFace.graphics.endFill();
			_optionFace.buttonMode = true;
			_optionFace.addEventListener(MouseEvent.CLICK, optionClickHandler);
			_optionFace.addEventListener(MouseEvent.MOUSE_OVER, optionMouseOverHandler);
			_optionFace.addEventListener(MouseEvent.MOUSE_OUT, optionMouseOutHandler);
			
			addChild(_defaultBack);
			addChild(_selectedBack);
			addChild(_optionText);
			addChild(_optionFace);
			
			_defaultBack.visible = true;
			_selectedBack.visible = false;
		}
		
		private function optionClickHandler(e:MouseEvent):void
		{
			_optionFace.buttonMode = false;
			_defaultBack.visible = false;
			_selectedBack.visible = true;
			_optionText.setTextFormat(new TextFormat('宋体', 12, 0xFFFFFF, true));
			dispatchEvent(new Event(SELECTED));
		}
		
		private function optionMouseOutHandler(e:MouseEvent):void
		{
			if (_optionFace.buttonMode)
			{
				_optionText.setTextFormat(new TextFormat('宋体', 12, 0x444444, false));
			}
		}
		
		private function optionMouseOverHandler(e:MouseEvent):void
		{
			if (_optionFace.buttonMode)
			{
				_optionText.setTextFormat(new TextFormat('宋体', 12, 0x4993E6, false));
			}
		}
		
		public function set optionFocus(isFocus:Boolean):void
		{
			if (isFocus) {
				_optionFace.buttonMode = false;
				_defaultBack.visible = false;
				_selectedBack.visible = true;
				_optionText.setTextFormat(new TextFormat('宋体', 12, 0xFFFFFF, true));
			}else {
				_optionFace.buttonMode = true;
				_defaultBack.visible = true;
				_selectedBack.visible = false;
				_optionText.setTextFormat(new TextFormat('宋体', 12, 0x444444, false));
			}
			_isFocus = isFocus;
		}
		
		public function get optionText():String
		{
			return _optionText.text;
		}
		
	}

}