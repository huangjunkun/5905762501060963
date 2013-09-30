package com.slice
{
	import com.common.JTracer;
	import com.global.GlobalVars;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	/**
	 * ...
	 * @author hwh
	 */
	public class StreamList
	{
		private static const AUDIO_TAG:int = 0x08;
		private static const VIDEO_TAG:int = 0x09;
		private static const SCRIPT_TAG:int = 0x18;
		private static var header:ByteArray = new ByteArray();
		private static var header_list:Dictionary = new Dictionary();
		private static var cur_list:Dictionary = new Dictionary();
		private static var next_list:Dictionary = new Dictionary();
		
		private static var header_list_id:Dictionary = new Dictionary();
		private static var cur_list_id:Dictionary = new Dictionary();
		private static var next_list_id:Dictionary = new Dictionary();
		private static var cur_serch_list:Dictionary = new Dictionary();

		private static var block_size:uint = 128 * 1024;	//socket请求的分块大小

		public static function clearHeader():void
		{
			header.clear();
			
			var i:*;
			var ba:ByteArray;
			for (i in header_list)
			{
				ba = header_list[i] as ByteArray;
				ba.clear();
				ba = null;
			}
			header_list = new Dictionary();
			header_list_id = new Dictionary();
		}
		
		public static function clearCurList():void
		{
			var i:*;
			var ba:ByteArray;
			for (i in cur_list)
			{
				ba = cur_list[i] as ByteArray;
				ba.clear();
				ba = null;
			}
			cur_list = new Dictionary();
			cur_serch_list = new Dictionary();
			cur_list_id = new Dictionary();
		}
		
		public static function clearNextList():void
		{
			var i:*;
			var ba:ByteArray;
			for (i in next_list)
			{
				ba = next_list[i] as ByteArray;
				ba.clear();
				ba = null;
			}
			next_list = new Dictionary();
			next_list_id = new Dictionary();
		}
		
		public static function replaceList():void
		{
			var i:*;
			var ba:ByteArray;
			for (i in next_list)
			{
				ba = clone(next_list[i]) as ByteArray;
				cur_list[i] = ba;
				cur_list_id[i] = next_list_id[i];
			}
			
			clearNextList();
		}
		
		public static function getHeader():ByteArray
		{
			return header;
		}
		
		public static function setHeader(bytes:ByteArray):void
		{
			header.clear();
			var pos:uint = 0;
			
			var file_bytes:ByteArray = bytes;
			var tag_start:uint = findTagsStart(file_bytes);
			
			//header
			var header_bytes:ByteArray = new ByteArray();
			header_bytes.writeBytes(file_bytes, pos, tag_start);
			JTracer.sendMessage("StreamList -> setHeader, header length:" + header_bytes.length);
			
			pos += tag_start;
			
			//=================metadata tag header
			var tag_header_metadata:ByteArray = new ByteArray();
			tag_header_metadata.writeBytes(file_bytes, pos, 11);
			JTracer.sendMessage("StreamList -> setHeader, metadata tag header length:" + tag_header_metadata.length);
			
			tag_header_metadata.position = 0;
			var tag_type:int = tag_header_metadata.readByte();//0x18
			var tag_size:int = tag_header_metadata.readUnsignedShort() << 8 | tag_header_metadata.readUnsignedByte();
			JTracer.sendMessage("StreamList -> setHeader, tag_type:" + tag_type + ", tag_size:" + tag_size);
			
			pos += 11;
			
			//metadata tag data
			var tag_data_metadata:ByteArray = new ByteArray();
			tag_data_metadata.writeBytes(file_bytes, pos, tag_size);
			JTracer.sendMessage("StreamList -> setHeader, tag data length:" + tag_data_metadata.length);
			
			pos += tag_size;
			
			//pre tag
			var pre_tag_bytes:ByteArray = new ByteArray();
			pre_tag_bytes.writeBytes(file_bytes, pos, 4);
			
			pos += 4;
			
			//=================video tag header
			var tag_header_video:ByteArray = new ByteArray();
			tag_header_video.writeBytes(file_bytes, pos, 11);
			JTracer.sendMessage("StreamList -> setHeader, video tag header length:" + tag_header_video.length);
			
			tag_header_video.position = 0;
			var tag_type_video:int = tag_header_video.readByte();//0x9
			var tag_size_video:int = tag_header_video.readUnsignedShort() << 8 | tag_header_video.readUnsignedByte();
			JTracer.sendMessage("StreamList -> setHeader, tag_type:" + tag_type_video + ", tag_size:" + tag_size_video);
			
			pos += 11;
			
			//video tag data
			var tag_data_video:ByteArray = new ByteArray();
			tag_data_video.writeBytes(file_bytes, pos, tag_size_video);
			JTracer.sendMessage("StreamList -> setHeader, tag data length:" + tag_data_video.length);
			
			pos += tag_size_video;
			
			//video pre tag
			var video_pre_tag_bytes:ByteArray = new ByteArray();
			video_pre_tag_bytes.writeBytes(file_bytes, pos, 4);
			
			pos += 4;
			
			//=================audio tag header
			var tag_header_audio:ByteArray = new ByteArray();
			tag_header_audio.writeBytes(file_bytes, pos, 11);
			JTracer.sendMessage("StreamList -> setHeader, audio tag header length:" + tag_header_audio.length);
			
			tag_header_audio.position = 0;
			var tag_type_audio:int = tag_header_audio.readByte();//0x9
			var tag_size_audio:int = tag_header_audio.readUnsignedShort() << 8 | tag_header_audio.readUnsignedByte();
			JTracer.sendMessage("StreamList -> setHeader, tag_type:" + tag_type_audio + ", tag_size:" + tag_size_audio);
			
			pos += 11;
			
			//audio tag data
			var tag_data_audio:ByteArray = new ByteArray();
			tag_data_audio.writeBytes(file_bytes, pos, tag_size_audio);
			JTracer.sendMessage("StreamList -> setHeader, tag data length:" + tag_data_audio.length);
			
			pos += tag_size_audio;
			
			//audio pre tag
			var audio_pre_tag_bytes:ByteArray = new ByteArray();
			audio_pre_tag_bytes.writeBytes(file_bytes, pos, 4);
			
			header.writeBytes(header_bytes);
			
			header.writeBytes(tag_header_metadata);
			header.writeBytes(tag_data_metadata);
			header.writeBytes(pre_tag_bytes);
			
			header.writeBytes(tag_header_video);
			header.writeBytes(tag_data_video);
			header.writeBytes(video_pre_tag_bytes);
			
			header.writeBytes(tag_header_audio);
			header.writeBytes(tag_data_audio);
			header.writeBytes(audio_pre_tag_bytes);
			
			JTracer.sendMessage("StreamList -> setHeader, total header length:" + header.length);
		}
		
		public static function setBytes(byte_type:String, start_pos:uint, end_pos:uint, bytes:ByteArray, sid:uint):void
		{
			//JTracer.sendMessage("setBytes -> start_pos:" + start_pos + ", end_pos:" + end_pos + ", bytes length:" + bytes.length);
			trace('\n'+getTime() + '----'+"sid:"+sid+" setBytes -> start_pos:" + start_pos + ", end_pos:" + end_pos + ", bytes length:" + bytes.length)
			var cache_bytes:ByteArray = new ByteArray();
			cache_bytes.writeBytes(bytes);
			if (byte_type == GlobalVars.instance.type_metadata)
			{
				if (start_pos == 0)
				{
					setHeader(cache_bytes);
				}
				
				header_list[start_pos.toString() + "-" + end_pos.toString()] = cache_bytes;
				header_list_id[start_pos.toString() + "-" + end_pos.toString()] = sid;
				return;
			}
			
			if (byte_type == GlobalVars.instance.type_curstream)
			{
				JTracer.sendMessage("sid"+sid+"curstream setBytes -> start_pos:" + start_pos + ", end_pos:" + end_pos + ", bytes length:" + bytes.length);
				trace(getTime() + '----'+"sid"+sid+" curstream setBytes -> start_pos:" + start_pos + ", end_pos:" + end_pos + ", bytes length:" + bytes.length);
				cur_list[start_pos.toString() + "-" + end_pos.toString()] = cache_bytes;
				cur_list_id[start_pos.toString() + "-" + end_pos.toString()] = sid;
				cur_serch_list[start_pos.toString() + "-" + end_pos.toString()] = (start_pos+end_pos)/2;
				
				return;
			}
			
			//JTracer.sendMessage("nextstream setBytes -> start_pos:" + start_pos + ", end_pos:" + end_pos + ", bytes length:" + bytes.length);
			next_list[start_pos.toString() + "-" + end_pos.toString()] = cache_bytes;
			next_list_id[start_pos.toString() + "-" + end_pos.toString()] = sid;
		}
		
		public static function getBytes(byte_type:String, start_pos:Number, end_pos:uint):ByteArray
		{
			//JTracer.sendMessage("getBytes -> start_pos:" + start_pos + ", end_pos:" + end_pos);
			if (byte_type == GlobalVars.instance.type_metadata)
			{
				trace(getTime() + '----'+'get metadata Bytes sid:'+header_list_id[start_pos.toString() + "-" + end_pos.toString()]+" getBytes -> start_pos:" + start_pos + ", end_pos:" + end_pos)
				return header_list[start_pos.toString() + "-" + end_pos.toString()];
			}
			
			if (byte_type == GlobalVars.instance.type_curstream)
			{
				trace(getTime() + '----'+'get curstream Bytes sid:'+cur_list_id[start_pos.toString() + "-" + end_pos.toString()]+" getBytes -> start_pos:" + start_pos + ", end_pos:" + end_pos)
				return cur_list[start_pos.toString() + "-" + end_pos.toString()];
			}
			trace(getTime() + '----'+'get netstream Bytes sid:'+next_list_id[start_pos.toString() + "-" + end_pos.toString()]+" getBytes -> start_pos:" + start_pos + ", end_pos:" + end_pos)			
			return next_list[start_pos.toString() + "-" + end_pos.toString()];
		}

		public static function getBytesRange(byte_type:String, start_pos:Number, end_pos:uint):ByteArray
		{
			//JTracer.sendMessage("getBytes -> start_pos:" + start_pos + ", end_pos:" + end_pos);
			var bytes:ByteArray = new ByteArray();
			return bytes;
		}
		public static function findBytesRange(pos:Number):Object{
			var i:*;
			var start:Number;
			var end:Number;
			var list:Dictionary = cur_serch_list;
			//trace(getTime()+' start find byte.\n')
			for (i in list)
			{
				var value:Number = list[i];
				var range:Number = Math.abs(value - pos);
				if ( range <= block_size/2 )
				{
					start = Number(i.substr(0, i.indexOf("-")));
					end = Number(i.substr(i.indexOf("-") + 1));
					trace(getTime() + '---- findBytesRange sid:'+ cur_list_id[start.toString()+'-'+end.toString()] + ' start:'+start + ' end:'+end);
					return { start:start, end:end };
				}
			}
			//trace(getTime()+' end find byte.')
			return { };
		}
		
		public static function findBytes(byte_type:String, pos:Number):Object
		{
			var i:*;
			var start:Number;
			var end:Number;
			var list:Dictionary = byte_type == GlobalVars.instance.type_curstream ? cur_list : next_list;
			var l_id:Dictionary = byte_type == GlobalVars.instance.type_curstream ? cur_list_id : next_list_id;
			//trace(getTime()+' start find byte.\n')
			for (i in list)
			{
				start = Number(i.substr(0, i.indexOf("-")));
				end = Number(i.substr(i.indexOf("-") + 1));
				
				if (start <= pos && pos <= end)
				{
					trace(getTime() + '---- findBytes sid:'+l_id[start.toString()+'-'+end.toString()] + ' start:'+start + ' end:'+end);
					return { start:start, end:end };
				}
			}
			
			return { };
		}

		public static function clearPlayedZoneBeforRange(pos:Number):void{
			var i:*;
			var start:Number;
			var end:Number;
			var list:Dictionary = cur_list;
			var l_id:Dictionary = cur_list_id;
			trace(getTime()+' start to clear bytes.\n')
			for (i in list)
			{
				start = Number(i.substr(0, i.indexOf("-")));
				end = Number(i.substr(i.indexOf("-") + 1));
				trace('start:'+ start +' - end:'+ end + ' pos:'+pos)
				if (pos > end)
				{
					trace(getTime() + '---- clearBytes sid:'+l_id[i] + ' start:'+start + ' end:'+end);

					var ba:ByteArray= list[i] as ByteArray;
					ba.clear();
					ba = null;
					delete list[i];					
					delete l_id[i];
					delete cur_serch_list[i];
				}
			}
			trace(getTime()+' end find byte.')
		}
		
		private static function findTagsStart(input:ByteArray):uint
		{
			input.position = 0;
			var signature:String = input.readUTFBytes(3);
			if (signature != "FLV") throw new Error("Not a valid VIDEO FLV file.");
			var version:int = input.readByte();
			var infos:int = input.readByte();
			var typeFlagsReserved1:int = (infos >> 3);
			var typeFlagsAudio:int = ((infos & 0x4 ) >> 2);
			var typeFlagsReserved2:int = ((infos & 0x2 ) >> 1);
			var typeFlagsVideo:int = (infos & 0x1);
			var dataOffset:int = input.readUnsignedInt();
			var position:uint = input.position + 4;
			return position;
		}
		
		private static function clone(source:Object):*
		{
			var copier:ByteArray = new ByteArray();
			copier.writeObject(source);
			copier.position = 0;
			return(copier.readObject());
		}
		private static function getTime():String
		{
			var dateObj:Date = new Date();
			var year:String = dateObj.getFullYear().toString();
			var month:String = formatZero(dateObj.getMonth() + 1);
			var date:String = formatZero(dateObj.getDate());
			var hour:String = formatZero(dateObj.getHours());
			var minute:String = formatZero(dateObj.getMinutes());
			var second:String = formatZero(dateObj.getSeconds());
			var milisecond:String = dateObj.getMilliseconds().toString();
			
			return (year + "-" + month + "-" + date + " " + hour + ":" + minute + ":" + second + " " + milisecond);
		}
		private static function formatZero(num:Number):String
		{
			if (num < 10)
			{
				return "0" + num.toString();
			}
			
			return num.toString();
		}
	}
}