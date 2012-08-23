package  {
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * ...
	 * @author Marcin Bugala
	 */
	public class Frame {
		public var dimension:Rectangle;
		public var offset:Point;
		public var name:String;
		
		public function Frame(n:String, d:Rectangle, o:Point) {
			name = n;
			dimension = d;
			offset = o;
		}
	
	}

}