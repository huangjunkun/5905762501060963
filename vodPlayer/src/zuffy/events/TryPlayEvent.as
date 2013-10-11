package zuffy.events
{
	import flash.events.Event;
	/**
	 * ...
	 * @author hwh
	 */
	public class TryPlayEvent extends Event
	{
		public static const BuyVIP:String = "buy_vip";				//购买白金会员
		public static const UpdateVIP:String = "update_vip";		//升级白金会员
		public static const GoHome:String = "go_home";				//打开首页
		public static const Resume:String = "resume";				//恢复试播
		public static const ViewList:String = "view_list";			//查看列表
		public static const HidePanel:String = "hide_panel";		//隐藏试播弹框
		public static const ShowViewList:String = "show_view_list";	//显示查看列表弹框
		public static const Login:String = "login";					//登陆
		public static const GetBytes:String = "get_bytes";			//获取免费流量
		public static const DontNoticeBytes:String = "dont_notice_bytes";//不再提示流量
		public static const BuyTime:String = "buy_time";			//购买时长
		public static const TRY_PLAY_ENDED_ADDBYTE:String = "try_play_ended_addbyte";// 试播结束
		public static const FEE_SUCCESS:String = "flux_deduct_callback";	//流量扣费返回事件
		private var _info:Object;
		
		public function TryPlayEvent(type:String, info:Object = null) 
		{
			super(type, true);
			_info = info;
		}
		
		public function get info():Object
		{
			return _info;
		}
	}
}