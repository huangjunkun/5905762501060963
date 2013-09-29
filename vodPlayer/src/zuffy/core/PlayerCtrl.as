package zuffy.core
{
	import com.global.GlobalVars;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.system.Security;
	
	import zuffy.ctr.contextMenu.*;
	
	public class PlayerCtrl extends Sprite
	{
		protected var _params:Object;
		protected var _movieType:String;
		
		public function PlayerCtrl()
		{
			Security.allowDomain("*");
			
			if(stage){
				init();
			}else{
				//侦听该类是否被添加到了舞台显示列表
				addEventListener(Event.ADDED_TO_STAGE, init);
			}
		}
		
		private function init():void{
			// 右键菜单
			CreateContextMenu.createMenu(this);
			CreateContextMenu.addItem('播放特权播放器：2.9.20130513', false, false, null);
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.tabChildren = false;
			
			_params = stage.loaderInfo.parameters;
			
			initializePlayCtrl();			
		}
		
		private function initializePlayCtrl():void 
		{
			stage.addEventListener(Event.RESIZE, on_stage_RESIZE);
			
			
			
			
			var _w:int = int(_params["width"]) ? int(_params["width"]) : stage.stageWidth;
			var _h:int = int(_params["height"]) ? int(_params["height"]) : stage.stageHeight;
			var _has_fullscreen:int = int(_params["fullscreenbtn"]) || 1;
			
			GlobalVars.instance.movieType = _movieType;
			GlobalVars.instance.windowMode = _params['windowMode'] || 'browser';
			GlobalVars.instance.platform = _params['platform'] || 'webpage';
			GlobalVars.instance.isMacWebPage = ((typeof _params['isMacWebPage'] != "undefined") && _params['isMacWebPage'] != 'false');
			GlobalVars.instance.isZXThunder = int(_params["isZXThunder"]) == 1;
			GlobalVars.instance.isStat = _params['defStatLevel'] == 2 ? true : false;	//0-不上报，1-只上报重要的，2-全部上报
		}
		protected function on_stage_RESIZE(e:Event):void{
			
			var _w:int = int(_params["width"]) ? int(_params["width"]) : stage.stageWidth;
			var _h:int = int(_params["height"]) ? int(_params["height"]) : stage.stageHeight;
			var _has_fullscreen:int = int(_params["fullscreenbtn"]) || 1;
			
		}
		
	}
}