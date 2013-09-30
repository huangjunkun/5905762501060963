package zuffy.display.format 
{
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldAutoSize;
	import flash.events.MouseEvent;
	
	/**
	 * ...
	 * @author Dragon.S
	 */
	public class FormatShowDetailBtn extends MovieClip
	{
		private var _showText:TextField;
		private var _count:Number = 0;
		private var _blueCircle:BlueCircle;
		private var _selectFormat:TextFormat;
		private var _noselectFormat:TextFormat;
		private var _disableFormat:TextFormat;
		private var _isEnable:Boolean = true;
		
		public function FormatShowDetailBtn(name:String) 
		{
			_selectFormat = new TextFormat('宋体', 12, 0x0E90D9, false);
			_noselectFormat = new TextFormat('宋体', 12, 0x9B9B9B, false);
			_disableFormat = new TextFormat('宋体', 12, 0x333333, false);
			
			_blueCircle = new BlueCircle();
			_blueCircle.gotoAndStop(3);
			_blueCircle.visible = false;
			_blueCircle.x = 36;
			_blueCircle.y = 8;
			addChild(_blueCircle);
			
			_showText = new TextField();
			_showText.defaultTextFormat = _disableFormat;
			_showText.width = 45;
			_showText.height = 18;
			_showText.text = name;
			addChild(_showText);
			
			this.mouseChildren = false;
			this.buttonMode = true;
			
			setEnable(false);
			
			this.addEventListener(MouseEvent.MOUSE_DOWN, mouseEventHandler);
			this.addEventListener(MouseEvent.MOUSE_UP, mouseEventHandler);
			this.addEventListener(MouseEvent.MOUSE_OUT, mouseEventHandler);
		}
		
		private function mouseEventHandler(e:MouseEvent):void
		{
			switch(e.type) {
				case MouseEvent.MOUSE_DOWN:
					this._count++;
					this._count = Math.min(_count, 1);
					this.x += this._count;
					this.y += this._count;
					break;
				case MouseEvent.MOUSE_UP:
				case MouseEvent.MOUSE_OUT:
					this.x -= this._count;
					this.y -= this._count;
					this._count --;
					this._count = Math.max(_count, 0);
					break;
				
			}
		}
		
		public function set text(str:String):void
		{
			_showText.text = str;
		}
		
		public function get isEnable():Boolean { return _isEnable; }
		
		public function setSelected(isBool:Boolean):void
		{
			if (isBool)
			{
				_showText.defaultTextFormat = _selectFormat;
				_showText.setTextFormat(_selectFormat);
				_blueCircle.gotoAndStop(2);
				_blueCircle.visible = true;
			}else {
				if (_isEnable)
				{
					_showText.defaultTextFormat = _noselectFormat;
					_showText.setTextFormat(_noselectFormat);
					_blueCircle.gotoAndStop(1);
					_blueCircle.visible = false;
				}
				else
				{
					_showText.defaultTextFormat = _disableFormat;
					_showText.setTextFormat(_disableFormat);
					_blueCircle.gotoAndStop(3);
					_blueCircle.visible = false;
				}
			}
		}
		
		public function setEnable(isBool:Boolean):void
		{
			if (isBool)
			{
				_isEnable = true;
				this.buttonMode = true;
			}else {
				_isEnable = false;
				this.buttonMode = false;
			}
		}
		
		public function setCurrentEnable(isBool:Boolean):void
		{
			if (isBool)
			{
				_isEnable = true;
				this.buttonMode = true;
			}else {
				_isEnable = false;
				this.buttonMode = false;
			}
		}
		
	}

}