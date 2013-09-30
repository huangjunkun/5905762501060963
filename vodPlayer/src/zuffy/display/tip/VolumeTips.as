package zuffy.display.tip
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	
	public class VolumeTips extends Sprite
	{
		public function VolumeTips()
		{
			volumeBg= new Volume();
			this.addChild( volumeBg );
			txt = new TextField();
			txt.autoSize=TextFieldAutoSize.CENTER;
			txt.width = 40;
			txt.selectable=false;
			this.addChild(txt);
			txt.x = 21;
			txt.y = 2;
			txt.setTextFormat(new TextFormat('Arial',12,0x8e8e8e));
		}
		
		public function set text( t:String ):void
		{
			txt.text=t;
			txt.setTextFormat(new TextFormat('Arial',12,0x8e8e8e));
		}
		
		public function get text():String
		{
			return txt.text;
		}
		private var volumeBg:Volume;
		private var txt:TextField;
	}
}