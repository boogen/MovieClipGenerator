package
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.geom.Rectangle;
	/**
     * ...
     * @author
     */
    public class GPUTextureAtlas extends Sprite
    {
        public var rect:Rectangle;
        public var bitmap:Bitmap;
        public var left:GPUTextureAtlas;
        public var right:GPUTextureAtlas;
        public var rootId:uint;

        public function GPUTextureAtlas(x:Number,y:Number,w:Number,h:Number, id:uint) {
            this.x = x;
            this.y = y;
            rect = new Rectangle(x, y, w, h);
            rootId = id;
        }

        public function add(bd:BitmapData, padding:int=0):GPUTextureAtlas {
            var result:GPUTextureAtlas;
            var w:int = bd.width + padding * 2;
            var h:int = bd.height + padding * 2;
            if (left && (result = left.add(bd, padding))) {
                return result;
            } else if (right && (result = right.add(bd, padding))) {
                return result;
            } else if (!bitmap && w <= rect.width && h <= rect.height) {
                bitmap = new Bitmap(bd);
                bitmap.x = padding;
                bitmap.y = padding;
                addChild(bitmap);
                if (w < rect.width) {
                    left = new GPUTextureAtlas(w, 0, rect.width - w, h, rootId);
                    addChild(left);
                }
                if (h < rect.height) {
                    right = new GPUTextureAtlas(0, h, rect.width, rect.height - h, rootId);
                    addChild(right);
                }
                return this;
            }
            return null;
        }

    }

}