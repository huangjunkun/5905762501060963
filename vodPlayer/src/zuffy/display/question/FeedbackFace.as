package zuffy.display.question 
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import com.common.JTracer;
	import com.common.Tools;
	import com.global.GlobalVars;
	import com.serialization.json.JSON;
	import zuffy.events.EventSet;
	import flash.text.TextFormat;
	import zuffy.core.PlayerCtrl;

	/**
	 * ...
	 * @author hwh
	 */
	public class FeedbackFace extends MovieClip 
	{
		private var qArray:Array = [];
		private var itemArray:Array = [];
		private var loadLoader:URLLoader;
		private var info_tips:String = "补充问题描述，或提交您所遇见的其它问题或建议。";
		private var email_tips:String = "请留下您的邮箱地址/QQ号，方便我们联系您。";
		private var isLoaded:Boolean;//是否加载成功数据
		private var mainMc:PlayerCtrl;
		private var defaultEmail:String = "";
		private var defaultInfo:String = "";
		private var tf:TextFormat;
		
		public function FeedbackFace(_mainMc:PlayerCtrl) 
		{
			mainMc = _mainMc;
			
			tf = new TextFormat("宋体");
			
			showFace(false);
			
			close_btn.addEventListener(MouseEvent.CLICK, onCloseClick);
			
			submit_btn.alpha = 0.4;
			submit_btn.mouseEnabled = false;
			submit_btn.addEventListener(MouseEvent.CLICK, onSubmitClick);
			
			initInfoInputText();
			initEmailInputText();
		}
		
		public function showFace(boo:Boolean):void
		{
			this.visible = boo;
			if (boo && !isLoaded)
			{
				loadData();
			}
		}
		
		public function setPosition():void
		{
			this.x = int((stage.stageWidth - 460) / 2);
			this.y = int((stage.stageHeight - 300 - 33) / 2);
		}
		
		private function loadData():void
		{
			var req:URLRequest = new URLRequest(GlobalVars.instance.url_feedback);
			
			loadLoader = new URLLoader();
			loadLoader.addEventListener(Event.COMPLETE, onDataLoaded);
			loadLoader.load(req);
		}
		
		private function onDataLoaded(evt:Event):void
		{
			isLoaded = true;
			
			var str:String = evt.target.data;
			var obj:Object = com.serialization.json.JSON.deserialize(str);
			var i:*;
			var inObj:Object;
			for (i in obj)
			{
				inObj = new Object();
				inObj.id = i;
				inObj.label = obj[i];
				inObj.selected = false;
				
				qArray.push(inObj);
				
				JTracer.sendMessage("FeedbackFace -> id:" + i + ", label:" + obj[i] + "\n");
			}
			
			initCheckbox();
			initInfoInputText();
		}
		
		private function onSubmitClick(evt:MouseEvent):void
		{
			var idArray:Array = [];
			var i:*;
			for (i in qArray)
			{
				if (qArray[i].selected)
				{
					idArray.push(qArray[i].id);
				}
			}
			var prob:String = idArray.join(",");
			var op:String = encodeURI(defaultInfo);
			var contact:String = encodeURI(defaultEmail);
			Tools.stat("b=feedback&gdl=" + encodeURIComponent(mainMc._player.playUrl) + "&prob=" + prob + "&op=" + op + "&contact=" + contact);
			
			dispatchEvent(new EventSet(EventSet.SHOW_FACE, "feedback"));
		}
		
		private function onCloseClick(evt:MouseEvent):void
		{
			dispatchEvent(new EventSet(EventSet.SHOW_FACE, "feedback"));
		}
		
		private function initCheckbox():void
		{
			var i:*;
			var item:CheckboxItem;
			for (i in qArray)
			{
				item = new CheckboxItem();
				item.name_txt.text = qArray[i].label;
				item.name_txt.setTextFormat(tf);
				item.name = qArray[i].id;
				item.name_txt.width = item.name_txt.textWidth + 10;
				item.name_txt.height = item.name_txt.textHeight + 4;
				item.x = i % 2 * 200 + 45;
				item.y = Math.floor(i / 2) * 25 + 40;
				item.cb_mc.gotoAndStop(1);
				item.bg_mc.width = item.name_txt.width;
				item.mouseChildren = false;
				item.buttonMode = true;
				item.addEventListener(MouseEvent.CLICK, onItemClick);
				addChild(item);
				
				itemArray.push(item);
			}
		}
		
		private function initInfoInputText():void
		{
			var idx:int = Math.ceil(qArray.length / 2);
			var curY:Number = idx * 25 + 40;
			
			info_bg.width = 424;
			info_bg.height = 225 - curY;
			info_bg.x = (460 - info_bg.width) / 2;
			info_bg.y = curY;
			
			info_txt.width = info_bg.width - 6;
			info_txt.height = info_bg.height - 6;
			info_txt.x = info_bg.x + 3;
			info_txt.y = info_bg.y + 3;
			info_txt.defaultTextFormat = tf;
			info_txt.text = info_tips;
			info_txt.addEventListener(FocusEvent.FOCUS_IN, onInInfoText);
			info_txt.addEventListener(FocusEvent.FOCUS_OUT, onOutInfoText);
			info_txt.addEventListener(Event.CHANGE, onInfoTextChange);
		}
		
		private function initEmailInputText():void
		{
			email_txt.defaultTextFormat = tf;
			email_txt.text = email_tips;
			email_txt.addEventListener(FocusEvent.FOCUS_IN, onInEmailText);
			email_txt.addEventListener(FocusEvent.FOCUS_OUT, onOutEmailText);
			email_txt.addEventListener(Event.CHANGE, onEmailTextChange);
		}
		
		private function onInInfoText(evt:FocusEvent):void
		{
			if (defaultInfo == "")
			{
				info_txt.text = "";
			}
		}
		
		private function onOutInfoText(evt:FocusEvent):void
		{
			if (defaultInfo == "")
			{
				info_txt.text = info_tips;
			}
		}
		
		private function onInfoTextChange(evt:Event):void
		{
			defaultInfo = info_txt.text;
			
			setSubmitStatus();
		}
		
		private function onInEmailText(evt:FocusEvent):void
		{
			if (defaultEmail == "")
			{
				email_txt.text = "";
			}
		}
		
		private function onOutEmailText(evt:FocusEvent):void
		{
			if (defaultEmail == "")
			{
				email_txt.text = email_tips;
			}
		}
		
		private function onEmailTextChange(evt:Event):void
		{
			defaultEmail = email_txt.text;
			
			setSubmitStatus();
		}
		
		private function setSubmitStatus():void
		{
			var isHasText:Boolean = checkHasText();
			if (isHasText)
			{
				submit_btn.alpha = 1;
				submit_btn.mouseEnabled = true;
			}
			else
			{
				submit_btn.alpha = 0.4;
				submit_btn.mouseEnabled = false;
			}
		}
		
		private function checkHasText():Boolean
		{
			var isCheckSelected:Boolean;
			var i:*;
			for (i in qArray)
			{
				if (qArray[i].selected)
				{
					isCheckSelected = true;
					break;
				}
			}
			
			var isInfoHasText:Boolean = defaultInfo != "";
			//var isEmailHasText:Boolean = email_txt.text != email_tips && email_txt.text != "";
			
			if (isInfoHasText || isCheckSelected)
			{
				return true;
			}
			
			return false;
		}
		
		private function onItemClick(evt:MouseEvent):void
		{
			var item:CheckboxItem = evt.currentTarget as CheckboxItem;
			var idx:int = findIndex(item);
			if (item.cb_mc.currentFrame == 1)
			{
				item.cb_mc.gotoAndStop(2);
				if (idx != -1)
				{
					qArray[idx].selected = true;
				}
			}
			else
			{
				item.cb_mc.gotoAndStop(1);
				if (idx != -1)
				{
					qArray[idx].selected = false;
				}
			}
			
			setSubmitStatus();
		}
		
		private function findIndex(item:CheckboxItem):int
		{
			var i:*;
			for (i in qArray)
			{
				if (qArray[i].id == item.name)
				{
					return i;
				}
			}
			
			return -1;
		}
	}
}