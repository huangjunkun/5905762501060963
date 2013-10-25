package com.global 
{
	import flash.display.Stage;
	/**
	 * ...
	 * @author zuffy
	 * 一个全局变量的保存类
	 */
	public class GlobalVars
	{
		private static var _instance:GlobalVars;
		public static function get instance():GlobalVars
		{
			if (!_instance)
			{
				_instance = new GlobalVars();
			}
			
			return _instance;
		}
		
		
		//================================================
		
		public var movieType:String = 'teleplay';	//影片信息
		
		public var windowMode:String = 'browser';	//窗口信息

		public var isStat:Boolean = true;	//0-不上报，1-只上报重要的，2-全部上报
		
		public var platform:String;
		public var isMacWebPage:Boolean = false;
		public var isZXThunder:Boolean = false;		
		
		//视频相关信息
		private var _videoRealSize:Object = { width:0, height:0 };
		private var _videoPlaySize:Object = { width:0, height:0 };
				
		//分享是否可点击
		public var enableShare:Boolean;
		
		//需要监控和分析的几个时间值
		public var loadTime:Object;
		public var getVodTime:int;
		//socket获取vod时上报 用gdl连接成功所用时间
		public var connectGldTime:int=0;
		public var vodAddr:String =  '';
		public var statCC:String = '';		
		//扣费相关
		public var preFeeTime:Number;			//前一个扣费点，单位毫秒
		public var nowFeeTime:Number;			//当前点，单位毫秒
		public var feeInterval:Number = 300000;	//扣费间隔，单位毫秒
		public var curFileInfo:Object;			//当前文件信息
		public var isExchangeError:Boolean;		//切换视频失败
		
		//影片清晰度
		public var movieFormat:String;
		
		//是否调节了默认清晰度
		public var defaultFormatChanged:Boolean;
		//是否调节了画面比例
		public var ratioChanged:Boolean;
		//是否调节了色彩
		public var colorChanged:Boolean;
		//是否调节了字幕
		public var captionStyleChanged:Boolean;
		//是否调节了时间轴
		public var captionTimeChanged:Boolean;
		
		//字幕列表是否已经加载完
		public var isCaptionListLoaded:Boolean;
		//字幕样式是否已经加载完
		public var isCaptionStyleLoaded:Boolean;
		//字幕时间调整信息是否已经加载完
		public var isCaptionTimeLoaded:Boolean;
		//是否存在自动的字幕
		public var isHasAutoloadCaption:Boolean;
		
		//i帧截图行列数，宽高
		public var iframeRow:uint = 10;
		public var iframeCol:uint = 10;
		public var iframeWidth:Number = 160;
		public var iframeHeight:Number = 90;
		public var isUseXlpanKanimg:Boolean = true;
		public var screenshot_size:String = '96';
		public var url_new_screen_shot:String = 'http://i{n}.xlpan.kanimg.com/pic/';
		
		//缓冲类型
		public var bufferType:int = 0;
		public var bufferTypeCustom:int = -2;
		public var bufferTypeFirstBuffer:int = -3;
		public var bufferTypeChangeFormat:int = -4;
		public var bufferTypeDrag:int = -5;
		public var bufferTypeKeyPress:int = -6;
		public var bufferTypePreview:int = -7;
		public var bufferTypeError:int = -8;
		
		//出现缓冲提示间隔，5分钟
		public var showLowSpeedTipsInterval:int = 300;
		//在5分钟内出现3次缓冲时，出现缓冲提示
		public var showBufferMax:int = 3;
		//出现缓冲的时间数组
		public var showLowSpeedTimeArray:Array = [];
		//是否点击不再提示
		public var isHideLowSpeedTips:Boolean;
		//是否已经显示网速较慢提示
		public var isHasShowLowSpeedTips:Boolean;
		//开始出现网速较慢提示的时间，2分钟
		public var startLowSpeedTipsTime:int = 0;
		//当前计时
		public var curLowSpeedTipsTime:int = 0;
		
		//出现有高清和超清提示的间隔，5分钟
		public var showHighSpeedTipsInterval:int = 300;
		//当前计时
		public var curHighSpeedTipsTime:int = 0;
		//以5分钟的平均速度值作为判断
		public var showHighSpeedTipsAverageSpeedInterval:int = 300;
		//网速达到此值时，出现有高清提示
		public var showGaoQingTipsSpeed:int = 300;
		//网速达到此值时，出现有超清提示
		public var showChaoQingTipsSpeed:int = 450;
		//是否点击不再提示
		public var isHideHighSpeedTips:Boolean;
		//是否已经显示网速较快提示
		public var isHasShowHighSpeedTips:Boolean;
		
		
		//是否有内嵌字幕
		public var hasSubtitle:Boolean;
		
		//是否使用多链
		public var isUseHttpSocket:Boolean = false;
		/**
		 * 机房配置
		 * 'p2p', 'multi':多链
		 */
		public var httpSocketMachines:Object = {};
		
		//是否已取得影片头
		public var isHeaderGetted:Boolean;
		//数据类型, type_metadata - 影片头, type_curstream - 当前切片, type_nextstream - 下一切片
		public var type_metadata:String = "type_metadata";
		public var type_curstream:String = "type_curstream";
		public var type_nextstream:String = "type_nextstream";
		
		//是否使用socket
		public var isUseSocket:Boolean = true;
		
		//不需要获取vod地址
		public var isIPLink:Boolean = false;
		
		//是否已经取得vod地址
		public var isVodGetted:Boolean;
		//vod地址
		public var vodURL:String;
		//点播地址
		public var vodURLList:Array = [];
		public var allURLList:Array = [];
		//正常缓冲后是否替换了地址
		public var isReplaceURL:Boolean;
		//是否改变了链接
		public var isChangeURL:Boolean;
		//是否开播缓冲302
		public var isFirstBuffer302:Boolean = true;
		//链路总数
		public var linkNum:int;
		
		//不同位置的支付
		public var paypos_tips:String = "1";					//底部提示条（试播）
		public var paypos_trying:String = "2";					//试播中弹框
		public var paypos_tryfinish:String = "3";				//试播完弹框
		public var paypos_trystop:String = "4";					//播完视频弹框
		public var paypos_tips_time:String = "5";				//底部提示条（时长卡）
		public var paypos_time:String = "6";					//时长卡
		public var referMaps:Object = { disanlan_btn: "XV_19",	//第三栏按钮
			disanlan_trylink: "XV_20",	//第三栏按钮右侧免费试播
			disanlan_tip: "XV_21",	//迅雷7最小化tips
			vodHome: "XV_22",	//首页试播
			vlist: "XV_23",	//列表无时长用户试播
			vodClientHome: "XV_24",	//独立播放器主页播放
			vodClientList: "XV_25",	//独立播放器列表播放
			vodClientPlayer: "XV_27",	//独立播放器播放页播放
			xl_scene: "XV_15",	//XL7客户端场景播放
			xl_lixian: "XV_26",	//离线按钮（快速播放）
			lxlua: "XV_26",	//离线lua页面
			bho_play: "XV_30",	//BHO助手
			kuaichuan_web: "XV_31",	//快传入口
			defaultReferer: "XV_26", //离线中间页或其他未定义的来源入口(包含了离线按钮，离线lua的试播和时长卡播放)
			macVodPage:"XV_36" // mac 客户端播放
		};	
		
		//来自网盘
		public var fromXLPan:String = "xlpan";
		public var ISERVER:String = "http://i.vod.xunlei.com/";
		public var url_buy_flow:String = "http://pay.vip.xunlei.com/vod.html?refresh=2";			//时长不足，开通会员入口
		public var url_buy_time:String = "http://pay.vip.xunlei.com/vodcard";						//时长卡
		public var url_free_flow:String = "http://act.vip.xunlei.com/vodfree/";						//免费获得流量
		public var url_deduct_flow:String = "http://i.vod.xunlei.com/flux_deduct/";					//流量扣费
		public var url_check_flow:String = "http://i.vod.xunlei.com/flux_query/";					//查询时长地址
		public var url_check_account:String = "http://i.vod.xunlei.com/check_user_info";			//校验用户
		public var url_screen_shot:String = "http://i.vod.xunlei.com/req_screenshot?jsonp=xxx";		//文件列表url缩略图
		public var bt_screen_shot:String = "http://i.vod.xunlei.com/req_screenshot?jsonp=xxx";		//文件列表bt缩略图
		public var url_login:String = "http://vod.xunlei.com/home.html#login=logout";				//登陆
		public var staticsUrl:String = "http://stat.vod.xunlei.com/stat/s.gif?";					//统计地址
		public var url_feedback:String = "http://i.vod.xunlei.com/feedback";						//反馈问题列表地址
		public var url_iframe:String = "http://i.vod.xunlei.com/req_screensnpt_url";				//查询i帧截图
		public var url_chome:String = "http://vod.xunlei.com/client/chome.html";					//客户端首页
		public var url_home:String = "http://vod.xunlei.com/home.html";								//首页
		public var url_search_subtitle:String = "http://www.shooter.cn/";							//字幕搜索
		public var url_subtitle_style:String = "http://i.vod.xunlei.com/subtitle/preference/font";	//字幕设置信息
		public var url_subtitle_content:String = "http://i.vod.xunlei.com/subtitle/content";		//获取字幕数据
		public var url_subtitle_list:String = "http://i.vod.xunlei.com/subtitle/list";				//获取所有字幕信息
		public var url_subtitle_autoload:String = "http://i.vod.xunlei.com/subtitle/autoload";		//自动加载字幕信息
		public var url_subtitle_time:String = "http://i.vod.xunlei.com/subtitle/preference/time";	//字幕时间轴调整信息
		public var url_subtitle_grade:String = "http://i.vod.xunlei.com/subtitle/grade";			//加载字幕观看满3分钟增加字幕分数
		public var url_subtitle_lastload:String = "http://i.vod.xunlei.com/subtitle/last_load"		//上次加载的字幕
		
		public function get videoRealSize():Object
		{
			return _videoRealSize;
		}
		
		public function set videoRealSize(sizeObj:Object):void
		{
			_videoRealSize.width = sizeObj.width;
			_videoRealSize.height = sizeObj.height;
		}
		
		public function get videoPlaySize():Object
		{
			return _videoPlaySize;
		}
		
		public function set videoPlaySize(sizeObj:Object):void
		{
			_videoPlaySize.width = sizeObj.width;
			_videoPlaySize.height = sizeObj.height;
		}
		
		
		// 判断XLNetStream功能是否可用。
		/**
		 * -1 : 未初始化.
		 *  0 : 调用失败.
		 *  1 : 调用成功.
		 *  2 : xlNetStream初始化成功.
		 */
		public var isXLNetStreamValid:int = -1;
		
		// 机房配置项;
		public var p2p_config_dl_link:String = '';
		public var p2p_config_fix_port:String = '';
		
		// 扣费用户
		public var feeUser:Boolean = false;

		public var isTryPayer:Boolean = false;
		

	}

}