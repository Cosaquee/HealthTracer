import MapKit

class PedalPathElevationRenderer: MKOverlayPathRenderer {
    
    var polyline : MKPolyline
    var elevations: [Int]
    var maxElevation: Int?
    var border: Bool = false
    var borderColor: UIColor?
    
    
    
    //MARK: Initializers
    init(polyline: MKPolyline, elevations: [Int]) {
        self.polyline = polyline
        self.elevations = elevations
        super.init(overlay: polyline)
        self.maxElevation = calculateMaxElevation()
    }
    
    //MARK: Override methods
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        
        var baseWidth: CGFloat
        if zoomScale > 0.1 {
            baseWidth = self.lineWidth * 2
        } else {
            baseWidth = self.lineWidth / zoomScale
        }
        
        /*
         Set path width relative to map zoom scale
         */
        
        var firstColor:UIColor = UIColor(hue: self.getHueFor(elevation: elevations[0]), saturation: 1, brightness: 1, alpha: 1)
        var lastColor: UIColor = UIColor(hue: self.getHueFor(elevation: elevations[1]), saturation: 1, brightness: 1, alpha: 1)
        
        
        if self.border {
            context.setLineWidth(baseWidth * 1.5)
            context.setLineJoin(CGLineJoin.round)
            context.setLineCap(CGLineCap.Round)
            context.addPath(self.path)
            CGContextSetStrokeColorWithColor(context, self.borderColor?.CGColor ?? UIColor.whiteColor.CGColor)
            CGContextStrokePath(context)
        }
        
        
        for i in 0...self.polyline.pointCount-1 {
            let point: CGPoint = pointForMapPoint(self.polyline.points()[i])
            let path: CGMutablePathRef  = CGPathCreateMutable()
            
            lastColor = UIColor(hue: self.getHueFor(elevation: elevations[i]), saturation: 1, brightness: 1, alpha: 1)
            if i==0 {
                CGPathMoveToPoint(path, nil, point.x, point.y)
            } else {
                let previousPoint = self.pointForMapPoint(polyline.points()[i-1])
                CGPathMoveToPoint(path, nil, previousPoint.x, previousPoint.y)
                CGPathAddLineToPoint(path, nil, point.x, point.y)
                
                
                CGContextSaveGState(context);
                let colorspace = CGColorSpaceCreateDeviceRGB()
                let locations: [CGFloat] = [0,1]
                let gradient = CGGradientCreateWithColors(colorspace, [firstColor.CGColor, lastColor.CGColor], locations)
                
                let pathToFill = CGPathCreateCopyByStrokingPath(path, nil, baseWidth, CGLineCap.Round, CGLineJoin.Round, self.miterLimit)
                CGContextAddPath(context, pathToFill)
                CGContextClip(context);
                
                let gradientStart = previousPoint;
                let gradientEnd = point;
                
                CGContextDrawLinearGradient(context, gradient, gradientStart, gradientEnd, CGGradientDrawingOptions.DrawsBeforeStartLocation);
                CGContextRestoreGState(context)
            }
            firstColor = UIColor(CGColor: lastColor.CGColor)
        }
        
        
        super.drawMapRect(mapRect, zoomScale: zoomScale, inContext: context)
    }
    
    /*
     Create path from polyline
     Thanks to Adrian Schoenig
     (http://adrian.schoenig.me/blog/2013/02/21/drawing-multi-coloured-lines-on-an-mkmapview/ )
     */
    override func createPath() {
        let path: CGMutablePathRef  = CGPathCreateMutable()
        var pathIsEmpty: Bool = true
        
        for i in 0...self.polyline.pointCount-1 {
            
            let point: CGPoint = pointForMapPoint(self.polyline.points()[i])
            if pathIsEmpty {
                CGPathMoveToPoint(path, nil, point.x, point.y)
                pathIsEmpty = false
            } else {
                CGPathAddLineToPoint(path, nil, point.x, point.y)
            }
        }
        self.path = path
    }
    
    
    private func getHueFor(elevation elevation: Int) -> CGFloat {
        let maxElevation = CGFloat(self.maxElevation ?? 50)
        let hue = CGFloat(elevation).map(from: 0...maxElevation+5, to: 0.0...0.4)
        return 0.4-hue
        
    }
    
    private func calculateMaxElevation() -> Int {
        return self.elevations.maxElement() ?? 0
    }
    
}


extension CGFloat {
    func map(from from: ClosedInterval<CGFloat>, to: ClosedInterval<CGFloat>) -> CGFloat {
        let result = ((self - from.start) / (from.end - from.start)) * (to.end - to.start) + to.start
        return result
    }
}
