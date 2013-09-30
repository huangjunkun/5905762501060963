package zuffy.display.toolBarTop
{
	import com.greensock.TweenLite;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	import com.common.JTracer;
	import com.common.Tools;
	import com.global.GlobalVars;
	import zuffy.events.PlayEvent;
	import zuffy.core.PlayerCtrl;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class ToolBarTop extends Sprite 
	{
		public var hidden:Boolean;
		
		private var _target:PlayerCtrl;
		private var _beMouseOn:Boolean;
		private var _urlTxt:TextField;
		private var _playBtn:PlayButtonTop;
		private var _outString:String = "";
		private var _overString:String = "输入视频下载链接点击播放";
		private var _playUrl:String;//当前播放原始地址
		private var _inputUrl:String;//用户输入的地址
		private var _systemTimeTxt:TextField;
		private var _isFocusIn:Boolean;
		
		public function ToolBarTop(target:PlayerCtrl) 
		{
			_target = target;
			_target.addChild(this);
			
			drawInputBg();
			
			var tf:TextFormat = new TextFormat("宋体");
			
			_urlTxt = new TextField();
			_urlTxt.defaultTextFormat = tf;
			_urlTxt.type = TextFieldType.INPUT;
			_urlTxt.textColor = 0x787878;
			_urlTxt.wordWrap = false;
			_urlTxt.multiline = false;
			_urlTxt.width = stage.stageWidth - 80;
			_urlTxt.height = _urlTxt.textHeight + 4;
			_urlTxt.x = 15;
			_urlTxt.y = 3;
			_urlTxt.addEventListener(MouseEvent.MOUSE_OVER, onOverUrlTxt);
			_urlTxt.addEventListener(MouseEvent.MOUSE_OUT, onOutUrlTxt);
			_urlTxt.addEventListener(FocusEvent.FOCUS_IN, onFocusInUrlTxt);
			_urlTxt.addEventListener(FocusEvent.FOCUS_OUT, onFocusOutUrlTxt);
			_urlTxt.addEventListener(MouseEvent.CLICK, onClickUrlTxt);
			_urlTxt.addEventListener(Event.CHANGE, onChangeUrlTxt);
			addChild(_urlTxt);
			
			_playBtn = new PlayButtonTop();
			_playBtn.x = stage.stageWidth - _playBtn.width - 8;
			_playBtn.y = 3;
			_playBtn.addEventListener(MouseEvent.CLICK, playNewUrl);
			addChild(_playBtn);
			
			_systemTimeTxt = new TextField();
			_systemTimeTxt.selectable = false;
			_systemTimeTxt.textColor = 0xFFFFFF;
			_systemTimeTxt.visible = false;
			addChild(_systemTimeTxt);
			
			this.addEventListener(MouseEvent.MOUSE_OVER, handleMouseOver);
			this.addEventListener(MouseEvent.MOUSE_OUT, handleMouseOut);
		}
		
		public function fullScreen():void
		{
			_urlTxt.visible = false;
			_playBtn.visible = false;
			_systemTimeTxt.visible = true;
			drawBg();
		}
		
		public function normalScreen():void
		{
			_urlTxt.visible = true;
			_playBtn.visible = true;
			_systemTimeTxt.visible = false;
			drawInputBg();
		}
		
		public function setSystemTime(str:String):void
		{
			_systemTimeTxt.htmlText = "<font size='18'>" + str + "</font>";
			_systemTimeTxt.width = _systemTimeTxt.textWidth + 10;
			_systemTimeTxt.height = _systemTimeTxt.textHeight + 4;
			_systemTimeTxt.x = stage.stageWidth - _systemTimeTxt.width;
			_systemTimeTxt.y = 2;
		}
		
		public function set infoObj(obj:Object):void
		{
			var str:String;
			try
			{
				str = decodeURI(obj.name);
			}
			catch(e:Error)
			{
				str = obj.name;
				JTracer.sendMessage("ToolBarTop -> decodeURI发生错误");
			}
			_urlTxt.text = str;
			_outString = str;
			
			_playUrl = obj.url;
			_inputUrl = obj.url;
			_playBtn.mouseEnabled = true;
		}
		
		public function show(rightNow:Boolean = false):void
		{
			if (rightNow) {
				TweenLite.killTweensOf(this);
				this.y = 0;
			}else{
				TweenLite.to(this, 0.5, { y:0 } );
			}
			
			hidden = false;
		}
		
		public function hide(rightNow:Boolean = false):void
		{
			if (rightNow) {
				TweenLite.killTweensOf(this);
				this.y = -25;
			}else {
				TweenLite.to(this, 0.5, { y:-25 } );
			}
			
			hidden = true;
		}
		
		public function setPosition():void
		{
			stage.addEventListener(Event.RESIZE, resizeHandler);
			resizeHandler(null);
		}
		
		public function get beMouseOn():Boolean
		{
			return _beMouseOn;
		}
		
		private function playNewUrl(evt:MouseEvent):void
		{
			if (_inputUrl == _playUrl)
			{
				dispatchEvent(new Event("ShowPlayingTips"));
				return;
			}
			
			//清除i帧数据
			_target.clearSnpt();
			
			if (GlobalVars.instance.isStat)
			{
				Tools.stat('b=topBarPlay');
			}
			
			_playBtn.mouseEnabled = false;
			ExternalInterface.call("XL_CLOUD_FX_INSTANCE.playOther", true, _inputUrl);
		}
		
		private function onOverUrlTxt(evt:MouseEvent):void
		{
			if(_isFocusIn)
			{
				return;
			}
			
			_urlTxt.text = _overString;
			_urlTxt.setSelection(_overString.length, _overString.length);
		}
		
		private function onOutUrlTxt(evt:MouseEvent):void
		{
			if(_isFocusIn)
			{
				return;
			}
			
			_urlTxt.text = _outString;
			_urlTxt.setSelection(_outString.length, _outString.length);
		}
		
		private function onFocusInUrlTxt(evt:FocusEvent):void
		{
			_isFocusIn = true;
			
			_urlTxt.text = "";
		}
		
		private function onFocusOutUrlTxt(evt:FocusEvent):void
		{
			_isFocusIn = false;
			
			_urlTxt.text = _outString;
			_urlTxt.setSelection(_outString.length, _outString.length);
		}
		
		private function onClickUrlTxt(evt:MouseEvent):void
		{
			_urlTxt.text = "";
		}
		
		private function onChangeUrlTxt(evt:Event):void
		{
			_outString = _urlTxt.text;
			_inputUrl = _urlTxt.text;
		}
		
		private function drawInputBg():void
		{
			this.graphics.clear();
			this.graphics.beginFill(0x242426);
			this.graphics.drawRect(0, 0, stage.stageWidth, 25);
			this.graphics.beginFill(0xC8C8C8);
			this.graphics.drawRoundRect(10, 3, stage.stageWidth - 70, 19, 4, 4);
			this.graphics.endFill();
		}
		
		private function drawBg():void
		{
			this.graphics.clear();
			this.graphics.beginFill(0x242426);
			this.graphics.drawRect(0, 0, stage.stageWidth, 25);
			this.graphics.endFill();
		}
		
		private function resizeHandler(e:Event):void
		{
			if (stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				drawBg();
			}
			else
			{
				drawInputBg();
			}
			
			this.x = 0;
			this.y = -25;
			
			_urlTxt.width = stage.stageWidth - 80;
			_playBtn.x = stage.stageWidth - _playBtn.width - 8;
			_systemTimeTxt.x = stage.stageWidth - _systemTimeTxt.width;
		}
		
		private function handleMouseOver(e:MouseEvent):void
		{
			_beMouseOn = true;
		}
		
		private function handleMouseOut(e:MouseEvent):void
		{
			_beMouseOn = false;
		}
	}
}