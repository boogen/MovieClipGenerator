package {
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;
	
	/**
	 * ...
	 * @author
	 */
	public class GPUTextureAtlasManager {
		private static var width:int = 1024;
		private static var height:int = 1024;
		private static var padding:int = 3;
		
		public static var nodeByBitmapData:Dictionary = new Dictionary(true);
		private static var nodeByPixels:Dictionary = new Dictionary();
		private static var uvByBitmapData:Dictionary = new Dictionary(true);
		
		private static var atlases:Vector.<GPUTextureAtlas> = new Vector.<GPUTextureAtlas>();
		private static var textures:Vector.<Texture> = new Vector.<Texture>();
		
		private static var ctx:Context3D;
		
		private static var queue:Vector.<BitmapData> = new Vector.<BitmapData>();
		private static var outdatedAtlases:Dictionary = new Dictionary(true);
		private static var startedJobs:uint;
		
		private static var bitmapBuffer:BitmapData;
		
		public static function init(context:Context3D):void {
			ctx = context;
			bitmapBuffer = new BitmapData(width, height, true, 0x00000000);
		}
		
		public static function beginAdding():void {
			startedJobs++;
		}
		
		public static function add(bd:BitmapData):void {
			queue.push(bd);
		}
		
		private static function compareBitmap(a:BitmapData, b:BitmapData):int {
			return b.height - a.height;
		}
		
		private static function getPixelsHash(bitmapData:BitmapData, x:int, y:int, w:int, h:int):uint {
			var hash:uint = 5381;
			for (var j:int = y; j < y + h; ++j) {
				for (var i:int = x; i < x + w; ++i) {
					var p:uint = bitmapData.getPixel32(i, j);
					hash = ((hash << 5) + hash) + (p & 0x00FF0000);
					hash = ((hash << 5) + hash) + (p & 0x0000FF00);
					hash = ((hash << 5) + hash) + (p & 0x000000FF);
					hash = ((hash << 5) + hash) + (p & 0xFF000000);
				}
			}
			return hash;
		}
		
		public static function endAdding():void {
			return
			startedJobs--;
			if (startedJobs == 0) {
				queue.sort(compareBitmap);
				while (queue.length) {
					var bd:BitmapData = queue.shift();
					var hash:uint = getPixelsHash(bd, 0, 0, bd.width, bd.height);
					var node:GPUTextureAtlas = nodeByPixels[hash];
					if (!node) {
						for (var i:int = 0; i < atlases.length; ++i) {
							if ((node = atlases[i].add(bd, padding))) {
								outdatedAtlases[atlases[i]] = atlases[i];
								break;
							}
						}
						if (!node) {
							var newAtlas:GPUTextureAtlas = createNewAtlas();
							node = newAtlas.add(bd, padding);
							outdatedAtlases[newAtlas] = newAtlas;
						}
						if (!node) {
							throw "Cannot add bitmap (" + bd.width + ", " + bd.height + ").";
						}
						nodeByPixels[hash] = node;
					}
					nodeByBitmapData[bd] = node;
				}
				
				for (var key:Object in outdatedAtlases) {
					uploadAtlasTexture(outdatedAtlases[key]);
					delete outdatedAtlases[key];
				}
				
			}
		
		}

		
		public static function createNewAtlas():GPUTextureAtlas {
			var atlas:GPUTextureAtlas = new GPUTextureAtlas(0, 0, width, height, atlases.length);
			atlases.push(atlas);
			
			/*
			   Main.instance.addChild(atlas);
			   atlas.x = Main.instance.lastX;
			   Main.instance.lastX += width;
			 //*/
			
			var texture:Texture = ctx.createTexture(width, height, Context3DTextureFormat.BGRA, false);
			textures.push(texture);
			return atlas;
		}
		
		public static function uploadAtlasTexture(atlas:GPUTextureAtlas):void {
			bitmapBuffer.fillRect(bitmapBuffer.rect, 0x00000000);
			bitmapBuffer.draw(atlas);
			textures[atlas.rootId].uploadFromBitmapData(bitmapBuffer);
		}
		
		public static function getNodeUV(bd:BitmapData):ByteArray {
			if (!uvByBitmapData[bd]) {
				var node:GPUTextureAtlas = nodeByBitmapData[bd];
				var rect:Rectangle = node.bitmap.getBounds(atlases[node.rootId]);
				var uv:ByteArray = new ByteArray();
				uv.endian = Endian.LITTLE_ENDIAN;
				
				uv.writeFloat((rect.x + 0.5) / width);
				uv.writeFloat((rect.y + 0.5) / height);
				uv.writeFloat(rect.width / width);
				uv.writeFloat(rect.height / height);
				uvByBitmapData[bd] = uv;
			}
			return uvByBitmapData[bd];
		}
		
		private static var _textures:Dictionary = new Dictionary();
		
		public static function getNodeTexture(bd:BitmapData):Texture {
			if (!_textures[bd]) {
				_textures[bd] = ctx.createTexture(bd.width, bd.height, Context3DTextureFormat.BGRA, false);
				_textures[bd].uploadFromBitmapData(bd);		
			}
			return _textures[bd];
			var node:GPUTextureAtlas = nodeByBitmapData[bd];
			return textures[node.rootId];
		}
	}

}