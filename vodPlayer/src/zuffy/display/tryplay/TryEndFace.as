package zuffy.display.tryplay 
{
	import com.global.GlobalVars;
	import eve.TryPlayEvent;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.text.StyleSheet;
	import com.common.Tools;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class TryEndFace extends MovieClip 
	{
		private var _time:Number = 0;
		private var _isTrial:Boolean;
		
		public function TryEndFace() 
		{
			var userType:Number = Number(Tools.getUserInfo("userType"));
			if (userType == 2 && Tools.getUserInfo("from") != GlobalVars.instance.fromXLPan)
			{
				//新10元会员用户
				desc_txt.htmlText = "<b><font color='#FF0000'>加5元</font>升级为白金会员，不限时观看</b>";
				update_btn.visible = true;
				buy_btn.visible = false;
			}
			else
			{
				desc_txt.htmlText = "<b>开通成为<font color='#FF0000'>白金会员</font>，不限时观看</b>";
				update_btn.visible = false;
				buy_btn.visible = true;
			}
			bottom_txt.htmlText = "以后不用等啦！<font color='#999999'>随时拖动BT种子或下载链接，即可观看。</font>";
			
			var style:StyleSheet = new StyleSheet();
			style.setStyle('a', {textDecoration:'underline', color:'#999999'});
			
			if (Tools.getUserInfo("userid") == "0" || Tools.getUserInfo("sessionid") == null)
			{
				//未登陆
				buy_txt.visible = true;
				buy_txt.styleSheet = style;
				buy_txt.htmlText = "<a href='event:login'>会员登陆</a>";
				buy_txt.addEventListener(TextEvent.LINK, clickText);
			}
			else
			{
				buy_txt.visible = false;
				buy_txt.styleSheet = style;
				buy_txt.htmlText = "";
			}
			
			buy_btn.addEventListener(MouseEvent.CLICK, onBuyClick);
			update_btn.addEventListener(MouseEvent.CLICK, onBuyClick);
			
			close_btn.visible = false;
			close_btn.addEventListener(MouseEvent.CLICK, onCloseClick);
		}
		
		public function setTime(time:Number):void
		{
			_time = time;
			time_txt.htmlText = "温馨提醒：您剩余的试播时间为 <font color='#FF0000'>" + Tools.calculateTimes(time) + "</font>";
		}
		
		public function set isTrial(value:Boolean):void
		{
			_isTrial = value;
		}
		
		public function setPosition():void
		{
			this.x = int(stage.stageWidth / 2);
			this.y = int((stage.stageHeight - 33) / 2);
		}
		
		private function clickText(evt:TextEvent):void
		{
			switch(evt.text)
			{
				case "login":
					dispatchEvent(new TryPlayEvent(TryPlayEvent.Login));
					break;
				case "home":
					dispatchEvent(new TryPlayEvent(TryPlayEvent.GoHome));
					break;
			}
		}
		
		private function onBuyClick(evt:MouseEvent):void
		{
			var referfrom:String = Tools.getReferfrom();
			var paypos:String = _time <= 0 ? GlobalVars.instance.paypos_tryfinish : GlobalVars.instance.paypos_trystop;
			if (_isTrial)
			{
				dispatchEvent(new TryPlayEvent(TryPlayEvent.ShowViewList, {refer:referfrom, paypos:paypos}));
			}
			else
			{
				dispatchEvent(new TryPlayEvent(TryPlayEvent.BuyVIP, {refer:referfrom, paypos:paypos}));
			}
		}
		
		private function onCloseClick(evt:MouseEvent):void
		{
			dispatchEvent(new TryPlayEvent(TryPlayEvent.HidePanel));
		}
	}
}