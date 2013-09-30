package zuffy.display.setting 
{
	import flash.display.MovieClip;
	import flash.text.TextFormat;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class CaptionStyleBtn extends MovieClip 
	{
		private var _selected:Boolean;
		private var _fontColor:uint;
		private var _filterColor:uint;
		
		public function CaptionStyleBtn() 
		{
			var tf:TextFormat = new TextFormat("微软雅黑");
			
			color_txt.defaultTextFormat = tf;
		}
		
		public function set fontColor(value:uint):void
		{
			_fontColor = value;
		}
		
		public function get fontColor():uint
		{
			return _fontColor;
		}
		public function set filterColor(value:uint):void
		{
			_filterColor = value;
		}
		
		public function get filterColor():uint
		{
			return _filterColor;
		}
		
		public function set selected(boo:Boolean):void
		{
			_selected = boo;
		}
		
		public function get selected():Boolean
		{
			return _selected;
		}
	}

}