package zuffy.ctr.contextMenu 
{
	import flash.display.Sprite;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuBuiltInItems;
	
	/**
	 * ...
	 * @author zuffy
	 */
	public class CreateContextMenu
	{
		private static var _menu:ContextMenu;
		private static var _target:Sprite;
		
		public function CreateContextMenu() 
		{
			
		}
		
		public static function createMenu(target:Sprite):void
		{
			if (_menu == null) {
				_menu = new ContextMenu();
				_target = target;
			}
			_menu.hideBuiltInItems();
			_target.contextMenu = _menu;
		}
		
		public static function addItem(caption:String,separatorBefore:Boolean, enabled:Boolean, action:Function):void
		{
			var index:int = getIndex(caption);
			var creatMenuItem:CreateMenuItem = new CreateMenuItem(caption, separatorBefore, enabled, action);
			if (index != -1) {
				_menu.customItems[index] = creatMenuItem.menuItem;
			}else {
				_menu.customItems.push(creatMenuItem.menuItem);
			}
		}
		
		public static function delItem(caption:String):void
		{
			var index:int = getIndex(caption);
			if(index != -1){
				_menu.customItems.slice(index, 1);
			}
		}
		
		public static function setEnabled(caption:String, enabled:Boolean):void
		{
			var index:int = getIndex(caption);
			if(index != -1){
				_menu.customItems[index].enabled = enabled;
			}
		}
		
		private static function getIndex(caption:String):int
		{
			var index:int = -1;
			for (var i:int = 0, len:int = _menu.customItems.length; i < len; i++ ) {
				if (caption == _menu.customItems[i].caption) {
					index = i;
					break;
				}
			}
			return index;
		}
		
	}
}