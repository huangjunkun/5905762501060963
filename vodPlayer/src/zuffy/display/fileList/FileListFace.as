package zuffy.display.fileList 
{
	import flash.desktop.ClipboardTransferMode;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.IMEConversionMode;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	import com.common.JTracer;
	import com.common.Tools;
	import com.global.GlobalVars;
	import com.greensock.TweenLite;
	import com.serialization.json.JSON;
	import zuffy.core.PlayerCtrl;
	import zuffy.display.tip.ToolTip;

	/**
	 * ...
	 * @author hwh
	 */
	public class FileListFace extends Sprite 
	{
		private var _prevBtn:PageNavBtn;
		private var _nextBtn:PageNavBtn;
		private var _itemsPerPage:uint = 0;	//每页数
		private var _curPageNum:uint = 0;	//当前页
		private var _curVodPageNum:uint = 0;//当前视频所在页
		private var _totalPageNum:uint;		//总页数
		private var _itemArray:Array = [];	//文件item数组
		private var _listLength:uint;		//文件列表总数
		private var _listArray:Array = [];	//文件列表
		private var _padding:Number = 5;	//左右按钮距离文件间隔
		private var _listWidth:Number = 0;	//文件列表宽度
		private var _itemWidth:Number = 83;	//文件item宽度
		private var _isPrevClick:Boolean;	//是否点击一页按钮
		private var _pageNavigator:PageNavigator;
		private var _closeBtn:CloseBtn;
		private var _totalText:TextField;
		private var _totalTF:TextFormat;
		private var _mainMc:PlayerCtrl;
		private var _nextID:int;
		private var _spacing:Number = 0;//列表左右间隔
		private var _paddingTop:Number = 5;
		private var _reqOffset:uint = 0;
		private var _reqNum:uint = 30;

		//for old api;
		private var __old__imgLoader:URLLoader;
		private var __old__imgDictionary:Dictionary;

		public function FileListFace(mainMc:PlayerCtrl) 
		{
			_mainMc = mainMc;
			
			this.visible = false;
			
			_prevBtn = new PageNavBtn();
			_prevBtn.rotation = 180;
			_prevBtn.gotoAndStop(3);
			_prevBtn.x = 10 + int(_prevBtn.width / 2) + _spacing;
			_prevBtn.y = _paddingTop + 55;
			_prevBtn.buttonMode = true;
			_prevBtn.mouseChildren = false;
			_prevBtn.mouseEnabled = false;
			_prevBtn.addEventListener(MouseEvent.CLICK, onPrevClick);
			_prevBtn.addEventListener(MouseEvent.MOUSE_OVER, onBtnOver);
			_prevBtn.addEventListener(MouseEvent.MOUSE_OUT, onBtnOut);
			addChild(_prevBtn);
			
			_nextBtn = new PageNavBtn();
			_nextBtn.gotoAndStop(3);
			_nextBtn.y = _paddingTop + 55;
			_nextBtn.buttonMode = true;
			_nextBtn.mouseChildren = false;
			_nextBtn.mouseEnabled = false;
			_nextBtn.addEventListener(MouseEvent.CLICK, onNextClick);
			_nextBtn.addEventListener(MouseEvent.MOUSE_OVER, onBtnOver);
			_nextBtn.addEventListener(MouseEvent.MOUSE_OUT, onBtnOut);
			addChild(_nextBtn);
			
			_closeBtn = new CloseBtn();
			_closeBtn.addEventListener(MouseEvent.CLICK, onCloseClick);
			_closeBtn.y = 4;
			addChild(_closeBtn);
			
			_totalTF = new TextFormat();
			_totalTF.color = 0x454545;
			_totalTF.size = 13;
			_totalTF.font = "宋体";
			
			_totalText = new TextField();
			_totalText.selectable = false;
			_totalText.defaultTextFormat = _totalTF;
			_totalText.x = 20 + _spacing;
			_totalText.y = _paddingTop;
			addChild(_totalText);
			
			_pageNavigator = new PageNavigator();
			_pageNavigator.addEventListener("SelectPage", selectPage);
			_pageNavigator.y = _paddingTop;
			addChild(_pageNavigator);
			
			__old__imgLoader = new URLLoader();
			__old__imgLoader.addEventListener(Event.COMPLETE, __old__onImgLoaded);
			__old__imgLoader.addEventListener(IOErrorEvent.IO_ERROR, __old__onImgIOError);
			__old__imgLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, __old__onImgSecurityError);
		}
		
		public function resetReqOffset():void
		{
			_reqOffset = 0;
		}
		
		public function resetListArray():void
		{
			_listArray = [];
		}
		
		public function loadFileList():void
		{
			var urlType:String = Tools.getUserInfo("urlType");
			if (urlType == "url")
			{
				JTracer.sendMessage("FileListFace -> start load url file");
				
				_listArray = [{gcid:Tools.getUserInfo("ygcid"),url_hash:Tools.getUserInfo("url_hash"), name:Tools.getUserInfo("name"), index:0}];
				_listLength = 1;
				
				updateView();
			}
			else
			{
				//var rdtime:Number = new Date().time;
				//var url:String = "http://i.vod.xunlei.com/req_subBT/info_hash/" + curObj.info_hash + "/req_num/" + _reqNum + "/req_offset/" + _reqOffset + "?cache=" + rdtime + "&jsonp=xxx";
				var url:String = "http://i.vod.xunlei.com/req_subBT/info_hash/" + Tools.getUserInfo("info_hash") + "/req_num/" + _reqNum + "/req_offset/" + _reqOffset;
				var req:URLRequest = new URLRequest(url);
				
				JTracer.sendMessage("FileListFace -> start load " + urlType + " file, url:" + url);
				
				var loader:URLLoader = new URLLoader();
				loader.addEventListener(Event.COMPLETE, onListLoaded);
				loader.addEventListener(IOErrorEvent.IO_ERROR, onListIOError);
				loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onListSecurityError);
				loader.load(req);
			}
		}
		
		public function clear():void
		{
			_prevBtn.mouseEnabled = false;
			_nextBtn.mouseEnabled = false;
			_totalText.text = "";
			_pageNavigator.clear();
			clearAllItem();
			_listArray = [];
		}
		
		public function get filelistLength():uint
		{
			return _listLength || 0;
		}
		
		public function setPosition():void
		{
			this.graphics.clear();
			this.graphics.beginFill(0x000000, 0.8);
			this.graphics.drawRect(_spacing, 0, stage.stageWidth - _spacing * 2, 145 + _paddingTop);
			this.graphics.endFill();
			
			this.y = stage.stageHeight - 145 - _paddingTop;
			_closeBtn.x = int(stage.stageWidth - _spacing - 20);
			_nextBtn.x = int(stage.stageWidth - _spacing - 10 - _nextBtn.width / 2);
			
			_listWidth = _nextBtn.x - _prevBtn.x - _prevBtn.width;
			_itemsPerPage = Math.floor(_listWidth / _itemWidth) - 1;
			
			if (this.visible)
			{
				getCurrentVodPageNum();
				
				_curPageNum = _curVodPageNum;
				_isPrevClick = true;
				
				updateView();
			}
		}
		
		public function hide(rightNow:Boolean = false):void
		{
			if (rightNow) {
				TweenLite.killTweensOf(this);
				this.y = stage.stageHeight - 110 - _paddingTop;
			} else {
				TweenLite.to(this, 0.3, { y:stage.stageHeight - 110 - _paddingTop } );
			}
		}
		
		public function show(rightNow:Boolean = false):void
		{
			if (rightNow) {
				TweenLite.killTweensOf(this);
				this.y = stage.stageHeight - 145 - _paddingTop;
			} else {
				TweenLite.to(this, 0.3, { y:stage.stageHeight - 145 - _paddingTop } );
			}
		}
		
		public function showFace(boo:Boolean):void
		{
			this.visible = boo;
			
			if (boo)
			{
				getCurrentVodPageNum();
				
				_curPageNum = _curVodPageNum;
				_isPrevClick = true;
				
				updateView();
			}
		}
		
		public function get isHasNext():Boolean
		{
			var idx:int = getIndex();
			if (idx == -1 || idx >= _listLength - 1)
			{
				_nextID = -1;
				//无下一集
				return false;
			}
			
			_nextID = idx;
			//有下一集
			return true;
		}
		
		public function playNext():void
		{
			var obj:Object = _listArray[_nextID + 1];
			exchangeVideo(obj);
		}
		
		private function getIndex():int
		{
			var i:*;
			for (i in _listArray)
			{
				if (Tools.getUserInfo("url_hash") == _listArray[i].url_hash || Tools.getUserInfo("index") == _listArray[i].index)
				{
					return int(i);
				}
			}
			
			return -1;
		}
		
		private function __old__onImgLoaded(evt:Event):void
		{
			var jsonStr:String = evt.target.data;
			jsonStr = jsonStr.substring(4, jsonStr.length - 1);
			var jsonObj:Object = com.serialization.json.JSON.deserialize(jsonStr);
			if (!jsonObj || !jsonObj.resp || !jsonObj.resp.screenshot_list)
			{
				return;
			}
			
			__old__imgDictionary = new Dictionary();
			
			var listObj:Object = jsonObj.resp.screenshot_list;
			var sizeStr:String = '_X' + GlobalVars.instance.screenshot_size;
			var picNum = "";
			var i:*;
			var obj:Object;
			for (i in listObj)
			{
				obj = listObj[i];
				var num:int = parseInt(obj.gcid.charAt(0), 15);
				num = num % 5;
				var url:String = '';
				
				if (Tools.getUserInfo("urlType") == "url")
				{
					__old__imgDictionary[0] = obj.smallshot_url;
				}
				else
				{
					__old__imgDictionary[obj.idx] = obj.smallshot_url;
				}
			}
			
			var j:*;
			var item:ListItem;
			for (j in _itemArray)
			{
				item = _itemArray[j] as ListItem;
				if (!item.isImgLoaded)
				{
					if (Tools.getUserInfo("urlType") == "url")
					{
						item.setImgInfo(__old__imgDictionary[0]);
					}
					else
					{
						item.setImgInfo(__old__imgDictionary[item.itemObj.index]);
					}
				}
			}
		}
		
		private function __old__onImgIOError(evt:IOErrorEvent):void
		{
			
		}
		
		private function __old__onImgSecurityError(evt:SecurityErrorEvent):void
		{
			
		}
		
		private function updateView():void
		{
			_totalText.text = _listLength == 0 ? "共" + _listLength + "个视频" : "共" + _listLength + "个视频，";
			_totalText.width = _totalText.textWidth + 5;
			_totalText.height = _totalText.textHeight + 5;
			_pageNavigator.x = _totalText.x + _totalText.width - 20;
			
			//总页数
			_totalPageNum = Math.ceil(_listLength / _itemsPerPage);
			
			_pageNavigator.setOuterParam(_listLength, _totalPageNum, _itemsPerPage);
			
			//设置按钮状态
			_prevBtn.mouseEnabled = false;
			if (_totalPageNum > 1)
			{
				_nextBtn.mouseEnabled = true;
			}
			else
			{
				_nextBtn.mouseEnabled = false;
			}
			
			killAllAlphaTween();
			
			_pageNavigator.showItemNum = Math.max(2, Math.floor((stage.stageWidth - _pageNavigator.x) / 62) - 2);
			_pageNavigator.currentPageNum = _curPageNum;
			setBtnStatus();
			if(GlobalVars.instance.isUseXlpanKanimg){
				JTracer.sendMessage('use xlpan kanimg');
				updateFileList();
			}
			else{
				JTracer.sendMessage('use old screenshot_list api.');
				__old__updateFileList();			
			}
			
			applyAlphaTween();
		}
		
		private function onListLoaded(evt:Event):void
		{
			JTracer.sendMessage("FileListFace -> " + Tools.getUserInfo("urlType") + " list loaded, req_offset:" + _reqOffset);
			
			var jsonStr:String = evt.target.data;
			var jsonObj:Object = com.serialization.json.JSON.deserialize(jsonStr);
			if (!jsonObj || !jsonObj.resp || !jsonObj.resp.subfile_list)
			{
				return;
			}
			
			JTracer.sendMessage("FileListFace -> parse " + Tools.getUserInfo("urlType") + " list json complete");
			
			if (jsonObj.resp.subfile_list.length > 0)
			{
				_listArray = _listArray.concat(jsonObj.resp.subfile_list);
				_listLength = jsonObj.resp.record_num;
				
				if (_listArray.length < _listLength)
				{
					_reqOffset += _reqNum;
					
					loadFileList();
				}
			}
		}
		
		private function onListIOError(evt:IOErrorEvent):void
		{
			
		}
		
		private function onListSecurityError(evt:SecurityErrorEvent):void
		{
			
		}
		
		private function getCurrentVodPageNum():void
		{
			var i:*;
			var itemObj:Object;
			for (i in _listArray)
			{
				itemObj = _listArray[i];
				
				if (itemObj.url_hash == Tools.getUserInfo("url_hash") || itemObj.index == Tools.getUserInfo("index"))
				{
					_curVodPageNum = Math.floor(i / _itemsPerPage);
					break;
				}
			}
		}
		
		private function onPrevClick(evt:MouseEvent):void
		{
			_curPageNum--;
			_isPrevClick = true;
			
			updateView();
		}
		
		private function onNextClick(evt:MouseEvent):void
		{
			_curPageNum++;
			_isPrevClick = false;
			
			updateView();
		}
		
		private function selectPage(evt:Event):void
		{
			_curPageNum = _pageNavigator.currentPageNum;
			_isPrevClick = true;
			
			updateView();
		}
		
		private function onCloseClick(evt:MouseEvent):void
		{
			showFace(false);
		}
		
		private function onBtnOver(evt:MouseEvent):void
		{
			var btn:MovieClip = evt.currentTarget as MovieClip;
			if (btn.mouseEnabled)
			{
				btn.gotoAndStop(2);
			}
		}
		
		private function onBtnOut(evt:MouseEvent):void
		{
			var btn:MovieClip = evt.currentTarget as MovieClip;
			if (btn.mouseEnabled)
			{
				btn.gotoAndStop(1);
			}
		}
		
		private function setBtnStatus():void
		{
			if (_curPageNum < 1)
			{
				_prevBtn.gotoAndStop(3);
				_prevBtn.mouseEnabled = false;
			}
			else
			{
				_prevBtn.gotoAndStop(1);
				_prevBtn.mouseEnabled = true;
			}
			
			if (_curPageNum < _totalPageNum - 1)
			{
				_nextBtn.gotoAndStop(1);
				_nextBtn.mouseEnabled = true;
			}
			else
			{
				_nextBtn.gotoAndStop(3);
				_nextBtn.mouseEnabled = false;
			}
		}
		
		private function updateFileList():void{
			clearAllItem();
			
			if (_listArray.length == 0)
			{
				return;
			}

			var startID:uint = _curPageNum * _itemsPerPage;
			var endID:uint = Math.min((_curPageNum + 1) * _itemsPerPage, _listLength);
			var i:uint;
			var item:ListItem;
			var itemSpace:Number = (_listWidth - 2 * _padding - _itemsPerPage * _itemWidth) / (_itemsPerPage - 1);
			var itemObj:Object;
			var idxArr:Array = [];
			var idxStr:String;
			var startX:Number = (_listWidth - 2 * _padding - ((endID - startID) * (_itemWidth + itemSpace) - itemSpace))/2;
			for (i = startID; i < endID; i++)
			{
				itemObj = _listArray[i];
				
				item = new ListItem();
				item.setItemInfo(itemObj, i);
				item.x = Math.round(_prevBtn.x + _prevBtn.width / 2 + _padding + (_itemWidth + itemSpace) * (i - startID));
				//item.x = Math.round(startX + _prevBtn.x + _prevBtn.width / 2 + _padding + (_itemWidth + itemSpace) * (i - startID));
				item.y = _paddingTop + 25;
				item.alpha = 0;

				if (itemObj.url_hash == Tools.getUserInfo("url_hash") || itemObj.index == Tools.getUserInfo("index"))
				{
					item.selected = true;
					item.buttonMode = false;
					item.removeEventListener(MouseEvent.CLICK, onItemClick);
				}
				else
				{
					item.selected = false;
					item.buttonMode = true;
					item.addEventListener(MouseEvent.CLICK, onItemClick);
				}
				item.addEventListener(MouseEvent.MOUSE_OVER, onItemOver);
				item.addEventListener(MouseEvent.MOUSE_OUT, onItemOut);
				item.addEventListener(MouseEvent.MOUSE_MOVE, onItemMove);
				addChildAt(item, 0);
				
				_itemArray.push(item);
				idxArr.push(itemObj.index);

				//加载图片
				if (this.visible)
				{
					var sizeStr:String = '_X' + GlobalVars.instance.screenshot_size;
					var picNum = "";
					var url:String = '';
					var num:int = parseInt(itemObj.gcid.charAt(0), 15);
					num = num % 5;
					if(GlobalVars.instance.isUseXlpanKanimg){
						url = GlobalVars.instance.url_new_screen_shot.replace(/{n}/g, num) + itemObj.gcid + sizeStr + picNum +'.jpg';
						JTracer.sendMessage('FileListFace -> image url:' + url);
					}
					item.setImgInfo(url)
				}

			}

		}		


		private function __old__updateFileList():void
		{
			clearAllItem();
			
			if (_listArray.length == 0)
			{
				return;
			}
			
			var startID:uint = _curPageNum * _itemsPerPage;
			var endID:uint = Math.min((_curPageNum + 1) * _itemsPerPage, _listLength);
			var i:uint;
			var item:ListItem;
			var itemSpace:Number = (_listWidth - 2 * _padding - _itemsPerPage * _itemWidth) / (_itemsPerPage - 1);
			var itemObj:Object;
			var idxArr:Array = [];
			var idxStr:String;
			var startX:Number = (_listWidth - 2 * _padding - ((endID - startID) * (_itemWidth + itemSpace) - itemSpace))/2;
			for (i = startID; i < endID; i++)
			{
				itemObj = _listArray[i];
				
				item = new ListItem();
				item.setItemInfo(itemObj, i);
				
				item.x = Math.round(_prevBtn.x + _prevBtn.width / 2 + _padding + (_itemWidth + itemSpace) * (i - startID));
				item.y = _paddingTop + 25;
				item.alpha = 0;
				if (itemObj.url_hash == Tools.getUserInfo("url_hash") || itemObj.index == Tools.getUserInfo("index"))
				{
					item.selected = true;
					item.buttonMode = false;
					item.removeEventListener(MouseEvent.CLICK, onItemClick);
				}
				else
				{
					item.selected = false;
					item.buttonMode = true;
					item.addEventListener(MouseEvent.CLICK, onItemClick);
				}
				item.addEventListener(MouseEvent.MOUSE_OVER, onItemOver);
				item.addEventListener(MouseEvent.MOUSE_OUT, onItemOut);
				item.addEventListener(MouseEvent.MOUSE_MOVE, onItemMove);
				addChildAt(item, 0);
				
				_itemArray.push(item);
				idxArr.push(itemObj.index);
			}
			
			//加载缩略图
			idxStr = idxArr.join("/");
			
			var url:String;
			if (Tools.getUserInfo("urlType") == "url")
			{
				url = GlobalVars.instance.url_screen_shot + "&req_list=" + Tools.getUserInfo("ygcid");
				JTracer.sendMessage("FileListFace -> 缩略图, url, url=" + url);
			}
			else
			{
				url = GlobalVars.instance.bt_screen_shot + "&info_hash=" + Tools.getUserInfo("info_hash") + "&req_list=" + idxStr;
				JTracer.sendMessage("FileListFace -> 缩略图, " + Tools.getUserInfo("urlType") + ", url=" + url);
			}
			var req:URLRequest = new URLRequest(url);
			//可见时才调用缩略图
			if (this.visible)
			{
				JTracer.sendMessage("FileListFace -> 加载缩略图");
				__old__imgLoader.load(req);
			}
		}
		
		private function onItemOver(evt:MouseEvent):void
		{
			var item:ListItem = evt.currentTarget as ListItem;
			item.itemOver();
			
			if (evt.target == item.nameMc)
			{
				var decodeName:String = decodeURI(item.itemObj.name);
				
				Tools.showToolTip(decodeName);
				Tools.moveToolTip();
			}
		}
		
		private function onItemOut(evt:MouseEvent):void
		{
			var item:ListItem = evt.currentTarget as ListItem;
			item.itmeOut();
			
			if (evt.target == item.nameMc)
			{
				Tools.hideToolTip();
			}
		}
		
		private function onItemMove(evt:MouseEvent):void
		{
			var item:ListItem = evt.currentTarget as ListItem;
			
			if (evt.target == item.nameMc)
			{
				Tools.moveToolTip();
			}
		}
		
		private function onItemClick(evt:MouseEvent):void
		{
			setAllNonSelect();
			
			var item:ListItem = evt.currentTarget as ListItem;
			//item.selected = true;
			item.clicked = true;
			item.buttonMode = false;
			item.removeEventListener(MouseEvent.CLICK, onItemClick);
			
			var obj:Object = item.itemObj;
			exchangeVideo(obj);
		}
		
		/**
		 * obj 文件参数
		 * obj.url_hash
		 * obj.index
		 * obj.name
		 */
		private function exchangeVideo(obj:Object):void
		{
			//切换视频
			_mainMc.exchangeVideo();
			
			var i:*;
			for (i in obj)
			{
				Tools.setUserInfo(i, obj[i]);
			}
			
			var url:String = "bt://" + Tools.getUserInfo("info_hash") + "/" + obj.index;
			ExternalInterface.call("XL_CLOUD_FX_INSTANCE.playOther", false, url, obj.url_hash, obj.name, obj.ygcid, obj.cid);
		}
		
		private function setAllNonSelect():void
		{
			var i:*;
			var item:ListItem;
			for (i in _itemArray)
			{
				item = _itemArray[i] as ListItem;
				item.selected = false;
				item.buttonMode = true;
				item.addEventListener(MouseEvent.CLICK, onItemClick);
			}
		}
		
		private function killAllAlphaTween():void
		{
			var i:*;
			var item:ListItem;
			for (i in _itemArray)
			{
				item = _itemArray[i] as ListItem;
				TweenLite.killTweensOf(item);
			}
		}
		
		private function applyAlphaTween():void
		{
			var i:uint;
			var len:uint = _itemArray.length;
			var item:ListItem;
			if (_isPrevClick)
			{
				for (i == 0; i < len; i++)
				{
					item = _itemArray[i] as ListItem;
					TweenLite.to(item, 0.3, { alpha:1, delay:i / 10 } );
				}
			}
			else
			{
				for ( i == 0; i < len; i++)
				{
					item = _itemArray[len - 1 - i] as ListItem;
					TweenLite.to(item, 0.3, { alpha:1, delay:i / 10 });
				}
			}
		}
		
		private function clearAllItem():void
		{
			var i:uint;
			var len:uint = _itemArray.length;
			var item:ListItem;
			for (i = 0; i < len; i++)
			{
				item = _itemArray[i] as ListItem;
				item.destroy();
				removeChild(item);
				item = null;
			}
			
			_itemArray = [];
		}
	}
}