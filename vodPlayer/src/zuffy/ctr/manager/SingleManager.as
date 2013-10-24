package zuffy.display {
	public class SingleManager {
		
		private static var _instance: SingleManager;

		public static function get instance(): SingleManager {
			
			if (!_instance) {
				_instance = new SingleManager (new __inner__());
			}
			
			return _instance;
		}

		public function SingleManager(__:__inner__) {
			init();
		}

		protected function init():void {

		}
		
	}	
}

class __inner__ {
	public function __inner__(){}
}