package com.common
{
	import flash.net.SharedObject;
	
	public class Boxroom
	{
		private var _so:SharedObject;
		
		public function Boxroom(soname:String):void{
			_so=SharedObject.getLocal(soname);
			var today:String=(new Date()).toDateString();
			if(today!=_so.data.Expires){
				_so.data.Expires=today;
				_so.data.boxes = [];
				try
				{
					_so.flush();
				}
				catch (e:Error)
				{
					
				}
			}
		}	
		
		public function checkNum(id:*):int{
			var boxes:Array=_so.data.boxes;
			for(var i:uint=0;i<boxes.length;i++){
				if(boxes[i].id==id){
					return boxes[i].num;
				}
			}
			return 0;
		}
		
		public function add(id:*):void{
			var boxes:Array=_so.data.boxes;
			for(var i:uint=0;i<boxes.length;i++){
				if(boxes[i].id==id){
					boxes[i].num++;
					try
					{
						_so.flush();
					}
					catch (e:Error)
					{
						
					}
					return;
				}
			}
			boxes.push({'id':id,'num':1});
			_so.data.boxes=boxes;
			try
			{
				_so.flush();
			}
			catch (e:Error)
			{
				
			}
		}
		
		public function setCookie(id:String,value:*):void
		{
			JTracer.sendLoaclMsg('writeCookie:id=' + id + ',value=' + value);
			var boxes:Array = _so.data.boxes;
			for(var i:uint=0;i<boxes.length;i++){
				if(boxes[i].id==id){
					boxes[i].value = value;
					try
					{
						_so.flush();
					}
					catch (e:Error)
					{
						
					}
					return;
				}
			}
			boxes.push( { 'id':id, 'value':value } );
			_so.data.boxes=boxes;
			try
			{
				_so.flush();
			}
			catch (e:Error)
			{
				
			}
		}
		
		public function getCookie(id:String):*
		{
			JTracer.sendLoaclMsg('getCookie:id=' + id );
			var boxes:Array = _so.data.boxes;
			for(var i:uint=0;i<boxes.length;i++){
				if(boxes[i].id==id){
					return boxes[i].value;
				}
			}
			return true;
		}
		
		public function get d():Object{
			return _so.data;
		}
	}
}