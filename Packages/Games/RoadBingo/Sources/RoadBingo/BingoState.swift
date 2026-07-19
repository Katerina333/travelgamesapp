import Foundation
import CoreKit
import ContentKit

/// Full bingo round state — serialized into `GameSessionRecord.resumeState`
/// after every move so a force-quit resumes the identical board (§2.2).
struct BingoState: Codable, Equatable {
    var gridSize: Int
    var items: [String]
    /// Cell index → traveler who spotted it.
    var marks: [Int: UUID] = [:]

    var isComplete: Bool { !items.isEmpty && marks.count == items.count }

    /// Builds a board from the age-capped pack: 3×3 for preschool rounds,
    /// 4×4 otherwise (falls back to 3×3 if the pack is small).
    static func generate(from pack: ContentPack, band: AgeBand) -> BingoState {
        let texts = pack.entries(cappedAt: band).map(\.text).shuffled()
        let size = band == .preschool ? 3 : 4
        if texts.count >= size * size {
            return BingoState(gridSize: size, items: Array(texts.prefix(size * size)))
        }
        return BingoState(gridSize: 3, items: Array(texts.prefix(9)))
    }
}
