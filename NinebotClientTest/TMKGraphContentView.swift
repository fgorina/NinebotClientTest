//
//  TMKGraphContentView.swift
//
//  Created by Francisco Gorina Vanrell on 9/10/15.
//  Copyright © 2015 Paco Gorina. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//( at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

import UIKit

class TMKGraphContentView: UIView {
    
    func gView() -> TMKGraphView?
    {
        if let v = self.superview as? TMKGraphView{
            return v
        }
        else{
            return nil
        }
    }
    
    func stepStep(_ st : CGFloat) -> CGFloat{
        
        var step : CGFloat = st
        if st <= 0.1{
            step = 1.0
        }
        else if  step <= 0.5{
            step = 0.5
        }
        else if  step <= 1.0{
            step = 1.0
        }
        else if  step <= 5.0{
            step = 5.0
        }
        else if  step <= 10.0{
            step = 10.0
        }
        else if  step <= 50.0{
            step = 50.0
        }
        else{
            step = 50.0
        }
        return step
        
    }
    
    override func draw(_ dirtyRect: CGRect)
    {
        // Get the Context
        
        if let v = self.gView(){
            let aContext = UIGraphicsGetCurrentContext()
            
            let font = UIFont(name: "Helvetica", size: 10.0)
            
            let fmt = NumberFormatter()
            fmt.numberStyle = NumberFormatter.Style.decimal
            fmt.maximumFractionDigits = 0
            
            aContext?.saveGState()
            
            let backColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0)
            backColor.setFill()
            var bbox = UIBezierPath(rect:self.bounds)
            bbox.fill()
            
            aContext?.restoreGState()
            
            
            v.computeDataForSeries()
            
            //  Dibuixem el fons amb l'alçada de la selected series
            
            if let ds = v.dataSource {
                
                
                var selSerie = -1
                
                
                for i in 0..<ds.numberOfSeries(){
                    if ds.isSelectedSerie(i){
                        selSerie = i
                    }
                }
                
                
                if selSerie != -1{
                    
                    aContext?.saveGState()
                    let backColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
                    backColor.setFill()
                    backColor.set()
                    
                    // Implementació amb unitats naturals. Comentat versio anterior
                    
                    var x = v.xmin
                    let d = (v.xmax - v.xmin) / self.bounds.width       // At most every pixel
                    
                    
                   // let n = ds.numberOfPointsForSerie(selSerie, value: v.yValue) // abans v.yValue
                    
                  //  if n > 0 {
                    
                    if x < v.xmax{
                        
                        let bz = UIBezierPath()
                        bz.lineJoinStyle =   CGLineJoin.round
                        
                        // Move to a point minimum
                        
                       // var pt = ds.value(v.yValue , axis:v.xAxis,  forPoint:0,  forSerie:selSerie) // Abans v.yValue
                        
                        var pt = ds.value(v.yValue, axis: v.xAxis, forX: x, forSerie: selSerie)
                        pt.y = v.yminH
                        
                        pt = v.heightPointFromTrackPoint(pt)
                        bz.move(to: pt)
                        
                        x = x + d
                        
                        //for i in 0..<n{
                            
                        while x < v.xmax{
                            //pt = ds.value(v.yValue, axis:v.xAxis, forPoint:i, forSerie:selSerie) // Abans v.yValue
                            
                            pt = ds.value(v.yValue, axis: v.xAxis, forX: x, forSerie: selSerie)
                            pt = v.heightPointFromTrackPoint(pt)
                            bz.addLine(to: pt)
                            x = x + d
                        }
                        
                        pt = ds.value(v.yValue, axis: v.xAxis, forX: v.xmax, forSerie: selSerie)
                        //pt = ds.value(v.yValue, axis:v.xAxis, forPoint:n-1, forSerie:selSerie) // Abans v.yValue
                        pt.y = v.yminH
                        pt = v.heightPointFromTrackPoint(pt)
                        bz.addLine(to: pt)
                        
                        
                        bz.fill()
                    }
                    
                    aContext?.restoreGState()
                }
                
                
                let deltax : CGFloat = self.bounds.size.width
                let height = self.bounds.size.height
                
                let step : CGFloat = v.exactNumber(20.0/v.sy)  // Amplada en unitats naturals de les divisions
                let step0 : CGFloat = floor(v.ymin / step) * step // Primer  Dibuixar
                
                let sy = v.sy
                let ymax = v.ymax
                
                // Draw coordinate horizontal lines
                
                aContext?.saveGState()
                
                UIColor.white.set()
                
                var j  = Int(floor(v.ymin / step))
                
                var firstLine = true
                
                var y = step0
                
                while y < ymax {
                    
                    if y > v.ymin{
                        let bz = UIBezierPath()
                        let ix = Int(y * 10.0)
                        let ss = Int(step * 50.0)
                        
                        if(ix % ss) == 0 || firstLine
                        {
                            bz.move(to: CGPoint(x: 0.0, y: height - (y - v.ymin) * sy))
                            bz.addLine(to: CGPoint(x: deltax, y: height - (y-v.ymin) * sy))
                            bz.lineWidth = 1.0
                            bz.stroke()
                            
                            firstLine = false
                            
                        }
                        else
                        {
                            bz .move(to: CGPoint(x: 0.0, y: height - (y - v.ymin) * sy))
                            bz.addLine(to: CGPoint(x: deltax, y: height - (y - v.ymin) * sy))
                            bz.lineWidth = 1.0
                            bz.stroke()
                        }
                        
                    }
                    
                    j += 1
                    y += step
                }
                
                // Ara hem de fer l'eix de les x. 2 Posibilitats
                
                if v.xAxis == 0 {// Km
                    
                    //  CGFloat delta = self.xmax-self.xmin;
                    
                    var km = Int(floor(v.xmin))
                    
                    if km < 0{
                        km = 0
                    }
                    
                    let delta : CGFloat = self.bounds.size.width
                    
                    var step : CGFloat = 1.0
                    
                    step = stepStep(30.0 / delta)
                    
                    var x : CGFloat = CGFloat(Double(km) * 1.0)
                    while x < v.xmax {
                        if x >= v.xmin {
                            
                            let ptLoc = CGPoint(x: x, y: 0.0)
                            
                            var ptView =  v.viewPointFromTrackPoint(ptLoc)
                            let float: Float = Float(x)
                            let num = NSNumber(value: float)
                            if let lab = fmt.string(from: num){
                                
                                let attr : [String : AnyObject] = NSDictionary(objects: NSArray(objects:font!, UIColor.white) as [AnyObject],
                                    forKeys: NSArray(objects:NSFontAttributeName, NSForegroundColorAttributeName) as! [NSCopying]) as! [String : AnyObject]
                                
                                
                                let w = lab.size(attributes: attr)
                                
                                ptView.y =  self.bounds.size.height
                                ptView.x = ptView.x - w.width / 2.0
                                
                                
                                lab.draw(at: ptView, withAttributes:attr)
                            }
                            
                        }
                        x = x + step
                    }
                    
                }
                else if (v.xAxis == 1){ // Minuts de la sortida
                    
                    var minuts = Int(floor(v.xmin))
                    
                    if(minuts < 0){
                        minuts = 0
                    }
                    
                    let delta = CGFloat(self.bounds.size.width / (v.xmax - v.xmin))
                    
                    let step = stepStep(30.0 / delta)
                    
                    var  x = CGFloat(CGFloat(minuts) * 1.0)
                    while x < v.xmax {
                        if x >= v.xmin{
                            
                            let ptLoc = CGPoint(x: x, y: 0.0)
                            
                            var ptView =  v.viewPointFromTrackPoint(ptLoc)
                            
                            // Calculem el format hh:mm
                            
                            let h = Int(floor(x/60.0))
                            let m = Int(floor(x - (CGFloat(h) * 60.0)))
                            
                            let lab = String(format:"%d:%d", h, m)
                            
                            let attr : [String : AnyObject] = NSDictionary(objects: NSArray(objects:font!, UIColor.white) as [AnyObject],
                                forKeys: NSArray(objects:NSFontAttributeName, NSForegroundColorAttributeName) as! [NSCopying]) as! [String : AnyObject]
                            
                            
                            let w = lab.size(attributes: attr)
                            ptView.y =  self.bounds.size.height
                            ptView.x = ptView.x - w.width/2.0
                            
                            
                            lab.draw(at: ptView, withAttributes:attr)
                        }
                        x = x + step
                    }
                }
                
                aContext?.restoreGState()
                
                
                // Draw data points
                
                for serie : Int in 0 ..< ds.numberOfSeries() {
                    
                    
                    aContext?.saveGState()
                    
                    ds.colorForSerie(serie).set()
                    
                    //let n = ds.numberOfPointsForSerie(serie, value:v.yValue)
                    
                    
                    // Implementació amb unitats naturals. Comentat versio anterior
                    
                    var x = v.xmin
                    let d = (v.xmax - v.xmin) / self.bounds.width       // At most every pixel
                 
                    
                   // if n > 0 {
                    if x < v.xmax{
                        
                        let bz = UIBezierPath()
                        bz.lineJoinStyle = CGLineJoin.round
                        
                        if ds.isSelectedSerie(serie){
                            bz.lineWidth = 2.0
                        }
                        
                        //var pt = ds.value(v.yValue, axis:v.xAxis, forPoint:0, forSerie:serie)
                        var pt = ds.value(v.yValue, axis: v.xAxis, forX: x, forSerie: serie)
                        
                        pt = v.viewPointFromTrackPoint(pt)
                        bz.move(to: pt)
                        
                        x = x + d
                        
                        //for i in 1..<n {
                        while x <= v.xmax{
                            //pt = ds.value(v.yValue, axis:v.xAxis, forPoint:i, forSerie:serie)
                            pt = ds.value(v.yValue, axis: v.xAxis, forX: x, forSerie: serie)
                            
                            pt = v.viewPointFromTrackPoint(pt)
                            bz.addLine(to: pt)
                            
                            x = x + d
                        }
                        
                        bz.stroke()
                    }
                    
                    aContext?.restoreGState()
                    
                }
                
                // Draw Waypoints
                
                for serie in 0..<ds.numberOfSeries() {
                    
                    aContext?.saveGState()
                    let n = ds.numberOfWaypointsForSerie(serie)
                    if(n > 0){
                        UIColor.red.set()
                        
                        for  i in 0..<n {
                            let bz = UIBezierPath()
                            
                            var pt = ds.valueForWaypoint(i, axis:v.xAxis, serie:serie)
                            pt = v.viewPointFromTrackPoint(pt)
                            
                            bz.move(to: CGPoint(x: pt.x, y: 0.0))
                            bz.addLine(to: CGPoint(x: pt.x, y: self.bounds.size.height))
                            
                            
                            if ds.isSelectedWaypoint(i, forSerie:serie) {
                                bz.lineWidth = 3.0
                            }
                            else{
                                bz.lineWidth = 1.0
                            }
                            
                            bz.stroke()
                        }
                        
                    }
                    
                    aContext?.restoreGState()
                }
                
                // Draw Pins
                
                
                aContext?.saveGState()
                let n = ds.numberOfPins()
                
                if n > 0 {
                    UIColor.purple.set()
                    
                    for  i in 0..<n {
                        let bz = UIBezierPath()
                        
                        var pt = ds.valueForPin(i,  axis:v.xAxis)
                        pt = v.viewPointFromTrackPoint(pt)
                        bz.move(to: CGPoint(x: pt.x, y: 0.0))
                        bz.addLine(to: CGPoint(x: pt.x, y: self.bounds.size.height))
                        
                        bz.lineWidth = 1.0
                        
                        if ds.isSelectedPin(i){
                            bz.lineWidth = 3.0
                        }
                        
                        bz.stroke()
                    }
                    
                }
                
                aContext?.restoreGState()
                
                
                // Now draw selection
                
                if ds.numberOfSeries() > 0{
                    aContext?.saveGState()
                    
                    if !v.clampDown {
                        UIColor.green.set()
                    }
                    else{
                        UIColor.cyan.set()
                    }
                    
                    bbox = UIBezierPath()
                    
                    bbox.move(to: CGPoint(x: v.selectionLeft-v.leftMargin, y: 0.0))
                    bbox.addLine(to: CGPoint(x: v.selectionLeft-v.leftMargin, y: self.bounds.size.height))
                    if v.movingLeftSelection{
                        bbox.lineWidth = 3.0
                    }else{
                        bbox.lineWidth = 1.0
                    }
                    
                    bbox.stroke()
                    
                    if fabs(v.selectionLeft - v.selectionRight) > 2.0 {
                        bbox = UIBezierPath()
                        
                        bbox.move(to: CGPoint(x: v.selectionRight-v.leftMargin, y: 0.0))
                        bbox.addLine(to: CGPoint(x: v.selectionRight-v.leftMargin, y: self.bounds.size.height))
                        
                        if v.movingRightSelection {
                            bbox.lineWidth = 3.0
                        }else{
                            bbox.lineWidth = 1.0
                        }
                        
                        bbox.stroke()
                        
                        
                        aContext?.restoreGState()
                    }
                }
                
            }
            
        }
    }
}
