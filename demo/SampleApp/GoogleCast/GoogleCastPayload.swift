//
//  GoogleCastPayload.swift
//  SampleApp
//

import Foundation

struct GoogleCastPayload: Codable {
    var progression: CastProgression
    /// Layer used for Pause state.
    var overlay: CastLayer
    /// Layer used to present a prompt.
    var prompt: CastLayer

    init() {
        progression = CastProgression()
        overlay = CastLayer()
        prompt = CastLayer()
    }

    var dictionaryValue: [AnyHashable: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [AnyHashable: Any]
    }
}

struct CastProgression: Codable {
    /// Duration string displayed on top left of progress bar.
    var duration: String?
    /// Completion between 0 and 1 of the bottom progress bar. Provide 0 or null to hide the progress track.
    var progress: Double?

    enum CodingKeys: String, CodingKey {
        case duration = "duration_string"
        case progress = "value"
    }
}

struct CastLayer: Codable {
    /// Flag that determines if the layer should be displayed on top of the player.
    var visible = false
    /// Title to be displayed on the layer.
    var title: String?
    /// Caption to be displayed on the layer.
    var caption: String?
}
