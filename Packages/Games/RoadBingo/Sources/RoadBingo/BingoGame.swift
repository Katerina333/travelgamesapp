import SwiftUI
import CoreKit
import GameEngine

/// Spotting bingo — one implementation, two manifests: Smart Road Bingo (car)
/// and Cabin Bingo (plane variant, §1.4). Content comes from the pack whose
/// gameID matches the manifest id.
public struct BingoGame: TripGame {
    public let manifest: GameManifest

    public static func roadBingo() -> BingoGame {
        BingoGame(manifest: GameManifest(
            id: "roadbingo",
            nameKey: "game.roadbingo.name",
            icon: "binoculars.fill",
            minPlayers: 1,
            ageBands: .preschool ... .adult,
            driverSafe: false, // board-tapping excluded for the driver (§1.2)
            screenLevel: .minimal,
            travelModes: [.car],
            contentScope: .youngestInRound
        ))
    }

    public static func cabinBingo() -> BingoGame {
        BingoGame(manifest: GameManifest(
            id: "cabinbingo",
            nameKey: "game.cabinbingo.name",
            icon: "airplane",
            minPlayers: 1,
            ageBands: .preschool ... .adult,
            driverSafe: true, // no driver concept on planes (§1.4)
            screenLevel: .minimal,
            travelModes: [.plane],
            contentScope: .youngestInRound
        ))
    }

    public func makeSetupView(session: GameSession) -> AnyView {
        AnyView(BingoBoardView(session: session, packGameID: manifest.id))
    }

    public func makePlayView(session: GameSession) -> AnyView {
        AnyView(BingoBoardView(session: session, packGameID: manifest.id))
    }
}
