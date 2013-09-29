package display.subtitle
{
	import ctr.setting.SetDrawBackground;
	import ctr.setting.SetDrawOption;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.net.SharedObject;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import ctr.filter.Filter;
	import eve.EventSet;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class CaptionFace extends Sprite
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
		private var _setCaptionFace:SetCaptionFace;
		private var _captionStyleFace:SetCaptionStyleFace;
		private var _setBorder:CommonBorder;
		private var _beMouseOn:Boolean;
		private var _optionBorder:Shape;
		
		public function CaptionFace()
		{
			_setBackSpace = new SetDrawBackground('字幕', WIDTH_NORMAL, HEIGHT_NORMAL);
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
		
		//清除字幕
		public function clearCaption():void
		{
			_setCaptionFace.clear();
		}
		
		//上传完状态
		public function showCompStatus():void
		{
			_setCaptionFace.showCompStatus();
		}
		
		//上传错误状态
		public function showErrorStatus():void
		{
			_setCaptionFace.showErrorStatus();
		}
		
		//字幕列表长度
		public function get listLength():uint
		{
			return _setCaptionFace.listLength;
		}
		
		//获取上次加载字幕
		public function loadLastload():void
		{
			_setCaptionFace.loadLastload();
		}
		
		//获取自动加载字幕
		public function loadAutoload():void
		{
			_setCaptionFace.loadAutoload();
		}
		
		//设置自动上传参数
		public function setOuterParam(obj:Object):void
		{
			_setCaptionFace.setOuterParam(obj);
		}
		
		public function subDeltaByMouse(interval:Number):void
		{
			if (_captionStyleFace.isThumbIconActive)
			{
				_captionStyleFace.subDeltaByMouse(interval);
			}
		}
		
		public function addDeltaByMouse(interval:Number):void
		{
			if (_captionStyleFace.isThumbIconActive)
			{
				_captionStyleFace.addDeltaByMouse(interval);
			}
		}
		
		//加载字幕样式
		public function loadCaptionStyle():void
		{
			_captionStyleFace.loadStyle();
		}
		
		//加载时间轴调整信息
		public function loadCaptionTime(obj:Object):void
		{
			_captionStyleFace.loadTime(obj);
		}
		
		//提前时间
		public function subTimeDeltaByKey(interval:Number):void
		{
			_captionStyleFace.subTimeDeltaByKey(interval, this.visible && _captionStyleFace.visible);
		}
		
		//推迟时间
		public function addTimeDeltaByKey(interval:Number):void
		{
			_captionStyleFace.addTimeDeltaByKey(interval, this.visible && _captionStyleFace.visible);
		}
		
		//是否激活拖动按钮
		public function get isThumbIconActive():Boolean
		{
			if (_captionStyleFace.isThumbIconActive)
			{
				return true;
			}
			
			return false;
		}
		
		private function updateOptionObject():void
		{
			for (var i:int = 0, len:int = _optionArr.length; i < len; i++) {
				this.removeChild(_optionArr[i]['option']);
				_optionDetailFace.removeChild(_optionArr[i]['detail']);
			}
			_optionArr = [];
			
			_setCaptionFace = new SetCaptionFace();
			addOption('在线字幕', _setCaptionFace);
			
			_captionStyleFace = new SetCaptionStyleFace();
			addOption('字幕调节', _captionStyleFace);
			
			showOption(_optionArr[0]['option']);
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
			
			dispatchEvent(new EventSet(EventSet.SHOW_FACE, 'caption'));
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
			addChildAt(_optionBorder, getChildIndex(_optionDetailFace));
		}
		
		private function updateDetailPosition(w:Number, h:Number):void
		{
			_setBackSpace.setSize(w, h);
			_setBorder.width = w;
			_setBorder.height = h;
			_currentHeight = h;
			
			resizeHandler();
		}
		
		public function setPosition():void
		{
			stage.addEventListener(Event.RESIZE, resizeHandler);
			resizeHandler();
		}
		
		public function showFace(boo:Boolean):void
		{
			this.visible = boo;
			
			if (!boo)
			{
				_captionStyleFace.deactiveThumbIcon();
			}
			else
			{
				if (_setCaptionFace.visible)
				{
					_setCaptionFace.loadCaptionList();
				}
				if (_captionStyleFace.visible)
				{
					_captionStyleFace.loadStyle();
				}
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
	}
}