package {
	import com.adobe.images.PNGEncoder;
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.desktop.NativeApplication;
	import flash.display.BitmapData;
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
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
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
		
		[Embed(source="../bin/male.swf")]
		private var male:Class;		
		
		[Embed(source="../bin/celebritie_011_martha_stuart.swf")]
		private var martha_stuart:Class;
		
		[Embed(source="../bin/courier1_walk.swf")]
		private var courier1_walk:Class;
		
		[Embed(source="../bin/courier1_idle1.swf")]
		private var courier1_idle:Class;		
		
		[Embed(source="../bin/courier2_walk.swf")]
		private var courier2_walk:Class;
		
		[Embed(source="../bin/courier2_idle1.swf")]
		private var courier2_idle:Class;		
		
		[Embed(source="../bin/courier3_walk.swf")]
		private var courier3_walk:Class;
		
		[Embed(source="../bin/courier3_idle1.swf")]
		private var courier3_idle:Class;
		
		[Embed(source="../bin/courier4_walk.swf")]
		private var courier4_walk:Class;
		
		[Embed(source="../bin/courier4_idle1.swf")]
		private var courier4_idle:Class;		
		
					
		
		[Embed(source="../bin/prepper_JunkMan_07.swf")]
		private var prepper07:Class;					
		
		[Embed(source="../bin/prepper_bartender_017.swf")]
		private var prepper017:Class;					
		
		[Embed(source="../bin/prepper_chef_016.swf")]
		private var prepper016:Class;
		[Embed(source="../bin/prepper_countrysinger_021.swf")]
		private var prepper021:Class;
		[Embed(source="../bin/prepper_diseasecontrolexpert_022.swf")]
		private var prepper022:Class;		
		[Embed(source="../bin/prepper_doctor_015.swf")]
		private var prepper015:Class;

		[Embed(source="../bin/prepper_mechanicalengineer_018.swf")]
		private var prepper018:Class;
		[Embed(source="../bin/prepper_metalworker_020.swf")]
		private var prepper020:Class;
		[Embed(source="../bin/prepper_militarytrainer_019.swf")]
		private var prepper019:Class;		
		
		[Embed(source="../bin/prepper_Botanist_03.swf")]
		private var prepper03:Class;			
		[Embed(source="../bin/prepper_Meteorologist_10.swf")]
		private var prepper010:Class;			
		[Embed(source="../bin/prepper_TechGeek_06.swf")]
		private var prepper06:Class;			
		[Embed(source="../bin/prepper_Plumber_09.swf")]
		private var prepper09:Class;			
		[Embed(source="../bin/prepper_Carpenter_04.swf")]
		private var prepper04:Class;			
		[Embed(source="../bin/prepper_DogTrainer_11.swf")]
		private var prepper011:Class;
		[Embed(source="../bin/prepper_Farmer_02.swf")]
		private var prepper02:Class;		
		[Embed(source="../bin/prepper_Hunter_08.swf")]
		private var prepper08:Class;		
		[Embed(source="../bin/prepper_SportsCoach_12.swf")]
		private var prepper012:Class;		
		[Embed(source="../bin/prepper_Survivor_01.swf")]
		private var prepper01:Class;		
		[Embed(source="../bin/prepper_WeaponsExpert_05.swf")]
		private var prepper05:Class;		
		
		private var _movieClip:MovieClip;
		private var _sqlConnection:SQLConnection;
		private var _assets:Vector.<MovieClip> = new Vector.<MovieClip>();
		
		public function Main():void {
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.addEventListener(Event.DEACTIVATE, deactivate);
			
			// touch or gesture?
			Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
			
			// entry point
			addAsset(new male());
		}
		
		var counter:int = 0;
		
		private function addAsset(asset:Object):void {
			var loader:Loader = Loader((asset as DisplayObjectContainer).getChildAt(0));
			var info:LoaderInfo = loader.contentLoaderInfo;
			counter++;
			info.addEventListener(Event.COMPLETE, onComplete);
		}
		
		private function onComplete(e:Event):void {
			var info:LoaderInfo = LoaderInfo(e.target);
			info.removeEventListener(Event.COMPLETE, onComplete);
			_movieClip = info.loader.content as MovieClip;
			
			_assets.push(_movieClip);
			initDb();
		//	singleAsset("prepper", "_005");
		/*	counter--;
			
			if (counter == 0) {
				couriers("courier1");
			}*/
		}
		
		private function initDb():void {
			_sqlConnection = new SQLConnection();
			var dbFile:File = File.applicationDirectory.resolvePath("content.s3db");
			_sqlConnection.open(dbFile);
			
			var sqlStatement:SQLStatement = new SQLStatement();
			sqlStatement.sqlConnection = _sqlConnection;
			
			sqlStatement.text = "SELECT Animation FROM PrepperAnimation WHERE Sex = 1";
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
				
				if (name.indexOf("jump") == -1) {
					animationsMap[category].push(name);
				}
			}
			
			generateAnimations(animationsMap);
		}
		
		
		private function singleAsset(name:String, category:String):void 
		{
			var anims:Array = ["_walk", "_idle1", "_idle2", "_jump", "_wave"];
			
			var animationsMap:Dictionary = new Dictionary();
			animationsMap[name + category] = new Vector.<String>
			for (var i:int = 0; i < anims.length; ++i) {
				animationsMap[name + category].push(name + anims[i] + category);
			}
			
			generateAnimations(animationsMap);
		}
		
		private function couriers(name:String):void {
			var anims:Array = ["_walk", "_idle1"];
			
			var animationsMap:Dictionary = new Dictionary();
			animationsMap[name] = new Vector.<String>
			for (var i:int = 0; i < anims.length; ++i) {
				animationsMap[name].push(name + anims[i]);
			}
			
			generateAnimations(animationsMap);			
		}
		
		
		private function generateAvatar(name:String):void 
		{
			var mc:DisplayObject = _movieClip.getChildByName(name);
			
			if (!mc) {
				return;
			}
			var bounds:Rectangle = mc.getBounds(mc);
			var bmp:BitmapData = new BitmapData(bounds.width + 1, bounds.height + 1, true, 0x00000000);
			bmp.draw(mc, new Matrix(1, 0, 0, 1, -1 * bounds.left, -1 * bounds.top));		
			
			var bArray:ByteArray = PNGEncoder.encode(bmp);
			
			var parts:Array = name.split("_");
			
			var file:File = File.applicationStorageDirectory.resolvePath([parts[0], parts[1], parts[3],"avatar.png"].join("_"));
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeBytes(bArray);
			fileStream.close();			
		}
		
		private function generateAnimations(animationsMap:Dictionary):void 
		{	
			var category:String;
			var i:int = 0;
			for (var k:Object in animationsMap) {
				category = k as String;
				
				generateAvatar(animationsMap[category][1]);
				
				var animations:Vector.<String> = animationsMap[category];
				var assets:Vector.<SpritesheetPart> = new Vector.<SpritesheetPart>();
				
				var r:Object = _movieClip.root;
				var xml:XML = <movieclip />
				for (i = 0; i < animations.length; ++i) {
					var mc:DisplayObject = _movieClip.getChildByName(animations[i]);					
					if (!mc) {
						for (var z:int = 0; z < _assets.length; ++z) {
							mc = _assets[z].getChildByName(animations[i]);
							if (mc) {
								break;
							}
						} 
					}
					if (mc != null) {		
						var gmc:GPUMovieClipBase = new GPUMovieClipBase();
						gmc.fromContainer(mc as DisplayObjectContainer);
						gmc.createGPUData(null);	
						gmc.mergeDressed("leftarm");
						gmc.mergeDressed("rightarm");
						gmc.mergeDressed("chest");
						gmc.mergeDressed("leftleg");
						gmc.mergeDressed("rightleg");
						gmc.mergeHeadShadow();
						gmc.mergeFaceInHead();
						gmc.flatten(assets);
						
						var animationXML:XML = <animation />
						animationXML.@name = animations[i];
						gmc.writeMovieClip(animationXML);
						xml.appendChild(animationXML);
					}
				}
				
				if (!assets.length) {
					continue;
				}
				
				var spritesheet:Spritesheet =  new Spritesheet();
				var png:Object = spritesheet.generate(assets);		
				if (!png) {
					continue;
				}

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
				var xmlFile:File = File.applicationStorageDirectory.resolvePath(category + ".xml");			   				
				var xmlStream:FileStream = new FileStream();
				xmlStream.open(xmlFile, FileMode.WRITE);				
				xmlStream.writeUTFBytes(spritesheetXML);
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
				xml += "<offset x=\"" + f.offset.x + "\" y=\"" + f.offset.y + "\"></offset>";
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