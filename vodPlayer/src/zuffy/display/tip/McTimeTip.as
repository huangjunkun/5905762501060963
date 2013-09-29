package ctr.tip
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.AsyncErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldAutoSize;
	import com.common.BitmapScale9Grid;
	import com.common.GetNextVodSocket;
	import com.common.JTracer;
	import com.global.GlobalVars;
	import com.greensock.TweenLite;

	public class McTimeTip extends Sprite
	{
		private var _txt:TextField;
		private var _borderMc:Sprite;
		private var _normalWidth:Number = 160;
		private var _normalHeight:Number = 90;
		private var _bigWidth:Number = 190;
		private var _bigHeight:Number = 108;
		private var _defaultWidth:Number = 48;
		private var _defaultHeight:Number = 25;
		private var _cn:NetConnection;
		private var _stream:NetStream;
		private var _video:Video;
		private var _loading:TimeTipsLoading;
		private var _timeBgMc:Sprite;
		private var _scaleType:uint;
		private var _curTime:Number;
		private var _curStageX:Number;
		private var _curMouseX:Number;
		private var _isScale:Boolean;
		private var _hasSnapShot:Boolean;
		private var _snptBm:Bitmap;
		private var _showLoading:Boolean;
		
		public function McTimeTip()
		{
			this.mouseChildren = false;
			
			var borderBmd:BitmapData = new TimeTipsBorder(47, 25);
			
			_borderMc = new BitmapScale9Grid(borderBmd, 2, 23, 2, 45);
			addChild(_borderMc);
			
			var tf:TextFormat = new TextFormat();
			tf.align = "center";
			tf.font = "Arial";
			tf.color = 0x9f9f9f;
			tf.size = 10;
			
			_txt = new TextField();
			_txt.defaultTextFormat = tf;
			_txt.width = 48;
			_txt.height = 18;
			_txt.x = -_txt.width / 2;
			_txt.y = -21;
			_txt.selectable = false;
			addChild(_txt);
			
			_cn = new NetConnection();
			_cn.connect(null);
			
			_stream = new NetStream(_cn);
			_stream.bufferTime = 1;
			_stream.soundTransform = new SoundTransform(0);
			_stream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			_stream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
			
			init();
		}
		
		public function init():void
		{
			_borderMc.width = _defaultWidth;
			_borderMc.height = _defaultHeight;
			_borderMc.x = -_defaultWidth / 2;
			_borderMc.y = -_defaultHeight;
			
			clear();
			killAllTweens();
		}
		
		public function get hasSnapShot():Boolean
		{
			return _hasSnapShot;
		}
		
		public function set hasSnapShot(value:Boolean):void
		{
			_hasSnapShot = value;
		}
		
		public function get isScale():Boolean
		{
			return _isScale;
		}
		
		public function set isScale(value:Boolean):void
		{
			_isScale = value;
		}
		
		public function get curTime():Number
		{
			return _curTime;
		}
		
		public function set curTime(time:Number):void
		{
			_curTime = time;
		}
		
		public function get curStageX():Number
		{
			return _curStageX;
		}
		
		public function set curStageX(_x:Number):void
		{
			_curStageX = _x;
		}
		
		public function get curMouseX():Number
		{
			return _curMouseX;
		}
		
		public function set curMouseX(value:Number):void
		{
			_curMouseX = value;
		}
		
		override public function get width():Number
		{
			return _borderMc.width;
		}
		
		override public function get height():Number
		{
			return _borderMc.height;
		}
		
		public function set text(t:String):void
		{
			_txt.text = t;
		}
		
		public function get text():String
		{
			return _txt.text;
		}
		
		public function get scaleType():uint
		{
			return _scaleType;
		}
		
		public function set scaleType(num:uint):void
		{
			_scaleType = num;
		}
		
		public function showSnap(value:BitmapData):void
		{
			if (_snptBm)
			{
				_snptBm.smoothing = true;
				_snptBm.bitmapData = value;
			}
		}
		
		public function playStream(url:String, suffix:String):void
		{
			var gdlURl:String = url + suffix;
			
			if (GlobalVars.instance.isUseSocket)
			{
				GetNextVodSocket.instance.connect(url, function(vod_url:String, utype:String, status_code:String, cost_time:int)
				{
					if (!vod_url || vod_url == "")
					{
						JTracer.sendMessage("McTimeTip -> playStream, get vod url fail, gdl url:" + gdlURl);
						if (_stream)
						{
							_stream.play(gdlURl);
						}
					}
					else
					{
						JTracer.sendMessage("McTimeTip -> playStream, get vod url success, vod url:" + vod_url + suffix);
						if (_stream)
						{
							_stream.play(vod_url + suffix);
						}
					}
				});
			}
			else
			{
				if (_stream)
				{
					_stream.play(gdlURl);
				}
			}
		}
		
		public function initDisplay():void
		{
			newSnptBm();
			if (_showLoading)
			{
				newLoading();
			}
			newVideo();
			newTimeBgMc();
			setChildIndex(_txt, numChildren - 1);
		}
		
		public function showLoading(boo:Boolean):void
		{
			_showLoading = boo;
		}
		
		public function setDisplayAlpha(alpha:Number):void
		{
			_snptBm.alpha = alpha;
			if (_showLoading)
			{
				_loading.alpha = alpha;
			}
			_video.alpha = alpha;
			_timeBgMc.alpha = alpha;
		}
		
		public function scaleNormal(rightNow:Boolean = false):void
		{
			if (rightNow)
			{
				_snptBm.width = _normalWidth - 4;
				_snptBm.height = _normalHeight - 4;
				_snptBm.x = -(_normalWidth - 4) / 2;
				_snptBm.y = -_normalHeight + 2;
				_snptBm.alpha = 1;
				
				if (_showLoading)
				{
					_loading.y = -_normalHeight / 2;
					_loading.alpha = 1;
				}
				
				_video.width = _normalWidth - 4;
				_video.height = _normalHeight - 4;
				_video.x = -(_normalWidth - 4) / 2;
				_video.y = -_normalHeight + 2;
				_video.alpha = 1;
				
				_timeBgMc.width = _normalWidth - 4;
				_timeBgMc.alpha = 1;
				
				_borderMc.width = _normalWidth;
				_borderMc.height = _normalHeight;
				_borderMc.x = -_normalWidth / 2;
				_borderMc.y = -_normalHeight;
			}
			else
			{
				TweenLite.to(_snptBm, 0.2, {width:_normalWidth - 4, height:_normalHeight - 4, x:-(_normalWidth - 4) / 2, y:-_normalHeight + 2, alpha:1});
				if (_showLoading)
				{
					TweenLite.to(_loading, 0.2, {y:-_normalHeight / 2, alpha:1});
				}
				TweenLite.to(_video, 0.2, {width:_normalWidth - 4, height:_normalHeight - 4, x:-(_normalWidth - 4) / 2, y:-_normalHeight + 2, alpha:1});
				TweenLite.to(_timeBgMc, 0.2, {width:_normalWidth - 4, alpha:1});
				TweenLite.to(_borderMc, 0.2, {width:_normalWidth, height:_normalHeight, x:-_normalWidth / 2, y:-_normalHeight});
			}
		}
		
		public function scaleBig(rightNow:Boolean = false):void
		{
			if (rightNow)
			{
				_snptBm.width = _bigWidth - 4;
				_snptBm.height = _bigHeight - 4;
				_snptBm.x = -(_bigWidth - 4) / 2;
				_snptBm.y = -_bigHeight + 2;
				_snptBm.alpha = 1;
				
				if (_showLoading)
				{
					_loading.y = -_bigHeight / 2;
					_loading.alpha = 1;
				}
				
				_video.width = _bigWidth - 4;
				_video.height = _bigHeight - 4;
				_video.x = -(_bigWidth - 4) / 2;
				_video.y = -_bigHeight + 2;
				_video.alpha = 1;
				
				_timeBgMc.width = _bigWidth - 4;
				_timeBgMc.alpha = 1;
				
				_borderMc.width = _bigWidth;
				_borderMc.height = _bigHeight;
				_borderMc.x = -_bigWidth / 2;
				_borderMc.y = -_bigHeight;
			}
			else
			{
				TweenLite.to(_snptBm, 0.2, {width:_bigWidth - 4, height:_bigHeight - 4, x:-(_bigWidth - 4) / 2, y:-_bigHeight + 2, alpha:1});
				if (_showLoading)
				{
					TweenLite.to(_loading, 0.2, {y:-_bigHeight / 2, alpha:1});
				}
				TweenLite.to(_video, 0.2, {width:_bigWidth - 4, height:_bigHeight - 4, x:-(_bigWidth - 4) / 2, y:-_bigHeight + 2, alpha:1});
				TweenLite.to(_timeBgMc, 0.2, {width:_bigWidth - 4, alpha:1});
				TweenLite.to(_borderMc, 0.2, {width:_bigWidth, height:_bigHeight, x:-_bigWidth / 2, y:-_bigHeight});
			}
		}
		
		public function scaleDefault():void
		{
			removeLoading();
			if (_video)
			{
				TweenLite.to(_video, 0.2, {width:_defaultWidth - 4, height:_defaultHeight - 4, x:-(_defaultWidth - 4) / 2, y:-_defaultHeight + 2, alpha:0, onComplete:removeVideoTips});
			}
			if (_snptBm)
			{
				TweenLite.to(_snptBm, 0.2, {width:_defaultWidth - 4, height:_defaultHeight - 4, x:-(_defaultWidth - 4) / 2, y:-_defaultHeight + 2, alpha:0, onComplete:removeSnptBm});
			}
			if (_timeBgMc)
			{
				TweenLite.to(_timeBgMc, 0.2, {width:_defaultWidth - 4, alpha:0, onComplete:removeTimeBgMc});
			}
			TweenLite.to(_borderMc, 0.2, {width:_defaultWidth, height:_defaultHeight, x:-_defaultWidth / 2, y:-_defaultHeight});
		}
		
		private function newSnptBm():void
		{
			if (!_snptBm)
			{
				_snptBm = new Bitmap();
				_snptBm.smoothing = true;
				_snptBm.width = _defaultWidth - 4;
				_snptBm.height = _defaultHeight - 4;
				_snptBm.x = -(_defaultWidth - 4) / 2;
				_snptBm.y = -_defaultHeight + 2;
				addChild(_snptBm);
			}
		}
		
		private function removeSnptBm():void
		{
			if (_snptBm)
			{
				removeChild(_snptBm);
				_snptBm = null;
			}
		}
		
		private function newTimeBgMc():void
		{
			if (!_timeBgMc)
			{
				_timeBgMc = new Sprite();
				_timeBgMc.graphics.beginFill(0x000000, 0.5);
				_timeBgMc.graphics.drawRect(-(_defaultWidth - 4) / 2, 0, _defaultWidth - 4, 20);
				_timeBgMc.graphics.endFill();
				_timeBgMc.y = -22;
				addChild(_timeBgMc);
			}
		}
		
		private function removeTimeBgMc():void
		{
			if (_timeBgMc)
			{
				removeChild(_timeBgMc);
				_timeBgMc = null;
			}
		}
		
		private function newLoading():void
		{
			if (!_loading)
			{
				_loading = new TimeTipsLoading();
				_loading.x = 0;
				_loading.y = -_defaultHeight / 2;
				addChild(_loading);
			}
		}
		
		private function removeLoading():void
		{
			if (_loading)
			{
				removeChild(_loading);
				_loading = null;
			}
		}
		
		private function newVideo():void
		{
			if (!_video)
			{
				_video = new Video(_defaultWidth - 4, _defaultHeight - 4);
				_video.x = -(_defaultWidth - 4) / 2;
				_video.y = -_defaultHeight + 2;
				_video.smoothing = true;
				_video.attachNetStream(_stream);
				addChild(_video);
			}
		}
		
		private function removeVideo():void
		{
			if (_video)
			{
				_video.clear();
				removeChild(_video);
				_video = null;
			}
		}
		
		private function removeVideoTips():void
		{
			removeVideo();
			_stream.close();
		}
		
		public function clear():void
		{
			removeSnptBm();
			removeLoading();
			removeVideoTips();
			removeTimeBgMc();
		}
		
		private function killAllTweens():void
		{
			if (_loading)
			{
				TweenLite.killTweensOf(_loading);
			}
			if (_video)
			{
				TweenLite.killTweensOf(_video);
			}
			if (_snptBm)
			{
				TweenLite.killTweensOf(_snptBm);
			}
			if (_timeBgMc)
			{
				TweenLite.killTweensOf(_timeBgMc);
			}
			TweenLite.killTweensOf(_borderMc);
		}
		
		private function netStatusHandler(evt:NetStatusEvent):void
		{
			if (evt.info.code == 'NetStream.Buffer.Full') {
				
			} else if (evt.info.code == 'NetStream.Play.Start') {
				
			} else if (evt.info.code == 'NetStream.Play.StreamNotFound') {
				
			} else if (evt.info.code == 'NetStream.Play.Stop') {
				_stream.seek(0);
			}
		}
		
		private function asyncErrorHandler(evt:AsyncErrorEvent):void
		{
			
		}
	}
}