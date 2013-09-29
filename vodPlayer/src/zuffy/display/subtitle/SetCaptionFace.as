package ctr.subtitle 
{
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TextEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.net.sendToURL;
	import com.common.JTracer;
	import com.common.Tools;
	import com.global.GlobalVars;
	import com.serialization.json.JSON;
	import ctr.tip.ToolTip;
	import eve.CaptionEvent;
	import eve.EventSet;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class SetCaptionFace extends Sprite
	{
		private var _fileFilter:FileFilter;
		private var _limitSize:Number;
		private var _timeOut:Number;
		private var _uploadURL:String;
		private var _listMc:Sprite;
		private var _listArray:Array = [];
		private var _itemArray:Array = [];
		private var _fileName:String;
		private var _timer:Timer;
		private var _overTF:TextFormat;
		private var _outTF:TextFormat;
		private var _noCaptionTips:NoCaptionTips;
		private var _uploadItem:CaptionItem;
		private var _uploadBtn:UploadCaptionBtn;
		private var _autoloadScid:String;//自动加载字幕scid
		private var _lastScid:String;
		
		public function SetCaptionFace() 
		{
			_overTF = new TextFormat();
			_overTF.color = 0x646464;
			
			_outTF = new TextFormat();
			_outTF.color = 0xAAAAAA;
			
			_listMc = new Sprite();
			_listMc.x = 3;
			_listMc.y = 0;
			addChild(_listMc);
			
			var style:StyleSheet = new StyleSheet();
			style.setStyle('a', { color:'#097BB3', fontSize:'12', textAlign:'center', fontFamily :'宋体', textDecoration:'underline' } );
			
			var search_txt:TextField = new TextField();
			search_txt.x = 280;
			search_txt.y = 153;
			search_txt.selectable = false;
			search_txt.styleSheet = style;
			search_txt.text = "<a href='event:search'>去射手网搜索字幕</a>";
			search_txt.width = search_txt.textWidth + 4;
			search_txt.addEventListener(TextEvent.LINK, onSearchClick);
			addChild(search_txt);
			
			_uploadBtn = new UploadCaptionBtn();
			_uploadBtn.x = 162;
			_uploadBtn.y = 141;
			addChild(_uploadBtn);
			
			showEmptyListTips();
		}
		
		public function clear():void
		{
			//删除全部字幕
			removeCaptions(0);
			//显示没字幕提示
			showEmptyListTips();
		}
		
		public function setOuterParam(obj:Object):void
		{
			if (!obj || !obj.description || !obj.extension || !obj.uploadURL || !obj.limitSize)
			{
				return;
			}
			
			_uploadURL = obj.uploadURL;
			_limitSize = obj.limitSize;
			_timeOut = obj.timeOut;
			_fileFilter = new FileFilter(obj.description, obj.extension);
			
			_uploadBtn.addEventListener(MouseEvent.CLICK, onUploadClick);
		}
		
		public function set showFace(boo:Boolean):void
		{
			this.visible = boo;
			
			if (!boo)
			{
				//显示其它tab时，确定
				commitInterfaceFunction();
			}
			else
			{
				//加载字幕列表
				loadCaptionList();
			}
		}
		
		public function setPosition():void
		{
			this.x = int((stage.stageWidth - 460) / 2);
			this.y = int((stage.stageHeight - 228 - 33) / 2);
		}
		
		public function get listLength():uint
		{
			return _listArray.length || 0;
		}
		
		public function showCompStatus():void
		{
			var i:*;
			var item:CaptionItem;
			for (i in _itemArray)
			{
				item = _itemArray[i] as CaptionItem;
				if (item.selected)
				{
					_lastScid = item.scid;
					
					item.status_mc.visible = true;
					item.status_mc.gotoAndStop(2);
					item.status_txt.text = "取消";
					
					//应用成功
					Tools.stat("b=tjzm&e=0&gcid=" + Tools.getUserInfo("ygcid"));
				}
				else
				{
					item.status_mc.visible = false;
					item.status_mc.gotoAndStop(1);
					item.status_txt.text = "";
				}
			}
		}
		
		public function showErrorStatus():void
		{
			var i:*;
			var item:CaptionItem;
			for (i in _itemArray)
			{
				item = _itemArray[i] as CaptionItem;
				if (item.selected)
				{
					_lastScid = null;
					
					item.selected = false;
					item.status_mc.visible = true;
					item.status_mc.gotoAndStop(3);
					item.status_txt.text = "重试";
					
					//应用失败
					Tools.stat("b=tjzm&e=-1&gcid=" + Tools.getUserInfo("ygcid"));
				}
				else
				{
					item.status_mc.visible = false;
					item.status_mc.gotoAndStop(1);
					item.status_txt.text = "";
				}
			}
		}
		
		//删除从startIdx开始后的所有字幕
		private function removeCaptions(startIdx:int):void
		{
			while (_itemArray.length > startIdx)
			{
				var item:CaptionItem = _itemArray.pop() as CaptionItem;
				removeCaption(item);
			}
		}
		
		//删除单个字幕
		private function removeCaption(item:CaptionItem):void
		{
			if (item && _listMc.contains(item))
			{
				item.removeEventListener(MouseEvent.CLICK, onItemClick);
				item.removeEventListener(MouseEvent.MOUSE_OVER, onItemOver);
				item.removeEventListener(MouseEvent.MOUSE_OUT, onItemOut);
				item.removeEventListener(MouseEvent.MOUSE_MOVE, onItemMove);
				_listMc.removeChild(item);
				item = null;
			}
		}
		
		public function initRecordStatus():void
		{
			
		}
		
		//确定
		public function commitInterfaceFunction():void
		{
			
		}
		
		//取消
		public function cancleInterfaceFunction():void
		{
			
		}
		
		private function getCaption(scid:String):CaptionItem
		{
			for (var i:* in _itemArray)
			{
				if (_itemArray[i].scid == scid)
				{
					return _itemArray[i];
				}
			}
			
			return null;
		}
		
		private function getSameContentCount(data:ByteArray):int
		{
			var count:int = 0;
			for (var i:* in _itemArray)
			{
				if (_itemArray[i].data && _itemArray[i].data.toString() == data.toString())
				{
					count++;
				}
			}
			
			JTracer.sendMessage("SetCaptionFace -> getSameContentCount, count:" + count);
			
			return count;
		}
		
		private function getCaptionByData(data:ByteArray):CaptionItem
		{
			var count:int = getSameContentCount(data);
			if (count <= 1)
			{
				return null;
			}
			
			for (var i:* in _itemArray)
			{
				if (_itemArray[i].data && _itemArray[i].data.toString() == data.toString())
				{
					return _itemArray[i];
				}
			}
			
			return null;
		}
		
		private function createCaption(propObj:Object):CaptionItem
		{
			var item:CaptionItem = new CaptionItem();
			setCaptionProp(item, propObj);
			_listMc.addChild(item);
			_itemArray.push(item);
			
			return item;
		}
		
		private function setCaptionProp(item:CaptionItem, propObj:Object):void
		{
			item.row = propObj.row;
			item.row_txt.text = propObj.rname;
			item.name_txt.text = decodeURI(propObj.sname);
			item.name_txt.width = item.name_txt.textWidth + 4;
			item.surl = propObj.surl;
			item.scid = propObj.scid;
			item.fullname = propObj.fname;
			item.manual = propObj.manual;
			item.selected = propObj.selected;
			item.buttonMode = propObj.enable;
			item.y = propObj.row * 30;
			item.mouseChildren = false;
			item.bg_mc.visible = false;
			item.status_mc.visible = false;
			item.status_mc.gotoAndStop(1);
			item.status_txt.text = "";
			item.status_txt.x = item.name_txt.x + item.name_txt.textWidth + 20;
			item.addEventListener(MouseEvent.CLICK, onItemClick);
			item.addEventListener(MouseEvent.MOUSE_OVER, onItemOver);
			item.addEventListener(MouseEvent.MOUSE_OUT, onItemOut);
			item.addEventListener(MouseEvent.MOUSE_MOVE, onItemMove);
		}
		
		private function showEmptyListTips():void
		{
			if (!_noCaptionTips)
			{
				_noCaptionTips = new NoCaptionTips();
				_noCaptionTips.x = 15;
				_noCaptionTips.y = 40;
				addChild(_noCaptionTips);
			}
		}
		
		private function hideNoCaptionTips():void
		{
			if (_noCaptionTips)
			{
				removeChild(_noCaptionTips);
				_noCaptionTips = null;
			}
		}
		
		/**
		 * 获取上次加载字幕信息
		 */
		public function loadLastload():void
		{
			JTracer.sendMessage("SetCaptionFace -> loadLastload, get lastload caption start");
			
			_autoloadScid = "";
			
			if (Tools.getUserInfo("ygcid") == null || Tools.getUserInfo("ycid") == null || Tools.getUserInfo("userid") == null)
			{
				JTracer.sendMessage("SetCaptionFace -> loadLastload, curFileInfo is null");
				return;
			}
			
			var gcid:String = Tools.getUserInfo("ygcid");
			var cid:String = Tools.getUserInfo("ycid");
			var userid:String = Tools.getUserInfo("userid");
			
			var req:URLRequest = new URLRequest(GlobalVars.instance.url_subtitle_lastload + "?gcid=" + gcid + "&cid=" + cid + "&userid=" + userid + "&t=" + new Date().time);
			
			var lastLoader:URLLoader = new URLLoader();
			lastLoader.addEventListener(Event.COMPLETE, onLastloadLoaded);
			lastLoader.addEventListener(IOErrorEvent.IO_ERROR, onLastloadIOError);
			lastLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLastloadSecurityError);
			lastLoader.load(req);
		}
		
		private function onLastloadLoaded(evt:Event):void
		{
			JTracer.sendMessage("SetCaptionFace -> onLastloadLoaded, data:" + evt.target.data);
			
			var lastloadStr:String = String(evt.target.data);
			var lastloadObj:Object = com.serialization.json.JSON.deserialize(lastloadStr) || { };
			if (String(lastloadObj.ret) == "0")
			{
				JTracer.sendMessage("SetCaptionFace -> onLastloadLoaded, get lastload caption complete, ret:0");
				
				//自动加载字幕scid
				_autoloadScid = lastloadObj.subtitle.scid;
				var lastloadSname:String = lastloadObj.subtitle.sname;
				if (_autoloadScid && _autoloadScid != "")
				{
					JTracer.sendMessage("SetCaptionFace -> onLastloadLoaded, has lastload scid, scid:" + _autoloadScid);
					
					//存在自动加载的字幕
					GlobalVars.instance.isHasAutoloadCaption = true;
					//加载字幕样式
					dispatchEvent(new CaptionEvent(CaptionEvent.LOAD_STYLE));
					//设置时间轴调整信息未加载完
					GlobalVars.instance.isCaptionTimeLoaded = false;
					//加载时间轴调整信息
					dispatchEvent(new CaptionEvent(CaptionEvent.LOAD_TIME, {scid:_autoloadScid}));
					//加载字幕内容
					dispatchEvent(new CaptionEvent(CaptionEvent.LOAD_CONTENT, {surl:null, scid:_autoloadScid, sname:lastloadSname, sdata:null, isSaveAutoload:false, gradeTime:180}));
				}
				else
				{
					JTracer.sendMessage("SetCaptionFace -> onLastloadLoaded, don't has lastload scid");
					
					if (!GlobalVars.instance.hasSubtitle)
					{
						loadAutoload();
					}
				}
			}
			else
			{
				JTracer.sendMessage("SetCaptionFace -> onLastloadLoaded, get lastload caption complete, ret:" + lastloadObj.ret);
				
				if (!GlobalVars.instance.hasSubtitle)
				{
					loadAutoload();
				}
			}
		}
		
		private function onLastloadIOError(evt:IOErrorEvent):void
		{
			JTracer.sendMessage("SetCaptionFace -> onLastloadIOError, get lastload caption IOError");
		}
		
		private function onLastloadSecurityError(evt:SecurityErrorEvent):void
		{
			JTracer.sendMessage("SetCaptionFace -> onLastloadSecurityError, get lastload caption SecurityError");
		}
		
		/**
		 * 获取自动加载字幕信息
		 */
		public function loadAutoload():void
		{
			JTracer.sendMessage("SetCaptionFace -> loadAutoload, get autoload caption start");
			
			_autoloadScid = "";
			
			if (Tools.getUserInfo("ygcid") == null || Tools.getUserInfo("ycid") == null || Tools.getUserInfo("userid") == null)
			{
				JTracer.sendMessage("SetCaptionFace -> loadAutoload, curFileInfo is null");
				return;
			}
			
			var gcid:String = Tools.getUserInfo("ygcid");
			var cid:String = Tools.getUserInfo("ycid");
			var userid:String = Tools.getUserInfo("userid");
			
			var req:URLRequest = new URLRequest(GlobalVars.instance.url_subtitle_autoload + "?gcid=" + gcid + "&cid=" + cid + "&userid=" + userid + "&t=" + new Date().time);
			
			var autoLoader:URLLoader = new URLLoader();
			autoLoader.addEventListener(Event.COMPLETE, onAutoloadLoaded);
			autoLoader.addEventListener(IOErrorEvent.IO_ERROR, onAutoloadIOError);
			autoLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onAutoloadSecurityError);
			autoLoader.load(req);
		}
		
		private function onAutoloadLoaded(evt:Event):void
		{
			JTracer.sendMessage("SetCaptionFace -> onAutoloadLoaded, data:" + evt.target.data);
			
			var autoloadStr:String = String(evt.target.data);
			var autoloadObj:Object = com.serialization.json.JSON.deserialize(autoloadStr) || { };
			if (String(autoloadObj.ret) == "0")
			{
				JTracer.sendMessage("SetCaptionFace -> onAutoloadLoaded, get autoload caption complete, ret:0");
				
				//自动加载字幕scid
				_autoloadScid = autoloadObj.subtitle.scid;
				var autoloadSname:String = autoloadObj.subtitle.sname;
				if (_autoloadScid && _autoloadScid != "")
				{
					var reliable:uint = autoloadObj.subtitle.reliable;
					var gradeTime:uint;
					if (reliable == 1)
					{
						gradeTime = 180;
					}
					else
					{
						gradeTime = 600;
					}
					
					JTracer.sendMessage("SetCaptionFace -> onAutoloadLoaded, has autoload scid, scid:" + _autoloadScid + ", reliable:" + reliable);
					
					//存在自动加载的字幕
					GlobalVars.instance.isHasAutoloadCaption = true;
					//加载字幕样式
					dispatchEvent(new CaptionEvent(CaptionEvent.LOAD_STYLE));
					//设置时间轴调整信息未加载完
					GlobalVars.instance.isCaptionTimeLoaded = false;
					//加载时间轴调整信息
					dispatchEvent(new CaptionEvent(CaptionEvent.LOAD_TIME, {scid:_autoloadScid}));
					//加载字幕内容
					dispatchEvent(new CaptionEvent(CaptionEvent.LOAD_CONTENT, {surl:null, scid:_autoloadScid, sname:autoloadSname, sdata:null, isSaveAutoload:false, gradeTime:gradeTime}));
				}
				else
				{
					JTracer.sendMessage("SetCaptionFace -> onAutoloadLoaded, don't has autoload scid");
				}
			}
			else
			{
				JTracer.sendMessage("SetCaptionFace -> onAutoloadLoaded, get autoload caption complete, ret:" + autoloadObj.ret);
			}
		}
		
		private function onAutoloadIOError(evt:IOErrorEvent):void
		{
			JTracer.sendMessage("SetCaptionFace -> onAutoloadIOError, get autoload caption IOError");
		}
		
		private function onAutoloadSecurityError(evt:SecurityErrorEvent):void
		{
			JTracer.sendMessage("SetCaptionFace -> onAutoloadSecurityError, get autoload caption SecurityError");
		}
		
		/**
		 * 加载全部字幕
		 */
		public function loadCaptionList():void
		{
			var globalVars:GlobalVars = GlobalVars.instance;
			if (!globalVars.isCaptionListLoaded)
			{
				globalVars.isCaptionListLoaded = true;
				
				JTracer.sendMessage("SetCaptionFace -> loadCaptionList, load caption list start");
				
				if (Tools.getUserInfo("ygcid") == null || Tools.getUserInfo("ycid") == null)
				{
					JTracer.sendMessage("SetCaptionFace -> loadCaptionList, curFileInfo is null");
					return;
				}
				var gcid:String = Tools.getUserInfo("ygcid");
				var cid:String = Tools.getUserInfo("ycid");
				var userid:String = Tools.getUserInfo("userid");
				
				var req:URLRequest = new URLRequest(globalVars.url_subtitle_list + "?gcid=" + gcid + "&cid=" + cid + "&userid=" + userid + "&t=" + new Date().time);
				
				var listLoader:URLLoader = new URLLoader();
				listLoader.addEventListener(Event.COMPLETE, onListLoaded);
				listLoader.addEventListener(IOErrorEvent.IO_ERROR, onListIOError);
				listLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onListSecurityError);
				listLoader.load(req);
			}
		}
		
		private function onListLoaded(evt:Event):void
		{
			JTracer.sendMessage("SetCaptionFace -> onListLoaded, data:" + evt.target.data);
			
			var listStr:String = String(evt.target.data);
			var listObj:Object = com.serialization.json.JSON.deserialize(listStr) || { };
			if (String(listObj.ret) == "0")
			{
				JTracer.sendMessage("SetCaptionFace -> onListLoaded, load caption list complete, ret:0");
				
				GlobalVars.instance.isCaptionListLoaded = true;
				
				var listArr:Array = listObj.sublist;
				setCaptionList(listArr);
				
				JTracer.sendMessage("SetCaptionFace -> onListLoaded, apply autoload caption");
				
				var item:CaptionItem = getCaption(_autoloadScid);
				if (item)
				{
					JTracer.sendMessage("SetCaptionFace -> onListLoaded, has autoload caption item");
					
					item.selected = true;
					showCompStatus();
				}
				else
				{
					JTracer.sendMessage("SetCaptionFace -> onListLoaded, don't has autoload caption item");
				}
			}
			else
			{
				JTracer.sendMessage("SetCaptionFace -> onListLoaded, load caption list complete, ret:" + listObj.ret);
				
				GlobalVars.instance.isCaptionListLoaded = false;
				setCaptionList([]);
			}
		}
		
		private function onListIOError(evt:IOErrorEvent):void
		{
			JTracer.sendMessage("SetCaptionFace -> onListIOError, load caption IOError");
			
			GlobalVars.instance.isCaptionListLoaded = false;
			setCaptionList([]);
		}
		
		private function onListSecurityError(evt:SecurityErrorEvent):void
		{
			JTracer.sendMessage("SetCaptionFace -> onListSecurityError, load caption SecurityError");
			
			GlobalVars.instance.isCaptionListLoaded = false;
			setCaptionList([]);
		}
		
		private function setCaptionList(arr:Array):void
		{
			removeCaptions(0);
			hideNoCaptionTips();
			
			_listArray = arr || [];
			_itemArray = [];
			
			if (!_listArray || _listArray.length == 0)
			{
				showEmptyListTips();
				return;
			}
			
			//只选择4个自动匹配的字幕
			while (_listArray.length > 4)
			{
				_listArray.pop();
			}
			
			for(var i:* in _listArray)
			{
				var rname:String = "在线字幕" + (i + 1) + "：";
				var sname:String = sliceSname(_listArray[i].sname);
				var fname:String = _listArray[i].sname;
				var surl:String = _listArray[i].surl;
				var scid:String = _listArray[i].scid;
				
				var propObj:Object = { rname:rname, sname:sname, fname:fname, surl:surl, scid:scid, manual:false, selected:false, enable:true, row:i };
				createCaption(propObj);
			}
		}
		
		private function onSearchClick(evt:TextEvent):void
		{
			switch(evt.text)
			{
				case "search":
					//点击搜索，退出全屏
					if (stage.displayState == StageDisplayState.FULL_SCREEN)
					{
						stage.displayState = StageDisplayState.NORMAL;
					}
					Tools.windowOpen(GlobalVars.instance.url_search_subtitle);
					break;
			}
		}
		
		private function onItemClick(evt:MouseEvent):void
		{
			var item:CaptionItem = evt.currentTarget as CaptionItem;
			var isRetry:Boolean = item.status_txt.text == "重试";
			if (!item.buttonMode)
			{
				return;
			}
			
			if (_lastScid && _lastScid != item.scid)
			{
				JTracer.sendMessage("SetCaptionFace -> onItemClick, subtitle grade, isRetry:" + isRetry);
				gradeCaption();
			}
			_lastScid = null;
			
			clearStatus();
			loadContent(item, isRetry);
		}
		
		private function gradeCaption():void
		{
			var gcid:String = Tools.getUserInfo("ygcid");
			var cid:String = Tools.getUserInfo("ycid");
			var scid:String = _lastScid;
			if (!gcid || !cid || !scid)
			{
				JTracer.sendMessage("SetCaptionFace -> subtitle grade, curFileInfo is null");
				return;
			}
			
			var params:URLVariables = new URLVariables();
			params.a = "";
			
			var req:URLRequest = new URLRequest(GlobalVars.instance.url_subtitle_grade + "?gcid=" + gcid + "&cid=" + cid + "&scid=" + scid + "&type=1");
			req.method = URLRequestMethod.POST;
			req.data = params;
			
			JTracer.sendMessage("SetCaptionFace -> subtitle grade, url:" + req.url);
			
			sendToURL(req);
		}
		
		private function onItemOver(evt:MouseEvent):void
		{
			var item:CaptionItem = evt.currentTarget as CaptionItem;
			item.bg_mc.visible = true;
			item.name_txt.setTextFormat(_overTF);
			
			Tools.showToolTip(decodeURI(item.fullname));
			Tools.moveToolTip();
		}
		
		private function onItemOut(evt:MouseEvent):void
		{
			var item:CaptionItem = evt.currentTarget as CaptionItem;
			item.bg_mc.visible = false;
			item.name_txt.setTextFormat(_outTF);
			
			Tools.hideToolTip();
		}
		
		private function onItemMove(evt:MouseEvent):void
		{
			Tools.moveToolTip();
		}
		
		private function clearStatus():void
		{
			var i:*;
			var item:CaptionItem;
			for (i in _itemArray)
			{
				item = _itemArray[i] as CaptionItem;
				item.status_mc.visible = false;
				item.status_txt.text = "";
			}
		}
		
		private function loadContent(item:CaptionItem, isRetry:Boolean):void
		{
			if (item.selected)
			{
				item.selected = false;
				item.status_mc.visible = false;
				item.status_mc.gotoAndStop(1);
				item.status_txt.text = "";
				
				//隐藏字幕
				dispatchEvent(new CaptionEvent(CaptionEvent.HIDE_CAPTION, {surl:item.surl, scid:item.scid, sdata:item.data}));
				
				Tools.stat("b=qxzm&e=0&gcid=" + Tools.getUserInfo("ygcid"));
			}
			else
			{
				deselect();
				
				item.selected = true;
				item.status_mc.visible = true;
				item.status_mc.gotoAndStop(1);
				item.status_txt.text = "加载中...";
				
				//加载字幕样式
				dispatchEvent(new CaptionEvent(CaptionEvent.LOAD_STYLE));
				//设置时间轴调整信息未加载完
				GlobalVars.instance.isCaptionTimeLoaded = false;
				//加载时间轴调整信息
				dispatchEvent(new CaptionEvent(CaptionEvent.LOAD_TIME, {scid:item.scid}));
				//加载字幕内容
				dispatchEvent(new CaptionEvent(CaptionEvent.LOAD_CONTENT, {surl:item.surl, scid:item.scid, sname:item.fullname, sdata:item.data, isSaveAutoload:true, isRetry:isRetry, gradeTime:180}));
			}
		}
		
		private function deselect():void
		{
			var i:*;
			var item:CaptionItem;
			for (i in _itemArray)
			{
				item = _itemArray[i] as CaptionItem;
				item.selected = false;
			}
		}
		
		private function onUploadClick(evt:MouseEvent):void
		{
			//上传文件自动退出全屏
			if (stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				stage.displayState = StageDisplayState.NORMAL;
			}
			
			var uploader:FileUploader = new FileUploader(_timeOut);
			uploader.addEventListener(CaptionEvent.SELECT_FILE, selectFile);
			uploader.addEventListener(CaptionEvent.UPLOAD_COMPLETE, uploadComplete);
			uploader.addEventListener(CaptionEvent.UPLOAD_ERROR, uploadError);
			uploader.addEventListener(CaptionEvent.LOAD_COMPLETE, loadComplete);
			uploader.browse([_fileFilter]);
		}
		
		private function selectFile(evt:CaptionEvent):void
		{
			var uploader:FileUploader = evt.currentTarget as FileUploader;
			var fileName:String = evt.info.fileName;
			var fileSize:Number = evt.info.fileSize;
			
			//删除字幕列表为空的提示
			hideNoCaptionTips();
			
			//如果当前已应用上传的字幕，再次上传会把之前的取消
			var i:*;
			var item:CaptionItem;
			for (i in _itemArray)
			{
				item = _itemArray[i] as CaptionItem;
				if (item.selected)
				{
					//隐藏字幕
					dispatchEvent(new CaptionEvent(CaptionEvent.HIDE_CAPTION, {surl:item.surl, scid:item.scid, sdata:item.data}));
					
					Tools.stat("b=qxzm&e=0&gcid=" + Tools.getUserInfo("ygcid"));
					break;
				}
			}
			
			//大于3个字幕时，删除最后一个字幕
			removeCaptions(3);
			
			var sname:String = sliceSname(fileName);
			var propObj:Object = { rname:"上传字幕：", sname:sname, fname:fileName, surl:"", scid:"", manual:true, selected:true, enable:false, row:_itemArray.length, data:null };
			var uploadItem:CaptionItem = createCaption(propObj);
			uploader.uploadItem = uploadItem;
			
			//文件大于规定大小
			if (fileSize > _limitSize)
			{
				uploadError(evt);
				return;
			}
			
			if (Tools.getUserInfo("userid") != "0")
			{
				var date:Date = new Date();
				var fix:String = formatUrl(_uploadURL);
				var url:String = _uploadURL + fix + "sname=" + encodeURIComponent(fileName) + "&t=" + date.getTime();
				uploader.upload(url);
			}
			else
			{
				uploader.load();
			}
			
			showUploadStatus(uploadItem, "正在上传...");
		}
		
		private function formatUrl(url:String):String
		{
			var fix:String = "";
			if (url.indexOf("?") != -1)
			{
				fix = "&";
			}
			else
			{
				fix = "?";
			}
			
			return fix;
		}
		
		private function uploadComplete(evt:CaptionEvent):void
		{
			deselect();
			
			var jsonStr:String = evt.info.data ? String(evt.info.data) : "";
			var uploadItem:CaptionItem = evt.info.uploadItem as CaptionItem;
			var fileName:String = evt.info.fileName;
			JTracer.sendMessage("上传字幕后的返回值:" + jsonStr);
			if (!jsonStr || jsonStr == "")
			{
				uploadError(evt);
				return;
			}
			
			var obj:Object = com.serialization.json.JSON.deserialize(jsonStr) || { };
			if (obj && obj.ret == 0)
			{
				//设置获取字幕列表为完成状态
				GlobalVars.instance.isCaptionListLoaded = true;
				
				var rname:String = "上传字幕：";
				var sname:String = sliceSname(fileName);
				var fname:String = fileName;
				var surl:String = obj.surl;
				var scid:String = obj.scid;
				
				var exsitItem:CaptionItem = getCaption(scid);
				//已经存在有相同scid的字幕，删除当前上传的字幕
				if (exsitItem)
				{
					removeCaption(uploadItem);
					_itemArray.pop();
					uploadItem = exsitItem;
				}
				
				var propObj:Object = { rname:rname, sname:sname, fname:fname, surl:surl, scid:scid, manual:true, selected:true, enable:true, row:uploadItem.row };
				setCaptionProp(uploadItem, propObj);
				
				//加载字幕样式
				dispatchEvent(new CaptionEvent(CaptionEvent.LOAD_STYLE));
				//设置时间轴调整信息未加载完
				GlobalVars.instance.isCaptionTimeLoaded = false;
				//加载时间轴调整信息
				dispatchEvent(new CaptionEvent(CaptionEvent.LOAD_TIME, {scid:scid}));
				//加载字幕内容
				dispatchEvent(new CaptionEvent(CaptionEvent.LOAD_CONTENT, {surl:surl, scid:scid, sname:fname, sdata:null, isSaveAutoload:true, gradeTime:180}));
				
				Tools.stat("b=sczm&e=0&gcid=" + Tools.getUserInfo("ygcid"));
			}
			else
			{
				uploadError(evt);
			}
		}
		
		private function loadComplete(evt:CaptionEvent):void
		{
			deselect();
			
			var content:ByteArray = evt.info.data;
			var uploadItem:CaptionItem = evt.info.uploadItem as CaptionItem;
			uploadItem.data = content;
			var fileName:String = evt.info.fileName;
			
			//设置获取字幕列表为完成状态
			GlobalVars.instance.isCaptionListLoaded = true;
			
			var rname:String = "上传字幕：";
			var sname:String = sliceSname(fileName);
			var fname:String = fileName;
			var surl:String = "";
			var scid:String = "";
			
			var exsitItem:CaptionItem = getCaptionByData(content);
			//已经存在有相同content的字幕，删除当前上传的字幕
			if (exsitItem)
			{
				removeCaption(uploadItem);
				_itemArray.pop();
				uploadItem = exsitItem;
			}
			
			var propObj:Object = { rname:rname, sname:sname, fname:fname, surl:surl, scid:scid, manual:true, selected:true, enable:true, row:uploadItem.row, data:uploadItem.data };
			setCaptionProp(uploadItem, propObj);
			
			//加载字幕样式
			dispatchEvent(new CaptionEvent(CaptionEvent.LOAD_STYLE));
			//设置时间轴调整信息未加载完
			GlobalVars.instance.isCaptionTimeLoaded = false;
			//加载时间轴调整信息
			dispatchEvent(new CaptionEvent(CaptionEvent.LOAD_TIME, {scid:scid}));
			//加载字幕内容
			dispatchEvent(new CaptionEvent(CaptionEvent.LOAD_CONTENT, {surl:surl, scid:scid, sname:fname, sdata:uploadItem.data, isSaveAutoload:false, gradeTime:180}));
		}

		private function uploadError(evt:CaptionEvent):void
		{
			showUploadStatus(evt.info.uploadItem, "上传失败");
			
			Tools.stat("b=sczm&e=-1&gcid=" + Tools.getUserInfo("ygcid"));
		}
		
		private function showUploadStatus(uploadItem:CaptionItem, status:String):void
		{
			uploadItem.status_txt.text = status;
		}
		
		private function sliceSname(sname:String):String
		{
			if (getStringLength(sname) > 24)
			{
				var sidx:int = getStartIndex(sname);
				var eidx:int = getEndIndex(sname);
				var sstr:String = sname.slice(0, sidx);
				var estr:String = sname.slice(eidx);
				sname = sstr + "..." + estr;
			}
			
			return sname;
		}
		
		private function getStringLength(str:String):Number
		{
			var byte:ByteArray = new ByteArray();
			byte.writeMultiByte(str, "gb2312");
			return byte.length;
		}
		
		private function getStartIndex(str:String):int
		{
			var len:int = str.length;
			for(var i:int = 0; i < len; i++)
			{
				if(getStringLength(str.slice(0, i)) > 11)
				{
					return i;
				}
			}
			
			return 0;
		}
		
		private function getEndIndex(str:String):int
		{
			var len:int = str.length;
			for(var i:int = len - 1; i >= 0; i--)
			{
				if(getStringLength(str.slice(i)) > 11)
				{
					return i;
				}
			}
			
			return len - 1;
		}
	}
}