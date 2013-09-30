package zuffy.display.setting 
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	/**
	 * ...
	 * @author dds
	 */
	public class SetDrawBackground extends Sprite
	{
		private static const TITLE_HEIGHT:Number = 30;
		private static const TITLE_STYLE:TextFormat = new TextFormat('宋体', 13, 0x3A8DDF, true, null, null, null, null, 'left');
		private static const MARGIN:Number = 15;
		private static const BACKGROUND_COLOR:int = 0x0e0e0e;
		private static const BACKGROUND_ALPHA:Number = 0.8;
		private static const BORDER_COLOR:int = 0x2b2b2b;
		private var _title:TextField;
		private var _bg:CommonBackGround;
		/**
		 * 根据高宽、标题生成一个背景面板
		 * @param	title 标题
		 * @param	bw 面板宽度
		 * @param	bh 面板高度
		 */
		public function SetDrawBackground(title:String,bw:Number,bh:Number) 
		{
			drawBackground(bw, bh);
			
			_title = new TextField();
			_title.defaultTextFormat = TITLE_STYLE;
			_title.selectable = false;
			_title.text = title;
			_title.width = _title.textWidth + 4;
			_title.height = 20;
			addChild(_title);
			
			updateTitlePosition();
		}
		
		private function drawBackground(bw:Number,bh:Number):void
		{
			if (!_bg)
			{
				_bg = new CommonBackGround();
				addChild(_bg);
			}
			_bg.width = bw;
			_bg.height = bh;
			
			/*
			this.graphics.lineStyle(1, BORDER_COLOR);
			this.graphics.beginFill(BACKGROUND_COLOR, BACKGROUND_ALPHA);
			this.graphics.drawRect(0, 0, bw, bh);
			this.graphics.moveTo(0, TITLE_HEIGHT);
			this.graphics.lineTo(bw, TITLE_HEIGHT);
			this.graphics.endFill();
			*/
		}
		
		private function updateTitlePosition():void
		{
			_title.x = 10;
			_title.y = 9;
			//_title.x = (this.width - _title.width) / 2;
			//_title.y = (TITLE_HEIGHT - _title.height) / 2;
		}
		
		public function setTitle(title:String):void
		{
			_title.text = title;
		}
		
		public function setSize(w:Number,h:Number):void
		{
			//this.graphics.clear();
			drawBackground(w, h);
			updateTitlePosition();
		}
	}
}