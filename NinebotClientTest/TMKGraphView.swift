//
//  TMKGraphView.swift
//  HealthInquire
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

class TMKGraphView: UIView {
    
    var movingLeftSelection = false
    var movingRightSelection = false
    
    
    
    @IBOutlet weak var dataSource : GraphViewController! // Preferiria un protocol però no va al Storyboard
    
    //    var document : TMKDocument?
    var topMargin : CGFloat = 30.0
    var bottomMargin : CGFloat = 30.0
    var leftMargin : CGFloat = 50.0
    var rightMargin : CGFloat = 40.0
    
    var selectionLeft : CGFloat = 50.0
    var selectionRight : CGFloat = 100.0
    var selectionLeftUnits : CGFloat = 0.0
    var selectionRightUnits : CGFloat = 100.0
    
    var oldSelectionLeft : CGFloat = 0.0
    var oldSelectionRight : CGFloat = 0.0
    
    
    var deltax : CGFloat = 0.0
    var deltay : CGFloat = 0.0
    var xmin : CGFloat = 0.0
    var xmax : CGFloat = 0.0
    var ymin : CGFloat = 0.0
    var ymax : CGFloat = 0.0
    var sx : CGFloat = 0.0
    var sy : CGFloat = 0.0
    
    var yminH : CGFloat = 0.0
    var ymaxH : CGFloat = 0.0
    
    var clampDown = false
    
    @IBOutlet  weak var heightConstraint :  NSLayoutConstraint!
    @IBOutlet weak var posConstraint :  NSLayoutConstraint!
    
    @IBOutlet  weak var  xAxisButton : UIButton!
    @IBOutlet  weak var  yValueButton : UIButton!
    @IBOutlet  weak var  infoField : UILabel!
    @IBOutlet  weak var  infoSelField : UILabel!
    @IBOutlet  weak var  filterSlider : UISlider!
    @IBOutlet  weak var  graphContent : TMKGraphContentView!
    
    var yValue = 0 // 0->elev 1->bpm 2->ºC
    var xAxis = 1   // Time
    
    weak var activeColor : UIColor?
    weak var highlightColor : UIColor?
    
    var origYPos = 0.0
    var origSize = 0.0
    var firstClick : CGPoint = CGPointZero
    var oldY : CGPoint = CGPointZero
    
    //MARK: Init
    
