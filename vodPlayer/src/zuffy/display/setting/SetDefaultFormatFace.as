package zuffy.display.setting 
{
	import com.common.JTracer;
	import com.common.Tools;
	import com.global.GlobalVars;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import com.common.Cookies;
	import zuffy.events.EventSet;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class SetDefaultFormatFace extends Sprite 
	{
		private var _formatArray:Array = [ { format:"p", label:"流畅", tips:"(1M带宽)" },
										 { format:"g", label:"高清", tips:"(2M带宽)" },
										 { format:"c", label:"超清", tips:"(4M带宽)" } ];
		private var _tipsTxt:TextField;
		private var _radioItemArr:Array = [];
		private var _curFormat:String;
		private var _defaultFormat:String;
		private var _commitBtn:SetCommitButton;
		
		public function SetDefaultFormatFace() 
		{
			var _tipsTf:TextFormat = new TextFormat('宋体', 12, 0xc1c1c1);
			
			_tipsTxt = new TextField();
			_tipsTxt.selectable = false;
			_tipsTxt.defaultTextFormat = _tipsTf;
			_tipsTxt.text = "优先为我选择(下次播放时生效)";
			_tipsTxt.width = _tipsTxt.textWidth + 10;
			_tipsTxt.height = _tipsTxt.textHeight + 5;
			_tipsTxt.x = 15;
			_tipsTxt.y = 15;
			addChild(_tipsTxt);
			
			var i:uint;
			var radioItem:SetDrawCheckButton;
			for (i = 0; i < 3; i++)
			{
				radioItem = new SetDrawCheckButton(_formatArray[i].label, _formatArray[i].format, _formatArray[i].tips);
				radioItem.x = 35 + 125 * i;
				radioItem.y = 50;
				radioItem.addEventListener(MouseEvent.CLICK, onRadioItemClick);
				addChild(radioItem);
				
				_radioItemArr.push(radioItem);
			}
			
			_commitBtn = new SetCommitButton();
			_commitBtn.x = 170;
			_commitBtn.y = 141;
			_commitBtn.addEventListener(MouseEvent.CLICK, onCommitClick);
			addChild(_commitBtn);
		}
		
		private function onCommitClick(evt:MouseEvent):void
		{
			if (_curFormat != _defaultFormat)
			{
				_defaultFormat = _curFormat;
				
				GlobalVars.instance.defaultFormatChanged = true;
				//Cookies.setCookie('defaultFormat', _curFormat);
				ExternalInterface.call("G_PLAYER_INSTANCE.setStorageData", "defaultFormat=" + _curFormat);
				
				JTracer.sendMessage("SetDefaultFormatFace -> set default format, defaultFormat:" + _curFormat);
			}
			
			dispatchEvent(new EventSet(EventSet.SHOW_FACE, 'set'));
		}
		
		private function onRadioItemClick(evt:MouseEvent):void
		{
			_curFormat = (evt.currentTarget as SetDrawCheckButton).buttonMessage;
			
			showCurrentFormat(_curFormat);
		}
		
		public function showCurrentFormat(format:String):void
		{
			var i:*;
			var radioItem:SetDrawCheckButton;
			for (i in _radioItemArr)
			{
				radioItem = _radioItemArr[i] as SetDrawCheckButton;
				radioItem.setFocus = false;
			}
			
			var curRadioItem:SetDrawCheckButton = getRadioItem(format);
			curRadioItem.setFocus = true;
		}
		
		private function getRadioItem(format:String):SetDrawCheckButton
		{
			var i:*;
			var btn:SetDrawCheckButton;
			for (i in _radioItemArr) {
				btn = _radioItemArr[i] as SetDrawCheckButton;
				if (btn.buttonMessage == format) {
					return btn;
				}
			}
			
			return null;
		}
		
		public function get defaultFormat():String
		{
			return _defaultFormat;
		}
		
		public function set showFace(isShow:Boolean):void
		{
			if (isShow == true) {
				this.visible = true;
				try{
					_defaultFormat = ExternalInterface.call("G_PLAYER_INSTANCE.getStorageData", "defaultFormat");
				}catch(e:Error){
					_defaultFormat = "p";
				}				
				JTracer.sendMessage("SetDefaultFormatFace -> get default format, defaultFormat:" + _defaultFormat);
				var isValidFormat:Boolean = false;
				for(var i:int=0; i<_formatArray.length; i++){
					JTracer.sendMessage("format:" + _formatArray[i]["format"] + ' _defaultFormat:' + _defaultFormat);
					if( _defaultFormat == _formatArray[i]["format"] ){
						isValidFormat = true;
						break;
					};
				}
				if (!isValidFormat)
				{
					_defaultFormat = "p";
				}
				
				showCurrentFormat(_defaultFormat);
			} else {
				this.visible = false;
			}
		}
		
		public function initRecordStatus():void
		{
			
		}
		
		public function commitInterfaceFunction():void
		{
			
		}
		
		public function cancleInterfaceFunction():void
		{
			
		}
	}

}