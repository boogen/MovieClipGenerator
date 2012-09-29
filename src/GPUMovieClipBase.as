package {
	import com.adobe.images.PNGEncoder;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display3D.Context3D;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.display3D.VertexBuffer3D;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import adobe.utils.CustomActions;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display3D.Context3D;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.textures.Texture;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DTextureFormat;
	import flash.utils.Endian;
	import flash.utils.getQualifiedClassName;
	import flash.utils.SetIntervalTimer;
	
	/**
	 * ...
	 * @author mosowski
	 */
	public class GPUMovieClipBase {
		
		public var bmp:BitmapData;
		public var children:Dictionary = new Dictionary();
		public var tracks:Dictionary = new Dictionary();
		public var framesChildren:Vector.<Vector.<GPUMovieClipBase>> = new Vector.<Vector.<GPUMovieClipBase>>();
		
		public var name:String;
		public var parent:GPUMovieClipBase;
		public var currentMatrix:Matrix = new Matrix();
		public var currentFrame:int = 0;
		
		private var matrixData:ByteArray;
		public var bitmapScaleX:Number = 1.0;
		public var bitmapScaleY:Number = 1.0;
		
		public var track:GPUMovieClipAnimationTrack;
		
		public var totalFrames:int;
		public var numChildren:int;
		
		public var uvs:ByteArray;
		
		public static var fuckthisshit:Dictionary = new Dictionary();
		private var offset:Point = new Point();
		private var bounds:Rectangle;
		private var concatenatedMatrix:Matrix;
		
		public function GPUMovieClipBase() {
		}
		
		private function nearUpPowOf2(n:uint):uint {
			n--;
			n |= n >> 1;
			n |= n >> 2;
			n |= n >> 4;
			n |= n >> 8;
			n |= n >> 16;
			n++;
			return n;
		}
		
		public function getBitmapFromDisplayObject(obj:DisplayObject):void {
			if (bmp) {
				bmp.dispose();
			}
			
			var container:DisplayObjectContainer = obj as DisplayObjectContainer;
			if (container) {
				var visibility:Vector.<Boolean> = new Vector.<Boolean>();
				for (var j:int = 0; j < container.numChildren; ++j) {
					visibility.push(container.getChildAt(j).visible);
					container.getChildAt(j).visible = false;
				}
			}
			
			bounds = obj.getBounds(obj);
			if (obj.parent.name.indexOf("head") >= 0) {
				trace(obj.parent.name);
				var b:Rectangle = obj.getBounds(obj.stage);
			}
			bmp = new BitmapData(bounds.width + 1, bounds.height + 1, true, 0x00000000);						
			var colorTransform:ColorTransform = new ColorTransform();
			var p:DisplayObject = obj;
			while (p) {
				colorTransform.concat(p.transform.colorTransform);
				p = p.parent;
			}
			
			bmp.draw(obj, new Matrix(1, 0, 0, 1, -bounds.left, -bounds.top), colorTransform);			
			
			offset.x = bounds.left;
			offset.y = bounds.top;
			
			var empty:Boolean = true;
			for (var i:int = 0; i < bmp.width; ++i) {
				for (j = 0; j < bmp.height; ++j) {
					if (bmp.getPixel32(i, j) != 0) {
						empty = false;
						break;
					}
				}
			}
			if (empty) {
				bmp.dispose();
				bmp = null;
			}
			
			if (bmp) {
				bitmapScaleX = bmp.width;
				bitmapScaleY = bmp.height;
			}
			
			if (container) {
				for (j = 0; j < container.numChildren; ++j) {
					container.getChildAt(j).visible = visibility.shift();
				}
			}
		}
		
		private function get currentChildren():Vector.<GPUMovieClipBase> {
			return currentFrame < framesChildren.length ? framesChildren[currentFrame] : noChildren;
		}
		
		private function processDisplayObject(d:DisplayObject):GPUMovieClipBase {
			if (d is DisplayObjectContainer) {
				var gpuMc:GPUMovieClipBase = new GPUMovieClipBase();
				gpuMc.fromContainer(d as DisplayObjectContainer);
				return gpuMc;
			} else {
				gpuMc = new GPUMovieClipBase();
				gpuMc.getBitmapFromDisplayObject(d);
				return gpuMc;
			}
		}
		
		private function processChild(parentname:String, index:int, child:DisplayObject, frame:int):GPUMovieClipBase {
			var name:String = child.name;
			if (name.indexOf("instance") >= 0) {
				if (fuckthisshit[parentname]) {
					parentname = fuckthisshit[parentname]
				}

				name = parentname + "_child" + index.toString();
			}
			
			fuckthisshit[child.name] = name;
			
			if (!children[name]) {
				var gpuChild:GPUMovieClipBase = processDisplayObject(child);
				gpuChild.name = name;
				children[name] = gpuChild;
				gpuChild.parent = this;
				gpuChild.track = tracks[name] = new GPUMovieClipAnimationTrack();
				gpuChild.track.fillPreceedingFrames(frame);
				numChildren++;
			}
			return children[name];
		}
		
		private function captureChildFrame(obj:DisplayObject, layer:int):void {
			
			var name:String = obj.name;
			name = fuckthisshit[name]
			var track:GPUMovieClipAnimationTrack = tracks[name];
			
			if (obj.visible == false) {
				track.matrix.push(new Matrix(0, 0, 0, 0, 0, 0));
			} else {
				var mtx:Matrix = obj.transform.matrix.clone();
				var bounds:Rectangle = obj.getBounds(obj);
				if (!(obj is DisplayObjectContainer)) {
					mtx.translate(bounds.x, bounds.y);
				}
				track.matrix.push(mtx);
			}
		}
		
		public function fromMC(mc:MovieClip):void {
			totalFrames = mc.totalFrames;
			
			for (var i:int = 0; i < mc.totalFrames; ++i) {
				// add trace to framescript to force movieclip revalidation
				mc.addFrameScript(i, function():void {
						trace(mc);
					});
				mc.gotoAndStop(i + 1);
				mc.gotoAndStop(i);
				if (mc.numChildren == 16) {
					var d1:DisplayObject = mc.getChildAt(13);
					if (d1 is MovieClip) {
						d1 = (d1 as MovieClip).getChildAt(0);
					}
					
					var b1:Rectangle = d1.getBounds(mc);
					
					mc.removeChildAt(13);
					var d2:DisplayObject = mc.getChildAt(12);
					var b2:Rectangle = d2.getBounds(mc);
					(d2 as DisplayObjectContainer).addChild(d1);
					var m:Matrix = d1.transform.matrix.clone();
					var m1:Matrix = new Matrix(m.a, m.b, m.c, m.d, 8, -10);
					d1.transform.matrix = m1;
				}
				
				currentFrame = i;
				framesChildren.push(new Vector.<GPUMovieClipBase>);
				
				for (var j:int = 0; j < mc.numChildren; ++j) {
					var d:DisplayObject = mc.getChildAt(j);
					if (d.transform.colorTransform.alphaOffset != -255) {
						currentChildren.push(processChild(mc.name, j, d, i));
						captureChildFrame(d, mc.getChildIndex(d));
					}
				}
				for each (var ch:GPUMovieClipBase in children) {
					if (ch.track.length <= i) {
						ch.track.addEmptyFrame();
					}
				}
			}
		}
		
		public function fromSprite(spr:Sprite):void {
			totalFrames = 1;
			framesChildren.push(new Vector.<GPUMovieClipBase>);
			
			for (var j:int = 0; j < spr.numChildren; ++j) {
				var d:DisplayObject = spr.getChildAt(j);
				currentChildren.push(processChild(spr.name, j, d, 0));
				captureChildFrame(d, spr.getChildIndex(d));
			}
		}
		
		public function fromContainer(c:DisplayObjectContainer):void {
			
			getBitmapFromDisplayObject(c);
			
			if (c is MovieClip) {
				fromMC(c as MovieClip);
			} else if (c is Sprite) {
				fromSprite(c as Sprite);
			} else {
				throw "GPUMovieClipData: unknown container.";
			}
		
		}
		
		public function createData():void {
			matrixData = new ByteArray();
			matrixData.endian = Endian.LITTLE_ENDIAN;
		}
		
		public function createGPUData(ctx:Context3D):void {
			GPUTextureAtlasManager.beginAdding();
			if (bmp) {
				GPUTextureAtlasManager.add(bmp);
			}
			
			createData();
			
			for each (var ch:GPUMovieClipBase in children) {
				ch.createGPUData(ctx);
			}
			
			GPUTextureAtlasManager.endAdding();
		}
		
		public function mergeDressed(partname:String):void {
			var naked:GPUMovieClipBase;
			var dressed:GPUMovieClipBase
			var child:GPUMovieClipBase;
			var nakedOffset:Point = new Point();
			var dressedOffset:Point = new Point();
			for each (child in children) {
				if (child.name.indexOf(partname) >= 0 && child.name.indexOf("dressed") == -1) {
					nakedOffset.x = tracks[child.name].matrix[0].tx;
					nakedOffset.y = tracks[child.name].matrix[0].ty;
					for each (var part:GPUMovieClipBase in child.children) 
					{
						naked = part;
						nakedOffset.x += child.tracks[part.name].matrix[0].tx;
						nakedOffset.y += child.tracks[part.name].matrix[0].ty;
						break;
					}
				}
			}
			
			for each (child in children) {
				if (child.name.indexOf(partname + "_dressed") >= 0) {
					dressedOffset.x = tracks[child.name].matrix[0].tx;
					dressedOffset.y = tracks[child.name].matrix[0].ty;
					for each (var part:GPUMovieClipBase in child.children) 
					{
						dressedOffset.x += child.tracks[part.name].matrix[0].tx;
						dressedOffset.y += child.tracks[part.name].matrix[0].ty;						
						dressed = part;
						break;
					}
				}
			}
			
			if (dressed) {
				var dx:Number = dressedOffset.x - nakedOffset.x;
				var dy:Number = dressedOffset.y - nakedOffset.y;	
				if (dressed.bmp)
				{
					naked.bmp.draw(dressed.bmp, new Matrix(1, 0, 0, 1, dx, dy));
				}

				dressed.bmp = null;
			}
		}
		
		public function mergeHeadShadow():void {
			var headOffset:Point = new Point();
			var child:GPUMovieClipBase;
			var part:GPUMovieClipBase;
			var head:GPUMovieClipBase;			
			for each (var child:GPUMovieClipBase in children) {
				if (child.name.indexOf("head") >= 0) {
					for each (part in child.children) {
						if (part.name.indexOf("child0") >= 0) {
							head = part;
							headOffset.x = child.tracks[part.name].matrix[0].tx
							headOffset.y = child.tracks[part.name].matrix[0].ty
							break;
						}
					}
				}
			}
			
			for each (var child:GPUMovieClipBase in children) {
				if (child.name.indexOf("head") >= 0) {
					for each (part in child.children) {
						if (part.name.indexOf("child1") >= 0 || part.name.indexOf("male_shadow") >= 0) {
							for each (var shadow:GPUMovieClipBase in part.children) {
							}
							var fx:Number = child.tracks[part.name].matrix[0].tx + part.tracks[shadow.name].matrix[0].tx;
							var fy:Number = child.tracks[part.name].matrix[0].ty + part.tracks[shadow.name].matrix[0].ty;
							var dx:Number = fx - headOffset.x;
							var dy:Number = fy - headOffset.y
							
							head.bmp.draw(shadow.bmp, new Matrix(1, 0, 0, 1, dx, dy));
							shadow.bmp = null;
							break;
						}
					}
				}
			}
		
		}
		
		public function mergeFaceInHead():void {
			var faceOffset:Point = new Point();
			var headOffset:Point = new Point();
			for (var key:String in tracks) {
				if (key.indexOf("face") >= 0) {
					var track:GPUMovieClipAnimationTrack = tracks[key];
					faceOffset.x = track.matrix[0].tx;
					faceOffset.y = track.matrix[0].ty;
				}
				if (key.indexOf("head") >= 0) {
					var track:GPUMovieClipAnimationTrack = tracks[key];
					headOffset.x = track.matrix[0].tx;
					headOffset.y = track.matrix[0].ty;
				}
			}
			var child:GPUMovieClipBase;
			var part:GPUMovieClipBase;
			var head:GPUMovieClipBase;
			for each (var child:GPUMovieClipBase in children) {
				if (child.name.indexOf("head") >= 0) {
					for each (part in child.children) {
						if (part.name.indexOf("child0") >= 0) {
							head = part;
							headOffset.x += child.tracks[part.name].matrix[0].tx
							headOffset.y += child.tracks[part.name].matrix[0].ty
							break;
						}
					}
				}
			}
			
			for each (var child:GPUMovieClipBase in children) {
				if (child.name.indexOf("face") >= 0) {
					for each (part in child.children) {
						if (part.name.indexOf("child0") >= 0) {
							var partOffset:Point = part.offset.clone();
							var p:GPUMovieClipBase = part.parent;
							while (p) {
								partOffset = partOffset.add(p.offset);
								p = p.parent;
							}
							
							var fx:Number = faceOffset.x + child.tracks[part.name].matrix[0].tx;
							var fy:Number = faceOffset.y + child.tracks[part.name].matrix[0].ty
							var dx:Number = fx - headOffset.x;
							var dy:Number = fy - headOffset.y
							
							head.bmp.draw(part.bmp, new Matrix(1, 0, 0, 1, dx, dy));
							part.bmp = null;
							break;
						}
					}
					
					for each (part in child.children) {
						if (part.name.indexOf("child1") >= 0 && part.bmp) {
							var partOffset:Point = part.offset.clone();
							var p:GPUMovieClipBase = part.parent;
							while (p) {
								partOffset = partOffset.add(p.offset);
								p = p.parent;
							}
							
							var fx:Number = faceOffset.x + child.tracks[part.name].matrix[0].tx;
							var fy:Number = faceOffset.y + child.tracks[part.name].matrix[0].ty
							var dx:Number = fx - headOffset.x;
							var dy:Number = fy - headOffset.y
							
							var w:Number = head.bmp.width;
							var h:Number = head.bmp.height;
							var dw:Number = 0;
							var dh:Number = 0;
							if (fx - headOffset.x < 0) {
								dw = Math.abs(fx - headOffset.x);
							}
							if (fy - headOffset.y < 0) {
								dh = Math.abs(fy - headOffset.y);
							}
							var hw:Number = part.bmp.width - head.bmp.width;
							if (hw < 0) {
								hw = 0;
							}
							var hh:Number = part.bmp.height - head.bmp.height;
							if (hh < 0) {
								hh = 0;
							}
							var newbmp:BitmapData = new BitmapData(w + dw + hw, h + dh + hh, true, 0x00000000);
							newbmp.draw(head.bmp, new Matrix(1, 0, 0, 1, dw, dh));
							newbmp.draw(part.bmp, new Matrix(1, 0, 0, 1, 0, 0));
							head.bmp = newbmp;
							head.offset.x -= dw;
							head.offset.y -= dh;
							part.bmp = null;
							break;
						}
					}
				}
			}
		}
		
		public function flatten(assets:Vector.<SpritesheetPart>):void {
			if (name && name.indexOf("face") >= 0) {
				return;
			}
			if (bmp) {
				var part:SpritesheetPart = new SpritesheetPart();
				part.bitmap = bmp;
				part.name = name;

				part.offset = offset;
				assets.push(part);
			}
			for each (var child:GPUMovieClipBase in children) {
				child.flatten(assets);
			}
		}
		
		public static var matrices:Dictionary = new Dictionary();
		
		public function writeMovieClip(parentXML:XML):void {
			var xml:XML =   <node />;
			parentXML.appendChild(xml)
			xml.@name = name;
			xml.children =   <children />
			if (framesChildren.length) {
				for (var i:int = 0; i < framesChildren[0].length; ++i) {
					var child:GPUMovieClipBase = framesChildren[0][i];
					var c:XML =   <node />					
					c.@name = child.name;
					xml.children.appendChild(c);
				}
			}
			
			xml.tracks =   <tracks />
			for (var key:Object in tracks) {
				var n:String = key as String;
				var track:XML =   <track />
				track.@name = n;
				for (var i:int = 0; i < tracks[n].matrix.length; ++i) {
					var m:Matrix = tracks[n].matrix[i];
					var frame:XML =   <frame />
					frame.@index = i;
					frame.a = m.a;
					frame.b = m.b;
					frame.c = m.c;
					frame.d = m.d;
					frame.tx = m.tx;
					frame.ty = m.ty;
					track.appendChild(frame)
				}
				xml.tracks.appendChild(track)
			}
			
			for each (child in children) {
				child.writeMovieClip(parentXML);
			}
		}
		
		private function serializeAnimation(anim:Vector.<Frame>):String {
			var xml:String = "<spritesheet>";
			for (var i:int = 0; i < anim.length; ++i) {
				var f:Frame = anim[i];
				xml += "<sprite name=\"" + f.name + "\">";
				xml += "<dimension x=\"" + f.dimension.x + "\" y=\"" + f.dimension.y + "\" width=\"" + f.dimension.width + "\" height=\"" + f.dimension.height + "\"></dimension>";
				xml += "</sprite>";
				
			}
			xml += "</spritesheet>";
			
			return xml;
		}
		
		public function setFrame(f:int):void {
			setChildrenFrame(f);
		}
		
		private function setChildrenFrame(f:int):void {
			currentFrame = f;
			for each (var ch:GPUMovieClipBase in currentChildren) {
				ch.currentMatrix.identity();
				ch.currentMatrix.scale(ch.bitmapScaleX, ch.bitmapScaleY);
				ch.currentMatrix.concat(ch.track.matrix[currentFrame]);
				ch.currentMatrix.concat(this.currentMatrix);
				
				ch.setChildrenFrame(ch.currentFrame);
			}
		}
		
		public function render(ctx:Context3D, screenMtx:Matrix3D):void {
			if (bmp) {
				matrixData.position = 0;
				matrixData.writeFloat(currentMatrix.a);
				matrixData.writeFloat(currentMatrix.c);
				matrixData.writeFloat(0);
				matrixData.writeFloat(currentMatrix.tx);
				
				matrixData.writeFloat(currentMatrix.b);
				matrixData.writeFloat(currentMatrix.d);
				matrixData.writeFloat(0);
				matrixData.writeFloat(currentMatrix.ty);
				
				var texture:Texture = GPUTextureAtlasManager.getNodeTexture(bmp);
				var uv:ByteArray = GPUTextureAtlasManager.getNodeUV(bmp);
				
				ctx.setBlendFactors(Context3DBlendFactor.ONE, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
				ctx.setDepthTest(false, "always");
				ctx.setProgram(program);
				ctx.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, screenMtx, true);
				ctx.setProgramConstantsFromByteArray(Context3DProgramType.VERTEX, 4, 2, matrixData, 0);
				ctx.setProgramConstantsFromByteArray(Context3DProgramType.VERTEX, 6, 1, uvs, 0);
				
				ctx.setTextureAt(0, texture);
				ctx.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
				
				ctx.drawTriangles(indexBuffer, 0, 2);
			}
			
			if (framesChildren.length) {
				for (var i:int = 0; i < framesChildren[currentFrame].length; ++i) {
					framesChildren[currentFrame][i].render(ctx, screenMtx);
				}
			}
		}
		
		private static var noChildren:Vector.<GPUMovieClipBase> = noChildren;
		private static var program:Program3D;
		private static var vertexBuffer:VertexBuffer3D;
		private static var indexBuffer:IndexBuffer3D;
		
		public static function prepareGPUStaticData(ctx:Context3D):void {
			var vsAsm:AGALMiniAssembler = new AGALMiniAssembler();
			vsAsm.assemble(Context3DProgramType.VERTEX, (["mul vt0, vc6.zw, va0.xy", "add v0, vc6.xy, vt0.xy", "mov vt0, va0", "dp4 vt0.x, va0, vc4", "dp4 vt0.y, va0, vc5", "m44 op, vt0, vc0"]).join("\n"), true);
			
			var fsAsm:AGALMiniAssembler = new AGALMiniAssembler();
			fsAsm.assemble(Context3DProgramType.FRAGMENT, (["tex oc, v0, fs0 <2d, norepeat, linear, nomip>"]).join("\n"), true);
			
			program = ctx.createProgram();
			program.upload(vsAsm.agalcode, fsAsm.agalcode);
			
			vertexBuffer = ctx.createVertexBuffer(4, 2);
			vertexBuffer.uploadFromVector(new <Number>[0, 0, 0, 1, 1, 1, 1, 0], 0, 4);
			
			indexBuffer = ctx.createIndexBuffer(6);
			indexBuffer.uploadFromVector(new <uint>[0, 1, 2, 2, 3, 0], 0, 6);
		}
	
	}

}