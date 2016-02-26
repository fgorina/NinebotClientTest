//
//  TMKGraphViewDataSource.swift
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
    func minMaxForSerie(serie : Int, value: Int) -> (CGFloat, CGFloat)
}