package  {
	import com.adobe.crypto.MD5;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	/**
	 * ...
	 * @author Marcin Bugala
	 */
	public class Spritesheet {
		
		private var insertionTree:Array;
		private var insertedImagesMap:Array;
		private var framesDict:Dictionary;
		private var _hashing:Boolean = true;
		
		public function Spritesheet() {
			insertionTree = new Array();
			insertedImagesMap = new Array();
			framesDict = new Dictionary;
		}
		
		public function generate(frames:Vector.<SpritesheetPart>):Object {
			generateFramesHashes(frames)
			var size:Point =  findSize(frames);
			var scalars:Array = new Array();
			if (size.x <= size.y) {
				scalars.push(2, 1, 0.5, 2, 2, 1);
			}
			else {
				scalars.push(1, 2, 2, 0.5, 1, 2);
			}
			var sortedFrames:Vector.<SpritesheetPart> = frames.concat().sort(compareSizes);
			
			var spriteSheet:BitmapData = new BitmapData(size.x, size.y, true, 0);
			insertionTree.push(spriteSheet.rect);
			
			var anim:Vector.<Frame> = new Vector.<Frame>();
			
			var counter:int = 0;
			while (!tryToFit(spriteSheet, sortedFrames, anim)) {
				var newSpriteSheet:BitmapData;
				if (counter % 3 == 0) {
					newSpriteSheet = new BitmapData(scalars[0] * spriteSheet.width, scalars[1] * spriteSheet.height, true, 0);
				}
				else if (counter % 3 == 1) {
					newSpriteSheet = new BitmapData(scalars[2] * spriteSheet.width, scalars[3] *  spriteSheet.height, true, 0);
				}
				else {
					newSpriteSheet = new BitmapData(scalars[4] * spriteSheet.width, scalars[5] * spriteSheet.height, true, 0);
				}
				counter++;
				spriteSheet.dispose();
				spriteSheet = newSpriteSheet;
				insertionTree = new Array();
				insertionTree.push(spriteSheet.rect);
				for each (var k:Array in framesDict) {
					k.length = 0;
				}
				anim = new Vector.<Frame>();
				
				insertedImagesMap = new Array();
				
			}
			
			var resultRect:Rectangle = spriteSheet.getColorBoundsRect(0xFF000000, 0x00000000, false);
			var m:Matrix = new Matrix(1, 0, 0, 1, resultRect.x, resultRect.y);

			var newspritesheet:BitmapData = new BitmapData(getNextPowerOfTwo(resultRect.width), getNextPowerOfTwo(resultRect.height), true, 0);
			newspritesheet.draw(spriteSheet, m);
			
			spriteSheet = newspritesheet;
			
			return {"bitmapData": spriteSheet, "animation": anim};
		}
		
		private function tryToFit(spriteSheet:BitmapData, sortedFrames:Vector.<SpritesheetPart>, anim:Vector.<Frame>):Boolean 
		{
			for (var i:int = 0; i < sortedFrames.length; ++i) {
				var currentFrame:Object = sortedFrames[i];
				
				var f:Frame;
				if (_hashing && framesDict[currentFrame.hash].length > 0) {
					f = framesDict[currentFrame.hash][0];
					anim.push(new Frame(currentFrame.name, f.dimension, f.offset));
				} else {
					while (true) {
						var rect:Rectangle = currentFrame.bitmap.rect.clone();
						if (rect.width % 2 == 1) {
							rect.width += 3;
						}
						else {
							rect.width += 2;
						}
						if (rect.height % 2 == 1) {
							rect.width += 2;
						}
						else {
							rect.height += 2;
						}
						var point:Point = insert(rect);
						
						if (!point) {
							return false;
						}
						
						var frameRegion:Rectangle = new Rectangle(point.x, point.y, currentFrame.bitmap.width, currentFrame.bitmap.height);
						f = new Frame(currentFrame.name, frameRegion, currentFrame.offset);
						anim.push(f);
						if (_hashing) {
							framesDict[currentFrame.hash].push(f);
						}
						spriteSheet.copyPixels(currentFrame.bitmap, currentFrame.bitmap.rect, point);
						break;
					}
				}
			}
			
			return true;
			
			
		}		
		
		private function generateFramesHashes(frames:Vector.<SpritesheetPart>):void {
			var len:int = frames.length;
			var i:int;
			for (i = 0; i < len; ++i) {
				var frame:Object = frames[i];
				var frameRect:Rectangle = new Rectangle(0, 0, frame.bitmap.width, frame.bitmap.height);
				frame.hash = MD5.hashBytes(frame.bitmap.getPixels(frameRect));
			}
		}
		
		// algorithm implementation from website: http://www.blackpawn.com/texts/lightmaps/default.html
		private function insert(imgRect:Rectangle, index:int = 0):Point {
			var currentRect:Rectangle = insertionTree[index] as Rectangle;
			
			if (!currentRect) {
				var point:Point = insert(imgRect, insertionTree[index][0]);
				if (point)
					return point;
				
				return insert(imgRect, insertionTree[index][1]);
			} else {
				
				if (insertedImagesMap[index])
					return null;
				
				if (imgRect.width > currentRect.width || imgRect.height > currentRect.height)
					return null;
				
				if (imgRect.width == currentRect.width && imgRect.height == currentRect.height) {
					insertedImagesMap[index] = true;
					return new Point(currentRect.x, currentRect.y);
				}
				
				var dw:int = currentRect.width - imgRect.width;
				var dh:int = currentRect.height - imgRect.height;
				
				insertionTree[index] = new Array();
				insertionTree[index].push(insertionTree.length);
				insertionTree[index].push(insertionTree.length + 1);
				
				if (dw > dh) {
					insertionTree.push(new Rectangle(currentRect.x, currentRect.y, imgRect.width, currentRect.height));
					insertionTree.push(new Rectangle(currentRect.x + imgRect.width, currentRect.y, dw, currentRect.height));
				} else {
					insertionTree.push(new Rectangle(currentRect.x, currentRect.y, currentRect.width, imgRect.height));
					insertionTree.push(new Rectangle(currentRect.x, currentRect.y + imgRect.height, currentRect.width, dh));
				}
				
				return insert(imgRect, insertionTree.length - 2);
			}
		}
		
		private function findSize(frames:Vector.<SpritesheetPart>):Point {
			var maxWidth:Number = 0;
			var maxHeight:Number = 0;
			var spriteWidth:Number = 0;
			var spriteHeight:Number = 0;
			var allWidth:Number = 0;
			
			var len:int = frames.length;
			var i:int;
			var allHeight:int = 0;
			var amountOfTextures:int = 0;
			var allArea:int = 0;
			maxHeight = 0;
			maxWidth = 0;
			allWidth = 0;
			
			for (i = 0; i < len; ++i) {
				
				if (!framesDict[frames[i].hash] || !_hashing) {
					allWidth += frames[i].bitmap.width;
					allHeight += frames[i].bitmap.height;
					allArea += frames[i].bitmap.width * frames[i].bitmap.height;
					++amountOfTextures;
					
					if (_hashing) {
						framesDict[frames[i].hash] = new Array();
					}
				}
				
				if (frames[i].bitmap.width > maxWidth)
					maxWidth = frames[i].bitmap.width;
				
				if (frames[i].bitmap.height > maxHeight)
					maxHeight = frames[i].bitmap.height;
			}
			
			var amountSqrt:Number = Math.sqrt(amountOfTextures);
			
			spriteWidth = getNearestPowerOfTwo(allWidth / amountOfTextures * amountSqrt);
			spriteHeight = getNearestPowerOfTwo(allHeight / amountOfTextures * amountSqrt);
			var widthInd:int = Math.floor(log2(spriteWidth));
			var heightInd:int = Math.floor(log2(spriteHeight));
			var indexDiff:int = widthInd - heightInd;
			var changeBy:int
			if (indexDiff >= 2) {
				changeBy = Math.floor(indexDiff / 2);
				spriteWidth = Math.pow(2, widthInd - changeBy + 1);
				spriteHeight = Math.pow(2, heightInd + changeBy + 1);
			} else if (indexDiff <= -2) {
				changeBy = Math.floor((-indexDiff) / 2);
				spriteWidth = Math.pow(2, widthInd + changeBy + 1);
				spriteHeight = Math.pow(2, heightInd - changeBy + 1);
			}
			
			var extendWidth:Boolean = spriteWidth <= spriteHeight;
			
			if (allArea > spriteWidth * spriteHeight) {
				if (extendWidth) {
					spriteWidth = getNextPowerOfTwo(spriteWidth + 1);
				} else {
					spriteHeight = getNextPowerOfTwo(spriteHeight + 1);
				}
			}
			
			return new Point(spriteWidth, spriteHeight);
		}
		
		private function getNearestPowerOfTwo(value:Number):Number {
			return Math.pow(2, Math.round(log2(value)));
		}
		
		private function getNextPowerOfTwo(value:Number):Number {
			return Math.pow(2, Math.ceil(log2(value)));
		}
		
		private function log2(value:Number):Number {
			return Math.log(value) / Math.log(2);
		}
		
		private function compareSizes(lhs:Object, rhs:Object):Number {
			return rhs.bitmap.height - lhs.bitmap.height;
		}
		
		private function extendSheet(spriteSheet:BitmapData):BitmapData {
			var extendTo:int;
			var extendedFrom:int;
			var tmp:BitmapData;
			if (spriteSheet.width <= spriteSheet.height) {
				extendedFrom = spriteSheet.width;
				extendTo = getNextPowerOfTwo(extendedFrom + 1);
				tmp = new BitmapData(extendTo, spriteSheet.height, true, 0);
			} else {
				extendedFrom = spriteSheet.height;
				extendTo = getNextPowerOfTwo(extendedFrom + 1);
				tmp = new BitmapData(spriteSheet.width, extendTo, true, 0);
			}
			tmp.copyPixels(spriteSheet, spriteSheet.rect, spriteSheet.rect.topLeft);
			spriteSheet.dispose();
			spriteSheet = tmp;
			
			updateInsertionArray(spriteSheet, extendedFrom);
			
			return spriteSheet;
		}
		
		private function updateInsertionArray(spriteSheet:BitmapData, extendedFrom:int):void {
			var len:int = insertionTree.length;
			var i:int;
			
			for (i = 0; i < len; ++i) {
				var rect:Rectangle = insertionTree[i] as Rectangle;
				if (rect) {
					if (spriteSheet.width <= spriteSheet.height && rect.right == extendedFrom) {
						if (insertedImagesMap[i]) {
							insertionTree[i] = new Array();
							insertionTree[i].push(len, len + 1);
							insertedImagesMap[len] = true;
							insertionTree.push(rect);
							insertionTree.push(new Rectangle(rect.right, rect.top, spriteSheet.width - extendedFrom, rect.height));
						} else {
							rect.right = spriteSheet.width;
						}
					} else if (spriteSheet.width >= spriteSheet.height && rect.bottom == extendedFrom) {
						if (insertedImagesMap[i]) {
							insertionTree[i] = new Array();
							insertionTree[i].push(len, len + 1);
							insertedImagesMap[len] = true;
							insertionTree.push(rect);
							insertionTree.push(new Rectangle(rect.left, rect.bottom, rect.width, spriteSheet.height - extendedFrom));
						} else {
							rect.bottom = spriteSheet.height;
						}
					}
				}
			}
		}
	}

}