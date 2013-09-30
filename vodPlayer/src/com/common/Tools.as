package com.common 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.sendToURL;
	import flash.text.StyleSheet;
	import com.global.GlobalVars;
	import zuffy.display.tip.ToolTip;

	/**
	 * ...
	 * @author hwh
	 */
	public class Tools 
	{
		private static var _mainMc:Sprite;
		private static var _snptBmd:BitmapData;
		
		public function Tools() 
		{
			
		}

		public static function getDocumentCookieWithKey(key:String):String{
			var value:String = '';
			if (ExternalInterface.available){
				var cookie:String = ExternalInterface.call('function(){return document.cookie;}');
				if(cookie && cookie != '' && cookie != 'null'){
					var k_v:Array = cookie.split('; '); // key=value; key2=value2;
					for(var k in k_v){
						var kv:Array = k_v[k].split('=');
						//ExternalInterface.call('window.console.log',kv[0]+'  '+key);
						if(kv[0] == key){
							value = kv[1];
							return value;
							break;
						}
					}
				}
			}
			return '';
		}
		
		public static function getUserInfo(key:String):String
		{
			var glovalVars:GlobalVars = GlobalVars.instance;
			if (!glovalVars.curFileInfo || !glovalVars.curFileInfo.hasOwnProperty(key) || glovalVars.curFileInfo[key] === "")
			{
				if (key == "userid" || key == "filesize")
				{
					return "0";
				}
				
				return null;
			}
			
			return glovalVars.curFileInfo[key];
		}
		
		public static function setUserInfo(key:String, value:String):void
		{
			var glovalVars:GlobalVars = GlobalVars.instance;
			if (glovalVars.curFileInfo)
			{
				glovalVars.curFileInfo[key] = value;
			}
		}
		
		public static function transDate(num:Number):String
		{  
            var date:Date = new Date(num * 1000);
			return (date.month + 1) + "月" + date.date + "日";
            //return date.fullYear + "年" + (date.month < 9 ? "0" + (date.month + 1) : (date.month + 1)) + "月" + (date.date < 10 ? "0" + date.date : date.date) + "日";
        }
		
		public static function cutScreenShot(source:BitmapData, pt:Point):BitmapData
		{
			var globalVars:GlobalVars = GlobalVars.instance;
			if (_snptBmd)
			{
				_snptBmd.dispose();
				_snptBmd = null;
			}
			_snptBmd = new BitmapData(globalVars.iframeWidth, globalVars.iframeHeight);
            _snptBmd.copyPixels(source, new Rectangle(pt.x, pt.y, globalVars.iframeWidth, globalVars.iframeHeight), new Point(0, 0));
            
			return _snptBmd;
		}
		
		public static function getReferfrom():String
		{
			var globalVars:GlobalVars = GlobalVars.instance;
			
			var userInfo:Object = globalVars.curFileInfo;
			if (!userInfo)
			{
				return null;
			}
			
			var referMaps:Object = globalVars.referMaps;
			if(globalVars.isMacWebPage){
				return referMaps["macVodPage"];
			}
			else if (userInfo.from.indexOf("lxlua") >= 0)
			{
				return referMaps["lxlua"];
			}
			else if (userInfo.from.indexOf("xl_lixian") >= 0)
			{
				return referMaps["xl_lixian"];
			}
			else if (userInfo.from.indexOf("xl_scene") >= 0)
			{
				return referMaps["xl_scene"];
			}
			else if(referMaps[userInfo.from])
			{
				return referMaps[userInfo.from];
			}
			
			return referMaps["defaultReferer"];
		}
		
		public static function getFormat():void
		{
			if (ExternalInterface.available)
			{
				ExternalInterface.call('G_PLAYER_INSTANCE.getFormats');
			}
		}
		
		public static function setFormatCallBack(format:String, isdefault:Boolean):void
		{
			if (ExternalInterface.available)
			{
				ExternalInterface.call('G_PLAYER_INSTANCE.setFormatsCallback', format, isdefault);
			}
		}
		
		public static function windowOpen(url:String, window:String = "_blank", type:String = ""):void
		{
			ExternalInterface.call("G_PLAYER_INSTANCE.windowOpen", url, window, type);
		}
		
		public static function stat(info:String):void
		{
			//ExternalInterface.call("XL_CLOUD_FX_INSTANCE.stat", obj);
			
			var userInfo:Object = GlobalVars.instance.curFileInfo;
			if (!userInfo)
			{
				return;
			}
			
			var p:String = "XCVP";
			var u:Number = userInfo.userid || 0;
			var v:Number = userInfo.isvip || 0;
			var usertype:String = userInfo.userType || null;
			var from:String = encodeURIComponent(userInfo.from || "XCVP");
			var d:Number = new Date().time;
			
			/*
			var param:Object = obj || { };
			param.p = "XCVP";
			param.u = userInfo.userid || 0;
			param.v = userInfo.isvip || 0;
			param.from = userInfo.from || "XCVP";
			param.d = new Date().time;
			
			var p:Array = [];
			for (var i:* in param)
			{
				p.push(i + "=" + encodeURIComponent(param[i]));
			}
			
			var url:String = GlobalVars.instance.staticsUrl + p.join("&");
			*/
			
			var url:String = GlobalVars.instance.staticsUrl + "p=" + p + "&u=" + u + "&v=" + v + "&usertype=" + usertype + "&from=" + from + "&d=" + d + "&" + info;
			var req:URLRequest = new URLRequest(url);
			sendToURL(req);
		}
		
		public static function statToJS(obj:Object):void
		{
			ExternalInterface.call("XL_CLOUD_FX_INSTANCE.stat", obj);
		}
		
		public static function formatBytes(bytes:Number):String
		{
			var suffix:String = "MB";
			bytes = bytes / (1024 * 1024);
			if (bytes > 1024)
			{
				suffix = "GB";
				bytes = bytes / 1024;
			}
			bytes = Math.round(bytes * 100) / 100;
			
			return bytes + suffix;
		}
		
		public static function calculateTimes(s:Number):String
		{
			s = Math.floor(s);
			var h:Number = 0;
			var m:Number = 0;
			if (isNaN(s))
			{
				s = 0;
			}
			if (s / 3600 >= 1)
			{
				h = Math.floor(s / 3600 * 10) / 10;
				
				return (h + "小时");
			}
			
			if (s / 60 >= 1)
			{
				m = Math.floor(s / 60);
				
				return (m + "分钟");
			}
			
			return (s == 0 ? "0" : s.toString() + "秒");
		}
		
		public static function getTimeUnit(s:Number):uint
		{
			s = Math.floor(s);
			var h:Number = 0;
			var m:Number = 0;
			if (isNaN(s))
			{
				s = 0;
			}
			
			if (s / 3600 >= 1)
			{
				return 1;//小时
			}
			
			if (s / 60 >= 1)
			{
				return 2;//分钟
			}
			
			return (s == 0 ? 4 : 3);//秒
		}
		
		public static function formatTimes(s:Number):String
		{
			s = Math.floor(s);
			var h:Number = 0;
			var m:Number = 0;
			if (isNaN(s))
			{
				s=0;
			}
			if(s/3600 >= 1)
			{
				h = Math.floor(s/3600);
				s -= h*3600;
			}
			if (s/60 >= 1)
			{
				m = Math.floor(s/60);
				s -= m*60;
			}
			
			return (h<10?'0'+h:h) + ':' + (m<10?'0'+m:m) + ':' + (s<10?'0'+s:s);
		}
		
		public static function registerToolTip(mainMc:Sprite):void
		{
			_mainMc = mainMc;
			new ToolTip(_mainMc);
		}
		
		public static function showToolTip(tips:String):void
		{
			ToolTip.show(tips);
		}
		
		public static function hideToolTip():void
		{
			ToolTip.hide();
		}
		
		public static function moveToolTip():void
		{
			ToolTip.move(_mainMc.stage.mouseX + 10, _mainMc.stage.mouseY + 45);
		}
		
		public static function moveToolTipToPoint(xPos:Number, yPos:Number):void
		{
			ToolTip.move(xPos, yPos);
		}
		
		public static function get toolTipWidth():Number
		{
			return ToolTip.width;
		}
	}

}