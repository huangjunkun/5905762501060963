/**
 *
 *  播放请求的数据处理对象
 *
 *
 */
package zuffy.ctr.module {
	import flash.external.ExternalInterface;
	import com.global.GlobalVars;

	public class VODReqBackDataModule {
		
		private var _curName:String;
		private var _lastPos:Number;
		private var _curPlay:Object = {};
		private var _fileList:Object = {};

		// 缓存请求列表
		private var _cacheData:Array;	

		private var _lastFormat:String;

		// 当前视频格式数量
		private var _formatNum:int = 0; 
		public function get formatNum():int {return _formatNum;}

		private	var _curFormat:String = 'p';
		public function get curFormat():String {return _curFormat;}

		private var _curUrl:String = "";
		public function get curUrl():String {return _curUrl;}

		private	var _curUrls:Array = [];
		public function get curUrls():Array {return _curUrls;}

		private var _vod_info_list:Array =[];
		public function get info_list():Array {return _vod_info_list;}

		private	var _curInfo:Object = {};
		public function get curInfo():Object {return _curInfo;}

		public function get totalTimeInMs():Number {return _curPlay.duration;}
		
		public function get totalByte():int {return int(_PU('s', curUrl));}


		private const format_types:Object = {'p' : 0, 'g' : 1, 'c' : 2 }

		public function VODReqBackDataModule(data:Object) {
			getDataFromQuery(data);
		}

		public function getDataFromQuery(req:Object):void {
			
			// 当前请求的数据;
			_curPlay = req;
			if( typeof req.status == 'undefined' || req.status != 0 ) {
				
			}
			else {
				// 缓存请求
				_cacheData = _cacheReqData(_cacheData, req, _curPlay.url_hash);

				var info:Array = req.vodinfo_list;
				_vod_info_list = info;

				// 是否内嵌字幕
				GlobalVars.instance.hasSubtitle = info[0].has_subtitle || 0;
				
				// 浏览器url带的格式;
				var urlFormat:String = 'p' //$PU("format");
				var format_types:Object = {'p' : 0, 'g' : 1, 'c' : 2};
				// 默认值
				if(urlFormat != 'c' && urlFormat != 'g' && urlFormat != 'p') {
					urlFormat = 'p';
				}

				// 本地存储的格式
				var t_initFormat:String;
				try{
					t_initFormat = ExternalInterface.call("G_PLAYER_INSTANCE.getStorageData", "defaultFormat") || 'p';
				}catch(e){
					t_initFormat = 'p';
				}
				t_initFormat = t_initFormat.match(/^(g|p|c)$/) ? t_initFormat : 'p';

				// 超出限制格式调整
				var t_formatNum:int = info.length;
				if((t_formatNum == 1 && (t_initFormat == 'g' || t_initFormat == 'c')))
					t_initFormat = 'p';
				else if ((t_formatNum == 2 && t_initFormat == 'c'))
					t_initFormat = 'g';

				if(parseInt(format_types[urlFormat]) <= t_formatNum) {
					t_initFormat = urlFormat;
				}

				_curInfo = info[0];
				_curUrl = info[0].vod_url;
				_curUrls = info[0].vod_urls;

				try {
					if(t_initFormat == 'g' ){
						_curInfo = info[1];
						_curUrl = info[1].vod_url;
						_curUrls = info[1].vod_urls;
					}
					else if(t_initFormat == 'c'){
						_curInfo = info[2];
						_curUrl = info[2].vod_url
						_curUrls = info[2].vod_urls;
					}
				}catch(e){}

				_curFormat = t_initFormat;
				_formatNum = info.length;
			}
			// 在给flash filename之前判断一下，如果filename为空则用点播请求的
			_curName = _curPlay.src_info.file_name;
		}

		private function _cacheReqData(tcacheData:Array, itemData:Object, uniqueValue:String):Array {
			
			var cacheData:Array = tcacheData || [];
			var cacheDataLength = cacheData.length;

			if(cacheDataLength > 0 && cacheDataLength < 6) {
				var tmpData = [];
				for(var i = 0; i < cacheDataLength; i++) {
					if(cacheData[i].url_hash && cacheData[i].url_hash != uniqueValue){
						tmpData.push(cacheData[i]);
					}
				}
				cacheData = tmpData;
			}

			cacheData.push(itemData);
			
			if(cacheData.length == 5)
				cacheData.shift();
			
			return cacheData;
		}

		public function _PU(parameter:String, url:String = null):String {
			var result = url.match(new RegExp("[\#|\?]([^#]*)[\#|\?]?"));
			url = "&" + (!result ? "" : result[1]);
			result = url.match(new RegExp("&" + parameter + "=", "i"));
			return !result ? '' : url.substr(result.index+1).split("&")[0].split("=")[1];
		}

	}
}


// inner class..
class __inner__ {
	function __inner__(){}	
}