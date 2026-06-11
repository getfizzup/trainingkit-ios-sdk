//
//  GoogleCastManager.swift
//  SampleApp
//

import CoreMedia
import Foundation
import GoogleCast
import TrainingKit

class GoogleCastManager: RemoteManager {
    var video: Video
    var metadata: VideoMetadata

    private(set) var channel = GCKCastChannel(namespace: "urn:x-cast:com.yourapp.cast")

    /// Last time reported by a media status update.
    var lastKnownTime: CMTime = .indefinite

    // MARK: -

    override var currentTime: CMTime {
        guard let client = GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient else {
            return .zero
        }
        return CMTime(seconds: client.approximateStreamPosition(), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    }

    override var playerState: RemoteMediaPlayerState {
        guard let state = GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient?.mediaStatus?.playerState else {
            return .unknown
        }

        return RemoteMediaPlayerState(rawValue: state.rawValue) ?? .unknown
    }

    override var delegate: RemoteManagerDelegate? {
        didSet {
            let manager = GCKCastContext.sharedInstance().sessionManager
            let session = manager.currentSession

            guard session != nil, let client = session?.remoteMediaClient else { return }

            // Add client listener.
            client.add(self) // Session already started. Add client to receive media updates.

            if let castSession = manager.currentCastSession {
                // Add channel listener.
                castSession.add(channel)
            }

            delegate?.remoteSessionDidResume()

            // Trigger some updates.
            client.notifyDidUpdateMetadata()
            client.notifyDidUpdateMediaStatus()
        }
    }

    // MARK: -

    init(video: Video, metadata: VideoMetadata) {
        self.video = video
        self.metadata = metadata
    }

    deinit {
        disconnect()
    }

    // MARK: -

    override func disconnect() {
        let manager = GCKCastContext.sharedInstance().sessionManager
        manager.endSession()
    }

    override func startMedia(at time: CMTime, with mode: WorkoutStateMode) {
        guard mode != .finished else { return }
        guard let client = GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient else {
            return
        }

        // Start media if nothing is playing.
        guard client.mediaStatus?.mediaInformation?.contentURL == nil else {
            return
        }

        // Load media.
        let castMetadata = GCKMediaMetadata()
        if let value = metadata.title { castMetadata.setString(value, forKey: kGCKMetadataKeyTitle) }
        if let value = metadata.subtitle { castMetadata.setString(value, forKey: kGCKMetadataKeySubtitle) }
        if let value = metadata.cover {
            castMetadata.addImage(GCKImage(url: value,
                                           width: Int(metadata.coverSize.width),
                                           height: Int(metadata.coverSize.height)))
        }

        let url = URL(string: video.url.absoluteString)
        guard let mediaURL = url else { return }

        let mediaInfoBuilder = GCKMediaInformationBuilder(contentURL: mediaURL)
        mediaInfoBuilder.streamType = GCKMediaStreamType.buffered
        mediaInfoBuilder.contentType = "application/vnd.apple.mpegurl"
        mediaInfoBuilder.metadata = castMetadata
        let mediaInfo = mediaInfoBuilder.build()

        // Adjust payload following state.
        var payload = GoogleCastPayload()
        payload.overlay.visible = mode != .ongoing

        // Add pause infos if current time is not zero.
        if time != .zero, mode != .paused {
            payload.progression.duration = formatDurations(time.seconds).joined(separator: " / ")
            payload.progression.progress = metadata.relativeProgress(from: time)
        }

        let loadOptions = GCKMediaLoadOptions()
        loadOptions.autoplay = mode != .paused && mode != .launcher
        loadOptions.customData = payload.dictionaryValue
        loadOptions.playPosition = time.seconds

        client.loadMedia(mediaInfo, with: loadOptions)
    }

    override func playMedia() {
        let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient

        var payload = GoogleCastPayload()
        payload.progression.duration = formatDurations(remoteMediaClient?.approximateStreamPosition()).joined(separator: " / ")
        payload.progression.progress = formatProgression(remoteMediaClient?.approximateStreamPosition())
        payload.overlay.visible = false

        remoteMediaClient?.play(withCustomData: payload.dictionaryValue)
    }

    override func pauseMedia(promptTitle: String? = nil, promptCaption: String? = nil) {
        let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient

        var payload = GoogleCastPayload()
        payload.progression.duration = formatDurations(remoteMediaClient?.approximateStreamPosition()).joined(separator: " / ")
        payload.progression.progress = formatProgression(remoteMediaClient?.approximateStreamPosition())
        payload.overlay.visible = true

        if promptTitle != nil {
            payload = GoogleCastPayload()
            payload.overlay.visible = false
            payload.prompt.visible = true
            payload.prompt.title = promptTitle
            payload.prompt.caption = promptCaption
        }

        remoteMediaClient?.pause(withCustomData: payload.dictionaryValue)
    }

    override func seekMedia(to time: CMTime) {
        let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient
        let paused = remoteMediaClient?.mediaStatus?.playerState == .paused

        var payload = GoogleCastPayload()
        payload.progression.duration = formatDurations(time.seconds).joined(separator: " / ")
        payload.progression.progress = formatProgression(time.seconds)
        payload.overlay.visible = paused

        let options = GCKMediaSeekOptions()
        options.interval = time.seconds
        options.relative = false
        options.resumeState = paused ? .pause : .unchanged
        options.customData = payload.dictionaryValue

        remoteMediaClient?.seek(with: options)
    }

    // MARK: -

    private func formatDurations(_ currentTime: TimeInterval?) -> [String] {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        formatter.unitsStyle = .positional

        let range = metadata.timeRange
        guard let time = currentTime else { return [] }
        let currentTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

        // Labels
        var parts: [String] = []
        if let value = formatter.string(from: max((currentTime - range.start).seconds, 0)) { parts.append(value) }
        if let value = formatter.string(from: range.duration.seconds) { parts.append(value) }

        return parts
    }

    private func formatProgression(_ currentTime: TimeInterval?) -> Double? {
        metadata.relativeProgress(from: currentTime)
    }
}
