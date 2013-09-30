package zuffy.display.subtitle 
{
	import flash.display.MovieClip;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author hwh
	 */
	public class CaptionItem extends MovieClip
	{
		//字幕地址
		public var surl:String;
		//字幕id
		public var scid:String;
		//字幕全名
		public var fullname:String;
		//是否手动添加的字幕
		public var manual:Boolean;
		//是否选中
		public var selected:Boolean;
		//当前行
		public var row:Number;
		//从本地添加的字幕的内容
		public var data:ByteArray;
		
		public function CaptionItem() 
		{
			var tf:TextFormat = new TextFormat();
			tf.font = "微软雅黑";
			
			row_txt.defaultTextFormat = tf;
			row_txt.setTextFormat(tf);
			name_txt.defaultTextFormat = tf;
			name_txt.setTextFormat(tf);
			status_txt.defaultTextFormat = tf;
			status_txt.setTextFormat(tf);
		}
	}
}