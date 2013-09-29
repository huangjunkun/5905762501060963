package ctr.statuMenu 
{
	import flash.display.MovieClip;
	import flash.events.TimerEvent;
	import flash.text.TextFormat;
	import flash.utils.setTimeout;
	import flash.utils.Timer;
	/**
	 * ...
	 * @author hwh
	 */
	public class ProcessLoading extends MovieClip
	{
		private var isTipsChanged:Boolean;
		
		public function ProcessLoading() 
		{
			var tf:TextFormat = new TextFormat("微软雅黑");
			tf.bold = true;
			
			_progress.defaultTextFormat = tf;
		}
		
		public function changeTips():void
		{
			isTipsChanged = false;
			setTimeout(onChangeTips, 1000);
		}
		
		public function set progress(num:Number):void
		{
			if (!isTipsChanged)
			{
				_progress.text = "正在从原始地址下载...";
				return;
			}
			
			if (num <= 0) {
				_progress.text = "已下载到云空间并转码，正在准备数据... 　";
			} else if (num >= 100) {
				_progress.text = "已下载到云空间并转码，正在准备数据...99%";
			} else {
				_progress.text = "已下载到云空间并转码，正在准备数据..." + String(num) + (num < 10 ? "% " : "%");
			}
		}
		
		public function set process(str:String):void
		{
			_progress.text = str;
		}
		
		private function onChangeTips():void
		{
			isTipsChanged = true;
		}
	}
}