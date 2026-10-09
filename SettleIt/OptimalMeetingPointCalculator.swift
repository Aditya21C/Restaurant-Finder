//
//  OptimalMeetingPointCalculator.swift
//  SettleIt
//
//  Created by Mayukh Baidya on 10/07/25.
//

import Foundation
import CoreLocation

// This struct is now defined here to make the file self-contained.
struct Coordinate {
    var latitude: Double
    var longitude: Double
}

struct OptimalMeetingPointCalculator {
    
    /// A helper struct to represent a circle during calculations.
    private struct Circle {
        let center: Coordinate
        let radiusSq: Double // Using squared radius to avoid costly square roots
    }

    /// Calculates the center of the smallest circle that encloses all people.
    static func calculate(for people: [PersonInput]) -> Coordinate? {
        let validPeople = people.filter { $0.latitude != nil && $0.longitude != nil }
        guard !validPeople.isEmpty else { return nil }
        
        // Use a mutable copy of the points, which we will shuffle.
        var points = validPeople.map { Coordinate(latitude: $0.latitude!, longitude: $0.longitude!) }.shuffled()
        
        // Handle trivial cases
        if points.isEmpty { return nil }
        if points.count == 1 { return points[0] }
        
        // Start with a circle defined by the first two points.
        var circle = circleFrom(p1: points[0], p2: points[1])
        
        // Iteratively expand the circle to include all other points.
        for i in 2..<points.count {
            let p = points[i]
            // If the point is already inside the current circle, continue.
            if distanceSq(from: p, to: circle.center) <= circle.radiusSq {
                continue
            }
            
            // If the point is outside, it must be on the boundary of the new smallest circle.
            // We re-calculate the circle based on this new point and the previous points.
            circle = circleWithPointOnBoundary(Array(points.prefix(i)), boundaryPoint: p)
        }
        
        // Debug: Print final center coordinate
        print("Optimal Center Coordinate: \(circle.center.latitude), \(circle.center.longitude)")
        
        return circle.center
    }

    // MARK: - Private Geometric Helper Functions

    private static func circleWithPointOnBoundary(_ points: [Coordinate], boundaryPoint q1: Coordinate) -> Circle {
        var circle = circleFrom(p1: points[0], p2: q1)
        
        for i in 1..<points.count {
            let p = points[i]
            if distanceSq(from: p, to: circle.center) <= circle.radiusSq {
                continue
            }
            circle = circleWithTwoPointsOnBoundary(Array(points.prefix(i)), q1: q1, q2: p)
        }
        return circle
    }

    private static func circleWithTwoPointsOnBoundary(_ points: [Coordinate], q1: Coordinate, q2: Coordinate) -> Circle {
        var circle = circleFrom(p1: q1, p2: q2)
        
        for p in points {
            if distanceSq(from: p, to: circle.center) <= circle.radiusSq {
                continue
            }
            let c1 = circleFrom(p1: q1, p2: p, p3: q2)
            let c2 = circleFrom(p1: q2, p2: p, p3: q1)
            circle = (c1.radiusSq < c2.radiusSq) ? c1 : c2
        }
        return circle
    }

    private static func distanceSq(from p1: Coordinate, to p2: Coordinate) -> Double {
        let latDiff = p1.latitude - p2.latitude
        let lonDiff = p1.longitude - p2.longitude
        return latDiff * latDiff + lonDiff * lonDiff
    }

    private static func circleFrom(p1: Coordinate, p2: Coordinate) -> Circle {
        let centerLat = (p1.latitude + p2.latitude) / 2
        let centerLon = (p1.longitude + p2.longitude) / 2
        let center = Coordinate(latitude: centerLat, longitude: centerLon)
        return Circle(center: center, radiusSq: distanceSq(from: p1, to: center))
    }

    private static func circleFrom(p1: Coordinate, p2: Coordinate, p3: Coordinate) -> Circle {
        let d = 2 * (p1.latitude * (p2.longitude - p3.longitude) +
                     p2.latitude * (p3.longitude - p1.longitude) +
                     p3.latitude * (p1.longitude - p2.longitude))

        if abs(d) < 1e-10 {
            // Handle collinear or near-collinear case by returning max-diameter circle
            let d12 = distanceSq(from: p1, to: p2)
            let d13 = distanceSq(from: p1, to: p3)
            let d23 = distanceSq(from: p2, to: p3)
            if d12 >= d13 && d12 >= d23 {
                return circleFrom(p1: p1, p2: p2)
            } else if d13 >= d12 && d13 >= d23 {
                return circleFrom(p1: p1, p2: p3)
            } else {
                return circleFrom(p1: p2, p2: p3)
            }
        }

        let p1_sq = p1.latitude * p1.latitude + p1.longitude * p1.longitude
        let p2_sq = p2.latitude * p2.latitude + p2.longitude * p2.longitude
        let p3_sq = p3.latitude * p3.latitude + p3.longitude * p3.longitude

        // ✅ Correct: Latitude and Longitude are now not swapped
        let centerLat = (p1_sq * (p2.longitude - p3.longitude) +
                         p2_sq * (p3.longitude - p1.longitude) +
                         p3_sq * (p1.longitude - p2.longitude)) / d

        let centerLon = (p1_sq * (p3.latitude - p2.latitude) +
                         p2_sq * (p1.latitude - p3.latitude) +
                         p3_sq * (p2.latitude - p1.latitude)) / d

        let center = Coordinate(latitude: centerLat, longitude: centerLon)
        return Circle(center: center, radiusSq: distanceSq(from: p1, to: center))
    }
}
