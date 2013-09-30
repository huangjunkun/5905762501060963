package com.common
{
	/**
	 * ...
	 * @author hwh
	 */
	public class StringUtil 
	{
		public static function getHostPort(url:String):Object
		{
			var real_url:String = getRealURL(url);
			var m_url:String = real_url.substr(real_url.indexOf("/"));
			var m_host:String = real_url.substr(0, real_url.indexOf("/"));
			var m_port:uint = 80;
			var host_arr:Array = m_host.split(":");
			if (host_arr.length > 1)
			{
				m_host = host_arr[0];
				m_port = host_arr[1];
			}
			
			return {url:m_url, host:m_host, port:m_port};
		}
		
		public static function getResponseHeader(response:String, header:String, separate:String):String
		{
			if (!response || response == "")
			{
				trace("not found header:" + header + ", separate:" + separate + ", response:" + response);
				return null;
			}
			
			var headerPos:int = response.indexOf(header);
			if (headerPos < 0)
			{
				trace("not found header:" + header);
				return null;
			}
			
			var headerArr:Array = response.split("\r\n");
			var i:*;
			var pos:int;
			var itemArr:Array;
			for (i in headerArr)
			{
				itemArr = headerArr[i].split(separate);
				if (itemArr.length > 1 && trim(itemArr[0]) == header)
				{
					if (separate == ":")
					{
						pos = headerArr[i].indexOf(":");
						return trim(headerArr[i].substr(pos + 1));
					}
					return trim(itemArr[1]);
				}
			}
			
			return null;
		}
		
		public static function trim(s:String):String
		{
			return s.replace(/^\s+/, '').replace(/\s+$/, '');
		}
		
		public static function getShortenURL(url:String):String
		{
			if (!url)
			{
				return null;
			}
			url = getRealURL(url);
			url = url.substr(0, url.indexOf("/"));
			return url;
		}
		
		private static function getRealURL(url:String):String
		{
			var result:String;
			if (url.indexOf("://") >= 0)
			{
				var split_arr:Array = url.split("://");
				result = split_arr[1];
			}
			else
			{
				result = url;
			}
			return result;
		}
	}
}