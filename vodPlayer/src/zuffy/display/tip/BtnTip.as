package ctr.tip
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldAutoSize;
	import com.common.BitmapScale9Grid;

	public class BtnTip extends Sprite
	{
		public function BtnTip()
		{
			_bgBmd = new BtnTipsBg(44, 32);
			
			_bg = new BitmapScale9Grid(_bgBmd, 4, 28, 4, 40);
			this.addChild(_bg);
			
			var tf:TextFormat = new TextFormat();
			tf.align = "center";
			
			_txt = new TextField();
			_txt.defaultTextFormat = tf;
			_txt.y = 8;
			_txt.selectable = false;
			_txt.text = '播放';
			_txt.height = _txt.textHeight + 5;
			_txt.setTextFormat(new TextFormat('宋体', 12, 0x8e8e8e));
			this.addChild(_txt);
		}
		
		public function set bgWidth(_w:Number):void
		{
			_bg.width = _w;
			_txt.width = _w;
		}
		
		public function set text(t)
		{
			_txt.text = t;
			_txt.setTextFormat(new TextFormat('宋体', 12, 0x8e8e8e));
		}
		
		public function get text()
		{
			return _txt.text;
		}
		
		private var _txt:TextField;
		private var _bg:Sprite;
		private var _bgBmd:BtnTipsBg;
	}
}