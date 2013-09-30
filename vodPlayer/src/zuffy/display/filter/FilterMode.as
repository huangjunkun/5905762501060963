package zuffy.display.filter 
{
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import zuffy.events.EventFilter;
	/**
	 * ...
	 * @author Drgon.S
	 */
	public class FilterMode extends Sprite
	{
		private var _filterModeBtnArr:Array = [];
		private var _restoreButton:SimpleButton;
		private var _cacheButton:SimpleButton;
		
		public function FilterMode() 
		{
			var _title:TextField = new TextField();
			_title.text = '色彩模式：';
			_title.width = 60;
			_title.height = 23;
			_title.setTextFormat(new TextFormat('宋体', 12, 0xC1C1C1));
			_title.selectable = false;
			//addChild(_title);
			_filterModeBtnArr.push( { 'btn':drawFilterModeButton(SetMingLiangButton, actionFunction), 'mode':'明亮', 'eve':EventFilter.FILTER_MINGLIANG } );
			_filterModeBtnArr.push( { 'btn':drawFilterModeButton(SetRouHuoButton, actionFunction), 'mode':'柔和', 'eve':EventFilter.FILTER_ROUHUO } );
			_filterModeBtnArr.push( { 'btn':drawFilterModeButton(SetFuGuButton, actionFunction), 'mode':'复古', 'eve':EventFilter.FILTER_FUGU } );
			_filterModeBtnArr.push( { 'btn':drawFilterModeButton(SetBiaoZhunButton, actionFunction), 'mode':'标准', 'eve':EventFilter.FILTER_BIAOZHUN} );
			setButtonPosition();
			_restoreButton = _filterModeBtnArr[0]['btn'];
			changeButtonStatusWidthTarget(_filterModeBtnArr[0]['btn']);
		}
		
		private function setButtonPosition():void
		{
			for (var i:int = 0; i < _filterModeBtnArr.length; i++ ) {
				_filterModeBtnArr[i]['btn'].x = i * 70;
				addChild(_filterModeBtnArr[i]['btn']);
			}
		}
		
		private function drawFilterModeButton(classRef:Class, action:Function):SimpleButton
		{
			var btnSprite:SimpleButton = new classRef();
			btnSprite.addEventListener(MouseEvent.CLICK, function(even:MouseEvent):void {
				action(even.currentTarget);
			} );
			return btnSprite;
		}
		
		private function actionFunction(target:SimpleButton):void
		{
			for (var i:int = 0; i < _filterModeBtnArr.length; i++ ) {
				if (_filterModeBtnArr[i]['btn'] == target) {
					_cacheButton = target;
					dispatchEvent(new EventFilter(_filterModeBtnArr[i]['eve']));
				}
			}
		}
		
		private function changeButtonStatusWidthTarget(target:SimpleButton):void
		{
			for (var i:int = 0; i < _filterModeBtnArr.length; i++ ) {
				if (_filterModeBtnArr[i]['btn'] == target) {
					_cacheButton = target;
				}
			}
		}
		
		public function resizeButton():void
		{
			
		}
		
		public function restoreButtonFunction():void
		{
			
		}
		
		public function commitButtonFunction():void
		{
			_restoreButton = _cacheButton;
		}
		
		public function changeButtonStatus(str:String):void
		{
			var target:SimpleButton;
			switch(str) {
				case 'filter_mingLiang':
					target = _filterModeBtnArr[0]['btn'];
					break;
				case 'filter_rouHuo':
					target = _filterModeBtnArr[1]['btn'];
					break;
				case 'filter_fugu':
					target = _filterModeBtnArr[2]['btn'];
					break;
				case 'filter_biaoZhun':
					target = _filterModeBtnArr[3]['btn'];
					break;
				default:
					target = _filterModeBtnArr[3]['btn'];
					break;
			}
			changeButtonStatusWidthTarget(target);
		}
		
	}
}