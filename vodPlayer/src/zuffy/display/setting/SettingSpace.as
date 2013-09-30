package zuffy.display.setting 
{
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.net.SharedObject;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import zuffy.display.filter.Filter;
	import zuffy.events.EventSet
	import com.global.GlobalVars;
	
	/**
	 * ...
	 * @author Drgon.S
	 */
	public class SettingSpace extends Sprite
	{
		private static const WIDTH_NORMAL:Number 	= 460;
		private static const HEIGHT_NORMAL:Number 	= 260;
		private static const OPTION_WIDTH:Number	= 84;
		private var _currentHeight:Number = 228;
		private var _filterTarget:*;
		private var _setBackSpace:SetDrawBackground;
		private var _setCloseButton:SetCloseButton = new SetCloseButton();
		private var _optionDetailFace:Sprite = new Sprite();
		private var _optionArr:Array = [];
		private var _currentOption:*;
		private var _mouseMoveSizeObject:Object = { };
		private var _defaultFormatFace:SetDefaultFormatFace;
		private var _videoSizeFace:SetVideoSizeFace;
		public var _filterFace:Filter;
		private var _setBorder:CommonBorder;
		private var _beMouseOn:Boolean;
		private var _optionBorder:Shape;
		
		public function SettingSpace(filterTarget:*) 
		{	
			_filterTarget = filterTarget;
			
			_setBackSpace = new SetDrawBackground('画面', WIDTH_NORMAL, HEIGHT_NORMAL);
			//_setBackSpace.addEventListener(MouseEvent.MOUSE_DOWN, setTitleMouseDownHandler);
			addChild(_setBackSpace);
			
			_setBorder = new CommonBorder();
			addChild(_setBorder);
			
			_setCloseButton.x = WIDTH_NORMAL - 25;
			_setCloseButton.y = 10;
			_setCloseButton.addEventListener(MouseEvent.CLICK, closeButtonClickHandler);
			addChild(_setCloseButton);
			
			_optionDetailFace.x = 16;
			_optionDetailFace.y = 75;
			addChild(_optionDetailFace);
			
			updateOptionObject();
			this.visible = false;
			
			this.addEventListener(MouseEvent.MOUSE_OVER, handleMouseOver);
			this.addEventListener(MouseEvent.MOUSE_OUT, handleMouseOut);
		}
		
		private function updateOptionObject():void
		{
			for (var i:int = 0, len:int = _optionArr.length; i < len; i++) {
				this.removeChild(_optionArr[i]['option']);
				_optionDetailFace.removeChild(_optionArr[i]['detail']);
			}
			_optionArr = [];
			
			_defaultFormatFace = new SetDefaultFormatFace();
			addOption('默认清晰度', _defaultFormatFace);
			
			_videoSizeFace = new SetVideoSizeFace();
			addOption('画面比例', _videoSizeFace);
			
			_filterFace = new Filter(_filterTarget);
			addOption('色彩调节', _filterFace);
			
			//showOption(_optionArr[0]['option']);
			this.updateOptionPosition(WIDTH_NORMAL, HEIGHT_NORMAL);
		}
		
		private function addOption(name:String,optionDetail:*):void
		{
			var option:SetDrawOption = new SetDrawOption(name);
			var optionObj:Object = { };
			optionObj['name'] = name;
			optionObj['option'] = option;
			optionObj['detail'] = optionDetail;
			option.addEventListener(SetDrawOption.SELECTED, optionClickHandler)
			addChild(option);
			if(optionDetail != null)
				_optionDetailFace.addChild(optionDetail);
			_optionArr.push(optionObj);
		}
		
		private function optionClickHandler(e:Event):void
		{
			if (_currentOption == e.target) return;
			showOption(e.target);
		}
		
		private function showOption(target:*):void
		{
			_currentOption = target;
			for (var i:* in _optionArr) {
				if (_optionArr[i]['option'] != target) {
					_optionArr[i]['option'].optionFocus = false;
					_optionArr[i]['detail'].showFace = false;
				}else {
					_optionArr[i]['option'].optionFocus = true;
					_optionArr[i]['detail'].showFace = true;
				}
			}
			setButtonStatus();
		}
		
		private function setButtonStatus():void
		{
			var name:String = '';
			for (var i:* in _optionArr) {
				if (_optionArr[i]['option'] == _currentOption) {
					name = _optionArr[i]['name'];
				}
			}
			
			this.updateDetailPosition(WIDTH_NORMAL, HEIGHT_NORMAL);
		}
		
		private function closeButtonClickHandler(e:MouseEvent):void
		{
			for (var i:* in _optionArr) {
				if(_optionArr[i]['option'] == _currentOption)
				_optionArr[i]['detail'].cancleInterfaceFunction();
			}
			
			dispatchEvent(new EventSet(EventSet.SHOW_FACE, 'set'));
		}
		
		private function updateOptionPosition(w:Number,h:Number):void
		{
			var len:int = _optionArr.length;
			//var margin:Number = (w - len * OPTION_WIDTH) / 2;
			var margin:Number = 15;
			for (var i:int = 0; i < len; i++ ) {
				(_optionArr[i]['option'] as SetDrawOption).y = 35;
				(_optionArr[i]['option'] as SetDrawOption).x = margin + i * OPTION_WIDTH;
			}
			
			_optionBorder = new Shape();
			_optionBorder.graphics.clear();
			_optionBorder.graphics.lineStyle(1, 0x373737);
			_optionBorder.graphics.moveTo(0, 62);
			_optionBorder.graphics.lineTo(w, 62);
			addChild(_optionBorder);
		}
		
		private function updateDetailPosition(w:Number, h:Number):void
		{
			_setBackSpace.setSize(w, h);
			_setBorder.width = w;
			_setBorder.height = h;
			_currentHeight = h;
			
			resizeHandler();
		}
		
		/*
		private function setTitleMouseDownHandler(e:MouseEvent):void
		{
			_mouseMoveSizeObject['marginLeft'] = e.stageX - this.x;
			_mouseMoveSizeObject['marginTop'] = e.stageY - this.y;
			_setBackSpace.stage.addEventListener(MouseEvent.MOUSE_MOVE, setTitleMouseMoveHandler);
			_setBackSpace.stage.addEventListener(MouseEvent.MOUSE_UP, setTitleMouseUpHandler);
			_setBackSpace.stage.addEventListener(MouseEvent.ROLL_OUT, setTitleMouseOutHandler);
		}
		
		private function setTitleMouseUpHandler(e:MouseEvent):void
		{
			_setBackSpace.stage.removeEventListener(MouseEvent.MOUSE_MOVE, setTitleMouseMoveHandler);
			_setBackSpace.stage.removeEventListener(MouseEvent.MOUSE_UP, setTitleMouseUpHandler);
			_setBackSpace.stage.removeEventListener(MouseEvent.ROLL_OUT, setTitleMouseOutHandler);
		}
		
		private function setTitleMouseMoveHandler(e:MouseEvent):void
		{
			this.x = e.stageX - _mouseMoveSizeObject['marginLeft'];
			this.y = e.stageY - _mouseMoveSizeObject['marginTop'];
			this.x = this.x < 0 - this.width / 2 ? 0 -this.width / 2 : this.x;
			this.x = this.x > stage.stageWidth - this.width / 2 ? stage.stageWidth - this.width / 2 :this.x;
			this.y = this.y < 0 ? 0 : this.y;
			this.y = this.y > stage.stageHeight - this.height / 2 ? stage.stageHeight - this.height / 2 : this.y;
			_mouseMoveSizeObject['ratioX'] = this.x / stage.stageWidth;
			_mouseMoveSizeObject['ratioY'] = this.y / stage.stageHeight;
		}
		
		private function setTitleMouseOutHandler(e:MouseEvent):void
		{
			_setBackSpace.stage.removeEventListener(MouseEvent.MOUSE_MOVE, setTitleMouseMoveHandler);
			_setBackSpace.stage.removeEventListener(MouseEvent.MOUSE_UP, setTitleMouseUpHandler);
			_setBackSpace.stage.removeEventListener(MouseEvent.ROLL_OUT, setTitleMouseOutHandler);
		}
		*/
		
		//是否激活拖动按钮
		public function get isThumbIconActive():Boolean
		{
			if (_filterFace.isThumbIconActive)
			{
				return true;
			}
			
			return false;
		}
		
		public function subDeltaByMouse(interval:Number):void
		{
			if (_filterFace.isThumbIconActive)
			{
				_filterFace.subDeltaByMouse(interval);
			}
		}
		
		public function addDeltaByMouse(interval:Number):void
		{
			if (_filterFace.isThumbIconActive)
			{
				_filterFace.addDeltaByMouse(interval);
			}
		}
		
		public function setPosition():void
		{
			stage.addEventListener(Event.RESIZE, resizeHandler);
			resizeHandler();
		}
		
		public function showSetFace():void
		{
			if (this.visible == true) {
				this.visible = false;
			}else {
				resizeHandler();
				_mouseMoveSizeObject = { };
				this.visible = true;
				
				showOption(_optionArr[0]['option']);
			}
		}
		
		private function resizeHandler(e:Event = null):void
		{
			if (stage) {
				this.x = int((stage.stageWidth - WIDTH_NORMAL) / 2);
				this.y = int((stage.stageHeight - _currentHeight - 33) / 2);
			}
		}
		
		private function handleMouseOver(e:MouseEvent):void
		{
			_beMouseOn = true;
		}
		
		private function handleMouseOut(e:MouseEvent):void
		{
			_beMouseOn = false;
		}
		
		public function get beMouseOn():Boolean
		{
			return _beMouseOn;
		}
		
		public function set videoSize(init:Object):void
		{
			_videoSizeFace.setFaceStatus(init);
		}
		
		public function get videoSize():Object
		{
			return _videoSizeFace.setInfo;
		}
	}
}