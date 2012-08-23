package
{
    import flash.display3D.Context3D;
	/**
     * ...
     * @author
     */
    public class GPUMovieClip
    {
        public var data:GPUMovieClipBase;
        public var x:Number;
        public var y:Number;
        public var currentFrame:Number;

        public function GPUMovieClip()
        {
        }

        public function get totalFrames():Number {
            return data.totalFrames;
        }

        public function createFromData(d:GPUMovieClipBase):void {
            data = d;
        }

        public function render(ctx:Context3D):void {
            data.currentMatrix.identity();
            data.currentMatrix.translate(x, y);
            data.setFrame(currentFrame);
            //data.render(ctx);
        }

    }

}