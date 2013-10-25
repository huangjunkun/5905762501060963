package zuffy.display.toolBarRight 
{
	import com.greensock.TweenLite;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.text.TextFormat;
	import flash.ui.Mouse;
	import flash.utils.Timer;
	import com.common.JTracer;
	import com.common.Tools;
	import zuffy.events.EventSet;
	import com.global.GlobalVars;
	import zuffy.events.PlayEvent;
	import flash.net.URLRequest;
	import flash.external.ExternalInterface;
	import flash.net.navigateToURL;
	import flash.utils.setTimeout;
	import zuffy.core.PlayerCtrl;
	
	/**
	 * ...
	 * @author dds
	 */
	public class ToolBarRight extends Sprite 
	{
		public var hidden:Boolean;
		private var _background:RightMenuBg;
		private var _target:PlayerCtrl;
		private var _beMouseOn:Boolean;
		private var _btnArray:Array;
		private var _windowBtnPosY:Number = 0;
		
		public function ToolBarRight(target:PlayerCtrl) 
		{
			_target = target;
			_background = new RightMenuBg();
			addChild(_background);
			
			_btnArray = [];
			_btnArray.push( { "btn":drawToolBtn(BtnDownload, actionFunction, "download") } );
			_btnArray.push( { "btn":drawToolBtn(BtnWindow, actionFunction, "window") } );
			_btnArray.push( { "btn":drawToolBtn(BtnCaption, actionFunction, "caption") } );
			_btnArray.push( { "btn":drawToolBtn(BtnSet, actionFunction, "set") } );
			_btnArray.push( { "btn":drawToolBtn(BtnFeedback, actionFunction, "feedback") } );
			
			for (var i:int = 1; i < this.numChildren; i++ ) {
				this.getChildAt(i).y = (i - 1) * 60 + 10;
				this.getChildAt(i).x = 16;
				if(this.getChildAt(i).name == 'window'){
					_windowBtnPosY = this.getChildAt(i).y = (i - 1) * 60 + 10;
				}
			}
			_background.height = this.getChildAt(this.numChildren - 1).y + this.getChildAt(this.numChildren - 1).height + 5;
			
			_target.addChild(this);
			
			this.addEventListener(MouseEvent.MOUSE_OVER, handleMouseOver);
			this.addEventListener(MouseEvent.MOUSE_OUT, handleMouseOut);
		}
		
		public function set enableObj(obj:Object):void
		{
			setBtnStatus([obj.enableDownload || false, obj.enableOpenWindow || false, obj.enableCaption || false, obj.enableSet || false, obj.enableFeedback || false]);
			//setBtnStatus([obj.enableDownload || false, obj.enableOpenWindow || false, obj.enableSet || false, obj.enableFeedback || false]);
		}
		
		public function show(rightNow:Boolean = false):void
		{
			
			displayOneButton(GlobalVars.instance.isZXThunder);
			
			if (rightNow) {
				TweenLite.killTweensOf(this);
				this.x = stage.stageWidth - this.width;
			}else{
				TweenLite.to(this, 0.5, { x:stage.stageWidth - this.width } );
			}
			
			hidden = false;
		}
		/**
		 * 针对 尊享版小窗口播放调整ui
		 * url 带preview=1
		 */
		private function displayOneButton(flag:Boolean):void{
			if(!_btnArray)return;
			var isFullScreen:Boolean = stage.displayState == StageDisplayState.FULL_SCREEN;
			
			if(flag){
				for(var i:int = 0; i < _btnArray.length; i++){
					var btn:MovieClip = _btnArray[i]['btn'] as MovieClip;
					if(!btn)continue;				
					btn.visible = !(btn.name == 'download' || btn.name == 'feedback');

					if(isFullScreen){
						if(btn.name == 'window')btn.y = _windowBtnPosY;
					}
					else{
						btn.visible = false;
						if(btn.name == 'window'){
							btn.y = 80;
							btn.visible = true;
						}
					}

				}				
			}

		}

		public function hide(rightNow:Boolean = false):void
		{
			if (rightNow) {
				TweenLite.killTweensOf(this);
				this.x = stage.stageWidth;
			}else {
				TweenLite.to(this, 0.5, { x:stage.stageWidth } );
			}
			
			hidden = true;
		}
		
		public function get beMouseOn():Boolean
		{
			return _beMouseOn;
		}
		
		private function drawToolBtn(classRef:Class, action:Function, evt:String):MovieClip
		{
			var tf:TextFormat = new TextFormat();
			tf.font = "宋体";
			
			var btn:MovieClip = new classRef();
			btn.name = evt;
			btn.txt.defaultTextFormat = tf;
			btn.gotoAndStop(3);
			btn.buttonMode = false;
			btn.mouseChildren = false;
			btn.mouseEnabled = false;
			btn.addEventListener(MouseEvent.MOUSE_OVER, onBtnOver);
			btn.addEventListener(MouseEvent.MOUSE_OUT, onBtnOut);
			btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { action(evt); } );
			addChild(btn);
			return btn;
		}
		
		private function setBtnStatus(statusArr:Array):void
		{
			var tf:TextFormat = new TextFormat();
			tf.font = "宋体";
			
			var i:*;
			for (i in statusArr)
			{
				if (statusArr[i])
				{
					_btnArray[i]["btn"].gotoAndStop(1);
				}
				else
				{
					_btnArray[i]["btn"].gotoAndStop(3);
				}
				_btnArray[i]["btn"].txt.setTextFormat(tf);
				_btnArray[i]["btn"].buttonMode = statusArr[i];
				_btnArray[i]["btn"].mouseEnabled = statusArr[i];
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
		
		private function onBtnOver(evt:MouseEvent):void
		{
			var tf:TextFormat = new TextFormat();
			tf.font = "宋体";
			
			var btn:MovieClip = evt.currentTarget as MovieClip;
			btn.gotoAndStop(2);
			btn.txt.setTextFormat(tf);
		}
		
		private function onBtnOut(evt:MouseEvent):void
		{
			var tf:TextFormat = new TextFormat();
			tf.font = "宋体";
			
			var btn:MovieClip = evt.currentTarget as MovieClip;
			btn.gotoAndStop(1);
			btn.txt.setTextFormat(tf);
		}
		
		private function actionFunction(evt:String):void
		{
			if (evt == "feedback")
			{
				if (stage.displayState == StageDisplayState.FULL_SCREEN)
				{
					stage.displayState = StageDisplayState.NORMAL;
				}
			}
			
			if (evt == "window")
			{
				if (stage.displayState == StageDisplayState.FULL_SCREEN)
				{
					stage.displayState = StageDisplayState.NORMAL;
				}
				clickWindow();
				return;
			}
			
			dispatchEvent(new EventSet(EventSet.SHOW_FACE, evt));
		}
		
		private function clickWindow():void
		{
			var from:String = Tools.getUserInfo("from");
			var filename:String = encodeURIComponent(Tools.getUserInfo("name"));
			var t:Number = new Date().getTime();
			var ygcid:String = Tools.getUserInfo("ygcid");
			var filesize:String = Tools.getUserInfo("filesize");
			var ycid:String = Tools.getUserInfo("ycid");
			var url:String = encodeURIComponent(Tools.getUserInfo("url"));
			var start:Number = _target._player.time;
			var format:String = GlobalVars.instance.movieFormat;
			var uvs:String = Tools.getUserInfo("userid") + "_" + Tools.getUserInfo("userType") + "_" + Tools.getUserInfo("sessionid");
			
			//Tools.windowOpen("http://10.10.2.201:8801/player.html?from=" + from + "&filename=" + filename + "&t=" + t + "&userid=" + userid + "&gcid=" + ygcid + "&filesize=" + filesize + "&cid=" + cid + "&url=" + url + "&start=" + start + "&format=" + format);
			var openURL:String = "from=" + from + "&filename=" + filename + "&t=" + t + "&uvs=" + uvs + "&gcid=" + ygcid + "&filesize=" + filesize + "&cid=" + ycid + "&url=" + url + "&start=" + start + "&format=" + format;
			ExternalInterface.call("XL_CLOUD_FX_INSTANCE.openMini", openURL);
			
			if (GlobalVars.instance.isStat)
			{
				Tools.stat('b=openmini');
			}
			
			JTracer.sendMessage("ToolBarRight -> openURL:" + openURL);
			
			dispatchEvent(new PlayEvent(PlayEvent.OPEN_WINDOW));
		}
		
		private function resizeHandler(e:Event):void
		{
			this.x = stage.stageWidth;
			this.y = int((stage.stageHeight - this.height - 36) / 2);
		}
		
		public function setPosition():void
		{
			stage.addEventListener(Event.RESIZE, resizeHandler);
			resizeHandler(null);
		}
	}
}