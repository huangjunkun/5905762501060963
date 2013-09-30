package com.common 
{
	import flash.net.SharedObject;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class Cookies 
	{
		private static var cookie:SharedObject;
		
		private static function init():void
		{
			if (!cookie)
			{
				cookie = SharedObject.getLocal("svInfo");
			}
		}
		
		public static function setCookie(id:String, value:*):void
		{
			JTracer.sendMessage('Cookies -> setCookie, id=' + id + ', value=' + value);
			
			init();
			
			var boxes:Array = cookie.data.boxes || [];
			var i:uint;
			var len:uint = boxes.length;
			for (i = 0; i < len; i++)
			{
				if (boxes[i].id == id)
				{
					boxes[i].value = value;
					try
					{
						cookie.flush();
					}
					catch (e:Error)
					{
						JTracer.sendMessage('Cookies -> setCookie, SharedObject.flush() error');
					}
					return;
				}
			}
			
			boxes.push({'id':id, 'value':value});
			cookie.data.boxes = boxes;
			try
			{
				cookie.flush();
			}
			catch (e:Error)
			{
				JTracer.sendMessage('Cookies -> setCookie, SharedObject.flush() error');
			}
		}
		
		public static function getCookie(id:String):*
		{
			init();
			
			var boxes:Array = cookie.data.boxes || [];
			var i:uint;
			var len:uint = boxes.length;
			for (i = 0; i < len; i++)
			{
				if (boxes[i].id == id)
				{
					JTracer.sendMessage('Cookies -> getCookie, id=' + id + ", value=" + boxes[i].value);
					return boxes[i].value;
				}
			}
			JTracer.sendMessage('Cookies -> getCookie, id=' + id + ", value=null");
			return null;
		}
	}
}