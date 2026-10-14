import Foundation

/// Retrospective onset from the first continuously covered five-minute sleep run.
/// Wake, unknown labels, gaps, and overlaps reset confirmation. Window identity stays with the caller.
public enum SleepOnsetEstimate {
    public static func timestamp(stages: [StageSegment]) -> Int? {
        var runStart: Int?
        var runEnd: Int?
        for segment in stages.sorted(by: { $0.start < $1.start }) where segment.end > segment.start {
            guard ["light", "deep", "rem"].contains(segment.stage) else {
                runStart = nil
                runEnd = nil
                continue
            }
            if let runEnd, segment.start != runEnd { runStart = nil }
            if runStart == nil { runStart = segment.start }
            runEnd = segment.end
            if let runStart, segment.end - runStart >= 300 { return runStart }
        }
        return nil
    }
}
