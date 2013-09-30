package zuffy.display.notice
{
	import com.common.StringUtil;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import com.common.Tools;
	import com.global.GlobalVars;
	import com.Player;
	import com.common.JTracer;
	import flash.net.sendToURL;
	import flash.net.URLRequest;
	import flash.utils.getTimer;
	import zuffy.events.SetQulityEvent;
	
	/**
	 * @author dds
	 */
	public class bufferTip extends Sprite
	{
		private var _countShow:Number = 0;
		private var _countBreak:Number = 0;
		private var _qulityCurr:int = 0;
		private var _qulityTotal:Array = []; 
		private var _isHasQulity:Boolean = false;
		private var _player:Player;
		private var _isRegisted:Boolean;//是否已注册测速
		
		public function bufferTip(player:Player) 
		{
			_player = player;
		}
		
		/*
		private function initTipBar():void
		{
			if (_countShow >= 2) { return; }
			if (_isHasQulity) {
				dispatchEvent(new SetQulityEvent(SetQulityEvent.HAS_QULITY));
			}else {
				dispatchEvent(new SetQulityEvent(SetQulityEvent.NO_QULITY));
			}
			_countShow += 1;
			
			var gcid:String = Tools.getUserInfo("gcid");
			Tools.stat("f=buffer&gcid=" + gcid + "&t=" + _player.time + "&e=-2");
			
			ExternalInterface.call("flv_playerEvent", "onShowBufferTip");
		}
		*/
		
		public function changeQulityHandler():void
		{
			if (_qulityCurr < 1) { return; }
			while (_qulityTotal[_qulityCurr - 1] != 1) {
				_qulityCurr -= 1;
				if (_qulityCurr == -1) {
					_isHasQulity = false;
					return;
				}
			}
			switch(_qulityCurr - 1) {
				case 0:
					ExternalInterface.call("flv_playerEvent", "onNomalClick");
					dispatchEvent(new SetQulityEvent(SetQulityEvent.CHANGE_QUILTY));
					break;
				case 1:
					ExternalInterface.call("flv_playerEvent", "onStandardClick");
					dispatchEvent(new SetQulityEvent(SetQulityEvent.CHANGE_QUILTY));
					break;
			}
			_qulityCurr -= 1;
			if (_qulityCurr == 0 || _qulityCurr == -1) {
				_isHasQulity = false;
			}
		}
		
		public function addBreakCount(time:Number):void
		{
			if (_countBreak == 0)
			{
				_countBreak = 1;
				
				var errorCode:int;
				var globalvars:GlobalVars = GlobalVars.instance;
				switch(globalvars.bufferType)
				{
					case globalvars.bufferTypeCustom:
						errorCode = -2;
						
						if (!_isRegisted)
						{
							_isRegisted = true;
							
							sendToURL(new URLRequest("http://i.vod.xunlei.com/cdn/req_regist?userid=" + Tools.getUserInfo("userid") + "&d=" + new Date().time));
						}
						
						if (globalvars.curLowSpeedTipsTime > globalvars.startLowSpeedTipsTime)
						{
							globalvars.showLowSpeedTimeArray.push(getTimer());
							
							JTracer.sendMessage("bufferTip -> custom buffer tips, time:" + getTimer());
						}
						
						if (!GlobalVars.instance.isReplaceURL && _player.nextIsDL() && !GlobalVars.instance.isUseHttpSocket)
						{
							GlobalVars.instance.isReplaceURL = true;
							
							var nextUrl:String = _player.getNextUrl();
							if (nextUrl)
							{
								_player.playUrl = nextUrl;
								GlobalVars.instance.isVodGetted = false;
							}
							JTracer.sendMessage("addBreakCount -> get next play url:" + _player.playUrl);
						}
						
						//如果有替换链接，则此次上报当作首缓冲上报
						if (!GlobalVars.instance.isChangeURL && _player.lastUrl != _player.playUrl)
						{
							GlobalVars.instance.isChangeURL = true;
							_player.lastUrl = _player.playUrl;
							
							errorCode = -3;
						}
						break;
					case globalvars.bufferTypeFirstBuffer:
						if (!GlobalVars.instance.isChangeURL && _player.lastUrl != _player.playUrl)
						{
							GlobalVars.instance.isChangeURL = true;
							_player.lastUrl = _player.playUrl;
						}
						errorCode = -3;
						break;
					case globalvars.bufferTypeChangeFormat:
						errorCode = -4;
						break;
					case globalvars.bufferTypeDrag:
						errorCode = -5;
						break;
					case globalvars.bufferTypeKeyPress:
						errorCode = -6;
						break;
					case globalvars.bufferTypePreview:
						errorCode = -7;
						break;
					case globalvars.bufferTypeError:
						errorCode = -8;
						break;
					default:
						errorCode = -2;
						break;
				}
				
				var statCC:String = GlobalVars.instance.statCC;
				if (errorCode == -2 || errorCode == -3)
				{
					var link:int = _player.getCurLink();
					Tools.stat("f=buffer&gcid=" + Tools.getUserInfo("gcid") + "&gdl=" + encodeURIComponent(StringUtil.getShortenURL(_player.originGdlUrl)) + "&vod=" + encodeURIComponent(StringUtil.getShortenURL(_player.vodUrl)) + "&t=" + time + "&e=" + errorCode + "&link=" + link + "&linknum=" + GlobalVars.instance.linkNum + "&format=" + GlobalVars.instance.movieFormat + statCC);
					//Tools.stat("f=buffer&gcid=" + Tools.getUserInfo("gcid") + "&gdl=" + encodeURIComponent(_player.originGdlUrl) + "&vod=" + encodeURIComponent(_player.vodUrl) + "&t=" + time + "&e=" + errorCode);
					
					JTracer.sendMessage("bufferTip -> addBreakCount, f=buffer&gcid=" + Tools.getUserInfo("gcid") + "&gdl=" + encodeURIComponent(_player.originGdlUrl) + "&vod=" + encodeURIComponent(_player.vodUrl) + "&t=" + time + "&e=" + errorCode + "&link=" + link + "&linknum=" + GlobalVars.instance.linkNum + statCC);
				}
				else
				{
					Tools.stat("f=buffer&gcid=" + Tools.getUserInfo("gcid") + "&gdl=" + encodeURIComponent(StringUtil.getShortenURL(_player.originGdlUrl)) + "&vod=" + encodeURIComponent(StringUtil.getShortenURL(_player.vodUrl)) + "&t=" + time + "&e=" + errorCode + "&format=" + GlobalVars.instance.movieFormat + statCC);
					
					JTracer.sendMessage("bufferTip -> addBreakCount, f=buffer&gcid=" + Tools.getUserInfo("gcid") + "&gdl=" + encodeURIComponent(_player.originGdlUrl) + "&vod=" + encodeURIComponent(_player.vodUrl) + "&t=" + time + "&e=" + errorCode + statCC);
				}
				
				//ExternalInterface.call("flv_playerEvent", "onShowBufferTip");
			}
			
			/*
			_countBreak += 1;
			JTracer.sendMessage('addBreakCount, _countBreak=' + _countBreak);
			if (_countBreak > 1) {
				initTipBar();
				clearBreakCount();
			}
			*/
		}
		
		public function clearBreakCount():void
		{
			_countBreak = 0;
			JTracer.sendMessage('bufferTip -> clearBreakCount');
		}
		
		public function setQulityType(total:String,curr:int):void
		{
			var qulity:String = total + '';
			_qulityTotal.push(qulity.charAt(0) || 0);
			_qulityTotal.push(qulity.charAt(1) || 0);
			_qulityTotal.push(qulity.charAt(2) || 0);
			_qulityCurr = curr;
			if (_qulityCurr == 0) { _isHasQulity = false; return; }
			for ( var i:Number = 0; i < _qulityCurr; i++) {
				if (_qulityTotal[i] == 1) {
					_isHasQulity = true;
				}
			}
		}
		
		public function autioChangeQuality():void
		{
			_qulityCurr++;
		}
	}

}