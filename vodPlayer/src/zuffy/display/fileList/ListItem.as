package zuffy.display.fileList 
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class ListItem extends Sprite 
	{
		private var _imgLoader:Loader;
		private var _nameTxt:TextField;
		private var _statusTxt:TextField;
		private var _itemObj:Object;
		private var _selected:Boolean;
		private var _enabledTF:TextFormat;
		private var _disabledTF:TextFormat;
		private var _bgMc:DefaultImg;
		private var _border:FileItemBorder;
		private var _isImgLoaded:Boolean;
		private var _statusMc:Sprite;
		private var _nameMc:Sprite;
		
		public function ListItem() 
		{
			_bgMc = new DefaultImg();
			addChild(_bgMc);
			
			_imgLoader = new Loader();
			_imgLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImgLoaded);
			_imgLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onImgIOError);
			_imgLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onImgSecurityError);
			addChild(_imgLoader);
			
			_border = new FileItemBorder();
			_border.visible = false;
			addChild(_border);
			
			_enabledTF = new TextFormat();
			_enabledTF.color = 0xeeeeee;
			_enabledTF.size = 13;
			_enabledTF.align = TextFieldAutoSize.CENTER;
			_enabledTF.font = "宋体";
			
			_disabledTF = new TextFormat();
			_disabledTF.color = 0x3990DF;
			_disabledTF.size = 13;
			_disabledTF.align = TextFieldAutoSize.CENTER;
			_disabledTF.font = "宋体";
		}
		
		public function setItemInfo(obj:Object, idx:uint):void
		{
			if (!obj)
			{
				return;
			}
			
			_itemObj = obj;
			
			_nameMc = new Sprite();
			_nameMc.mouseChildren = false;
			
			_nameTxt = new TextField();
			_nameTxt.defaultTextFormat = _enabledTF;
			_nameTxt.selectable = false;
			_nameTxt.text = "视频" + (idx + 1);
			_nameTxt.width = _nameTxt.textWidth + 10;
			_nameTxt.height = _nameTxt.textHeight + 4;
			_nameMc.addChild(_nameTxt);
			
			_nameMc.x = (this.width - _nameMc.width) / 2;
			_nameMc.y = 62;
			_nameMc.graphics.clear();
			_nameMc.graphics.beginFill(0xffffff, 0);
			_nameMc.graphics.drawRect(0, 0, _nameMc.width, _nameMc.height);
			_nameMc.graphics.endFill();
			addChild(_nameMc);
		}
		
		public function get nameMc():Sprite
		{
			return _nameMc;
		}
		
		public function get isImgLoaded():Boolean
		{
			return _isImgLoaded;
		}
		
		public function set selected(boo:Boolean):void
		{
			_selected = boo;
			
			_border.visible = boo;
			
			if (boo)
			{
				_nameTxt.setTextFormat(_disabledTF);
				
				if (!_statusMc)
				{
					_statusMc = new Sprite();
					_statusMc.graphics.clear();
					_statusMc.graphics.beginFill(0x000000, 0.5);
					_statusMc.graphics.drawRect(0, 40, 83, 20);
					_statusMc.graphics.endFill();
					addChild(_statusMc);
				}
				
				if (!_statusTxt)
				{
					var tf:TextFormat = new TextFormat("宋体");
					
					_statusTxt = new TextField();
					_statusTxt.selectable = false;
					_statusTxt.textColor = 0xACAAAB;
					_statusTxt.text = "播放中...";
					_statusTxt.setTextFormat(tf);
					_statusTxt.width = _statusTxt.textWidth + 4;
					_statusTxt.height = _statusTxt.textHeight + 5;
					_statusTxt.x = (83 - _statusTxt.width) / 2;
					_statusTxt.y = 60 - _statusTxt.textHeight - 6;
					addChild(_statusTxt);
				}
			}
			else
			{
				_nameTxt.setTextFormat(_enabledTF);
				
				if (_statusTxt)
				{
					removeChild(_statusTxt);
					_statusTxt = null;
				}
				
				if (_statusMc)
				{
					removeChild(_statusMc);
					_statusMc = null;
				}
			}
		}
		
		public function get selected():Boolean
		{
			return _selected;
		}
		
		public function set clicked(boo:Boolean):void
		{
			_selected = boo;
			
			_border.visible = boo;
		}
		
		public function itemOver():void
		{
			if (!_selected)
			{
				_border.visible = true;
			}
		}
		
		public function itmeOut():void
		{
			if (!_selected)
			{
				_border.visible = false;
			}
		}
		
		public function get itemObj():Object
		{
			return _itemObj;
		}
		
		public function setImgInfo(url:String):void
		{
			if (!url || url == "" || isImgLoaded)
			{
				return;
			}
			
			var req:URLRequest = new URLRequest(url);
			_imgLoader.load(req);
		}
		
		public function destroy():void
		{
			if (_imgLoader)
			{
				_imgLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onImgLoaded);
				_imgLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onImgIOError);
				_imgLoader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onImgSecurityError);
				_imgLoader.unloadAndStop();
				removeChild(_imgLoader);
				_imgLoader = null;
			}
		}
		
		private function onImgLoaded(evt:Event):void
		{
			_isImgLoaded = true;
			
			//需要策略文件
			//(_imgLoader.content as Bitmap).smoothing = true;
			_imgLoader.width = 83;
			_imgLoader.height = 60;
		}
		
		private function onImgIOError(evt:IOErrorEvent):void
		{
			_isImgLoaded = false;
		}
		
		private function onImgSecurityError(evt:SecurityErrorEvent):void
		{
			_isImgLoaded = false;
		}
	}

}