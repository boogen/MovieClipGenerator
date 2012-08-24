package {
	import com.adobe.images.PNGEncoder;
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
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
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
			var animationsMap:Dictionary = new Dictionary();
			var category:String;
			for (var i:int = 0; i < numRows; i++) {
				var row:Object = result.data[i];
				var name:String = row.Animation as String;
				
				var parts:Array = name.split("_");
				category = parts[0] + "_" + parts[1] + "_" + parts[3];
				if (!animationsMap[category]) {
					animationsMap[category] = new Vector.<String>();
				}
				
				animationsMap[category].push(name);
			}
			
			var i:int = 0;
			for (var k:Object in animationsMap) {
				category = k as String;
				
				var animations:Vector.<String> = animationsMap[category];
				var assets:Vector.<SpritesheetPart> = new Vector.<SpritesheetPart>();
				
				var r:Object = _movieClip.root;
				var xml:XML = <movieclip />
				for (i = 0; i < animations.length; ++i) {
					var mc:DisplayObject = _movieClip.getChildByName(animations[i]);
					if (mc != null) {		
						var gmc:GPUMovieClipBase = new GPUMovieClipBase();
						gmc.fromContainer(mc as DisplayObjectContainer);
						gmc.createGPUData(null);		  						
						gmc.flatten(assets);
						
						var animationXML:XML = <animation />
						animationXML.@name = animations[i];
						gmc.writeMovieClip(animationXML);
						xml.appendChild(animationXML);

					}
				}
				
				var spritesheet:Spritesheet =  new Spritesheet();
				var png:Object = spritesheet.generate(assets);				

				var bArray:ByteArray = PNGEncoder.encode(png.bitmapData);
			
				var file:File = File.applicationStorageDirectory.resolvePath(category + ".png");
				var fileStream:FileStream = new FileStream();
				fileStream.open(file, FileMode.WRITE);
				fileStream.writeBytes(bArray);
				fileStream.close();

				var spritesheetXML:XML = serializeAnimation(png.animation);
				xml.appendChild(spritesheetXML);
				
				var ba:ByteArray = new ByteArray();
				ba.writeObject(xml);
				ba.compress();
				var xmlFile:File = File.applicationStorageDirectory.resolvePath(category + ".cxml");			   				
				var xmlStream:FileStream = new FileStream();
				xmlStream.open(xmlFile, FileMode.WRITE);				
				xmlStream.writeBytes(ba);
				xmlStream.close();
				/*
				var xml:XML = <movieclip />
				var fileName:String = row.Animation;
				gmc.dumpLikeABoss(xml, fileName + ".png");
			
				var ba:ByteArray = new ByteArray();
				ba.writeObject(xml);
				ba.compress();
			  
				var xmlFile:File = File.applicationStorageDirectory.resolvePath(fileName + ".zip");
			   
				var xmlStream:FileStream = new FileStream();
				xmlStream.open(xmlFile, FileMode.WRITE);
				xmlStream.writeBytes(ba);
				xmlStream.close();	
				//*/
				break
			}

		}
		
		private function writeXML(xml:XML, filename:String):void 
		{
				var ba:ByteArray = new ByteArray();
				ba.writeObject(xml);
				ba.compress();
				var xmlFile:File = File.applicationStorageDirectory.resolvePath(filename + ".cxml");
			   
				var xmlStream:FileStream = new FileStream();
				xmlStream.open(xmlFile, FileMode.WRITE);
				xmlStream.writeBytes(ba);
				xmlStream.close();				
		}
		
		private function serializeAnimation(anim:Vector.<Frame>):XML {
			var xml:String = "<spritesheet>";
			for (var i:int = 0; i < anim.length; ++i) {
				var f:Frame = anim[i];
				xml += "<sprite name=\"" + f.name + "\">";
				xml += "<dimension x=\"" + f.dimension.x + "\" y=\"" + f.dimension.y + "\" width=\"" + f.dimension.width + "\" height=\"" + f.dimension.height + "\"></dimension>";
				xml += "</sprite>";
				
			}
			xml += "</spritesheet>";
			
			return new XML(xml);
		}			
		
		private function deactivate(e:Event):void {
			// auto-close
			NativeApplication.nativeApplication.exit();
		}
	
	}

}