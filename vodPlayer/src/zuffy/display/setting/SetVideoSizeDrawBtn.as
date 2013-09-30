package zuffy.display.setting 
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	/**
	 * ...
	 * @author Drgon.S
	 */
	public class SetVideoSizeDrawBtn extends Sprite
	{
		private var _buttonText:TextField = new TextField();
		private var _button:SetCheckButton;
		private var _msg:String = '';
		
		public function SetVideoSizeDrawBtn(name:String,msg:String) 
		{
			_button = new SetCheckButton();
			
			_msg = msg;
			_buttonText.text = name;
			_buttonText.width = 55;
			_buttonText.height = 16;
			_buttonText.x = 20;
			_buttonText.selectable = false;
			addChild(_buttonText);
			addChild(_button);
			setNormalStyle();
		}
		
		private function setNormalStyle():void
		{
			_buttonText.setTextFormat(new TextFormat('宋体', 12, 0xc1c1c1));
			_button.gotoAndStop(1);
		}
		
		private function setFocusStyle():void
		{
			_buttonText.setTextFormat(new TextFormat('宋体', 12, 0xc1c1c1));
			_button.gotoAndStop(2);
		}
		
		public function get buttonMessage():*
		{
			return _msg;
		}
		
		public function set setFocus(isFocus:Boolean):void
		{
			if (isFocus) {
				setFocusStyle();
			}else {
				setNormalStyle();
			}
		}
		
	}

}