package {
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.desktop.NativeApplication;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	
	/**
	 * ...
	 * @author Marcin Bugala
	 */
	public class Main extends Sprite {
		[Embed(source="../bin/female.swf")]
		private var female:Class;
		
		private var _movieClip:MovieClip;
		private var _sqlConnection:SQLConnection;
		
		public function Main():void {
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.DEACTIVATE, deactivate);
			
			// touch or gesture?
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			
			// entry point
			addAsset(new female());
		}
		
		private function addAsset(asset:Object):void {
			var loader:Loader = Loader((asset as DisplayObjectContainer).getChildAt(0));
			var info:LoaderInfo = loader.contentLoaderInfo;
			info.addEventListener(Event.COMPLETE, onComplete);
		}
		
		private function onComplete(e:Event):void {
			var info:LoaderInfo = LoaderInfo(e.target);
			info.removeEventListener(Event.COMPLETE, onComplete);
			_movieClip = info.loader.content as MovieClip;
			
			initDb();
		}
		
		private function initDb():void {
			_sqlConnection = new SQLConnection();
			var dbFile:File = File.applicationDirectory.resolvePath("content.s3db");
			_sqlConnection.open(dbFile);
			
			var sqlStatement:SQLStatement = new SQLStatement();
			sqlStatement.sqlConnection = _sqlConnection;
			
			sqlStatement.text = "SELECT Animation FROM PrepperAnimation";
			sqlStatement.addEventListener(SQLEvent.RESULT, onAnimationsLoaded);
			sqlStatement.execute();
		}
		
		private function onAnimationsLoaded(e:SQLEvent):void {
			var stm:SQLStatement = e.target as SQLStatement;
			var result:SQLResult = stm.getResult();
			
			var numRows:int = result.data.length;
			for (var i:int = 0; i < numRows; i++) {
				var row:Object = result.data[i];
				
				var mc:DisplayObject = _movieClip.getChildByName(row.Animation);
				if (mc != null) {		
					var gmc:GPUMovieClipBase = new GPUMovieClipBase();
					gmc.fromContainer(mc as DisplayObjectContainer);
					gmc.createGPUData(null);//*/			  
				   var xml:XML = <movieclip />
				    var fileName:String = row.Animation;
				   gmc.dumpLikeABoss(xml, fileName + ".png");
				
				  
				   var xmlFile:File = File.applicationStorageDirectory.resolvePath(fileName + ".xml");
				   
				   var xmlStream:FileStream = new FileStream();
				   xmlStream.open(xmlFile, FileMode.WRITE);
				   xmlStream.writeUTFBytes(xml);
				   xmlStream.close();				
				}
			}
		}
		
		private function deactivate(e:Event):void {
			// auto-close
			NativeApplication.nativeApplication.exit();
		}
	
	}

}