package com.global 
{
	import flash.display.Stage;
	/**
	 * ...
	 * @author zuffy
	 * 一个全局变量的保存类
	 */
	public class GlobalVars
	{
		private static var _instance:GlobalVars;
		public static function get instance():GlobalVars
		{
			if (!_instance)
			{
				_instance = new GlobalVars();
			}
			
			return _instance;
		}
		
		
		//================================================
		
		public var movieType:String = 'teleplay';	//影片信息
		
		public var windowMode:String = 'browser';	//窗口信息

		public var isStat:Boolean = true;	//0-不上报，1-只上报重要的，2-全部上报
		
		public var platform:String;
		public var isMacWebPage:Boolean = false;
		public var isZXThunder:Boolean = false;			
		

	}

}