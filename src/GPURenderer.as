package
{
    import flash.display.Stage;
    import flash.display3D.Context3D;
    import flash.events.Event;
    import flash.geom.Matrix3D;
	/**
     * ...
     * @author
     */
    public class GPURenderer
    {
        public var ctx:Context3D;
        public var screenMatrix:Matrix3D;
        public var stage:Stage;

        public function GPURenderer()
        {

        }

        public function init(stage:Stage):void {
            this.stage = stage;
            stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreate);
            stage.stage3Ds[0].requestContext3D();

            screenMatrix = new Matrix3D();
            screenMatrix.appendScale(2 / stage.stageWidth, -2 / stage.stageHeight, 1);
			screenMatrix.appendTranslation(-1, 1, 0);
        }

        public function onContext3DCreate(e:Event):void {
            ctx = stage.stage3Ds[0].context3D;
            ctx.configureBackBuffer(stage.stageWidth, stage.stageHeight, 0 , false);

            stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }

        public function onEnterFrame(e:Event):void {
            ctx.clear();

            ctx.present();
        }

    }

}