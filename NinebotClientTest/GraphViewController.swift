//
//  GraphViewController.swift
//  NinebotClientTest
//
//  Created by Francisco Gorina Vanrell on 9/2/16.
//  Copyright © 2016 Paco Gorina. All rights reserved.
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
            if v == BLENinebot.kPower {
                return nb.data[BLENinebot.kCurrent].log.count
            }else {
                return nb.data[v].log.count
            }
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
        
        var xv = value
        
        if value == 9 {
            xv = 3
        }
        
        if let nb = self.ninebot{
            
            let v = nb.getLogValue(value, index: point)
            
            let t = nb.data[BLENinebot.displayableVariables[xv]].log[point].time
            return CGPoint(x: CGFloat(t.timeIntervalSinceDate(nb.firstDate!)), y:CGFloat(v) )
        }
        else{
            return CGPoint(x: 0, y: 0)
        }
    
    }
    
    func value(value : Int, axis: Int,  forX x:CGFloat,  forSerie serie:Int) -> CGPoint{
 
        if let nb = self.ninebot{
            
            let v = nb.getLogValue(value, time: NSTimeInterval(x))
            return CGPoint(x: x, y:CGFloat(v))
            
        }else{
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
        
        case 9:
            return (-50.0, +50.0) // Power
            
            
        default:
            return (0.0, 0.0)
            
            
            
        }
        
        
        
    }

}
