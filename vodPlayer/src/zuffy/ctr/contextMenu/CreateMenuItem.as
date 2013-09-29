package zuffy.ctr.contextMenu 
{
	import flash.events.EventDispatcher;
	import flash.events.ContextMenuEvent;
	import flash.ui.ContextMenuItem;
	/**
	 * ...
	 * @author zuffy
	 */
	public class CreateMenuItem extends EventDispatcher
	{
		private var _menuItem:ContextMenuItem;
		private var _action:Function;
		
		public function CreateMenuItem(caption:String, separatorBefore:Boolean, enabled:Boolean, action:Function)
		{
			_menuItem = new ContextMenuItem(caption, separatorBefore, enabled);
			_menuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, menuItemSelectedHandler, false, 0, false);
			_action  = action;
		}
		
		public function get menuItem():ContextMenuItem
		{
			return _menuItem;
		}
		
		private function menuItemSelectedHandler(e:ContextMenuEvent):void
		{
			if (_action != null && _action is Function) {
				_action();
			}
		}
		
	}

}