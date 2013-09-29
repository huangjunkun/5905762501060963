package ctr.subtitle 
{
	import com.common.Cookies;
	import com.common.Tools;
	import ctr.setting.CaptionStyleBtn;
	import ctr.setting.CommonSlider;
	import eve.EventFilter;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TextEvent;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import com.common.JTracer;
	import com.global.GlobalVars;
	import com.serialization.json.JSON;
	import eve.CaptionEvent;
	import eve.EventSet;
	import ctr.filter.FilterUI;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class SetCaptionStyleFace extends Sprite
	{
		private var _sizeSlider:CommonSlider;
		private var _timeSlider:CommonSlider;
		private var _styleTxt:TextField;
		private var _fontSize:Number = 25;
		private var _fontColor:uint = 0xffffff;
		private var _filterColor:uint = 0x000000;
		private var _timeStamp:Number = 0;//秒
		private var _controllType:String;
		private var _lastFontSize:Number = _fontSize;
		private var _lastFontColor:uint = _fontColor;
		private var _lastFilterColor:uint = _filterColor;
		private var _lastTimeStamp:Number = _timeStamp;
		private var _btnArray:Array = [];
		private var _styleLoader:URLLoader;
		private var _timeLoader:URLLoader;
		
		public function SetCaptionStyleFace() 
		{
			_sizeSlider = new CommonSlider();
			addChild(_sizeSlider);
			_sizeSlider.title = "字体大小";
			_sizeSlider.x = 30;
			_sizeSlider.y = 10;
			_sizeSlider.minValue = 10;
			_sizeSlider.maxValue = 36;
			_sizeSlider.snapInterval = 1;
			_sizeSlider.clickInterval = 1;
			_sizeSlider.decimalNum = 0;
			_sizeSlider.isShowToolTip = true;
			_sizeSlider.isThumbIconHasStatus = true;
			_sizeSlider.currentValue = _fontSize;
			_sizeSlider.addEventListener(CommonSlider.CHANGE_VALUE, changeSizeHandler);
			
			_timeSlider = new CommonSlider();
			addChild(_timeSlider);
			_timeSlider.title = "字幕同步";
			_timeSlider.minValue = -200;
			_timeSlider.maxValue = 200;
			_timeSlider.snapInterval = 0.1;
			_timeSlider.clickInterval = 0.5;
			_timeSlider.decimalNum = 1;
			_timeSlider.isShowToolTip = true;
			_timeSlider.isFormatTip = true;
			_timeSlider.isSupportHover = true;
			_timeSlider.isThumbIconHasStatus = true;
			_timeSlider.prefixTip = "提前|推迟";
			_timeSlider.unit = "秒";
			_timeSlider.currentValue = _timeStamp;
			_timeSlider.addEventListener(CommonSlider.CHANGE_VALUE, changeTimeHandler);
			_timeSlider.x = 30;
			_timeSlider.y = 50;
			
			var tf:TextFormat = new TextFormat("宋体");
			
			_styleTxt = new TextField();
			_styleTxt.textColor = 0xC1C1C1;
			_styleTxt.selectable = false;
			_styleTxt.text = "样式风格";
			_styleTxt.setTextFormat(tf);
			_styleTxt.width = _styleTxt.textWidth + 10;
			_styleTxt.height = _styleTxt.textHeight + 5;
			_styleTxt.x = 48;
			_styleTxt.y = 85;
			addChild(_styleTxt);
			
			_btnArray = [];
			_btnArray.push(drawToolBtn("黑/黄", 0x000000, 0xFFFF00, false, actionFunction));
			_btnArray.push(drawToolBtn("白/粉", 0xFFFFFF, 0xFF00FF, false, actionFunction));
			_btnArray.push(drawToolBtn("白/蓝", 0xFFFFFF, 0x0000FF, false, actionFunction));
			_btnArray.push(drawToolBtn("黑/白", 0x000000, 0xFFFFFF, true, actionFunction));
			
			for (var i:int = 3; i < this.numChildren; i++ ) {
				this.getChildAt(i).y = 84;
				this.getChildAt(i).x = 123 + (i - 3) * 60;
			}
			
			var style:StyleSheet = new StyleSheet();
			style.setStyle('a', { color:'#097BB3', fontSize:'12', textAlign:'center', fontFamily :'宋体' } );
			
			var default_txt:TextField = new TextField();
			default_txt.x = 380;
			default_txt.y = 100;
			default_txt.selectable = false;
			default_txt.styleSheet = style;
			default_txt.text = "<a href='event:default'>恢复默认</a>";
			default_txt.width = default_txt.textWidth + 4;
			default_txt.addEventListener(TextEvent.LINK, onDefaultClick);
			addChild(default_txt);
			
			var commitButton:SetCommitButton = new SetCommitButton();
			commitButton.y = 141;
			commitButton.x = 170;
			commitButton.addEventListener(MouseEvent.CLICK, commitButtonClickHandler);
			addChild(commitButton);
			
			deactiveThumbIcon();
		}
		
		public function deactiveThumbIcon():void
		{
			_sizeSlider.isThumbIconActive = false;
			_timeSlider.isThumbIconActive = false;
		}
		
		public function get isThumbIconActive():Boolean
		{
			if (_sizeSlider.isThumbIconActive || _timeSlider.isThumbIconActive)
			{
				return true;
			}
			
			return false;
		}
		
		public function subDeltaByMouse(interval:Number):void
		{
			if (_sizeSlider.isThumbIconActive)
			{
				_sizeSlider.subTimeDelta(1, true, _sizeSlider.controllBtn);
			}
			
			if (_timeSlider.isThumbIconActive)
			{
				_timeSlider.subTimeDelta(interval, true, _timeSlider.controllBtn);
			}
		}
		
		public function addDeltaByMouse(interval:Number):void
		{
			if (_sizeSlider.isThumbIconActive)
			{
				_sizeSlider.addTimeDelta(1, true, _sizeSlider.controllBtn);
			}
			
			if (_timeSlider.isThumbIconActive)
			{
				_timeSlider.addTimeDelta(interval, true, _timeSlider.controllBtn);
			}
		}
		
		public function subTimeDeltaByKey(interval:Number, isShowTips:Boolean):void
		{
			_timeSlider.subTimeDelta(interval, isShowTips, _timeSlider.controllBtn, "key");
		}
		
		public function addTimeDeltaByKey(interval:Number, isShowTips:Boolean):void
		{
			_timeSlider.addTimeDelta(interval, isShowTips, _timeSlider.controllBtn, "key");
		}
		
		public function set showFace(boo:Boolean):void
		{
			this.visible = boo;
			
			if (!boo)
			{
				deactiveThumbIcon();
				
				//显示其它tab时，确定
				commitInterfaceFunction();
			}
			else
			{
				//加载样式
				loadStyle();
				
				//显示快捷键提示
				var isHide:* = Cookies.getCookie('hideShortcutsTips');
				if (!isHide)
				{
					//Cookies.setCookie('hideShortcutsTips', true);
					_timeSlider.showShortcuts();
				}
			}
		}
		
		public function initRecordStatus():void
		{
			
		}
		
		//确定
		public function commitInterfaceFunction():void
		{
			checkValueChanged();
			
			_lastFontSize = _fontSize;
			_lastFontColor = _fontColor;
			_lastFilterColor = _filterColor;
			_lastTimeStamp = _timeStamp;
		}
		
		//取消
		public function cancleInterfaceFunction():void
		{
			//更新面板设置
			var infoObj:Object = { fontColor:_lastFontColor, fontSize:_lastFontSize, filterColor:_lastFilterColor };
			setStyle(infoObj);
			//更新字幕设置
			dispatchEvent(new CaptionEvent(CaptionEvent.SET_STYLE, infoObj));
			
			//更新面板设置
			_timeSlider.currentValue = _lastTimeStamp;
			//更新字幕设置
			dispatchEvent(new CaptionEvent(CaptionEvent.SET_TIME, { time:_lastTimeStamp * 1000, type:null } ));
		}
		
		/**
		 * 获取字幕设置信息
		 */
		public function loadStyle():void
		{
			var globalVars:GlobalVars = GlobalVars.instance;
			if (!globalVars.isCaptionStyleLoaded)
			{
				globalVars.isCaptionStyleLoaded = true;
				
				JTracer.sendMessage("SetCaptionStyleFace -> loadCaptionStyle");
				
				if (Tools.getUserInfo("ygcid") == null || Tools.getUserInfo("ycid") == null || Tools.getUserInfo("userid") == "0")
				{
					JTracer.sendMessage("SetCaptionStyleFace -> loadCaptionStyle, curFileInfo is null");
					return;
				}
				var gcid:String = Tools.getUserInfo("ygcid");
				var cid:String = Tools.getUserInfo("ycid");
				var userid:String = Tools.getUserInfo("userid");
				
				var req:URLRequest = new URLRequest(globalVars.url_subtitle_style + "?userid=" + userid + "&t=" + new Date().time);
				
				_styleLoader = new URLLoader();
				_styleLoader.addEventListener(Event.COMPLETE, onStyleLoaded);
				_styleLoader.addEventListener(IOErrorEvent.IO_ERROR, onStyleIOError);
				_styleLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onStyleSecurityError);
				_styleLoader.load(req);
			}
		}
		
		/**
		 * 获取时间轴调整信息
		 */
		public function loadTime(obj:Object):void
		{
			var globalVars:GlobalVars = GlobalVars.instance;
			if (!globalVars.isCaptionTimeLoaded)
			{
				globalVars.isCaptionTimeLoaded = true;
				
				JTracer.sendMessage("SetCaptionStyleFace -> loadCaptionTime");
				
				if (Tools.getUserInfo("ygcid") == null || Tools.getUserInfo("ycid") == null || Tools.getUserInfo("userid") == "0" || !obj.scid || obj.scid == "")
				{
					JTracer.sendMessage("SetCaptionStyleFace -> loadCaptionTime, curFileInfo is null");
					return;
				}
				
				var gcid:String = Tools.getUserInfo("ygcid");
				var cid:String = Tools.getUserInfo("ycid");
				var userid:String = Tools.getUserInfo("userid");
				var scid:String = obj.scid;
				
				var req:URLRequest = new URLRequest(globalVars.url_subtitle_time + "?gcid=" + gcid + "&cid=" + cid + "&userid=" + userid + "&scid=" + scid + "&t=" + new Date().time);
				
				_timeLoader = new URLLoader();
				_timeLoader.addEventListener(Event.COMPLETE, onTimeDeltaLoaded);
				_timeLoader.addEventListener(IOErrorEvent.IO_ERROR, onTimeDeltaIOError);
				_timeLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onTimeDeltaSecurityError);
				_timeLoader.load(req);
			}
		}
		
		private function checkValueChanged():void
		{
			if (_lastFontSize != _fontSize || _lastFontColor != _fontColor || _lastFilterColor != _filterColor)
			{
				GlobalVars.instance.captionStyleChanged = true;
			}
			
			if (_lastTimeStamp != _timeStamp)
			{
				GlobalVars.instance.captionTimeChanged = true;
			}
		}
		
		private function commitButtonClickHandler(evt:MouseEvent):void
		{
			commitInterfaceFunction();
			
			dispatchEvent(new EventSet(EventSet.SHOW_FACE, 'caption'));
		}
		
		private function cancelLoadStyle():void
		{
			if (_styleLoader)
			{
				_styleLoader.removeEventListener(Event.COMPLETE, onStyleLoaded);
				_styleLoader.removeEventListener(IOErrorEvent.IO_ERROR, onStyleIOError);
				_styleLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onStyleSecurityError);
				try
				{
					_styleLoader.close();
					_styleLoader = null;
				}
				catch (e:Error)
				{
					
				}
			}
		}
		
		private function onStyleLoaded(evt:Event):void
		{
			JTracer.sendMessage("SetCaptionStyleFace -> onStyleLoaded, data:" + evt.target.data);
			
			var styleStr:String = String(evt.target.data);
			var styleObj:Object = com.serialization.json.JSON.deserialize(styleStr) || { };
			if (String(styleObj.ret) == "0")
			{
				JTracer.sendMessage("SetCaptionStyleFace -> onStyleLoaded, get style complete, ret:0");
				
				GlobalVars.instance.isCaptionStyleLoaded = true;
				
				var colorStr:String = styleObj.preference.font_color ? styleObj.preference.font_color : "255,255,255";
				var colorArr:Array = colorStr.split(",");
				_fontSize = styleObj.preference.font_size ? uint(styleObj.preference.font_size) : 25;
				_fontColor = toDec(uint(colorArr[0]), uint(colorArr[1]), uint(colorArr[2]));
				
				var filterColorStr:String = styleObj.preference.background_color ? styleObj.preference.background_color : "0,0,0";
				var filterColorArr:Array = filterColorStr.split(",");
				_filterColor = toDec(uint(filterColorArr[0]), uint(filterColorArr[1]), uint(filterColorArr[2]));
				
				_lastFontSize = _fontSize;
				_lastFontColor = _fontColor;
				_lastFilterColor = _filterColor;
				
				//更新面板设置
				var infoObj:Object = { fontColor:_fontColor, fontSize:_fontSize, filterColor:_filterColor };
				setStyle(infoObj);
				//更新字幕设置
				dispatchEvent(new CaptionEvent(CaptionEvent.SET_STYLE, infoObj));
			}
			else
			{
				JTracer.sendMessage("SetCaptionStyleFace -> onStyleLoaded, get style complete, ret:" + styleObj.ret);
				
				GlobalVars.instance.isCaptionStyleLoaded = false;
			}
		}
		
		private function onStyleIOError(evt:IOErrorEvent):void
		{
			JTracer.sendMessage("SetCaptionStyleFace -> onStyleIOError, get style IOError");
			
			GlobalVars.instance.isCaptionStyleLoaded = false;
		}
		
		private function onStyleSecurityError(evt:SecurityErrorEvent):void
		{
			JTracer.sendMessage("SetCaptionStyleFace -> onStyleSecurityError, get style SecurityError");
			
			GlobalVars.instance.isCaptionStyleLoaded = false;
		}
		
		private function setStyle(obj:Object):void
		{
			_fontSize = obj.fontSize;
			_fontColor = obj.fontColor;
			_filterColor = obj.filterColor;
			
			_sizeSlider.currentValue = _fontSize;
			
			for (var i:* in _btnArray)
			{
				var btn:CaptionStyleBtn = _btnArray[i] as CaptionStyleBtn;
				if (btn.fontColor == _fontColor && btn.filterColor == _filterColor)
				{
					btn.selected = true;
					btn.gotoAndStop(1);
				}
				else
				{
					btn.selected = false;
					btn.gotoAndStop(3);
				}
			}
		}
		
		private function onTimeDeltaLoaded(evt:Event):void
		{
			JTracer.sendMessage("SetCaptionStyleFace -> onTimeDeltaLoaded, data:" + evt.target.data);
			
			var deltaStr:String = String(evt.target.data);
			var deltaObj:Object = com.serialization.json.JSON.deserialize(deltaStr) || { };
			if (String(deltaObj.ret) == "0")
			{
				JTracer.sendMessage("SetCaptionStyleFace -> onTimeDeltaLoaded, load time delta complete, ret:0");
				
				_timeStamp = deltaObj.time_delta / 1000;
				_lastTimeStamp = _timeStamp;
				
				//更新面板设置
				_timeSlider.currentValue = deltaObj.time_delta / 1000;
				//更新字幕设置
				dispatchEvent(new CaptionEvent(CaptionEvent.SET_TIME, { time:deltaObj.time_delta, type:null } ));
			}
			else
			{
				JTracer.sendMessage("SetCaptionStyleFace -> onTimeDeltaLoaded, load time delta complete, ret:" + deltaObj.ret);
				
				GlobalVars.instance.isCaptionTimeLoaded = false;
			}
		}
		
		private function onTimeDeltaIOError(evt:IOErrorEvent):void
		{
			JTracer.sendMessage("SetCaptionStyleFace -> onTimeDeltaIOError, load time delta IOError");
			
			GlobalVars.instance.isCaptionTimeLoaded = false;
		}
		
		private function onTimeDeltaSecurityError(evt:SecurityErrorEvent):void
		{
			JTracer.sendMessage("SetCaptionStyleFace -> onTimeDeltaSecurityError, load time delta SecurityError");
			
			GlobalVars.instance.isCaptionTimeLoaded = false;
		}
		
		private function cancelLoadTime():void
		{
			if (_timeLoader)
			{
				_timeLoader.removeEventListener(Event.COMPLETE, onTimeDeltaLoaded);
				_timeLoader.removeEventListener(IOErrorEvent.IO_ERROR, onTimeDeltaIOError);
				_timeLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onTimeDeltaSecurityError);
				try
				{
					_timeLoader.close();
					_timeLoader = null;
				}
				catch (e:Error)
				{
					
				}
			}
		}
		
		private function toDec(r:uint, g:uint, b:uint, a:uint = 255):uint
		{
			//var sa:uint = a << 24;
			var sr:uint = r << 16;
			var sg:uint = g << 8;
			return sr | sg | b;
		}
		
		private function changeSizeHandler(evt:Event):void
		{
			_fontSize = _sizeSlider.currentValue;
			
			changeFontSize();
		}
		
		private function changeTimeHandler(evt:Event):void
		{
			_timeStamp = _timeSlider.currentValue;
			_controllType = _timeSlider.controllType;
			
			changeTimeStamp();
		}
		
		private function changeFontSize():void
		{
			cancelLoadStyle();
			
			JTracer.sendMessage("SetCaptionStyleFace -> change caption style, fontSize:" + _fontSize + ", fontColor:" + _fontColor + ", filterColor:" + _filterColor);
			
			dispatchEvent(new CaptionEvent(CaptionEvent.SET_STYLE, {fontColor:_fontColor, fontSize:_fontSize, filterColor:_filterColor}));
		}
		
		private function changeTimeStamp():void
		{
			cancelLoadTime();
			
			JTracer.sendMessage("SetCaptionStyleFace -> change caption time, time:" + _timeStamp * 1000);
			
			dispatchEvent(new CaptionEvent(CaptionEvent.SET_TIME, { time:_timeStamp * 1000, type:_controllType } ));
			
			_controllType = null;
			_timeSlider.controllType = null;
		}
		
		private function drawToolBtn(lable:String, filterColor:uint, fontColor:uint, selected:Boolean, action:Function):MovieClip
		{
			var btn:CaptionStyleBtn = new CaptionStyleBtn();
			btn.buttonMode = true;
			btn.mouseChildren = false;
			btn.selected = selected;
			btn.fontColor = fontColor;
			btn.filterColor = filterColor;
			btn.color_txt.text = lable;
			btn.gotoAndStop(selected ? 1 : 3);
			btn.addEventListener(MouseEvent.MOUSE_OVER, onBtnOver);
			btn.addEventListener(MouseEvent.MOUSE_OUT, onBtnOut);
			btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { action(e); } );
			addChild(btn);
			return btn;
		}
		
		private function onBtnOver(evt:MouseEvent):void
		{
			var btn:CaptionStyleBtn = evt.currentTarget as CaptionStyleBtn;
			btn.gotoAndStop(btn.selected ? 2 : 4);
		}
		
		private function onBtnOut(evt:MouseEvent):void
		{
			var btn:CaptionStyleBtn = evt.currentTarget as CaptionStyleBtn;
			btn.gotoAndStop(btn.selected ? 1 : 3);
		}
		
		private function actionFunction(e:MouseEvent):void
		{
			var btn:CaptionStyleBtn;
			for (var i:* in _btnArray)
			{
				btn = _btnArray[i] as CaptionStyleBtn;
				btn.selected = false;
				btn.gotoAndStop(3);
			}
			
			var curBtn:CaptionStyleBtn = e.currentTarget as CaptionStyleBtn;
			curBtn.selected = true;
			curBtn.gotoAndStop(2);
			
			_fontColor = curBtn.fontColor;
			_filterColor = curBtn.filterColor;
			
			changeFontSize();
		}
		
		private function onDefaultClick(evt:TextEvent):void
		{
			if (evt.text == "default")
			{
				_fontSize = 25;
				_fontColor = 0xFFFFFF;
				_filterColor = 0x000000;
				
				var btn:CaptionStyleBtn;
				for (var i:* in _btnArray)
				{
					btn = _btnArray[i] as CaptionStyleBtn;
					btn.selected = false;
					btn.gotoAndStop(3);
				}
				
				var curBtn:CaptionStyleBtn = _btnArray[3] as CaptionStyleBtn;
				curBtn.selected = true;
				curBtn.gotoAndStop(2);
				
				_sizeSlider.currentValue = 25;
				_timeSlider.currentValue = 0;
				
				changeFontSize();
			}
		}
	}
}