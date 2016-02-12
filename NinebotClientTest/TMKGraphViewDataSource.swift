//
//  TMKGraphViewDataSource.swift
//  HealthInquire
//
//  Created by Francisco Gorina Vanrell on 9/10/15.
//  Copyright © 2015 Paco Gorina. All rights reserved.
//

import Foundation
import UIKit


protocol TMKGraphViewDataSource {
    
    func numberOfSeries() -> Int
    func numberOfPointsForSerie(serie : Int, value : Int) -> Int
    func styleForSerie(serie : Int) -> Int
    func colorForSerie(serie : Int) -> UIColor
    func offsetForSerie(serie : Int) -> CGPoint
    func value(value : Int, axis: Int,  forPoint point: Int,  forSerie serie:Int) -> CGPoint
    func value(value : Int, axis: Int,  forX x:CGFloat,  forSerie serie:Int) -> CGPoint
    func numberOfWaypointsForSerie(serie: Int) -> Int
    func valueForWaypoint(point : Int,  axis:Int,  serie: Int) -> CGPoint
    func isSelectedWaypoint(point: Int, forSerie serie:Int) -> Bool
    func isSelectedSerie(serie: Int) -> Bool
    func numberOfXAxis() -> Int
    func nameOfXAxis(axis: Int) -> String
    func numberOfValues() -> Int
    func nameOfValue(value: Int) -> String
    func numberOfPins() -> Int
    func valueForPin(point:Int, axis:Int) -> CGPoint
    func isSelectedPin(pin: Int) -> Bool
    func pointForX(x: Double, value: Int) -> Int
    func minMaxForSerie(serie : Int, value: Int) -> (CGFloat, CGFloat)
}