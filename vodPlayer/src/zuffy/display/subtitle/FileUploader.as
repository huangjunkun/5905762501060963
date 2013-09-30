package zuffy.display.subtitle 
{
	import com.common.Tools;
	import flash.events.EventDispatcher;
	import flash.net.FileReference;
	import flash.events.*;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	import com.global.GlobalVars;
	import zuffy.events.CaptionEvent;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class FileUploader extends EventDispatcher 
	{
		private var file:FileReference;
		private var timer:Timer;
		private var item:CaptionItem;
		
		public function FileUploader(timeout:Number)
		{
			file = new FileReference();
			file.addEventListener(Event.SELECT, onSelectFile);
			file.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, onUploadComplete);
			file.addEventListener(ProgressEvent.PROGRESS, onUploadProgress);
			file.addEventListener(IOErrorEvent.IO_ERROR, onUploadIOError);
			file.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onUploadSecurityError);
			file.addEventListener(Event.COMPLETE, onLoadComplete);
			
			timer = new Timer(timeout * 1000, 1);
			timer.addEventListener(TimerEvent.TIMER, onTimeout);
		}
		
		public function browse(filters:Array):void
		{
			file.browse(filters);
		}
		
		public function upload(url:String):void
		{
			file.upload(new URLRequest(url));
			
			//开始计时器，检测是否上传超时
			timer.reset();
			timer.start();
		}
		
		public function load():void
		{
			file.load();
		}
		
		public function set uploadItem(item:CaptionItem):void
		{
			this.item = item;
		}
		
		private function onSelectFile(evt:Event):void
		{
			dispatchEvent(new CaptionEvent(CaptionEvent.SELECT_FILE, {uploadItem:item, fileName:file.name, fileSize:file.size}));
		}
		
		private function onUploadComplete(evt:DataEvent):void
		{
			timer.stop();
			
			dispatchEvent(new CaptionEvent(CaptionEvent.UPLOAD_COMPLETE, {uploadItem:item, fileName:file.name, data:evt.data}));
		}
		
		private function onUploadProgress(evt:ProgressEvent):void
		{
			
		}
		
		private function onUploadIOError(evt:IOErrorEvent):void
		{
			timer.stop();
			file.cancel();
			dispatchEvent(new CaptionEvent(CaptionEvent.UPLOAD_ERROR, {uploadItem:item}));
		}
		
		private function onUploadSecurityError(evt:SecurityErrorEvent):void
		{
			timer.stop();
			file.cancel();
			dispatchEvent(new CaptionEvent(CaptionEvent.UPLOAD_ERROR, {uploadItem:item}));
		}
		
		private function onLoadComplete(evt:Event):void
		{
			if (Tools.getUserInfo("userid") != "0")
			{
				dispatchEvent(new CaptionEvent(CaptionEvent.LOAD_COMPLETE, {uploadItem:item, fileName:file.name, data:file.data}));
			}
		}
		
		private function onTimeout(evt:TimerEvent):void
		{
			timer.stop();
			file.cancel();
			dispatchEvent(new CaptionEvent(CaptionEvent.UPLOAD_ERROR, {uploadItem:item}));
		}
	}

}