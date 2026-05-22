//
//  DungeonGeometry.swift
//  GeoShot
//

import CoreGraphics

struct DungeonGeometry {
    /// Split a segment [start..end] by gaps into contiguous segments.
    /// Returns list of (start, end) tuples along the same axis.
    static func getSegments(start: CGFloat, end: CGFloat, gaps: [(CGFloat, CGFloat)]) -> [(CGFloat, CGFloat)] {
        var result: [(CGFloat, CGFloat)] = []
        let sortedGaps = gaps
            .map { (min($0.0, $0.1), max($0.0, $0.1)) }
            .filter { $0.1 > start && $0.0 < end }
            .sorted { $0.0 < $1.0 }

        var current = start
        for (gStart, gEnd) in sortedGaps {
            if gStart > current {
                result.append((current, gStart))
            }
            current = max(current, gEnd)
        }
        if current < end {
            result.append((current, end))
        }
        return result
    }
}
