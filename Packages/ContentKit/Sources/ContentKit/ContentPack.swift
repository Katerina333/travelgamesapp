import Foundation
import CoreKit

/// Versioned JSON content pack keyed by locale × age band (§4.3, §4.4).
/// New content ships without touching game code.
public struct ContentPack: Codable, Sendable {
    public struct Entry: Codable, Sendable {
        /// Primary text: bingo item, charades word, trivia question, or the
        /// first option of a Would-You-Rather dilemma.
        public let text: String
        /// Age bands this entry suits. Empty/nil = all bands.
        public let bands: [AgeBand]?
        /// Forbidden words for Taboo-style games; extra payload per game type.
        public let forbidden: [String]?
        /// Second option for Would-You-Rather dilemmas.
        public let optionB: String?
        /// Answer choices for trivia questions.
        public let choices: [String]?
        /// Index into `choices` of the correct trivia answer.
        public let answer: Int?

        public init(
            text: String,
            bands: [AgeBand]? = nil,
            forbidden: [String]? = nil,
            optionB: String? = nil,
            choices: [String]? = nil,
            answer: Int? = nil
        ) {
            self.text = text
            self.bands = bands
            self.forbidden = forbidden
            self.optionB = optionB
            self.choices = choices
            self.answer = answer
        }
    }

    public let id: String
    public let gameID: String
    public let locale: String
    public let version: Int
    public let entries: [Entry]

    public init(id: String, gameID: String, locale: String, version: Int, entries: [Entry]) {
        self.id = id
        self.gameID = gameID
        self.locale = locale
        self.version = version
        self.entries = entries
    }

    /// Entries usable at or below the given band cap (§1.5 youngest-in-round)
    /// — an entry qualifies if it suits the cap band itself.
    public func entries(cappedAt band: AgeBand) -> [Entry] {
        entries.filter { entry in
            guard let bands = entry.bands, !bands.isEmpty else { return true }
            return bands.contains(band)
        }
    }
}

/// Loads packs from a bundle with regional fallback (en-GB → en, fr-CA → fr-FR → fr).
public enum PackLoader {
    /// Fallback chain per §4.4: exact regional file first, then language root.
    public static func localeFallbackChain(for locale: String) -> [String] {
        var chain = [locale]
        let language = locale.split(separator: "-").first.map(String.init) ?? locale
        // French Canada prefers France French content before generic French.
        if locale == "fr-CA" { chain.append("fr-FR") }
        if language != locale { chain.append(language) }
        return chain
    }

    /// Loads from ContentKit's bundled packs, normalizing "en_US" → "en-US",
    /// with a final fallback to the English base pack.
    public static func loadBundledPack(
        gameID: String,
        localeIdentifier: String = Locale.current.identifier
    ) -> ContentPack? {
        let normalized = localeIdentifier.replacingOccurrences(of: "_", with: "-")
        return loadPack(gameID: gameID, locale: normalized, in: .module)
            ?? loadPack(gameID: gameID, locale: "en", in: .module)
    }

    public static func loadPack(gameID: String, locale: String, in bundle: Bundle) -> ContentPack? {
        for candidate in localeFallbackChain(for: locale) {
            if let url = bundle.url(forResource: "\(gameID)_\(candidate)", withExtension: "json"),
               let data = try? Data(contentsOf: url),
               let pack = try? JSONDecoder().decode(ContentPack.self, from: data) {
                return pack
            }
        }
        return nil
    }
}
