package zuffy.display.tip
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;	
	public class Volume100Tips extends Sprite
	{
		public function Volume100Tips()
		{
			volumeBg= new Volume100();
			this.addChild( volumeBg );
			txt = new TextField();
			txt.x = 30;
			txt.y = 2;
			txt.autoSize=TextFieldAutoSize.CENTER;
			txt.selectable=false;
			this.addChild(txt);
			txt.setTextFormat(new TextFormat('Arial',12,0x8e8e8e));
			txt.text = "100%(按↑键继续放大音量)";
		}
		public function set text(t:String):void
		{
			txt.text=t;
			txt.setTextFormat(new TextFormat('Arial',12,0x8e8e8e));
		}
		
		public function get text():String
		{
			return txt.text;
		}
		private var volumeBg:Volume100;
		private var txt:TextField;
	}
}