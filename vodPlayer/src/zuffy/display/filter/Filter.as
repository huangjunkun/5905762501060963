package zuffy.display.filter 
{
	import zuffy.display.setting.CommonSlider;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.filters.ColorMatrixFilter;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import com.common.Tools;
	import com.global.GlobalVars;
	import zuffy.events.EventFilter;
	import com.Player;
	import com.common.JTracer;
	import zuffy.events.EventSet;
	import zuffy.events.EventFilter;

	/**
	 * ...
	 * @author Dragon.S
	 */
	public class Filter extends Sprite
	{
		private var _player:Player;
		private var _nRed:Number 	= 0.3086;
		private var _nGreen:Number 	= 0.6094;
		private var _nBlue:Number 	= 0.0820;
		private var _resetAllBtn:Sprite;
		private var _sSaturation:CommonSlider;
		private var _sTint:CommonSlider;
		private var _sBrighten:CommonSlider;
		private var _sContrast:CommonSlider;
		private var _commitButton:SetCommitButton;
		private var _recordFiltersArr:Array = [];
		private var _filtersArr:Array = [];
		private var _filtersObj:Object = { };
		private var _lastTint:Number;
		private var _lastBrighten:Number;
		private var _lastContrast:Number;
		private var _lastSaturation:Number;
		public var _filterMode:FilterMode;
		
		public function Filter(target:Player) 
		{
			_player = target;
			init();
		}
		private function init():void
		{
			_sTint = new CommonSlider();
			//addChild(_sTint);
			_sTint.title = '色　调';
			_sTint.x = 30;
			_sTint.y = 10;
			_sTint.defLevel = 1;
			_sTint.aveLevel = 1;
			_sTint.minValue = -113;
			_sTint.maxValue = 114;
			_sTint.snapInterval = 1;
			_sTint.clickInterval = 1;
			_sTint.decimalNum = 0;
			_sTint.isShowToolTip = true;
			_sTint.isThumbIconHasStatus = true;
			_sTint.currentValue = 0;
			_sTint.addEventListener(CommonSlider.CHANGE_VALUE, changeFilterHandler);
			
			_sBrighten = new CommonSlider();
			addChild(_sBrighten);
			_sBrighten.title = '亮　度';
			_sBrighten.x = 30;
			_sBrighten.y = 10;
			_sBrighten.defLevel = 1;
			_sBrighten.aveLevel = 2;
			_sBrighten.minValue = -113;
			_sBrighten.maxValue = 114;
			_sBrighten.snapInterval = 1;
			_sBrighten.clickInterval = 1;
			_sBrighten.decimalNum = 0;
			_sBrighten.isShowToolTip = true;
			_sBrighten.isThumbIconHasStatus = true;
			_sBrighten.currentValue = 0;
			_sBrighten.addEventListener(CommonSlider.CHANGE_VALUE, changeFilterHandler);
			
			_sContrast = new CommonSlider();
			addChild(_sContrast);
			_sContrast.title = '对比度';
			_sContrast.x = 30;
			_sContrast.y = 26 + 10;
			_sContrast.defLevel = 0.1;
			_sContrast.aveLevel = 0.9;
			_sContrast.minValue = -113;
			_sContrast.maxValue = 114;
			_sContrast.snapInterval = 1;
			_sContrast.clickInterval = 1;
			_sContrast.decimalNum = 0;
			_sContrast.isShowToolTip = true;
			_sContrast.isThumbIconHasStatus = true;
			_sContrast.currentValue = 0;
			_sContrast.addEventListener(CommonSlider.CHANGE_VALUE, changeFilterHandler);
			
			_sSaturation = new CommonSlider();
			addChild(_sSaturation);
			_sSaturation.title = '饱和度';
			_sSaturation.x = 30;
			_sSaturation.y = 26 * 2 + 10;
			_sSaturation.defLevel = 1;
			_sSaturation.aveLevel = 1;
			_sSaturation.minValue = -113;
			_sSaturation.maxValue = 114;
			_sSaturation.snapInterval = 1;
			_sSaturation.clickInterval = 1;
			_sSaturation.decimalNum = 0;
			_sSaturation.isShowToolTip = true;
			_sSaturation.isThumbIconHasStatus = true;
			_sSaturation.currentValue = 0;
			_sSaturation.addEventListener(CommonSlider.CHANGE_VALUE, changeFilterHandler);
			
			_lastTint = _sTint.currentValue;
			_lastBrighten = _sBrighten.currentValue;
			_lastContrast = _sContrast.currentValue;
			_lastSaturation = _sSaturation.currentValue;
			
			_filterMode = new FilterMode();
			addChild(_filterMode);
			_filterMode.y = 85;
			_filterMode.x = (this.width - _filterMode.width) / 2 + 20;
			_filterMode.addEventListener(EventFilter.FILTER_MINGLIANG, filterModeEventHandler);
			_filterMode.addEventListener(EventFilter.FILTER_ROUHUO, filterModeEventHandler);
			_filterMode.addEventListener(EventFilter.FILTER_FUGU, filterModeEventHandler);
			_filterMode.addEventListener(EventFilter.FILTER_BIAOZHUN, filterModeEventHandler);
			
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
		
		private function filterModeEventHandler(e:EventFilter):void
		{
			switch(e.type) {
				case 'filter_mingLiang':
					filterModeMingLiang();
					break;
				case 'filter_rouHuo':
					filterModeRouHuo();
					break;
				case 'filter_fugu':
					filterModeFuGu();
					break;
				case 'filter_biaoZhun':
					filterModeBiaoZhun();
					break;
			}
		}
		
		private function changeFilterHandler(evt:Event):void
		{
			var level:Number = evt.currentTarget.level;
			switch(evt.target)
			{
				case _sTint:
					cmfTint(level);
					break;
				case _sBrighten:
					cmfBrighten(level);
					break;
				case _sContrast:
					cmfContrast(level);
					break;
				case _sSaturation:
					cmfSaturation(level);
					break;
			}
			JTracer.sendMessage("Filter -> 饱和度, 亮度, 对比度, 色相: " + _sSaturation.currentValue + ", " + _sBrighten.currentValue + ", " + _sContrast.currentValue + ", " + _sTint.currentValue);
		}
		
		private function filterModeBiaoZhun():void//色调：0 饱和度：0 亮度：0 对比度：0
		{
			_filterMode.changeButtonStatus("filter_biaoZhun");
			
			_sTint.currentValue = 0;
			_sBrighten.currentValue = 0;
			_sContrast.currentValue = 0;
			_sSaturation.currentValue = 0;
		}
		
		private function filterModeMingLiang():void//色调：18 饱和度：18 亮度：12 对比度：0 
		{
			_filterMode.changeButtonStatus("filter_mingLiang");
			
			_sTint.currentValue = 17;
			_sBrighten.currentValue = 11;
			_sContrast.currentValue = 0;
			_sSaturation.currentValue = 17;
		}
		
		private function filterModeRouHuo():void//色调：0 饱和度：-15 亮度：0 对比度：0 
		{
			_filterMode.changeButtonStatus("filter_rouHuo");
			
			_sTint.currentValue = 0;
			_sBrighten.currentValue = 0;
			_sContrast.currentValue = 0;
			_sSaturation.currentValue = -15;
		}
		
		private function filterModeFuGu():void//色调：0 饱和度：-100 亮度：20 对比度：20 
		{
			_filterMode.changeButtonStatus("filter_fuGu");
			
			_sTint.currentValue = 0;
			_sBrighten.currentValue = 0;
			_sContrast.currentValue = 0;
			_sSaturation.currentValue = -113;
		}
		
		private function resetAllHandler():void
		{
			_player.filters = [];
			_filtersArr = [];
			_filtersObj = {};
			
			_sTint.currentValue = _lastTint;
			_sBrighten.currentValue = _lastBrighten;
			_sContrast.currentValue = _lastContrast;
			_sSaturation.currentValue = _lastSaturation;
			
			recordAllPosition();
		}
		
		private function recordAllPosition():void
		{
			_lastTint = _sTint.currentValue;
			_lastBrighten = _sBrighten.currentValue;
			_lastContrast = _sContrast.currentValue;
			_lastSaturation = _sSaturation.currentValue;
			
			if (_recordFiltersArr != _filtersArr)
			{
				_recordFiltersArr = _filtersArr;
				
				GlobalVars.instance.colorChanged = true;
			}
		}
		
		private function restoreAllPosition():void
		{
			_sSaturation.currentValue = _lastSaturation;
			_sBrighten.currentValue = _lastBrighten;
			_sContrast.currentValue = _lastContrast;
			_sTint.currentValue = _lastTint;
			
			_filtersArr = _recordFiltersArr;
			_player.filters = _filtersArr;
		}
		
		private function cmfDigitalNegative():void//负片
		{
			var fDigitalNegative:ColorMatrixFilter = new ColorMatrixFilter([
				-1, 0, 0, 0, 255,
				0, -1, 0, 0, 255,
				0, 0, -1, 0, 255,
				0, 0,  0, 1, 0
			]);
			_player.filters = [fDigitalNegative];
		}
		
		private function cmfGrayscale():void//灰度
		{
			var fGrayscale:ColorMatrixFilter = new ColorMatrixFilter([
				_nRed, _nGreen, _nBlue, 0, 0,
				_nRed, _nGreen, _nBlue, 0, 0,
				_nRed, _nGreen, _nBlue, 0, 0,
				0, 	   0, 		0, 		1, 0
			]);
			_player.filters = [fGrayscale];
		}
		
		private function cmfSaturation(level:Number = 1):void//饱和度0~3,0表示灰度，1时是默认
		{
			var nA:Number = (1 - level) * _nRed + level;
			var nB:Number = (1 - level) * _nGreen;
			var nC:Number = (1 - level) * _nBlue;
			var nD:Number = (1 - level) * _nRed;
			var nE:Number = (1 - level) * _nGreen + level;
			var nF:Number = (1 - level) * _nBlue;
			var nG:Number = (1 - level) * _nRed;
			var nH:Number = (1 - level) * _nGreen;
			var nI:Number = (1 - level) * _nBlue + level;
			var fStaturation:ColorMatrixFilter = new ColorMatrixFilter([
				nA, nB, nC, 0, 0,
				nD, nE, nF, 0, 0,
				nG, nH, nI, 0, 0,
				0,  0,  0,  1, 0
			]);
			_filtersObj['fStaturation'] = fStaturation;
			objToArray();
		}
		
		private function cmfTint(level:Number):void//色调-1~1
		{
			var fTint:ColorMatrixFilter = new ColorMatrixFilter([
				level, 0, 0, 0, 0,
				0, level, 0, 0, 0,
				0, 0, level, 0, 0,
				0, 0, 0, level, 0
			]);
			_filtersObj['fTint'] = fTint;
			objToArray();
		}
		
		private function cmfBrighten(level:Number=1):void//亮度默认为1
		{
			var fBrighten:ColorMatrixFilter = new ColorMatrixFilter([
				level, 0, 0, 0, 0,
				0, level, 0, 0, 0,
				0, 0, level, 0, 0,
				0, 0, 0, level, 0
			]);
			_filtersObj['fBrighten'] = fBrighten;
			objToArray();
		}
		
		private function cmfContrast(level:Number = 0.1):void//对比度0~1
		{
			//if (level < 0) level = 0.001;
			var nScale:Number = level * 11;
			var nOffset:Number = 63.5 - (level * 698.5);
			var fContrast:ColorMatrixFilter = new ColorMatrixFilter([
				nScale, 0, 0, 0, nOffset,
				0, nScale, 0, 0, nOffset,
				0, 0, nScale, 0, nOffset,
				0, 0, 0, 	  1, 0
			]);
			_filtersObj['fContrast'] = fContrast;
			objToArray();
		}
		
		private function objToArray():void
		{
			_filtersArr = [];
			if (_filtersObj['fContrast'] && _filtersObj['fContrast'] != null) {
				_filtersArr.push(_filtersObj['fContrast']);
			}
			if (_filtersObj['fBrighten'] && _filtersObj['fBrighten'] != null) {
				_filtersArr.push(_filtersObj['fBrighten']);
			}
			if (_filtersObj['fTint'] && _filtersObj['fTint'] != null) {
				_filtersArr.push(_filtersObj['fTint']);
			}
			if (_filtersObj['fStaturation'] && _filtersObj['fStaturation'] != null) {
				_filtersArr.push(_filtersObj['fStaturation']);
			}
			_player.filters = _filtersArr;
		}
		
		public function get isThumbIconActive():Boolean
		{
			if (_sTint.isThumbIconActive || _sBrighten.isThumbIconActive || _sContrast.isThumbIconActive || _sSaturation.isThumbIconActive)
			{
				return true;
			}
			
			return false;
		}
		
		public function subDeltaByMouse(interval:Number):void
		{
			if (_sTint.isThumbIconActive)
			{
				_sTint.subTimeDelta(interval, true, _sTint.controllBtn);
			}
			
			if (_sBrighten.isThumbIconActive)
			{
				_sBrighten.subTimeDelta(interval, true, _sBrighten.controllBtn);
			}
			
			if (_sContrast.isThumbIconActive)
			{
				_sContrast.subTimeDelta(interval, true, _sContrast.controllBtn);
			}
			
			if (_sSaturation.isThumbIconActive)
			{
				_sSaturation.subTimeDelta(interval, true, _sSaturation.controllBtn);
			}
		}
		
		public function addDeltaByMouse(interval:Number):void
		{
			if (_sTint.isThumbIconActive)
			{
				_sTint.addTimeDelta(interval, true, _sTint.controllBtn);
			}
			
			if (_sBrighten.isThumbIconActive)
			{
				_sBrighten.addTimeDelta(interval, true, _sBrighten.controllBtn);
			}
			
			if (_sContrast.isThumbIconActive)
			{
				_sContrast.addTimeDelta(interval, true, _sContrast.controllBtn);
			}
			
			if (_sSaturation.isThumbIconActive)
			{
				_sSaturation.addTimeDelta(interval, true, _sSaturation.controllBtn);
			}
		}
		
		public function set showFace(isShow:Boolean):void
		{
			if (isShow == false) {
				this.visible = false;
			}else {
				this.visible = true;
				
				//显示其它tab时，确定
				commitInterfaceFunction();
			}
		}
		
		//恢复默认
		public function initRecordStatus():void
		{
			resetAllHandler();
		}
		
		//确定
		public function commitInterfaceFunction():void
		{
			recordAllPosition();
		}
		
		//取消
		public function cancleInterfaceFunction():void
		{
			restoreAllPosition();
		}
	}
}