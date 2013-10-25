package zuffy.display.setting 
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import com.common.Tools;
	import com.global.GlobalVars;
	import zuffy.events.EventSet;
	/**
	 * ...
	 * @author Drgon.S
	 */
	public class SetVideoSizeFace extends Sprite
	{
		private var _ratioButtonCommon:SetDrawCheckButton;
		private var _ratioButton4_3:SetDrawCheckButton;
		private var _ratioButton16_9:SetDrawCheckButton;
		private var _ratioButtonFull:SetDrawCheckButton;
		private var _commitButton:SetCommitButton;
		private var _ratioButtonArr:Array = [];
		private var _setInfo:Object = { 'ratio':'common', 'size':'100' };
		private var _recordSetInfo:Object = { 'ratio':'common', 'size':'100' };
		
		public function SetVideoSizeFace() 
		{
			_ratioButtonCommon = new SetDrawCheckButton('原始', 'common');
			_ratioButton4_3 = new SetDrawCheckButton('4：3', '4_3');
			_ratioButton16_9 = new SetDrawCheckButton('16：9', '16_9');
			_ratioButtonFull = new SetDrawCheckButton('满屏', 'full');
			
			_ratioButtonArr.push(_ratioButtonCommon);
			_ratioButtonArr.push(_ratioButton4_3);
			_ratioButtonArr.push(_ratioButton16_9);
			_ratioButtonArr.push(_ratioButtonFull);
			for (var i:* in _ratioButtonArr) {
				_ratioButtonArr[i].x = 35 + 100 * i;
				_ratioButtonArr[i].y = 50;
				_ratioButtonArr[i].addEventListener(MouseEvent.CLICK, ratioButtonClickHandler);
				addChild(_ratioButtonArr[i]);
			}
			
			showRatioButton(_ratioButtonArr[0]);
			
			_commitButton = new SetCommitButton();
			_commitButton.y = 141;
			_commitButton.x = 170;
			_commitButton.addEventListener(MouseEvent.CLICK, commitButtonClickHandler);
			addChild(_commitButton);
		}
		
		private function commitButtonClickHandler(e:MouseEvent):void
		{
			commitInterfaceFunction();
			
			dispatchEvent(new EventSet(EventSet.SHOW_FACE, 'set'));
		}
		
		private function ratioButtonClickHandler(e:MouseEvent):void
		{
			showRatioButton(e.currentTarget);
		}
		
		private function showRatioButton(target:*):void
		{
			for (var i:* in _ratioButtonArr) {
				if (_ratioButtonArr[i] == target) {
					_ratioButtonArr[i].setFocus = true;
				}else {
					_ratioButtonArr[i].setFocus = false;
				}
			}
			_setInfo['ratio'] = target.buttonMessage;
			dispatchEvent(new EventSet(EventSet.SET_SIZE));
		}
		
		private function checkValueChanged():void
		{
			if (_recordSetInfo['ratio'] != _setInfo['ratio'] || _recordSetInfo['size'] != _setInfo['size'])
			{
				GlobalVars.instance.ratioChanged = true;
			}
		}
		
		public function setFaceStatus(obj:Object):void
		{
			if (obj['ratio'] == '4_3') {
				showRatioButton(_ratioButton4_3);
			} else if (obj['ratio'] == '16_9') {
				showRatioButton(_ratioButton16_9);
			} else if (obj['ratio'] == 'common') {
				showRatioButton(_ratioButtonCommon);
			} else {
				showRatioButton(_ratioButtonFull);
			}
			_setInfo['ratio'] = _recordSetInfo['ratio'] = obj['ratio'];
			_setInfo['size'] = _recordSetInfo['size'] = obj['size'];
		}
		
		public function set showFace(isShow:Boolean):void
		{
			if (isShow == true) {
				this.visible = true;
			}else {
				this.visible = false;
				
				//显示其它tab时，确定
				commitInterfaceFunction();
			}
		}
		
		public function get setInfo():Object
		{
			return _setInfo;
		}
		
		//默认
		public function initRecordStatus():void
		{
			_recordSetInfo['ratio'] = 'common';
			_recordSetInfo['size'] = '100';
			setFaceStatus(_recordSetInfo);
		}
		
		//确定
		public function commitInterfaceFunction():void
		{
			checkValueChanged();
			
			_recordSetInfo['ratio'] = _setInfo['ratio'];
			_recordSetInfo['size'] = _setInfo['size'];
		}
		
		//取消
		public function cancleInterfaceFunction():void
		{
			setFaceStatus(_recordSetInfo);
		}
	}
}