package ctr.filter
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.printing.PrintJobOrientation;
	import flash.text.TextField;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.EventDispatcher;
	import flash.text.TextFormatAlign;
	import com.common.JTracer;
	import com.common.Tools;
	/**
	 * ...
	 * @author Drgon.S
	 */
	public class FilterUI extends Sprite  
	{
		public static const CHANGE_FILTER:String = 'change_filter';
		public static const CHANGE_FILTER_MODE:String = 'change_filter_mode';
		public static const ADD_VALUE:String = 'add_value';
		public static const SUB_VALUE:String = 'sub_value';
		public var multiply:Number;
		public var minValue:Number;
		private var _barWidth:Number = 234;
		private var _barHeight:Number = 10;
		private var _btnWidth:Number = 18;
		private var _btnHeight:Number = 12;
		private var _defLevel:Number; //默认值
		private var _aveLevel:Number; //平均值
		private var _ctrLevel:Number;
		private var _controlBar:FilterControlBar;
		private var _controlBtn:FilterControlBtn;
		private var _controlTxt:TextField;
		private var _controlTitle:String;
		private var _currentCount:Number;//等于控制按钮的X坐标
		private var _controlUpBtn:Sprite;
		private var _controlDownBtn:Sprite;
		private var _perCount:Number = 3;
		private var _recordPos:Number;
		private var _isStepSlider:Boolean;
		private var _isShowTooltip:Boolean;
		private var _curValue:int;
		
		public function FilterUI(defaul:Number,dec:Number)
		{
			this._defLevel = defaul;
			this._aveLevel = dec * 2 / _barWidth;
			this.initControlUI();
		}
		
		private function initControlUI():void
		{
			this._controlBar = new FilterControlBar();
			this._controlBar.width = _barWidth;
			this._controlBar.mouseEnabled = true;
			this._controlBar.buttonMode = true;
			this._controlBtn = new FilterControlBtn();
			this._controlBtn.buttonMode = true;
			this._controlUpBtn = drawUpBtn();
			this._controlDownBtn = drawDownBtn();
			this.addChild(_controlBar);
			this.addChild(_controlBtn);
			this.addChild(_controlDownBtn);
			this.addChild(_controlUpBtn);
			this._controlBar.x = 92;
			this._controlBar.y = -6;
			this._controlBtn.x = _barWidth / 2 + this._controlBar.x - this._controlBtn.width / 2;
			this._controlBtn.y = -7;
			this._controlDownBtn.x = 74;
			this._controlUpBtn.x = int(_controlBar.x + _barWidth + 5);
			this._controlDownBtn.y = this._controlUpBtn.y = -7;
			
			this._controlBar.addEventListener(MouseEvent.CLICK, barClickHandler);
			this._controlBtn.addEventListener(MouseEvent.MOUSE_DOWN, btnMouseDownHandler);
			this._controlDownBtn.addEventListener(MouseEvent.MOUSE_DOWN, controlDownHandler);
			this._controlUpBtn.addEventListener(MouseEvent.MOUSE_DOWN, controlUpHandler);
			
			_currentCount = _barWidth / 2 + _controlBar.x - _controlBtn.width / 2;
			recordPosition();
			updateBarWidth();
		}
		
		private function controlDownHandler(e:MouseEvent):void
		{
			this._controlDownBtn.stage.addEventListener(MouseEvent.MOUSE_UP, controlMouseUpHandler);
			
			if (_isStepSlider)
			{
				dispatchEvent(new Event(SUB_VALUE));
				showToolTip(this._controlDownBtn);
				return;
			}
			
			var dex_x:Number = _currentCount - _perCount - _barWidth / 2 - _controlBar.x;
			this._controlBtn.x = _currentCount = dex_x + _barWidth / 2 + _controlBar.x;
			if (this._controlBtn.x <= this._controlBar.x )
				this._controlBtn.x = this._controlBar.x;
			if (this._controlBtn.x >= this._controlBar.x + _barWidth - _btnWidth + 1)
				this._controlBtn.x = this._controlBar.x + _barWidth - _btnWidth + 1;
			dex_x = this._controlBtn.x - _barWidth / 2 - _controlBar.x + _controlBtn.width / 2;
			this._currentCount = this._controlBtn.x;
			this._ctrLevel = dex_x * _aveLevel + _defLevel;
			updateBarWidth();
			dispatchEvent(new Event(CHANGE_FILTER));
		}
		
		private function controlMouseUpHandler(e:MouseEvent):void
		{
			hideToolTip();
			
			this._controlDownBtn.stage.removeEventListener(MouseEvent.MOUSE_UP, controlMouseUpHandler);
			this._controlUpBtn.stage.removeEventListener(MouseEvent.MOUSE_UP, controlMouseUpHandler);
		}
		
		private function controlUpHandler(e:MouseEvent):void
		{
			this._controlUpBtn.stage.addEventListener(MouseEvent.MOUSE_UP, controlMouseUpHandler);
			
			if (_isStepSlider)
			{
				dispatchEvent(new Event(ADD_VALUE));
				showToolTip(this._controlUpBtn);
				return;
			}
			
			var dex_x:Number = _currentCount + _perCount - _barWidth / 2 - _controlBar.x;
			this._controlBtn.x = _currentCount = dex_x + _barWidth / 2 + _controlBar.x;
			if (this._controlBtn.x <= this._controlBar.x )
				this._controlBtn.x = this._controlBar.x;
			if (this._controlBtn.x >= this._controlBar.x + _barWidth - _btnWidth + 1)
				this._controlBtn.x = this._controlBar.x + _barWidth - _btnWidth + 1;
			dex_x = this._controlBtn.x - _barWidth / 2 - _controlBar.x + _controlBtn.width / 2;
			this._currentCount = this._controlBtn.x;
			this._ctrLevel = dex_x * _aveLevel + _defLevel;
			updateBarWidth();
			dispatchEvent(new Event(CHANGE_FILTER));
		}
		
		private function btnMouseDownHandler(e:MouseEvent):void
		{
			showToolTip(this._controlBtn);
			
			this._controlBtn.stage.addEventListener(MouseEvent.MOUSE_UP, btnMouseUpHandler);
			this._controlBtn.stage.addEventListener(MouseEvent.MOUSE_MOVE, btnMouseMoveHandler);
		}
		
		private function btnMouseUpHandler(e:MouseEvent):void
		{
			hideToolTip();
			
			this._controlBtn.stage.removeEventListener(MouseEvent.MOUSE_MOVE, btnMouseMoveHandler);
			this._controlBtn.stage.removeEventListener(MouseEvent.MOUSE_UP, btnMouseUpHandler);
		}
		
		private function btnMouseMoveHandler(e:MouseEvent):void
		{
			showToolTip(this._controlBtn);
			
			this._controlBtn.x = _currentCount = e.stageX - getStagePosition(this).x - _controlBtn.width / 2;
			if (this._controlBtn.x <= this._controlBar.x )
				this._controlBtn.x = this._controlBar.x;
			if (this._controlBtn.x >= this._controlBar.x + _barWidth - _btnWidth + 1)
				this._controlBtn.x = this._controlBar.x + _barWidth - _btnWidth + 1;
			var dex_x:Number = this._controlBtn.x - _barWidth / 2 - _controlBar.x + _controlBtn.width / 2;
			this._ctrLevel = dex_x * _aveLevel + _defLevel;
			updateBarWidth();
			dispatchEvent(new Event(CHANGE_FILTER));
		}
		
		private function showToolTip(target:DisplayObject):void
		{
			if (_isShowTooltip)
			{
				var globalPt:Point = target.localToGlobal(new Point(0, 0));
				
				Tools.showToolTip("   " + _curValue.toString() + "   ");
				Tools.moveToolTipToPoint(globalPt.x + target.width / 2 - 20, globalPt.y - 1);
			}
		}
		
		private function hideToolTip():void
		{
			if (_isShowTooltip)
			{
				Tools.hideToolTip();
			}
		}
		
		private function barClickHandler(e:MouseEvent):void
		{
			this._controlBtn.x = _currentCount = e.stageX - getStagePosition(this).x - _controlBtn.width / 2;
			if (this._controlBtn.x <= this._controlBar.x )
				this._controlBtn.x = this._controlBar.x;
			if (this._controlBtn.x >= this._controlBar.x + _barWidth - _btnWidth + 1)
				this._controlBtn.x = this._controlBar.x + _barWidth - _btnWidth + 1;
			var dex_x:Number = this._controlBtn.x - _barWidth / 2 - _controlBar.x + _controlBtn.width / 2;
			this._ctrLevel = dex_x * _aveLevel + _defLevel;
			updateBarWidth();
			dispatchEvent(new Event(CHANGE_FILTER));
		}
		
		private function updateBarWidth():void
		{
			this._controlBar.mask_mc.width = this._controlBtn.x - this._controlBar.x + _btnWidth / 2;
		}
		
		private function drawDownBtn():Sprite
		{
			var btn:Sprite = new Sprite();
			var btnBg:Sprite = drawCircleSize(_btnHeight, _btnHeight, 0xffffff);
			var btnIcon:Sprite = drawCircleSize(_btnHeight - 3, 1, 0x6c6b6b);
			var btnMace:Sprite = drawCircleSize(_btnHeight, _btnHeight, 0xffffff);
			btnIcon.x = 1;
			btnIcon.y = 7;
			btnMace.alpha = 0;
			btnBg.alpha = 0;
			btn.addChild(btnBg);
			btn.addChild(btnIcon);
			btn.addChild(btnMace);
			btn.buttonMode = true;
			return btn;
		}
		
		private function drawUpBtn():Sprite
		{
			var btn:Sprite = new Sprite();
			var btnBg:Sprite = drawCircleSize(_btnHeight, _btnHeight, 0xffffff);
			var btnIcon:Sprite = drawCircleSize(_btnHeight - 3, 1, 0x6c6b6b);
			var btnIcon2:Sprite = drawCircleSize(_btnHeight - 3, 1, 0x6c6b6b);
			btnIcon2.rotation = 90;
			var btnMace:Sprite = drawCircleSize(_btnHeight, _btnHeight, 0xffffff);
			btnIcon.x = 1;
			btnIcon.y = 7;
			btnIcon2.x = 6;
			btnIcon2.y = 3;
			btnMace.alpha = 0;
			btnBg.alpha = 0;
			btn.addChild(btnBg);
			btn.addChild(btnIcon);
			btn.addChild(btnIcon2);
			btn.addChild(btnMace);
			btn.buttonMode = true;
			return btn;
		}
		
		private function drawCircleSize(w:Number, h:Number,color:*):Sprite
		{
			var sSprite:Sprite = new Sprite();
			sSprite.graphics.beginFill(color, 1);
			sSprite.graphics.drawRect(0, 0, w, h);
			sSprite.graphics.endFill();
			sSprite.buttonMode = true;
			return sSprite;
		}
		
		private function drawButton():Sprite
		{
			var btnText:TextField = new TextField();
			btnText.text = 'RESET';
			btnText.textColor = 0xff0000;
			btnText.selectable = false;
			btnText.width = 50;
			btnText.height = 24;
			btnText.x = 5;
			var btnSpace:Sprite = new Sprite();
			btnSpace.graphics.beginFill(0xffffff, 0);
			btnSpace.graphics.drawRect(0, 0, 50, 20);
			btnSpace.graphics.endFill();
			btnSpace.buttonMode = true;
			var btnBg:Sprite = new Sprite();
			btnBg.graphics.beginFill(0xff9865, 0.4);
			btnBg.graphics.drawRoundRect(0, 0, 50, 20, 3, 3);
			btnBg.graphics.endFill();
			btnBg.addChild(btnText);
			btnBg.addChild(btnSpace);
			return btnBg;
		}
		
		private function getStagePosition(o:Object):Object
		{
			var x:Number=o.x,y:Number=o.y;
			var p:DisplayObject=o.parent;
			while(p){
				x+=p.x;
				y+=p.y;
				p=p.parent;
			}
			return {'x':x,'y':y};
		}
		
		public function showDefaultPoint():void
		{
			this._controlBar.point_mc.graphics.beginFill(0xffffff);
			this._controlBar.point_mc.graphics.drawCircle(0, 0, 4);
			this._controlBar.point_mc.graphics.endFill();
			this._controlBar.point_mc.x = this._controlBtn.x + this._controlBtn.width / 2 - this._controlBar.x;
			this._controlBar.point_mc.y = 7.5;
		}
		
		public function set isStepSlider(boo:Boolean):void
		{
			_isStepSlider = boo;
		}
		
		public function set isShowTooltip(boo:Boolean):void
		{
			_isShowTooltip = boo;
		}
		
		public function set title(str:String):void
		{
			this._controlTxt = new TextField();
			_controlTxt.text = str;
			_controlTxt.x = 18;
			_controlTxt.y = -8;
			_controlTxt.width = _controlTxt.textWidth + 10;
			_controlTxt.height = 25;
			_controlTxt.textColor = 0xC1C1C1;
			_controlTxt.selectable = false;
			this.addChild(_controlTxt);
			this._controlTitle = str;
		}
		
		public function set icon(icon:MovieClip):void
		{
			addChild(icon);
			icon.y = -5;
		}
		
		public function get botton():FilterControlBtn
		{
			return this._controlBtn;
		}
		
		public function get bar():FilterControlBar
		{
			return this._controlBar;
		}
		
		public function get level():Number
		{
			return this._ctrLevel;
		}
		
		public function get levelNum():int
		{
			return ((this._ctrLevel - this._defLevel) / this._aveLevel ) * 100 / 95;
		}
		
		public function get curValue():int
		{
			//(0, 0) (309, 92)
			_curValue = (_controlBtn.x - _controlBar.x) / multiply + minValue;
			return _curValue;//字体大小从10~36，字幕同步从-200到200
		}
		
		public function set curValue(num:int):void
		{
			_curValue = num;
			_controlBtn.x = (num - minValue) * multiply + _controlBar.x;
			
			updateBarWidth();
		}
		
		public function recordPosition():void
		{
			_recordPos = this._controlBtn.x;
		}
		
		public function restorePosition():void
		{
			this._controlBtn.x = _recordPos;
			updateBarWidth();
		}
		
		public function initBtn():void
		{
			this._controlBtn.x = _currentCount = _barWidth / 2 + this._controlBar.x - this._controlBtn.width / 2;
			updateBarWidth();
		}
		
		public function changeValueWithMode(value:Number):void
		{
			var dex_x:Number = 95 / 100 * value;
			this._ctrLevel = dex_x * _aveLevel + _defLevel;
			this._controlBtn.x = _currentCount = dex_x + _barWidth / 2 + _controlBar.x - _controlBtn.width / 2;
			updateBarWidth();
			dispatchEvent(new Event(CHANGE_FILTER_MODE));
		}
	}
}