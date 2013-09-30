package zuffy.display.setting 
{
	import com.common.Cookies;
	import com.common.JTracer;
	import com.common.Tools;
	import com.global.GlobalVars;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.Point;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.setTimeout;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class CommonSlider extends Sprite 
	{
		public static const CHANGE_VALUE:String = "change_value";
		
		private var _controlTxt:TextField;
		private var _controlBar:FilterControlBar;
		private var _controlBtn:FilterControlBtn;
		private var _controlUpBtn:Sprite;
		private var _controlDownBtn:Sprite;
		private var _barWidth:Number = 234;
		private var _btnWidth:Number = 12;
		private var _btnHeight:Number = 12;
		private var _minValue:Number;
		private var _maxValue:Number;
		private var _snapInterval:Number;
		private var _clickInterval:Number;
		private var _currentX:Number;
		private var _currentValue:Number;
		private var _isShowToolTip:Boolean;
		private var _isFormatTip:Boolean;
		private var _isSupportHover:Boolean;
		private var _isThumbIconHasStatus:Boolean;
		private var _prefixTip:String = "";
		private var _unit:String = "";
		private var _mouseX:Number;
		private var _decimalNum:int;
		private var _shortcuts:ShortcutsTips;
		private var _defLevel:Number;
		private var _aveLevel:Number;
		private var _controllType:String;
		
		public function CommonSlider() 
		{
			initControlUI();
		}
		
		private function initControlUI():void
		{
			_controlBar = new FilterControlBar();
			_controlBar.width = _barWidth;
			_controlBar.buttonMode = true;
			_controlBar.x = 92;
			_controlBar.y = -6;
			_controlBar.addEventListener(MouseEvent.CLICK, barClickHandler);
			_controlBar.addEventListener(MouseEvent.MOUSE_OVER, barOverHandler);
			_controlBar.addEventListener(MouseEvent.MOUSE_OUT, barOutHandler);
			addChild(_controlBar);
			
			_controlBtn = new FilterControlBtn();
			_controlBtn.x = _controlBar.x + _barWidth / 2 - _controlBtn.width / 2;
			_controlBtn.y = -7;
			_controlBtn.buttonMode = true;
			_controlBtn.addEventListener(MouseEvent.MOUSE_DOWN, btnMouseDownHandler);
			_controlBtn.addEventListener(MouseEvent.MOUSE_OVER, btnOverHandler);
			_controlBtn.addEventListener(MouseEvent.MOUSE_OUT, btnOutHandler);
			addChild(_controlBtn);
			
			_controlDownBtn = drawDownBtn();
			_controlDownBtn.x = 74;
			_controlDownBtn.y = -7;
			_controlDownBtn.addEventListener(MouseEvent.MOUSE_DOWN, controlDownHandler);
			addChild(_controlDownBtn);
			
			_controlUpBtn = drawUpBtn();
			_controlUpBtn.x = _controlBar.x + _barWidth + 5;
			_controlUpBtn.y = -7;
			_controlUpBtn.addEventListener(MouseEvent.MOUSE_DOWN, controlUpHandler);
			addChild(_controlUpBtn);
			
			if (stage)
			{
				initStage();
			}
			else
			{
				addEventListener(Event.ADDED_TO_STAGE, initStage);
			}
		}
		
		public function subTimeDelta(interval:Number, isShowTips:Boolean = true, displayObj:DisplayObject = null, type:String = ""):void
		{
			_controllType = type;
			
			stage.addEventListener(MouseEvent.MOUSE_UP, controlMouseUpHandler);
			
			currentValue -= interval;
			if (currentValue < _minValue)
			{
				currentValue = _minValue;
			}
			
			if (isShowTips)
			{
				showToolTip(displayObj);
			}
		}
		
		public function addTimeDelta(interval:Number, isShowTips:Boolean = true, displayObj:DisplayObject = null, type:String = ""):void
		{
			_controllType = type;
			
			stage.addEventListener(MouseEvent.MOUSE_UP, controlMouseUpHandler);
			
			currentValue += interval;
			if (currentValue > _maxValue)
			{
				currentValue = _maxValue;
			}
			
			if (isShowTips)
			{
				showToolTip(displayObj);
			}
		}
		
		private function drawDownBtn():Sprite
		{
			var btn:Sprite = new Sprite();
			var btnBg:Sprite = drawRect(_btnWidth, _btnHeight, 0xffffff, 0);
			var btnIcon:Sprite = drawRect(_btnWidth - 3, 1, 0x6c6b6b, 1);
			btnIcon.x = 1;
			btnIcon.y = 7;
			btn.addChild(btnBg);
			btn.addChild(btnIcon);
			btn.buttonMode = true;
			btn.mouseChildren = false;
			return btn;
		}
		
		private function drawUpBtn():Sprite
		{
			var btn:Sprite = new Sprite();
			var btnBg:Sprite = drawRect(_btnWidth, _btnHeight, 0xffffff, 0);
			var btnIcon:Sprite = drawRect(_btnWidth - 3, 1, 0x6c6b6b, 1);
			btnIcon.x = 1;
			btnIcon.y = 7;
			var btnIcon2:Sprite = drawRect(_btnWidth - 3, 1, 0x6c6b6b, 1);
			btnIcon2.rotation = 90;
			btnIcon2.x = 6;
			btnIcon2.y = 3;
			btn.addChild(btnBg);
			btn.addChild(btnIcon);
			btn.addChild(btnIcon2);
			btn.buttonMode = true;
			btn.mouseChildren = false;
			return btn;
		}
		
		private function drawRect(w:Number, h:Number, color:uint, alpha:Number):Sprite
		{
			var sSprite:Sprite = new Sprite();
			sSprite.graphics.beginFill(color, alpha);
			sSprite.graphics.drawRect(0, 0, w, h);
			sSprite.graphics.endFill();
			return sSprite;
		}
		
		private function initStage(evt:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, initStage);
			
			stage.addEventListener(MouseEvent.CLICK, stageClickHandler);
		}
		
		private function stageClickHandler(e:MouseEvent):void
		{
			if (e.target != _controlBtn)
			{
				isThumbIconActive = false;
			}
			else
			{
				if (!isThumbIconActive)
				{
					isThumbIconActive = !isThumbIconActive;
				}
			}
		}
		
		private function barClickHandler(e:MouseEvent):void
		{
			_mouseX = this.mouseX - _controlBtn.width / 2;
			if (_mouseX <= _controlBar.x)
			{
				_mouseX = _controlBar.x;
			}
			if (_mouseX >= _controlBar.x + _barWidth - _controlBtn.width)
			{
				_mouseX = _controlBar.x + _barWidth - _controlBtn.width;
			}
			
			currentValue = (_maxValue - _minValue) * (_mouseX - _controlBar.x) / (_barWidth - _controlBtn.width) + _minValue;
		}
		
		private function barOverHandler(e:MouseEvent):void
		{
			if (_isSupportHover)
			{
				showToolTip(_controlBtn);
			}
		}
		
		private function barOutHandler(e:MouseEvent):void
		{
			if (_isSupportHover)
			{
				hideToolTip();
			}
		}
		
		private function btnMouseDownHandler(e:MouseEvent):void
		{
			stageClickHandler(e);
			
			showToolTip(_controlBtn);
			
			stage.addEventListener(MouseEvent.MOUSE_MOVE, btnMouseMoveHandler);
			stage.addEventListener(MouseEvent.MOUSE_UP, btnMouseUpHandler);
		}
		
		private function btnOverHandler(e:MouseEvent):void
		{
			if (_isSupportHover)
			{
				showToolTip(_controlBtn);
			}
		}
		
		private function btnOutHandler(e:MouseEvent):void
		{
			if (_isSupportHover)
			{
				hideToolTip();
			}
		}
		
		private function btnMouseMoveHandler(e:MouseEvent):void
		{
			_mouseX = this.mouseX - _controlBtn.width / 2;
			if (_mouseX <= _controlBar.x)
			{
				_mouseX = _controlBar.x;
			}
			if (_mouseX >= _controlBar.x + _barWidth - _controlBtn.width)
			{
				_mouseX = _controlBar.x + _barWidth - _controlBtn.width;
			}
			
			currentValue = (_maxValue - _minValue) * (_mouseX - _controlBar.x) / (_barWidth - _controlBtn.width) + _minValue;
			
			showToolTip(_controlBtn);
		}
		
		private function btnMouseUpHandler(e:MouseEvent):void
		{
			hideToolTip();
			
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, btnMouseMoveHandler);
			stage.removeEventListener(MouseEvent.MOUSE_UP, btnMouseUpHandler);
		}
		
		private function controlDownHandler(e:MouseEvent):void
		{
			subTimeDelta(_clickInterval, true, _controlDownBtn);
		}
		
		private function controlUpHandler(e:MouseEvent):void
		{
			addTimeDelta(_clickInterval, true, _controlUpBtn);
		}
		
		private function controlMouseUpHandler(e:MouseEvent):void
		{
			hideToolTip();
			
			stage.removeEventListener(MouseEvent.MOUSE_UP, controlMouseUpHandler);
		}
		
		private function setControllBtnPos(xPos:Number):void
		{
			_controlBtn.x = xPos;
			if (_controlBtn.x <= _controlBar.x)
				_controlBtn.x = _controlBar.x;
			if (_controlBtn.x >= _controlBar.x + _barWidth - _controlBtn.width)
				_controlBtn.x = _controlBar.x + _barWidth - _controlBtn.width;
			
			_controlBar.mask_mc.width = _controlBtn.x - _controlBar.x + _controlBtn.width / 2;
			
			if (_shortcuts)
			{
				setShortcutsPos();
			}
		}
		
		private function showToolTip(target:DisplayObject):void
		{
			if (_shortcuts)
			{
				return;
			}
			
			if (_isShowToolTip)
			{
				var globalPt:Point = target.localToGlobal(new Point(0, 0));
				var prefixs:Array = _prefixTip.split("|");
				var tips:String = _isFormatTip ? (_currentValue < 0 ? prefixs[0] + Math.abs(_currentValue).toString() + _unit : prefixs[1] + Math.abs(_currentValue).toString() + _unit) : _currentValue.toString();
				
				Tools.showToolTip("   " + tips + "   ");
				Tools.moveToolTipToPoint(globalPt.x + target.width / 2 - Tools.toolTipWidth / 2, globalPt.y - 1);
			}
		}
		
		private function hideToolTip():void
		{
			if (_isShowToolTip)
			{
				Tools.hideToolTip();
			}
		}
		
		private function setShortcutsPos():void
		{
			_shortcuts.x = _controlBtn.x + _controlBtn.width / 2 - 41;
			_shortcuts.y = _controlBtn.y - 68;
		}
		
		private function hideShortcuts(evt:TextEvent = null):void
		{
			if (_shortcuts)
			{
				removeChild(_shortcuts);
				_shortcuts = null;
			}
			
			Cookies.setCookie('hideShortcutsTips', true);
		}
		
		public function showShortcuts():void
		{
			if (!_shortcuts)
			{
				var style:StyleSheet = new StyleSheet();
				style.setStyle('a', { textDecoration:'underline', fontFamily:'宋体' } );
				
				var tf:TextFormat = new TextFormat();
				tf.font = "宋体";
				
				_shortcuts = new ShortcutsTips();
				_shortcuts.info_txt.defaultTextFormat = tf;
				_shortcuts.info_txt.setTextFormat(tf);
				_shortcuts.know_txt.htmlText = " <a href='event:hide'>我知道了</a>";
				_shortcuts.know_txt.styleSheet = style;
				_shortcuts.know_txt.height = 20;
				_shortcuts.know_txt.addEventListener(TextEvent.LINK, hideShortcuts);
				addChild(_shortcuts);
				
				setShortcutsPos();
			}
			
			//setTimeout(hideShortcuts, 5000);
		}
		
		public function set title(str:String):void
		{
			var tf:TextFormat = new TextFormat("宋体");
			
			_controlTxt = new TextField();
			_controlTxt.text = str;
			_controlTxt.setTextFormat(tf);
			_controlTxt.x = 18;
			_controlTxt.y = -8;
			_controlTxt.width = _controlTxt.textWidth + 10;
			_controlTxt.height = 25;
			_controlTxt.textColor = 0xC1C1C1;
			_controlTxt.selectable = false;
			addChild(_controlTxt);
		}
		
		public function get currentValue():Number
		{
			return _currentValue;
		}
		
		public function set currentValue(value:Number):void
		{
			_currentValue = Number(value.toFixed(_decimalNum));
			
			if (currentValue < _minValue)
			{
				currentValue = _minValue;
			}
			if (currentValue > _maxValue)
			{
				currentValue = _maxValue;
			}
			
			_currentX = _controlBar.x + (_currentValue - _minValue) / (_maxValue - _minValue) * (_barWidth - _controlBtn.width);
			setControllBtnPos(_currentX);
			
			dispatchEvent(new Event(CHANGE_VALUE));
		}
		
		public function get minValue():Number
		{
			return _minValue;
		}
		
		public function set minValue(value:Number):void
		{
			_minValue = value;
		}
		
		public function get maxValue():Number
		{
			return _maxValue;
		}
		
		public function set maxValue(value:Number):void
		{
			_maxValue = value;
		}
		
		public function get snapInterval():Number
		{
			return _snapInterval;
		}
		
		public function set snapInterval(value:Number):void
		{
			_snapInterval = value;
		}
		
		public function get clickInterval():Number
		{
			return _clickInterval;
		}
		
		public function set clickInterval(value:Number):void
		{
			_clickInterval = value;
		}
		
		public function get decimalNum():int
		{
			return _decimalNum;
		}
		
		public function set decimalNum(value:int):void
		{
			_decimalNum = value;
		}
		
		public function get isShowToolTip():Boolean
		{
			return _isShowToolTip;
		}
		
		public function set isShowToolTip(value:Boolean):void
		{
			_isShowToolTip = value;
		}
		
		public function get isFormatTip():Boolean
		{
			return _isFormatTip;
		}
		
		public function set isFormatTip(value:Boolean):void
		{
			_isFormatTip = value;
		}
		
		public function get prefixTip():String
		{
			return _prefixTip;
		}
		
		public function set prefixTip(value:String):void
		{
			_prefixTip = value;
		}
		
		public function get unit():String
		{
			return _unit;
		}
		
		public function set unit(value:String):void
		{
			_unit = value;
		}
		
		public function get isSupportHover():Boolean
		{
			return _isSupportHover;
		}
		
		public function set isSupportHover(value:Boolean):void
		{
			_isSupportHover = value;
		}
		
		public function get isThumbIconHasStatus():Boolean
		{
			return _isThumbIconHasStatus;
		}
		
		public function set isThumbIconHasStatus(value:Boolean):void
		{
			_isThumbIconHasStatus = value;
		}
		
		public function get isThumbIconActive():Boolean
		{
			if (_isThumbIconHasStatus && _controlBtn.currentFrame == 2)
			{
				return true;
			}
			
			return false;
		}
		
		public function set isThumbIconActive(value:Boolean):void
		{
			if (_isThumbIconHasStatus)
			{
				_controlBtn.gotoAndStop(value ? 2 : 1);
			}
		}
		
		public function get controllBtn():DisplayObject
		{
			return _controlBtn;
		}
		
		public function get controllType():String
		{
			return _controllType;
		}
		
		public function set controllType(value:String):void
		{
			_controllType = value;
		}
		
		//------滤镜相关------//
		public function get defLevel():Number
		{
			return _defLevel;
		}
		
		public function set defLevel(value:Number):void
		{
			_defLevel = value;
		}
		
		public function get aveLevel():Number
		{
			return _aveLevel;
		}
		
		public function set aveLevel(value:Number):void
		{
			_aveLevel = value * 2 / _barWidth;
		}
		
		public function get level():Number
		{
			return _currentValue * _aveLevel * 95 / 100 + _defLevel;
		}
	}
}