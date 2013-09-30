package zuffy.display.setting 
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	/**
	 * ...
	 * @author Drgon.S
	 */
	public class SetDrawCheckButton extends Sprite
	{
		private var _checkButton:SetCheckButton = new SetCheckButton();
		private var _checkButtonText:TextField = new TextField();
		private var _checkTipsText:TextField = new TextField();
		private var _msg:* = null;
		private var _isFocus:Boolean = false;
		private var _isEnabled:Boolean = true;
		
		public function SetDrawCheckButton(txt:String, msg:* = null, tips:String = null) 
		{
			_msg = msg;
			_checkButtonText.text = txt;
			_checkButtonText.width = _checkButtonText.textWidth + 10;
			_checkButtonText.height = 16;
			_checkButtonText.x = 20;
			_checkButtonText.selectable = false;
			addChild(_checkButtonText);
			if (tips)
			{
				_checkTipsText.defaultTextFormat = new TextFormat('宋体', 12, 0x666666);
				_checkTipsText.text = tips;
				_checkTipsText.width = _checkTipsText.textWidth + 10;
				_checkTipsText.height = 16;
				_checkTipsText.x = _checkButtonText.x + _checkButtonText.textWidth;
				_checkTipsText.selectable = false;
				addChild(_checkTipsText);
			}
			addChild(_checkButton);
			setNormalStyle();
		}
		
		private function setNormalStyle():void
		{
			this.mouseChildren = true;
			this.mouseEnabled = true;
			
			_checkButtonText.setTextFormat(new TextFormat('宋体', 12, 0xc1c1c1));
			_checkButton.gotoAndStop(1);
		}
		
		private function setFocusStyle():void
		{
			this.mouseChildren = true;
			this.mouseEnabled = true;
			
			_checkButtonText.setTextFormat(new TextFormat('宋体', 12, 0xc1c1c1));
			_checkButton.gotoAndStop(2);
		}
		
		private function setDisableStyle():void
		{
			this.mouseChildren = false;
			this.mouseEnabled = false;
			
			_checkButtonText.setTextFormat(new TextFormat('宋体', 12, 0x666666));
			_checkButton.gotoAndStop(3);
		}
		
		public function get buttonMessage():*
		{
			return _msg;
		}
		
		public function set setFocus(isFocus:Boolean):void
		{
			_isFocus = isFocus;
			
			if (_isEnabled)
			{
				if (_isFocus)
				{
					setFocusStyle();
				}
				else
				{
					setNormalStyle();
				}
			}
		}
		
		public function set setEnabled(isEnabled:Boolean):void
		{
			_isEnabled = isEnabled;
			
			if (_isEnabled)
			{
				setNormalStyle();
			}
			else
			{
				setDisableStyle();
			}
		}
	}

}