//
//  GraphViewController.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 9/2/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, TMKGraphViewDataSource {
    
    @IBOutlet weak var graphView : TMKGraphView!
    
    weak var delegate : BLENinebotDashboard?
    weak var ninebot : BLENinebot?
    var shownVariable = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.hidden = true
        self.graphView.setup()
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.graphView.setNeedsDisplay()
        })
        
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        if size.width < size.height{
            
            self.navigationController?.navigationBar.hidden = false
            self.navigationController?.popViewControllerAnimated(true)

        }
    }
    
    
    // MARK: TMKGraphViewDataSource
    
    func numberOfSeries() -> Int{
        return 1
    }
    func numberOfPointsForSerie(serie : Int, value: Int) -> Int{
        let v = BLENinebot.displayableVariables[value]
        
        if let nb = self.ninebot{
            return nb.data[v].log.count
        }
        else{
            return 0
        }
    }
    func styleForSerie(serie : Int) -> Int{
        return 0
    }
    func colorForSerie(serie : Int) -> UIColor{
        return UIColor.redColor()
    }
    func offsetForSerie(serie : Int) -> CGPoint{
        return CGPoint(x: 0, y: 0)
    }
    func value(value : Int, axis: Int,  forPoint point: Int,  forSerie serie:Int) -> CGPoint{
        if let nb = self.ninebot{
            let v = nb.getLogValue(value, index: point)
            let t = nb.data[BLENinebot.displayableVariables[value]].log[point].time
            return CGPoint(x: CGFloat(t.timeIntervalSinceDate(nb.firstDate!)), y:CGFloat(v) )
        }
        else{
            return CGPoint(x: 0, y: 0)
        }
    
    }

    // Retorna un punt donada l'abcisa. Interpola entre punts
    
    func value(value : Int, axis: Int,  forX x:CGFloat,  forSerie serie:Int) -> CGPoint{
        
        let v = BLENinebot.displayableVariables[value]
        
        
        if let nb = self.ninebot{
            
            if nb.data[v].log.count <= 0{       // No Data
                return CGPoint(x: x, y: 0.0)
            }
            
            var p0 = 0  // Index before
            var p1 = 0  // Index after
            
            for (var i = 1; i <  nb.data[v].log.count; i++){
                
                let xValue = CGFloat(nb.data[v].log[i].time.timeIntervalSinceDate(nb.firstDate!))
                
                p0 = p1
                p1 = i
                
                if xValue >= x {
                    break
                }
            }
            
            // If p0 == p1 just return value
            
            if p0 == p1 {
                return self.value(value, axis: axis,  forPoint:p0,  forSerie :serie)
            }
            else {      // Intentem interpolar
                
                let v0 = self.value(value, axis: axis,  forPoint:p0,  forSerie :serie)
                let v1 = self.value(value, axis: axis,  forPoint:p1,  forSerie :serie)
                
                if v0.x == v0.y {   // One more check not to have div/0
                    return v0
                }
                
                let deltax = v1.x - v0.x
                let deltay = v1.y - v0.y
                
                let v = (x - v0.x) / deltax * deltay + v0.y
                
                return CGPoint(x: x, y:v)
                
            }
            
        }else {
            return CGPoint(x: x, y: 0.0)
        }
    }
    

    func numberOfWaypointsForSerie(serie: Int) -> Int{
            return 0
     
    }
    func valueForWaypoint(point : Int,  axis:Int,  serie: Int) -> CGPoint{
        return CGPoint(x: 0, y: 0)
    }
    func isSelectedWaypoint(point: Int, forSerie serie:Int) -> Bool{
        return false
    }
    func isSelectedSerie(serie: Int) -> Bool{
        return true
    }
    func numberOfXAxis() -> Int {
        return 1
    }
    func nameOfXAxis(axis: Int) -> String{
        return "t"
    }
    func numberOfValues() -> Int{
        return BLENinebot.displayableVariables.count
    }
    func nameOfValue(value: Int) -> String{
        return BLENinebot.labels[BLENinebot.displayableVariables[value]]
    }
    func numberOfPins() -> Int{
        return 0
    }
    func valueForPin(point:Int, axis:Int) -> CGPoint{
        return CGPoint(x: 0, y: 0)
    }
    func isSelectedPin(pin: Int) -> Bool{
        return false
    }
    
    func pointForX(x: Double, value: Int) -> Int{
        
        let v = BLENinebot.displayableVariables[value]
        
         if let nb = self.ninebot{

            for (var i = 0; i <  nb.data[v].log.count; i++){
            
                if nb.data[v].log[i].time.timeIntervalSinceDate(nb.firstDate!) >= x {
                    return i
                }
            }
        }
        
        return 0
    }

    func minMaxForSerie(serie : Int, value: Int) -> (CGFloat, CGFloat){
        
        switch(value){
            
        case 0:
            return (0.0, 1.0)   // Speed
            
        case 1:
            return (15.0, 20.0) // T
            
        case 2:                 // Voltage
            return (50.0, 60.0)
            
        case 3:                 // Current
            return  (-1.0, 1.0)
            
        case 4:
            return (0.0, 100.0) // Battery
            
        case 5:
            return (-1.0, 1.0)  // Pitch
            
        case 6:
            return (-1.0, 1.0)  //  Roll
            
        case 7:
            return (0.0, 0.5)   // Distance
            
        case 8:
            return (-10.0,10.0)   // Altitude
            
            
        default:
            return (0.0, 0.0)
            
            
            
        }
        
        
        
    }

}
