package zuffy.display.download 
{
	import com.global.GlobalVars;
	import flash.display.MovieClip;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.geom.PerspectiveProjection;
	import flash.ui.Mouse;
	import flash.utils.Dictionary;
	import com.common.Tools;
	import zuffy.events.EventSet;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class DownloadFace extends MovieClip 
	{
		private var _constArray:Array = [ { format:"c", label:"超清(1080P)", tips:"适合电视、电脑等高分辨率大屏幕" },
										 { format:"g", label:"高清(720P)", tips:"适合iPad等大尺寸移动设备" },
										 { format:"p", label:"流畅(480P)", tips:"适合iPhone等高分辨率手机" },
										 { format:"y", label:"原始版本", tips:"原始清晰度" } ];
		private var _itemDiction:Dictionary;
		private var _currentFormat:String;
		
		public function DownloadFace() 
		{
			this.visible = false;
			
			_itemDiction = new Dictionary(true);
			
			var i:uint;
			var len:uint = _constArray.length;
			var obj:Object;
			var item:CheckBoxItem;
			for (i = 0; i < len; i++)
			{
				obj = _constArray[i];
				
				item = new CheckBoxItem();
				item.format = obj.format;
				item.formatText = obj.label;
				item.tipsText = obj.tips;
				item.enabled = false;
				item.x = 50;
				item.y = 50 + i * 25;
				item.addEventListener("SelectItem", onSelectItem);
				addChild(item);
				
				_itemDiction[obj.format] = item;
			}
			
			close_btn.addEventListener(MouseEvent.CLICK, onCloseClick);
			
			download_btn.buttonMode = true;
			download_btn.mouseChildren = false;
			download_btn.alpha = 0.6;
			download_btn.mouseEnabled = false;
			download_btn.gotoAndStop(1);
			download_btn.addEventListener(MouseEvent.MOUSE_OVER, onDownloadOver);
			download_btn.addEventListener(MouseEvent.MOUSE_OUT, onDownloadOut);
			download_btn.addEventListener(MouseEvent.CLICK, onDownloadClick);
		}
		
		public function setDownloadFormat(obj:Object):void
		{
			if (!obj)
			{
				return;
			}
			
			var i:*;
			var item:CheckBoxItem;
			for (i in obj)
			{
				item = _itemDiction[i] as CheckBoxItem;
				//原始在什么情况下都能用
				if (i == "y")
				{
					item.enabled = true;
				}
				else
				{
					item.enabled = obj[i].enable;
				}
			}
			
			//默认选中第一个
			selectFirstEnableItem();
		}
		
		public function setPosition():void
		{
			this.x = int((stage.stageWidth - 460) / 2);
			this.y = int((stage.stageHeight - 228 - 33) / 2);
		}
		
		public function showFace(boo:Boolean):void
		{
			this.visible = boo;
			
			if (boo)
			{
				setNonSelected();
				//默认选中第一个
				selectFirstEnableItem();
				
				//download_btn.alpha = 0.6;
				//download_btn.mouseEnabled = false;
			}
		}
		
		public function setAllDisabled():void
		{
			var i:*;
			var item:CheckBoxItem;
			for (i in _itemDiction)
			{
				item = _itemDiction[i] as CheckBoxItem;
				item.enabled = false;
			}
			
			download_btn.alpha = 0.6;
			download_btn.mouseEnabled = false;
		}
		
		private function selectFirstEnableItem():void
		{
			var i:*;
			var item:CheckBoxItem;
			for (i in _constArray)
			{
				item = _itemDiction[_constArray[i].format] as CheckBoxItem;
				if (item.enabled)
				{
					item.selected = true;
					_currentFormat = item.format;
					break;
				}
			}
			
			download_btn.alpha = 1;
			download_btn.mouseEnabled = true;
		}
		
		private function setNonSelected():void
		{
			var i:*;
			var item:CheckBoxItem;
			for (i in _itemDiction)
			{
				item = _itemDiction[i] as CheckBoxItem;
				if (item.enabled)
				{
					item.selected = false;
				}
			}
		}
		
		private function onSelectItem(evt:Event):void
		{
			setNonSelected();
			
			var item:CheckBoxItem = evt.currentTarget as CheckBoxItem;
			item.selected = true;
			
			_currentFormat = item.format;
			
			download_btn.alpha = 1;
			download_btn.mouseEnabled = true;
		}
		
		private function onCloseClick(evt:MouseEvent):void
		{
			dispatchEvent(new EventSet(EventSet.SHOW_FACE, "download"));
		}
		
		private function onDownloadClick(evt:MouseEvent):void
		{
			//点击下载，如果全屏，退出全屏
			if (stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				stage.displayState = StageDisplayState.NORMAL;
			}
			
			var dwType:String;
			if (_currentFormat == "c")
			{
				dwType = "chaoqing";
			}
			else if (_currentFormat == "g")
			{
				dwType = "gaoqing";
			}
			else if (_currentFormat == "p")
			{
				dwType = "liuchang";
			}
			else if (_currentFormat == "y")
			{
				dwType = "yuanshi";
			}
			
			if (GlobalVars.instance.isStat)
			{
				Tools.stat("b=download&dwType=" + dwType);
			}
			
			ExternalInterface.call("XL_CLOUD_FX_INSTANCE.download", _currentFormat);
		}
		
		private function onDownloadOver(evt:MouseEvent):void
		{
			download_btn.gotoAndStop(2);
		}
		
		private function onDownloadOut(evt:MouseEvent):void
		{
			download_btn.gotoAndStop(1);
		}
	}

}