    func setup()
    {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.multipleTouchEnabled = true
        self.contentMode = UIViewContentMode.Redraw
        self.opaque = false
        self.activeColor = UIColor(red: 0.4, green: 0.8, blue: 0.8, alpha: 1.0)
        self.highlightColor = UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        self.addContent()
        self.addXAxeButton()
        self.addyValueButton()
        self.addGearButton()
        self.addInfoField()
        //self.addSlider()
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: "swipeLeft:")
        swipeLeft.direction = .Left
        swipeLeft.numberOfTouchesRequired = 2
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: "swipeRight:")
        swipeRight.direction = .Right
        swipeRight.numberOfTouchesRequired = 2
        
        self.addGestureRecognizer(swipeLeft)
        self.addGestureRecognizer(swipeRight)
        
        self.setupGestureRecognizers()
        self.computeDataForSeries()
        self.recomputeSelectionUnits()
        // self.setupNotifications()
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //self.setup()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //self.setup()
    }
    
    
    
    //MARK: Recognizers
    
    func setupGestureRecognizers(){
        let tapG = UITapGestureRecognizer(target: self, action: "clamp:")
        tapG.numberOfTapsRequired = 2
        self.addGestureRecognizer(tapG)
    }
    
    
    
    @IBAction func clamp(src: UITapGestureRecognizer)
    {
        
        let myPt = src.locationInView(self)
        
        if myPt.x > self.selectionLeft && myPt.x < self.selectionRight && myPt.y > ( self.topMargin) && myPt.y < (self.bounds.size.height - self.bottomMargin)
        {
            self.clampDown = !self.clampDown
            self.recomputeSelectionUnits()
            self.setNeedsDisplay()
            
        }
        
    }
    
    //MARK: Computation
    
    func computeDataForSeries()
    {
        var xmin : CGFloat = 0.0
        var xmax : CGFloat = 100.0
        var ymin : CGFloat = 0.0
        var ymax : CGFloat = 100.0
        var yminH : CGFloat = 0.0
        var ymaxH : CGFloat = 100.0
        
        self.xmin = 0.0
        self.xmax = 100.0
        self.ymin = 0.0
        self.ymax = 100.0
        self.yminH  = 0.0
        self.ymaxH = 100.0
        
        if let ds = self.dataSource {
            
            let nseries = ds.numberOfSeries()
            
            if nseries == 0{
                return
            }
            
            if ds.numberOfPointsForSerie(0, value: self.yValue) == 0{
                return
            }
            
            var pt = ds.value(self.yValue, axis:self.xAxis,  forPoint:0 ,forSerie:0)
            
            xmin = pt.x
            xmax = pt.x
            
            (ymin, ymax) = ds.minMaxForSerie(0, value: self.yValue)
            
           // pt = ds.value(self.yValue, axis:self.xAxis,  forPoint:0, forSerie:0) // Height
            
            yminH = ymin
            ymaxH = ymax
            
            
            for serie in 0..<nseries{
                
                let n = ds.numberOfPointsForSerie(serie, value: self.yValue)
                
                for i in 0..<n {
                    pt = ds.value(self.yValue, axis:self.xAxis, forPoint:i, forSerie:serie)
                    
                    xmin = min(xmin, pt.x)
                    xmax = max(xmax, pt.x)
                    ymin = min(ymin, pt.y)
                    ymax = max(ymax, pt.y)
                    
                    pt = ds.value(self.yValue ,axis:self.xAxis, forPoint:i, forSerie:serie) //Height
                    
                    yminH = min(yminH, pt.y)
                    ymaxH = max(ymaxH, pt.y)
                    
                }
                
            }
            
            self.xmin = xmin
            self.xmax = xmax
            self.ymin = ymin
            self.ymax = ymax
            self.yminH = yminH
            self.ymaxH = ymaxH
            
            if self.xmax == self.xmin{
                self.xmax = self.xmin + 100.0
            }
            
            if self.ymax == self.ymin{
                self.ymax = self.ymin + 100.0
            }
            
            if self.selectionLeftUnits < self.xmin{
                self.selectionLeftUnits = self.xmin
            }
            
            if self.selectionRightUnits > self.xmax{
                self.selectionRightUnits = self.xmax
            }
            
            // General scales
            
            let deltax : CGFloat = self.bounds.size.width - self.leftMargin - self.rightMargin
            let deltay : CGFloat = self.bounds.size.height - self.topMargin - self.bottomMargin
            self.sx = deltax / (self.xmax-self.xmin)
            self.sy = deltay / (self.ymax-self.ymin)
        }
        
    }
    
    func exactNumber(x : CGFloat) -> CGFloat{
        
        if x < 0.0 {
            return 0 - self.exactNumberPositive(-x)
        }
        else{
            return exactNumberPositive(x)
        }
    }
    
    func exactNumberPositive(x : CGFloat) -> CGFloat
    {
        
        
    
        switch x {
            
        case 0...0.1:
            return 0.1
            
        case 0.1...0.5:
            return 0.5
            
        case 0.5...1.0:
            return 1.0
            
        case 1.0...5.0:
            return 5.0
            
        case 5.0...10.0:
            return 10.0
            
        case 10.0...50.0:
            return 50.0
            
        case 50.0...100.0:
            return 100.0
            
        case 100.0...500.0:
            return 500.0
            
        case 500.0...1000.0:
            return 1000.0
            
        default:
            return 5000.0
        }
    }
    
    func recomputeSelectionUnits()
    {
        let deltax = self.bounds.size.width - self.leftMargin - self.rightMargin
        let deltay = self.bounds.size.height - self.topMargin - self.bottomMargin
        
        self.sx = deltax / (self.xmax-self.xmin)
        self.sy = deltay / (self.ymax-self.ymin)
        
        self.selectionLeftUnits = (self.selectionLeft - self.leftMargin) / self.sx + self.xmin
        
        self.selectionRightUnits = (self.selectionRight - self.leftMargin) / self.sx + self.xmin
        
    }
    
    func recomputeSelectionPosition()
    {
        let deltax = self.bounds.size.width - self.leftMargin - self.rightMargin
        let deltay = self.bounds.size.height - self.topMargin - self.bottomMargin
        
        self.sx = deltax / (self.xmax - self.xmin)
        self.sy = deltay / (self.ymax - self.ymin)
        
        
        self.selectionLeft = (self.selectionLeftUnits - self.xmin) * self.sx + self.leftMargin;
        self.selectionRight = (self.selectionRightUnits - self.xmin) * self.sx + self.leftMargin;
        //self.selectionLeftUnits =(self.selectionLeft - self.leftMargin)/self.sx + self.xmin;
        //self.selectionRightUnits = (self.selectionRight - self.leftMargin)/self.sx + self.xmin;
        
    }
    
    
    func oldTrackPointFromViewPoint(p:CGPoint) -> CGPoint {
        
        var myPt : CGPoint = CGPoint(x:p.x-self.leftMargin, y: p.y-self.bottomMargin)
        
        // Get point in area
        
        myPt.x = (myPt.x / self.sx) + self.xmin
        myPt.y = (myPt.y / self.sy) + self.ymin
        
        return myPt;
    }
    
    
    func trackPointFromViewPoint(pt:CGPoint) -> CGPoint   {
        var myPt = CGPoint(x:0, y:0)
        let height = self.bounds.size.height
        
        // General scales
        
        let deltax : CGFloat = self.bounds.size.width - self.leftMargin - self.rightMargin
        let deltay : CGFloat = self.bounds.size.height - self.topMargin - self.bottomMargin
        self.sx = deltax / (self.xmax-self.xmin)
        self.sy = deltay / (self.ymax-self.ymin)
        
        
        // 3 posibilitats :
        
        if pt.x >= self.leftMargin && pt.x  < self.selectionLeft{
            let scx : CGFloat = (self.selectionLeft - self.leftMargin)/(self.selectionLeftUnits - self.xmin)
            
            myPt = CGPoint(x:(pt.x - self.leftMargin ) / scx + self.xmin,
                y:height - ((pt.y - self.bottomMargin ) / self.sy) + self.ymin)
        }
        else if pt.x >= self.selectionLeft && pt.x < self.selectionRight{
            let scx : CGFloat = (self.selectionRight - self.selectionLeft)/(self.selectionRightUnits - self.selectionLeftUnits)
            
            myPt = CGPoint(x: (pt.x - self.selectionLeft ) / scx + self.selectionLeftUnits,
                y:height - ((pt.y - self.bottomMargin ) / self.sy) + self.ymin);
        }
        else if pt.x >= self.selectionRight{
            let scx : CGFloat = (self.leftMargin + deltax - self.selectionRight)/(self.xmax - self.selectionRightUnits)
            
            myPt = CGPoint(x:(pt.x - self.selectionRight ) / scx + self.selectionRightUnits,
                y:height - ((pt.y - self.bottomMargin ) / self.sy) + self.ymin);
        }
        
        return myPt
    }
    
    func heightPointFromTrackPoint(pt : CGPoint) -> CGPoint
    {
        var myPt = CGPoint(x:0,y:0)
        let height = self.bounds.size.height
        
        // General scales
        
        let deltax : CGFloat = self.bounds.size.width - self.leftMargin - self.rightMargin
        let deltay : CGFloat = self.bounds.size.height - self.topMargin - self.bottomMargin
        let sy : CGFloat = deltay / (self.ymaxH-self.yminH)
        
        
        // 3 posibilitats :
        
        if(pt.x < self.selectionLeftUnits)
        {
            let scx: CGFloat = (self.selectionLeft - self.leftMargin) / (self.selectionLeftUnits - self.xmin)
            
            myPt = CGPoint(x: (pt.x - self.xmin ) * scx + self.leftMargin, y: height - ((pt.y - self.yminH ) * sy ) - self.bottomMargin)
        }
        else if (pt.x >= self.selectionLeftUnits && pt.x < self.selectionRightUnits)
        {
            let scx : CGFloat = (self.selectionRight - self.selectionLeft) / (self.selectionRightUnits - self.selectionLeftUnits)
            
            myPt = CGPoint(x: (pt.x - self.selectionLeftUnits ) * scx + self.selectionLeft,
                y: height - ((pt.y - self.yminH ) * sy) - self.bottomMargin);
        }
        else if (pt.x >= self.selectionRightUnits)
        {
            let scx : CGFloat = (self.leftMargin + deltax - self.selectionRight) / (self.xmax - self.selectionRightUnits)
            
            myPt = CGPoint(x: (pt.x - self.selectionRightUnits ) * scx + self.selectionRight,
                y: height - ((pt.y - self.yminH ) * sy) - self.bottomMargin);
        }
        
        if(isnan(myPt.x)){
            myPt.x = 0.0
        }
        
        if(isnan(myPt.y)){
            myPt.y = 0.0
        }
        
        myPt = CGPoint(x: myPt.x-self.leftMargin, y: myPt.y-self.topMargin)
        return myPt
    }
    
    
    func viewPointFromTrackPoint(pt:CGPoint) -> CGPoint
    {
        var  myPt = CGPoint(x:0, y:0)
        let height = self.bounds.size.height
        
        // General scales
        
        let deltax : CGFloat = self.bounds.size.width - self.leftMargin - self.rightMargin
        let deltay : CGFloat = self.bounds.size.height - self.topMargin - self.bottomMargin
        self.sx = deltax / (self.xmax-self.xmin)
        self.sy = deltay / (self.ymax-self.ymin)
        
        
        // 3 posibilitats :
        
        if(pt.x < self.selectionLeftUnits){
            let scx : CGFloat = (self.selectionLeft - self.leftMargin) / (self.selectionLeftUnits - self.xmin)
            
            myPt = CGPoint(x: (x: pt.x - self.xmin ) * scx + self.leftMargin,
                y: height - ((pt.y - self.ymin ) * self.sy) - self.bottomMargin)
        }
        else if pt.x >= self.selectionLeftUnits && pt.x <= self.selectionRightUnits{
            let scx : CGFloat = (self.selectionRight - self.selectionLeft) / (self.selectionRightUnits - self.selectionLeftUnits)
            
            myPt = CGPoint(x: (pt.x - self.selectionLeftUnits ) * scx + self.selectionLeft,
                y: height - ((pt.y - self.ymin ) * self.sy) - self.bottomMargin)
        }
        else if pt.x > self.selectionRightUnits{
            let scx : CGFloat = (self.leftMargin + deltax - self.selectionRight)/(self.xmax - self.selectionRightUnits)
            
            myPt = CGPoint(x: (pt.x - self.selectionRightUnits ) * scx + self.selectionRight,
                y: height - ((pt.y - self.ymin ) * self.sy) - self.bottomMargin);
        }
        
        if(isnan(myPt.x)){
            myPt.x = 0.0
        }
        
        if(isnan(myPt.y)){
            myPt.y = 0.0
        }
        
        myPt = CGPoint(x: myPt.x - self.leftMargin, y:  myPt.y - self.topMargin)
        return myPt
        
    }
    
    //MARK: Drawing
    
    
    func addContent(){
        let gcv = TMKGraphContentView()
        gcv.translatesAutoresizingMaskIntoConstraints = false
        
        
        self.addSubview(gcv)
        var sCons : NSLayoutConstraint = NSLayoutConstraint(item:gcv, attribute:NSLayoutAttribute.Top, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Top, multiplier:CGFloat(1.0), constant:self.topMargin)
        
        self.addConstraint(sCons)
        
        sCons  = NSLayoutConstraint(item:gcv, attribute:NSLayoutAttribute.Left, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Left, multiplier:CGFloat(1.0), constant:self.leftMargin)
        
        self.addConstraint(sCons)
        
        sCons  = NSLayoutConstraint(item:gcv, attribute:NSLayoutAttribute.Right, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Right, multiplier:CGFloat(1.0), constant:-self.rightMargin)
        
        self.addConstraint(sCons)
        
        sCons  = NSLayoutConstraint(item:gcv, attribute:NSLayoutAttribute.Bottom, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Bottom, multiplier:CGFloat(1.0), constant:-self.bottomMargin)
        
        self.addConstraint(sCons)
        
        self.graphContent = gcv
    }
    
    
    // Parametritzar els valors en funcio del tipus de variable presentt
    func addSlider()
    {
        
        let sl = UISlider()
        sl.minimumValue = 1.0
        sl.maximumValue = 10.0
        sl.value = 1.0
        sl.continuous = true
        
        
        let leftImage = UIImage(named:"rough_32")
        let rightImage = UIImage(named:"smooth_32")
        
        sl.minimumValueImage = leftImage
        sl.maximumValueImage = rightImage
        
        sl.translatesAutoresizingMaskIntoConstraints = false
        sl.addTarget(self, action:"sliderMoved:", forControlEvents:UIControlEvents.ValueChanged)
        
        self.addSubview(sl)
        
        var sCons  = NSLayoutConstraint(item:sl, attribute:NSLayoutAttribute.Left, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Left, multiplier:1.0, constant:self.leftMargin)
        
        self.addConstraint(sCons)
        
        sCons  = NSLayoutConstraint(item:sl, attribute:NSLayoutAttribute.Right, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Right, multiplier:1.0, constant:-self.rightMargin)
        
        self.addConstraint(sCons)
        
        sCons  = NSLayoutConstraint(item:sl, attribute:NSLayoutAttribute.Height,  relatedBy:NSLayoutRelation.Equal, toItem:nil, attribute:NSLayoutAttribute.NotAnAttribute, multiplier:1.0, constant:32.0)
        
        
        self.addConstraint(sCons)
        
        sCons  = NSLayoutConstraint(item:sl, attribute:NSLayoutAttribute.Bottom ,relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Bottom, multiplier:1.0, constant:-10.0)
        
        self.addConstraint(sCons)
        
        self.filterSlider = sl
    }
    
    
    func addGearButton()
    {
        let but = UIButton(type: UIButtonType.Custom)
        but.translatesAutoresizingMaskIntoConstraints = false
        
        let clearImage = UIImage(named:"nakedGear_32")
        but.setImage(clearImage, forState:UIControlState.Normal)
        
        
        //    [but addTarget:self action:@selector(switchyValue:) forControlEvents:UIControlEventTouchUpInside];
        
        self.addSubview(but)
        
        but.addTarget(self, action:"openGear:", forControlEvents:UIControlEvents.TouchUpInside)
        
        
        
        var sCons = NSLayoutConstraint(item:but, attribute:NSLayoutAttribute.Top, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Top, multiplier:1.0, constant:5)
        
        self.addConstraint(sCons)
        
        
        sCons = NSLayoutConstraint(item:but, attribute:NSLayoutAttribute.Right, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Right, multiplier:1.0, constant:0.0)
        
        self.addConstraint(sCons)
        
    }
    
    func addXAxeButton()
    {
        if let ds = self.dataSource{
            
            let iax = self.xAxis
            let lab = ds.nameOfXAxis(iax)
            
            let but = UIButton(type:UIButtonType.RoundedRect)
            but.translatesAutoresizingMaskIntoConstraints = false
            
            but.setTitle(lab, forState:UIControlState.Normal)
            if let titLab = but.titleLabel{
                titLab.font = UIFont.boldSystemFontOfSize(15)
            }
            but.setTitleColor(self.activeColor, forState:UIControlState.Normal)
            but.setTitleColor(self.highlightColor, forState:UIControlState.Highlighted)
            
            but.addTarget(self, action:"switchHorizontalAxe:", forControlEvents:UIControlEvents.TouchUpInside)
            
            self.addSubview(but)
            
            var sCons = NSLayoutConstraint(item:but, attribute:NSLayoutAttribute.Height, relatedBy:NSLayoutRelation.Equal, toItem:nil, attribute:NSLayoutAttribute.NotAnAttribute, multiplier:1.0, constant:21)
            
            
            but.addConstraint(sCons)
            
            sCons = NSLayoutConstraint(item:but, attribute:NSLayoutAttribute.Left, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Right, multiplier:1.0, constant:-self.rightMargin+2.0)
            
            self.addConstraint(sCons)
            
            sCons = NSLayoutConstraint(item:but, attribute:NSLayoutAttribute.Right, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Right, multiplier:1.0, constant:-1.0)
            
            self.addConstraint(sCons)
            
            sCons = NSLayoutConstraint(item:but, attribute:NSLayoutAttribute.CenterY, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Bottom, multiplier:1.0 ,constant:-self.bottomMargin)
            
            self.addConstraint(sCons)
            
            self.xAxisButton = but
        }
    }
    
    // Ad button for switching y Value
    func addyValueButton(){
        if let ds = self.dataSource {
            let iax = self.yValue
            let lab = ds.nameOfValue(iax)
            
            
            let but = UIButton(type:UIButtonType.RoundedRect)
            but.translatesAutoresizingMaskIntoConstraints = false
            
            but.setTitle(lab, forState:UIControlState.Normal)
            if let lb = but.titleLabel{
                lb.font = UIFont.boldSystemFontOfSize(15)
            }
            but.setTitleColor(self.activeColor, forState:UIControlState.Normal)
            but.setTitleColor(self.highlightColor,  forState:UIControlState.Highlighted)
            //[but setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5]];
            
            but.addTarget(self, action:"switchyValue:", forControlEvents:UIControlEvents.TouchUpInside)
            
            self.addSubview(but)
            
            
            
            var sCons = NSLayoutConstraint(item:but, attribute:NSLayoutAttribute.Height, relatedBy:NSLayoutRelation.Equal, toItem:nil, attribute:NSLayoutAttribute.NotAnAttribute, multiplier:1.0, constant:21)
            
            but.addConstraint(sCons)
            
            sCons = NSLayoutConstraint(item:but, attribute:NSLayoutAttribute.CenterX, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Left, multiplier:1.0, constant:self.leftMargin)
            
            self.addConstraint(sCons)
            
            
            sCons = NSLayoutConstraint(item:but, attribute:NSLayoutAttribute.Bottom, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Top, multiplier:1.0, constant:self.topMargin-1.0)
            
            self.addConstraint(sCons)
            
            self.yValueButton = but
        }
    }
    
    
    func addInfoField()
    {
        
        var tf = UILabel()
        
        tf.textColor = UIColor.whiteColor()
        tf.backgroundColor = UIColor.clearColor()
        tf.translatesAutoresizingMaskIntoConstraints = false
        
        //NSFont *theFont = [[NSFont fontWithName:@"Helvetica Neue Ultra Light" size:12] screenFontWithRenderingMode:NSFontIntegerAdvancementsRenderingMode];
        
        tf.font = UIFont.systemFontOfSize(12)
        tf.adjustsFontSizeToFitWidth = true
        
        self.addSubview(tf)
        
        var sCons = NSLayoutConstraint(item:tf, attribute:NSLayoutAttribute.Height, relatedBy:NSLayoutRelation.Equal, toItem:nil, attribute:NSLayoutAttribute.NotAnAttribute, multiplier:1.0 ,constant:17)
        
        tf.addConstraint(sCons)
        
        sCons = NSLayoutConstraint(item:tf, attribute:NSLayoutAttribute.Left, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Left, multiplier:1.0, constant:self.leftMargin + 50.0)
        
        self.addConstraint(sCons)
        
        
        sCons = NSLayoutConstraint(item:tf, attribute:NSLayoutAttribute.Right, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.CenterX, multiplier:1.0, constant:-10.0)
        
        self.addConstraint(sCons)
        
        sCons = NSLayoutConstraint(item:tf, attribute:NSLayoutAttribute.Top, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Top, multiplier:1.0, constant:7.0)
        
        self.addConstraint(sCons)
        
        
        self.infoField = tf
        
        tf = UILabel()
        
        tf.textColor = UIColor.whiteColor()
        tf.backgroundColor = UIColor.clearColor()
        tf.translatesAutoresizingMaskIntoConstraints = false
        
        
        tf.font = UIFont.systemFontOfSize(12)
        tf.textAlignment = NSTextAlignment.Right
        
        //[tf setFont:[NSFont systemFontOfSize:10]];
        
        tf.adjustsFontSizeToFitWidth = true
        
        self.addSubview(tf)
        
        sCons = NSLayoutConstraint(item:tf, attribute:NSLayoutAttribute.Height, relatedBy:NSLayoutRelation.Equal, toItem:nil, attribute:NSLayoutAttribute.NotAnAttribute, multiplier:1.0, constant:17)
        
        tf.addConstraint(sCons)
        
        //   sCons = [NSLayoutConstraint constraintWithItem:tf attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:10.0];
        
        sCons = NSLayoutConstraint(item:tf, attribute:NSLayoutAttribute.Left, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Left, multiplier:1.0, constant:self.leftMargin + 50.0)
        
        
        self.addConstraint(sCons)
        
        
        sCons = NSLayoutConstraint(item:tf, attribute:NSLayoutAttribute.Right, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Right, multiplier:1.0, constant: -self.rightMargin)
        
        self.addConstraint(sCons)
        
        sCons = NSLayoutConstraint(item:tf, attribute:NSLayoutAttribute.Top, relatedBy:NSLayoutRelation.Equal, toItem:self, attribute:NSLayoutAttribute.Top, multiplier:1.0, constant:7.0)
        
        self.addConstraint(sCons)
        
        
        self.infoSelField = tf
        
    }
    
    
    override func drawRect(dirtyRect : CGRect){
        // Get the Context
        
        self.recomputeSelectionUnits()
        self.graphContent.setNeedsDisplay()
        let aContext = UIGraphicsGetCurrentContext()
        
        let font = UIFont(name: "Helvetica", size:10.0)
        let fmt = NSNumberFormatter()
        fmt.numberStyle = NSNumberFormatterStyle.DecimalStyle
        fmt.maximumFractionDigits = 0
        
        CGContextSaveGState(aContext)
        
        let backColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.6)
        backColor.setFill()
        var bbox = UIBezierPath(rect: self.bounds)
        bbox.fill()
        
        // El fons del gràfic es mes opac per que es vegi millor.
        
        // Si tenim clampDown la zona mes fosca es la clamped
        
        //    if(self.clampDown)
        //    {
        //        backColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.7];
        //        [backColor setFill];
        //        CGRect rbox = CGRectMake(self.selectionLeft, self.topMargin, self.selectionRight-self.selectionLeft, self.bounds.size.height-self.topMargin-self.bottomMargin);
        //
        //        bbox = [UIBezierPath bezierPathWithRect:rbox];
        //        [bbox fill];
        //    }
        //    else{
        //        backColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.7];
        //        [backColor setFill];
        //        CGRect rbox = CGRectMake(self.leftMargin, self.topMargin, self.bounds.size.width-self.leftMargin-self.rightMargin, self.bounds.size.height-self.topMargin-self.bottomMargin);
        //
        //        bbox = [UIBezierPath bezierPathWithRect:rbox];
        //        [bbox fill];
        //    }
        
        
        CGContextRestoreGState(aContext)
        
        
        CGContextSaveGState(aContext)
        
        
        // Draw Rect
        
        let borderRect = CGRectMake(self.leftMargin,
            self.topMargin,
            self.bounds.size.width - self.leftMargin - self.rightMargin,
            self.bounds.size.height - self.bottomMargin - self.topMargin)
        
        bbox = UIBezierPath(rect: borderRect)
        UIColor.whiteColor().set()
        bbox.lineWidth = 1.0
        
        bbox.stroke()
        CGContextRestoreGState(aContext)
        
        
        self.computeDataForSeries()
        
        
        
        //   CGFloat deltax = self.bounds.size.width - self.leftMargin - self.rightMargin;
        let height = self.bounds.size.height
        
        let step : CGFloat = self.exactNumber(20.0/self.sy)  // Amplada en unitats naturals de les divisions
        let step0 : CGFloat = floor(self.ymin / step) * step  // Primer  Dibuixar
        
        
        // Draw coordinate horizontal lines
        
        CGContextSaveGState(aContext)
        
        UIColor.whiteColor().set()
        
        var j : Int  = Int(floor(self.ymin / step))
        
        var firstLine = true
        
        for var y : CGFloat = step0; y < self.ymax; y = y + step {
            
            if y > self.ymin{
                let s1  = Int(y*10.0)
                let ss = Int(step * 50.0)
                
                if(s1 % ss) == 0 || firstLine || y+step > self.ymax{
                    let bz = UIBezierPath()
                    
                    bz.moveToPoint(CGPointMake(self.leftMargin-5.0, height - ((y - self.ymin)*self.sy)-self.bottomMargin))
                    bz.addLineToPoint(CGPointMake(self.leftMargin, height - ((y - self.ymin)*self.sy)-self.bottomMargin))
                    bz.lineWidth = 1.0
                    bz.stroke()
                    
                    
                    if (y - floor(y)) >= 0.1 {
                        fmt.maximumFractionDigits = 1
                    }
                    else{
                        fmt.maximumFractionDigits = 0
                    }
                    let lab = fmt.stringFromNumber(y)!
                    
                    let attr : [String : AnyObject] = NSDictionary(objects: NSArray(objects:font!, UIColor.whiteColor()) as [AnyObject],
                        forKeys: NSArray(objects:NSFontAttributeName, NSForegroundColorAttributeName) as! [NSCopying]) as! [String : AnyObject]
                    
                    
                    let w = lab.sizeWithAttributes(attr)
                    
                    //[lab sizeWithFont:font];
                    
                    lab.drawAtPoint(CGPointMake(self.leftMargin-8.0-w.width, height-5.0 - ((y - self.ymin)*self.sy)-self.bottomMargin), withAttributes:attr)
                    //  [lab drawAtPoint:CGPointMake(self.leftMargin-8.0-w.width, height-5.0 - ((y - self.ymin)*self.sy)-self.bottomMargin) withFont:font];
                    
                    firstLine = false
                    
                }
                else
                {
                    let bz = UIBezierPath()
                    
                    bz.moveToPoint(CGPointMake(self.leftMargin, height - ((y - self.ymin)*self.sy)-self.bottomMargin))
                    bz.addLineToPoint(CGPointMake(self.leftMargin, height - ((y - self.ymin)*self.sy)-self.bottomMargin))
                    bz.lineWidth = 0.5
                    bz.stroke()
                }
                
            }
            
            j++
        }
        
        // Ara hem de fer l'eix de les x. 2 Posibilitats
        
        if self.xAxis == 0 { // Km
            
            //  CGFloat delta = self.xmax-self.xmin;
            
            var km : Int = Int(floor(self.xmin))
            
            if km < 0 {
                km = 0
            }
            
            let delta : CGFloat = self.bounds.size.width / (self.xmax - self.xmin)
            
            var  step : CGFloat = 1.0
            
            step = 30.0 / delta
            
            if step <= 1.0{
                step = 1.0
            }
            else if step <= 5.0{
                step = 5.0
            }
            else if step <= 10.0{
                step = 10.0
            }
            else if step <= 50.0{
                step = 50.0
            }
            else{
                step = 50.0
            }
            
            for var x : CGFloat = CGFloat(km); x < self.xmax; x = x + step {
                if x >= self.xmin{
                    
                    let ptLoc = CGPointMake(x, 0.0)
                    
                    var ptView =  self.viewPointFromTrackPoint(ptLoc)
                    
                    ptView = CGPointMake(ptView.x+self.leftMargin, ptView.y)
                    
                    let lab = fmt.stringFromNumber(x)
                    
                    let attr : [String : AnyObject] = NSDictionary(objects: NSArray(objects:font!, UIColor.whiteColor()) as [AnyObject],
                        forKeys: NSArray(objects:NSFontAttributeName, NSForegroundColorAttributeName) as! [NSCopying]) as! [String : AnyObject]
                    
                    
                    let w = lab!.sizeWithAttributes(attr)
                    
                    ptView.y =  self.bounds.size.height - self.bottomMargin + 9.0
                    ptView.x = ptView.x - w.width/2.0
                    
                    
                    lab!.drawAtPoint(ptView, withAttributes:attr)
                    
                }
            }
            
        }
        else if self.xAxis == 1 {// Minuts de la sortida
            
            var minuts   = Int(floor(self.xmin))
            
            if(minuts < 0){
                minuts = 0
            }
            
            let delta : CGFloat = self.bounds.size.width / (self.xmax - self.xmin)
            
            var step : CGFloat = 1.0
            
            step = 30.0 / delta
            
            if step <= 1.0 {
                step = 1.0
            }
            else if step <= 5.0{
                step = 5.0
            }
            else if step <= 10.0{
                step = 10.0
            }
            else if step <= 50.0{
                step = 50.0
            }
            else{
                step = 50.0
            }
            
            for var x  = CGFloat(minuts); x < self.xmax; x = x + step {
                
                if x >= self.xmin{
                    
                    let ptLoc = CGPointMake(x, 0.0)
                    
                    var ptView =  self.viewPointFromTrackPoint(ptLoc)
                    ptView = CGPointMake(ptView.x+self.leftMargin, ptView.y)
                    
                    // Calculem el format hh:mm
                    
                    let h = Int(floor(x/60.0))
                    let m = Int(floor(x - (CGFloat(h) * 60.0)))
                    
                    let lab = String(format:"%ld:%ld", h, m)
                    
                    let attr : [String : AnyObject] = NSDictionary(objects: NSArray(objects:font!, UIColor.whiteColor()) as [AnyObject],
                        forKeys: NSArray(objects:NSFontAttributeName, NSForegroundColorAttributeName) as! [NSCopying]) as! [String : AnyObject]
                    let w = lab.sizeWithAttributes(attr)
                    
                    ptView.y =  self.bounds.size.height - self.bottomMargin + 9.0
                    ptView.x = ptView.x - w.width / 2.0
                    
                    
                    lab.drawAtPoint(ptView, withAttributes:attr)
                }
            }
        }
        
        
        
        
        CGContextRestoreGState(aContext)
        
    }
    
    //MARK: UTILITIES
    
    func selectionInfo() -> String{
        
        if let ds = self.dataSource {
            if movingLeftSelection{
                
                let p = ds.value(self.yValue, axis: self.xAxis, forX: self.selectionLeftUnits, forSerie:0)
                let un = ds.nameOfValue(self.yValue)
                
                var s0 = String(format: "%4.2f", p.x)
                if self.xAxis == 1{
                    
                    let h = Int(floor(p.x/3600.0)) // Hours
                    let m = Int(floor((p.x - CGFloat(h) * 3600.0) / 60.0))      // Minuts
                    let s = Int(p.x -  CGFloat(h) * 3600.0 -  CGFloat(m) * 60.0) // Segons
                     
                    s0 = String(format:"%ld:%ld:%ld", h, m, s)
                    
                }
                
                let s = String(format: "%4.2f %@ @ %@", p.y, un, s0)
                return s
            }
            else
            {
                let p = ds.value(self.yValue, axis: self.xAxis, forX: self.selectionRightUnits, forSerie:0)
                 let un = ds.nameOfValue(self.yValue)
                
                var s0 = String(format: "%4.2f", p.x)
                if self.xAxis == 1{
                    
                    let h = Int(floor(p.x/3600.0)) // Hours
                    let m = Int(floor((p.x - CGFloat(h) * 3600.0) / 60.0))      // Minuts
                    let s = Int(p.x -  CGFloat(h) * 3600.0 -  CGFloat(m) * 60.0) // Segons
                    
                    
                    s0 = String(format:"%ld:%ld:%ld", h, m, s)
                    
                }
                
                let s = String(format: "%4.2f %@ @ %@", p.y, un, s0)
                return s
            }
            
        }
        
        return "Not Available"
    }
    
    //MARK:  - Interaction, Touches, Taps
    
    override func touchesBegan(touches: Set<UITouch>,  withEvent event:UIEvent?)
    {
        
        if touches.count != 1{
            self.oldSelectionLeft = self.selectionLeft
            self.oldSelectionRight = self.selectionRight
            return
        }
        
        let to : UITouch = touches.first!
        
        let myPt = to.locationInView(self)
        
        if myPt.y > self.topMargin && myPt.y < (self.bounds.size.height - self.bottomMargin){
            
            if myPt.x >= self.leftMargin && myPt.x < (self.bounds.size.width  - self.rightMargin){
                
                // Check if it is less than 15 points from left selection
                
                let dleft = fabs(myPt.x - self.selectionLeft)
                let dright = fabs(myPt.x - self.selectionRight)
                
                if dleft < 30.0 || dright < 30.0 {
                    
                    if dleft < dright {
                        
                        movingLeftSelection = true
                        movingRightSelection = false
                        self.oldSelectionLeft = self.selectionLeft
                        self.oldSelectionRight = self.selectionRight
                    }
                    else{
                        movingLeftSelection = false
                        movingRightSelection = true
                        self.oldSelectionLeft = self.selectionLeft
                        self.oldSelectionRight = self.selectionRight
                    }
                }
                firstClick = myPt
            }
        }
        
    }
    
    
    override func touchesMoved(touches: Set<UITouch>,  withEvent event:UIEvent?)
    {
        if touches.count != 1{
            // Recover Selections
            
            self.selectionLeft = self.oldSelectionLeft
            self.selectionRight = self.oldSelectionRight
            self.recomputeSelectionUnits()
            movingRightSelection = false
            movingLeftSelection = false
            
            if movingLeftSelection{
                self.infoField.text = self.selectionInfo()
            }else {
                self.infoSelField.text = self.selectionInfo()
            }
            self.graphContent.setNeedsDisplay()
            return
        }
        
        if !movingLeftSelection && !movingRightSelection {
            return
        }
        
        let to = touches.first!
        let myPt = to.locationInView(self)
        
        if movingLeftSelection{
            var newVal  = CGFloat(self.oldSelectionLeft + myPt.x - firstClick.x)
            
            if(newVal > self.selectionRight-9.0){
                newVal = self.selectionRight-9.0
            }
            
            if(newVal < self.leftMargin){
                newVal = self.leftMargin
            }
            
            self.selectionLeft = newVal
            
            if(!self.clampDown){
                self.recomputeSelectionUnits()
            }
            self.infoField.text = self.selectionInfo()
            self.graphContent.setNeedsDisplay()
            
        }
            
        else if movingRightSelection{
            var newVal = CGFloat(self.oldSelectionRight + myPt.x - firstClick.x)
            
            if(newVal < self.selectionLeft+9.0){
                newVal = self.selectionLeft + 9.0
            }
            
            if(newVal > self.bounds.size.width-self.rightMargin){
                newVal = self.bounds.size.width-self.rightMargin
            }
            
            self.selectionRight = newVal
            
            if !self.clampDown {
                self.recomputeSelectionUnits()
            }
            
            self.infoSelField.text = self.selectionInfo()
            self.graphContent.setNeedsDisplay()
            
            
        }
    }
    
    
    override func touchesEnded(touches: Set<UITouch>,  withEvent event:UIEvent?){
        
        if(touches.count != 1){  // Cancel
            
            self.selectionLeft = self.oldSelectionLeft
            self.selectionRight = self.oldSelectionRight
            
            self.recomputeSelectionUnits()
            
            movingLeftSelection = false
            movingRightSelection = false
            
            self.graphContent.setNeedsDisplay()
            return
        }
        
        movingRightSelection = false
        movingLeftSelection = false
        self.updateSelection()
        self.graphContent.setNeedsDisplay()
    }
    
    func updateSelection()
    {
        //[ self.document selectFrom:self.selectionLeftUnits  to:self.selectionRightUnits  axis:self.xAxis];
        
    }
    
    override func touchesCancelled(touches: Set<UITouch>?,  withEvent event:UIEvent?){
        
        movingRightSelection = false
        movingLeftSelection = false
        
        
        self.updateSelection()
        self.infoSelField.text = self.selectionInfo()
        self.setNeedsDisplay()
    }
    
    
    @IBAction func switchHorizontalAxe(src: AnyObject?)
    {
        
        // Estem intentat visualitzar coses que no son tracks
        
        //        tr = self.document.selectedTrack;
        //        var ptLeft = 0
        //        var ptRight = 100
        //
        //    // Obtenim els punts se la seleccio
        //
        //    if(self.xAxis == 0) // Km
        //    {
        //    ptLeft = [tr nearerTrackPointForDist:self.selectionLeftUnits*1000.0];
        //    ptRight=[ tr nearerTrackPointForDist:self.selectionRightUnits*1000.0];
        //    }
        //    else
        //    {
        //    ptLeft = [tr nearerTrackPointForTime:self.selectionLeftUnits*60.0];
        //    ptRight = [tr nearerTrackPointForTime:self.selectionRightUnits*60.0];
        //    }
        //
        if let ds = self.dataSource {
            
            var axe = self.xAxis
            axe = (axe + 1) % ds.numberOfXAxis()
            
            let label = ds.nameOfXAxis(axe)
            self.xAxis = axe
            self.xAxisButton.setTitle(label, forState: UIControlState.Normal)
            
            //             if self.xAxis == 0{ // Km
            //
            //                self.selectionLeftUnits = ((TGLTrackPoint *)[tr.data objectAtIndex:ptLeft]).distanciaOrigen/1000.0;
            //                self.selectionRightUnits = ((TGLTrackPoint *)[tr.data objectAtIndex:ptRight]).distanciaOrigen/1000.0;
            //            }
            //            else{
            //
            //                self.selectionLeftUnits = ((TGLTrackPoint *)[tr.data objectAtIndex:ptLeft]).tempsOrigen/60.0;
            //                self.selectionRightUnits = ((TGLTrackPoint *)[tr.data objectAtIndex:ptRight]).tempsOrigen/60.0;
            //            }
            
            self.computeDataForSeries()
            self.recomputeSelectionPosition()
            self.infoSelField.text = self.selectionInfo()
            
            self.setNeedsDisplay()
        }
        
    }
    
    @IBAction func switchyValue(src : AnyObject?)
    {
        if let ds = self.dataSource{
            
            var axe = self.yValue
            
            axe = (axe + 1) % ds.numberOfValues()
            
            self.setanYValue(axe)
            
        }
        
    }
    
    
    func swipeLeft(gesture: UIGestureRecognizer){
        if let ds = self.dataSource{
            
            var axe = self.yValue
            
            axe = (axe - 1)
            
            if axe < 0 {
                axe = ds.numberOfValues()-1
            }
            
            self.setanYValue(axe)
        }
    }
    func swipeRight(gesture: UIGestureRecognizer){
        self.switchyValue(nil)
    }
    
    func setanYValue(axe:Int){
        if let ds = self.dataSource{
            let label = ds.nameOfValue(axe)
            self.yValue = axe
            self.yValueButton.setTitle(label, forState:UIControlState.Normal)
            
            //            TGLTrack *tr = self.document.selectedTrack;
            //
            //
            //            if(axe == 0)
            //            {
            //            [self.filterSlider setHidden:NO];
            //            [self.filterSlider setValue:tr.filterHeightLevel];
            //            }
            //            else if(axe == 1)
            //            {
            //            [self.filterSlider setHidden:NO];
            //            [self.filterSlider setValue:tr.filterBpmLevel];
            //            }
            //
            //            else if(axe == 2)
            //            {
            //            [self.filterSlider setHidden:NO];
            //            [self.filterSlider setValue:tr.filterSpeedLevel];
            //            }
            //
            //            else
            //self.filterSlider.hidden = true
            
        }
        
        self.computeDataForSeries()
        self.recomputeSelectionPosition()
        
        self.setNeedsDisplay()
        
        
    }
    
    
    
    //MARK: Disabled
    
    
    
    
    /* Std Filterig is not OK here.
    
    func openGear(src : AnyObject){
    
    let hud = self.getHudView]()
    hud.openGear()
    
    }
    
    func getHudView() ->TMKHudView? {
    
    var v : UIView? = self
    
    while v != nil && !v.isKindOfClass(TMKHudView) {
    v = v!.superview
    }
    
    
    return v as? TMKHudView
    
    }
    */
    
    @IBAction func sliderMoved(src : AnyObject?){
        
        //    let v = floor(self.filterSlider.value)
        //
        //    // NSString *vs = [NSString stringWithFormat:@"%ld", (long)v];
        //
        //    self.filterTracks(v)
        //
        //    if !self.filterSlider.tracking{
        //    dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //
        //    let userInfo = ["WAYPOINTS":"YES", "CENTER":"NO"]
        //    letnotification = NSNotification(name: kTrackUpdatedNotification, object: nil, userInfo: userInfo)
        //    });
        //    
        //    }
    }
    
    
    
    
    
}
