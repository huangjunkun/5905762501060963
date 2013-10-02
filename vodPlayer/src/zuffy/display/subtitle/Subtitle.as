package zuffy.display.subtitle
{
	import com.common.Tools;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.sendToURL;
	import flash.system.Capabilities;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	import com.common.JTracer;
	import com.global.GlobalVars;
	import com.Player;
	import zuffy.events.CaptionEvent;
	import zuffy.core.PlayerCtrl;
	
	/**
	 * ...字幕框
	 * @author luoyuqiang
	 */
	public class Subtitle extends Sprite
	{
		private var _player:Player;
		private var _currentWidth:Number;
		private var _currentHeight:Number;
		private var _txtSubTitle:TextField;
		private var _normalTextFormat:TextFormat;
		private var _normalTextFilter:GlowFilter;
        private var _arrList:Array;
        private var _lastTime:uint = 0;
        private var _lastIndex:uint = 0;		
		private var _getTitleTimer:Timer;
		private var _captionStamp:Number = 0;
		private var _mainMc:PlayerCtrl;
		private var _fontSize:Number = 25;
		private var _scid:String;
		private var _surl:String;
		private var _sname:String;
		private var _sdata:ByteArray;
		private var _isSaveAutoload:Boolean;
		private var _isRetry:Boolean;
		private var _reg_html:RegExp;
		private var _reg_rn:RegExp;
		private var _reg_r:RegExp;
		private var _reg_n:RegExp;
		private var _reg_N:RegExp;
		private var _startTime:Number;
		private var _endTime:Number;
		private var _curTime:Number;
		private var _totalTime:Number = 3 * 60 * 1000;
		private var _timeInterval:Number;
		private var _isGrade:Boolean;
		
		public function Subtitle(mainMc:PlayerCtrl, w:Number = 352, h:Number = 293) 
		{
			this.visible = false;
			_mainMc = mainMc;
			_mainMc.addChild(this);
			_currentWidth = w;
			_currentHeight = h;
			initializeViews();
			initializeGetSubtitleTimer();
			initRegExp();
		}
		
		public function get hasSubtitle():Boolean
		{
			if (_arrList && _arrList.length > 0)
			{
				return true;
			}
			
			return false;
		}
		
		public function setStyle(styleObj:Object):void
		{
			_normalTextFormat.color = styleObj.fontColor;
			_normalTextFormat.size = styleObj.fontSize;
			_fontSize = Number(_normalTextFormat.size);
			_normalTextFormat.size = int(_fontSize / 500 * stage.stageHeight);
			
			_normalTextFilter.color = styleObj.filterColor;
			
			_txtSubTitle.defaultTextFormat = _normalTextFormat;
			_txtSubTitle.setTextFormat(_normalTextFormat);
			_txtSubTitle.filters = [_normalTextFilter];
			_txtSubTitle.height = _txtSubTitle.textHeight + 10;
			
			this.y = stage.stageHeight - _txtSubTitle.textHeight - 50;
		}
		
		public function setTimeDelta(num:Number):void
		{
			//毫秒
			_captionStamp = num;
		}
		
		public function loadContent(contentObj:Object):void
		{
			_arrList = [];
			_surl = contentObj.surl;
			_scid = contentObj.scid;
			_sname = contentObj.sname;
			_sdata = contentObj.sdata;
			_isSaveAutoload = contentObj.isSaveAutoload;
			_isRetry = Boolean(contentObj.isRetry);
			_totalTime = Number(contentObj.gradeTime) * 1000;
			
			var req:URLRequest;
			var loader:URLLoader;
			/*
			if (_surl && _surl != "")
			{
				req = new URLRequest(_surl);
				
				loader = new URLLoader();
				loader.addEventListener(Event.COMPLETE, onLoadComplete);
				loader.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
				loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadSecurityError);
				loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onLoadStatusError);
				loader.load(req);
			}
			else 
			*/
			if (_scid)
			{
				var suffix:String = _isRetry ? "&t=" + new Date().time : "";
				req = new URLRequest(GlobalVars.instance.url_subtitle_content + "?scid=" + _scid + suffix);
				
				loader = new URLLoader();
				loader.addEventListener(Event.COMPLETE, onLoadComplete);
				loader.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
				loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoadSecurityError);
				loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onLoadStatusError);
				loader.load(req);
				return;
			}
			if (_sdata)
			{
				applyContent(_sdata);
				return;
			}
		}
		
		public function hideCaption(contentObj:Object):void
		{
			this.visible = false;
			_getTitleTimer.stop();
			
			_arrList = [];
			_surl = contentObj.surl;
			_scid = contentObj.scid;
			_txtSubTitle.htmlText = "";
			
			//取消字幕，取消下次自动加载
			saveAutoload("0");
		}
		
		public function setContent(str:String):void
		{
			if (str != "")
			{
				_arrList = parseCaptions(str);
			}
			
			if (_arrList.length > 0)
			{
				_getTitleTimer.start();
				
				ExternalInterface.call("G_PLAYER_INSTANCE.captionCallback", 1);
				dispatchEvent(new CaptionEvent(CaptionEvent.APPLY_SUCCESS));
			}
			else
			{
				ExternalInterface.call("G_PLAYER_INSTANCE.captionCallback", 5);
				dispatchEvent(new CaptionEvent(CaptionEvent.APPLY_ERROR));
			}
		}
		
		/**
		 * 保存字幕设置信息
		 */
		public function saveStyle():void
		{
			var globalVars:GlobalVars = GlobalVars.instance;
			if (Tools.getUserInfo("userid") == "0")
			{
				JTracer.sendMessage("Subtitle -> saveStyle, userid is empty");
				return;
			}
			
			var userid:String = Tools.getUserInfo("userid");
			var scid:String = _scid;
			var font_size:String = _fontSize.toString();
			var font_color:String = toARGB(uint(_normalTextFormat.color));
			var background_color:String = toARGB(uint(_normalTextFilter.color));
			
			var params:URLVariables = new URLVariables();
			params.font_size = font_size;
			params.font_color = font_color;
			params.background_color = background_color;
			
			var req:URLRequest = new URLRequest(globalVars.url_subtitle_style + "?userid=" + userid);
			req.method = URLRequestMethod.POST;
			req.data = params;
			
			JTracer.sendMessage("Subtitle -> saveStyle, url:" + req.url + ", params:" + params);
			
			sendToURL(req);
		}
		
		/**
		 * 保存时间轴调整信息
		 */
		public function saveTimeDelta():void
		{
			if (!_scid)
			{
				return;
			}
			
			var globalVars:GlobalVars = GlobalVars.instance;
			if (Tools.getUserInfo("ygcid") == null || Tools.getUserInfo("ycid") == null || Tools.getUserInfo("userid") == "0")
			{
				JTracer.sendMessage("Subtitle -> saveTimeDelta, userid is empty");
				return;
			}
			var gcid:String = Tools.getUserInfo("ygcid");
			var cid:String = Tools.getUserInfo("ycid");
			var userid:String = Tools.getUserInfo("userid");
			var scid:String = _scid;
			
			var params:URLVariables = new URLVariables();
			params.time_delta = _captionStamp;
			
			var req:URLRequest = new URLRequest(globalVars.url_subtitle_time + "?gcid=" + gcid + "&cid=" + cid + "&userid=" + userid + "&scid=" + scid);
			req.method = URLRequestMethod.POST;
			req.data = params;
			
			JTracer.sendMessage("Subtitle -> saveTimeDelta, url:" + req.url + ", params:" + params);
			
			sendToURL(req);
		}
		
		private function getFontFamily():String
		{
			var fontObj:Object = { "微软雅黑":["Windows Vista", "Windows 7", "Windows 8"], "幼圆": ["Windows XP"] };
			var i:*;
			var j:*;
			var arr:Array;
			for (i in fontObj)
			{
				arr = fontObj[i];
				for (j in arr)
				{
					if (arr[j].indexOf(Capabilities.os) > -1)
					{
						return i;
					}
				}
			}
			
			return "宋体";
		}
		
		private function initializeViews():void
		{
			var fontFamily:String = getFontFamily();
			
			_normalTextFormat = new TextFormat();
			_normalTextFormat.color = 0xffffff;
			_normalTextFormat.size = int(_fontSize / 500 * stage.stageHeight);
			_normalTextFormat.font = fontFamily;
			_normalTextFormat.align = "center";
			_normalTextFormat.bold = true;
			
			_normalTextFilter = new GlowFilter(0x000000, 1, 2, 2, 5, BitmapFilterQuality.HIGH);
			
			_txtSubTitle = new TextField();
			_txtSubTitle.wordWrap = true;
			_txtSubTitle.multiline = true;
			_txtSubTitle.defaultTextFormat = _normalTextFormat;
			_txtSubTitle.selectable = false;
			_txtSubTitle.width = _currentWidth - 40;
			_txtSubTitle.x = 20;
			_txtSubTitle.filters = [_normalTextFilter];
			addChild(_txtSubTitle);
		}
		
		/*获取字幕的timer*/
		private function initializeGetSubtitleTimer():void
		{
			_getTitleTimer = new Timer(50);
			_getTitleTimer.addEventListener(TimerEvent.TIMER, function handlGetTitleTimer():void{
				if(_scid)
				dispatchEvent(new CaptionEvent(CaptionEvent.GET_TITLE_TIMER));
			});
		}
		
		private function initRegExp():void
		{
			//去掉html标签
			//reg_html = new RegExp("<(\S*?)[^>]*>.*?|<.*? />", "g");
			_reg_html = new RegExp("<([\S|/]*?)[^/>]*>.*?|<.*? />", "g");//过滤html，保留<br/>
			_reg_rn = /\\r\\n/g;
			_reg_r = /\\r/g;
			_reg_n = /\\n/g;
			_reg_N = /\\N/g;
		}
		
		private function toARGB(color:uint):String
		{
			//var a:uint = color >> 24 & 0xFF;
			var r:uint = color >> 16 & 0xFF;
			var g:uint = color >> 8 & 0xFF;
			var b:uint = color & 0xFF;
			return (r + "," + g + "," + b);
		}
		
		/**
		 * 保存字幕自动加载信息
		 */
		private function saveAutoload(autoload:String):void
		{
			if (!_scid)
			{
				return;
			}
			
			var globalVars:GlobalVars = GlobalVars.instance;
			if (Tools.getUserInfo("ygcid") == null || Tools.getUserInfo("ycid") == null || Tools.getUserInfo("userid") == "0")
			{
				JTracer.sendMessage("Subtitle -> saveStyle, userid is empty");
				return;
			}
			
			var gcid:String = Tools.getUserInfo("ygcid");
			var cid:String = Tools.getUserInfo("ycid");
			var userid:String = Tools.getUserInfo("userid");
			var scid:String = _scid;
			var sname:String = _sname;
			
			var params:URLVariables = new URLVariables();
			params.autoload = autoload;
			
			var req:URLRequest = new URLRequest(globalVars.url_subtitle_autoload + "?gcid=" + gcid + "&cid=" + cid + "&userid=" + userid + "&scid=" + scid + "&sname=" + encodeURIComponent(sname));
			req.method = URLRequestMethod.POST;
			req.data = params;
			
			JTracer.sendMessage("Subtitle -> saveAutoload, url:" + req.url + ", params:" + params);
			
			sendToURL(req);
		}
		
		private function onLoadComplete(e:Event):void 
		{
            var loader:URLLoader = URLLoader(e.target);
            applyContent(loader.data)
		}
		
		private function applyContent(data:Object):void
		{
			var txt:String = data.toString();
            if (txt != "") {
                _arrList = parseCaptions(txt);
            }
			
			if (_arrList.length > 0)
			{
				_isGrade = false;
				_startTime = getTimer();
				_curTime = 0;
				
				JTracer.sendMessage("Subtitle -> subtitle grade, start timer, getTimer():" + _startTime);
				
				_getTitleTimer.start();
				
				//加载成功，显示字幕
				this.visible = true;
				//加载成功，设置下次自动加载，开播自动加载的字幕不用保存
				if (_isSaveAutoload)
				{
					saveAutoload("1");
				}
				ExternalInterface.call("G_PLAYER_INSTANCE.captionCallback", 1);
				dispatchEvent(new CaptionEvent(CaptionEvent.APPLY_SUCCESS));
			}
			else
			{
				ExternalInterface.call("G_PLAYER_INSTANCE.captionCallback", 5);
				dispatchEvent(new CaptionEvent(CaptionEvent.APPLY_ERROR));
			}
		}
		
		private function parseCaptions(dat:String):Array
		{
			var arr:Array = [];
			//清除前面和后面的空格
			dat = trim(dat);
			
			var lst:Array = dat.split("\r\n\r\n");
			if(lst.length == 1)
			{
				lst = dat.split("\n\n");
			}
			
			var i:uint;
			var len:uint = lst.length;
			for(i = 0; i < len; i++)
			{
				var obj:Object = parseCaption(lst[i]);
				if(obj.bt && obj.et && obj.txt)
				{
					arr.push(obj);
				}
			}
			
			return arr;
		}
		
		private function parseCaption(dat:String):Object
		{
			//清除前面和后面的空格
			dat = trim(dat);
			
			var obj:Object = new Object();
			var arr:Array = dat.split("\r\n");
			if(arr.length == 1)
			{
				arr = dat.split("\n");
			}
			
			try
			{
				var idx:Number = arr[1].indexOf('-->');
				if(idx > 0)
				{
					obj['bt'] = parseTime(arr[1].substr(0, idx));
					obj['et'] = parseTime(arr[1].substr(idx + 3));
				}
				
				if(arr[2])
				{
					
					obj['txt'] = arr[2].replace(_reg_html, "");
					
					var i:uint;
					var len:uint = arr.length;
					for (i = 3; i < len; i++)
					{
						obj['txt'] += '<br/>' + arr[i];
					}
					
					obj['txt'] = obj['txt'].replace(_reg_rn, "<br/>");
					obj['txt'] = obj['txt'].replace(_reg_r, "<br/>");
					obj['txt'] = obj['txt'].replace(_reg_n, "<br/>");
					obj['txt'] = obj['txt'].replace(_reg_N, "<br/>");
				}
			}
			catch (err:Error)
			{
			}
			
			return obj;
		}
		
		//清除前面和后面的空格
		private function trim(s:String):String
		{
			return s.replace(/^\s+/, '').replace(/\s+$/, '');
		}
		
		private function onLoadError(evt:IOErrorEvent):void
		{
			ExternalInterface.call("G_PLAYER_INSTANCE.captionCallback", 2);
			dispatchEvent(new CaptionEvent(CaptionEvent.APPLY_ERROR));
		}
		
		private function onLoadSecurityError(evt:SecurityErrorEvent):void
		{
			ExternalInterface.call("G_PLAYER_INSTANCE.captionCallback", 3);
			dispatchEvent(new CaptionEvent(CaptionEvent.APPLY_ERROR));
		}
		
		private function onLoadStatusError(evt:HTTPStatusEvent):void
		{
			ExternalInterface.call("G_PLAYER_INSTANCE.captionCallback", 4);
		}
		
		/*解析开始时间跟结束时间*/
        private function parseTime(str:String):uint {
            var nRet:uint = 0;
            if (str != "") {
                var arr1:Array = str.split(",");
                var nMs:uint = parseInt(arr1[1]);
                var arr2:Array = arr1[0].split(":");
                var nH:uint = parseInt(arr2[0]);
                var nM:uint = parseInt(arr2[1]);
                var nS:uint = parseInt(arr2[2]);
                nRet += nS * 1000;
                nRet += nM * 60 * 1000;
                nRet += nH * 60 * 60 * 1000;
                nRet += nMs;
                
            }
			trace("parseTime:" + nRet);
            return nRet;
        }
		
		/*获得对应时间点的字幕*/
        private function getText(time:uint):String {
            var strRet:String = "";
			var i:uint;
			var len:uint = _arrList.length;
            for (i = 0; i < len; i++) {
                var obj:Object = _arrList[i];
                if (obj.bt <= time && time <= obj.et) {
                    strRet = obj.txt;
                    break;
                }
            }
			trace("getText:" + strRet);
            
            return strRet;
        }		

        public function setPlayerTime(time:Number, isStartPlayLoading:Boolean):void{
        	if (isStartPlayLoading)
			{
				_txtSubTitle.text = "";
				return;
			}
			
			var subTitle:String = getText(time * 1000 - _captionStamp);
			_txtSubTitle.htmlText = subTitle;
			_txtSubTitle.height = _txtSubTitle.textHeight + 10;
			
			this.y = stage.stageHeight - _txtSubTitle.textHeight - 50;

			//字幕打分
			_endTime = getTimer();
			_timeInterval = _endTime - _startTime;
			_startTime = _endTime;
			_curTime += _timeInterval;
			if (_curTime > _totalTime && !_isGrade)
			{
				_isGrade = true;
				
				var gcid:String = Tools.getUserInfo("ygcid");
				var cid:String = Tools.getUserInfo("ycid");
				var scid:String = _scid;
				
				var params:URLVariables = new URLVariables();
				params.a = "";
				
				var req:URLRequest = new URLRequest(GlobalVars.instance.url_subtitle_grade + "?gcid=" + gcid + "&cid=" + cid + "&scid=" + scid + "&type=0");
				req.method = URLRequestMethod.POST;
				req.data = params;
				
				JTracer.sendMessage("Subtitle -> subtitle grade, end timer, getTimer():" + _curTime + ", url:" + req.url);
				
				sendToURL(req);
			}
        }
		
		//flash大小改变后
		public function handleStageResize(width:Number,height:Number,isFullScreen:Boolean = false):void
		{
			_normalTextFormat.size = int(_fontSize / 500 * height);
			
			_txtSubTitle.defaultTextFormat = _normalTextFormat;
			_txtSubTitle.setTextFormat(_normalTextFormat);
			_txtSubTitle.width = width - 40;
			_txtSubTitle.height = _txtSubTitle.textHeight + 10;
			
			this.y = height - _txtSubTitle.textHeight - 50;
			
			_currentWidth = width;
			_currentHeight = height;
		}
	}
}