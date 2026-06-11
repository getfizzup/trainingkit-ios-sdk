//
//  GoogleCastManager+RemoteMediaClientListener.swift
//  SampleApp
//

import CoreMedia
import GoogleCast
import TrainingKit

extension GoogleCastManager: GCKRemoteMediaClientListener {
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        let time = CMTime(seconds: client.approximateStreamPosition(), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let hasMedia = mediaStatus?.mediaInformation?.contentURL != nil

        var state: RemoteMediaPlayerState?
        if let value = mediaStatus?.playerState {
            // Actually mapping is equal between RemoteMediaPlayerState and GCKMediaPlayerState.
            state = RemoteMediaPlayerState(rawValue: value.rawValue)
        }

        delegate?.remoteSessionCanStartMedia()

        delegate?.remoteSessionDidUpdateMediaStatus(time: time, hasMedia: hasMedia, state: state)
    }
}
