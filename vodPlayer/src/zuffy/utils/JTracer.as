package zuffy.utils
{
    import flash.net.LocalConnection;
    import flash.events.StatusEvent;
	import flash.external.ExternalInterface;

    public class JTracer {
        private static var conn:LocalConnection;
        
        public static function sendMessage(text:*):void
		{
			try {
				sendLoaclMsg(text);
				ExternalInterface.call('G_PLAYER_INSTANCE.trace', getTime() + '----' + text);
				trace(getTime() + '----' + text);				
			}catch (e:Error) {
				trace(e.message);
			}
        }
		
		public static function sendLoaclMsg(text:*):void
		{
			var _conn:LocalConnection = init();
			_conn.send("_myConnection", "lcHandler", text);
		}
		
		private static function init():LocalConnection
		{
			if (conn) {
				return conn;
			}else{
				conn = new LocalConnection();
				conn.addEventListener(StatusEvent.STATUS, onStatus);
				return conn;
			}
        }
        
        private static function onStatus(event:StatusEvent):void {
            switch (event.level) {
                case "status":
                    break;
                case "error":
                    break;
            }
        }
		
		private static function getTime():String
		{
			var dateObj:Date = new Date();
			var year:String = dateObj.getFullYear().toString();
			var month:String = formatZero(dateObj.getMonth() + 1);
			var date:String = formatZero(dateObj.getDate());
			var hour:String = formatZero(dateObj.getHours());
			var minute:String = formatZero(dateObj.getMinutes());
			var second:String = formatZero(dateObj.getSeconds());
			var milisecond:String = dateObj.getMilliseconds().toString();
			
			return (year + "-" + month + "-" + date + " " + hour + ":" + minute + ":" + second + " " + milisecond);
		}
		
		private static function formatZero(num:Number):String
		{
			if (num < 10)
			{
				return "0" + num.toString();
			}
			
			return num.toString();
		}
    }
}
