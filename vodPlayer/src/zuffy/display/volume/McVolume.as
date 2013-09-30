package zuffy.display.volume
{
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.net.SharedObject;
	import com.common.JTracer;
	import zuffy.events.VolumeEvent;
	
	public class McVolume extends MovieClip 
	{	
		public var ctrB;
		public function McVolume(_s) 
		{
			ctrB = _s;
			_volumeCtr = new VolumeCtr();
			this.addChild(_volumeCtr);
			
			_volumeBg = _volumeCtr.unget;
			_volumeMask = _volumeCtr.mask1;
			_btnVolume = _volumeCtr.scroll;
			_volumeBg.mask = _volumeMask;
			
			_btnVolume.y = 0;
			_volumeBg.buttonMode = true;
			_volumeBg.useHandCursor = true;	
			
			_btnVolume.addEventListener(MouseEvent.MOUSE_DOWN, handleBtnVolumeMouseDown);
			this.addEventListener(MouseEvent.CLICK, handleMouseClick);
			//this.addEventListener(MouseEvent.MOUSE_OVER, showHandler);
			//this.addEventListener(MouseEvent.MOUSE_OUT, showHandler);
			init();
		}

		private function showHandler(e:MouseEvent):void
		{
			switch(e.type)
			{
				case 'mouseOver':
					this.visible = true;
					_isShow = true;
					break;
				case 'mouseOut':
					this.visible = false;
					_isShow = false;
					break;
			}
		}
		
		public function get show():Boolean
		{
			return _isShow;
		}
		
		private function handleMouseClick(e:MouseEvent):void 
		{	
			var mouseX:Number = e.stageX;
			var mouseY:Number = e.stageY;
			_btnVolume.x = this.globalToLocal(new Point(mouseX, mouseY)).x;
			if (_btnVolume.x >= 45)
			{
				_btnVolume.x = 45;
			}
			if (_btnVolume.x <= 0)
			{
				_btnVolume.x = 0;
				
			}
			_volumeMask.width = 53 - _btnVolume.x - 1;
			_volumeMask.x = _btnVolume.x + 1;
			_currentVolume = _btnVolume.x / 45;
			this.dispatchEvent(new VolumeEvent(VolumeEvent.VOLUME_CHANGE, String( _currentVolume )));
			saveVV();
		}
		public function handleVolumeBar( volume:Number ):void
		{
			_currentVolume = volume;
			if( _currentVolume > 1 )
				_btnVolume.x = 45;
			else
				_btnVolume.x = _currentVolume * 45;
			_volumeMask.width = 53 - _btnVolume.x - 1;
			_volumeMask.x = _btnVolume.x + 1;
			saveVV();
		}
		private function handleBtnVolumeMouseMove(e:MouseEvent):void 
		{
			var mouseX:Number = e.stageX;
			var mouseY:Number = e.stageY;
			_btnVolume.x = this.globalToLocal(new Point(mouseX, mouseY)).x;
			if (_btnVolume.x >= 45)
			{
				_btnVolume.x = 45;
			}
			if (_btnVolume.x <= 0)
			{
				_btnVolume.x = 0;
			}
			_volumeMask.width = 53 - _btnVolume.x - 1;
			_volumeMask.x = _btnVolume.x + 1;
			_currentVolume = _btnVolume.x / 45;
			this.dispatchEvent(new VolumeEvent(VolumeEvent.VOLUME_CHANGE, String( _currentVolume ) ));
		}
		
		private function handleBtnVolumeMouseDown(e:MouseEvent):void 
		{
			_btnVolume.stage.addEventListener(MouseEvent.MOUSE_MOVE, handleBtnVolumeMouseMove);			
			_btnVolume.stage.addEventListener(MouseEvent.MOUSE_UP, handleBtnVolumeMouseUp);	
			//this.removeEventListener(MouseEvent.MOUSE_OUT, showHandler);
		}
		
		private function handleBtnVolumeMouseUp(e:MouseEvent):void 
		{
			//this.addEventListener(MouseEvent.MOUSE_OUT, showHandler);
			_btnVolume.stage.removeEventListener(MouseEvent.MOUSE_MOVE, handleBtnVolumeMouseMove);			
			_btnVolume.stage.removeEventListener(MouseEvent.MOUSE_UP, handleBtnVolumeMouseUp);		
			
			if (this.mouseY < 0 || this.mouseY > 12 || this.mouseX < 0 || this.mouseX > 53)
			{
				this.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
			}
			
			saveVV();
		}
		
		public function get currentVolume():Number 
		{ 
			return _currentVolume;
		}
		
		override public function set width(value:Number):void 
		{
			_currentVolume = value / 45;
			_btnVolume.x = value > 45 ? 45 : value;
			_volumeMask.width = 53 - _btnVolume.x - 1;
			_volumeMask.x = _btnVolume.x + 1;
			dispatchEvent(new VolumeEvent(VolumeEvent.VOLUME_CHANGE, String( _currentVolume ) ));
		}
		
		private function init():void
		{
			_so = SharedObject.getLocal("kkV");
			if ( _so.data.v ) 
			{
				this.width = _so.data.v * 45;
			}else {
				this.width = 0.5 * 45;
			}
		}
		
		private function saveVV():void
		{
			_so = SharedObject.getLocal("kkV");
			var v = _currentVolume;
			if (v <= 0) v = 0;
			_so.data.v = v;
			_so.flush();
		}
		
		private var _volumeBg:MovieClip;
		private var _volumeProgress:MovieClip;
		private var _btnVolume:SimpleButton;
		private var _currentVolume:Number = 0.5;
		private var _volumeMask:MovieClip;
		private var _so:SharedObject;
		private var _volumeCtr:VolumeCtr;
		private var _isShow:Boolean = false;
		
	}
}