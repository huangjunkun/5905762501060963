package zuffy.ctr.manager {
	public class SingleManager {
		
		private static var _instance: SingleManager;

		public static function get instance(): SingleManager {
			
			if (!_instance) {
				_instance = new SingleManager ();
			}
			
			return _instance;
		}

		public function SingleManager() {
			init();
		}

		protected function init():void {

		}
		
	}	
}