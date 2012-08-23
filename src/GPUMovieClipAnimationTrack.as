package
{
    import flash.display.BitmapData;
    import flash.geom.Matrix;
    import flash.utils.ByteArray;
    import flash.utils.Endian;
	/**
     * ...
     * @author mosowski
     */
    public class GPUMovieClipAnimationTrack
    {
        public var matrix:Vector.<Matrix> = new Vector.<Matrix>();

        public function get length():int {
            return matrix.length;
        }

        public function fillPreceedingFrames(frame:int):void {
            while (length != frame) {
                addEmptyFrame();
            }
        }

        public function addEmptyFrame():void {
            matrix.push(new Matrix(0,0,0,0,0,0));
        }


        public function isFrameVisible(i:int):Boolean {
            return i < length && (matrix[i].a || matrix[i].b || matrix[i].c || matrix[i].d);
        }
    }

}