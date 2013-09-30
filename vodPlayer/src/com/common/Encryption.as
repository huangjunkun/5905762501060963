package com.common 
{
	/**
	 * ...
	 * @author Drgon.S
	 */
	public class Encryption
	{
		
		public function Encryption() 
		{
			
		}
		
		public static function EncryptionUrl(jsonObj:Object):String
		{
			JTracer.sendLoaclMsg('jsonObj:' + jsonObj);
			var url:String = '';
			if (jsonObj == null) {
				return url;
			}
			for (var vars:* in jsonObj) {
				if (vars == null) {
					JTracer.sendLoaclMsg('获取的url对象中有字段为空,空的字段是:' + vars);
					return url;
				}
			}
			if (jsonObj == null || jsonObj.ip == null || jsonObj.path == null || jsonObj.param1 == null || jsonObj.param2 == null) {
				JTracer.sendLoaclMsg('获取的url对象中有字段为空');
				return url;
			}
			var port:String = '80';
			var prefix:String = 'xl_mp43651';
			var serverUrl:String = 'http://' + jsonObj.ip + ':' + port +'/' + jsonObj.path;
			var key:String =MD5.hash(prefix + jsonObj.param1 + jsonObj.param2);
			JTracer.sendLoaclMsg('key:' + prefix + jsonObj.param1 + jsonObj.param2);
			var key1:String = jsonObj.param2;
			serverUrl += '?key=' + key + '&key1=' + key1;
			JTracer.sendMessage('serverUrl:' + serverUrl);
			return serverUrl;
		}
		
	}

}