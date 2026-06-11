//
//  GoogleCastManager+SessionManagerListener.swift
//  SampleApp
//

import CoreMedia
import GoogleCast
import TrainingKit

extension GoogleCastManager: GCKSessionManagerListener {
    // MARK: Session start

    func sessionManager(_ sessionManager: GCKSessionManager, didStart _: GCKSession) {
        guard let client = sessionManager.currentSession?.remoteMediaClient else { return }
        delegate?.remoteSessionDidStart()

        // Session started. Add client to receive media updates.
        client.add(self)
    }

    func sessionManager(_: GCKSessionManager, didStart session: GCKCastSession) {
        // Cast session started. Add channel to communicate with receiver.
        session.add(channel)
    }

    // MARK: Session suspend

    func sessionManager(_: GCKSessionManager, didSuspend _: GCKSession, with _: GCKConnectionSuspendReason) {
        delegate?.remoteSessionDidEnd(at: lastKnownTime)
    }

    // MARK: Session resume

    func sessionManager(_: GCKSessionManager, didResumeSession session: GCKSession) {
        guard let client = session.remoteMediaClient else { return }
        delegate?.remoteSessionDidResume()

        client.add(self) // Session resumed. Add client to receive media updates.
    }

    func sessionManager(_: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        // Cast session resumed. Add channel to communicate with receiver.
        session.add(channel)
    }

    // MARK: Session end

    func sessionManager(_ sessionManager: GCKSessionManager, willEnd _: GCKSession) {
        guard let client = sessionManager.currentSession?.remoteMediaClient else { return }

        if let playingID = client.mediaStatus?.mediaInformation?.contentURL, playingID == video.url {
            lastKnownTime = CMTime(seconds: client.approximateStreamPosition(), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        }
    }

    func sessionManager(_: GCKSessionManager, didEnd _: GCKSession, withError _: Error?) {
        delegate?.remoteSessionDidEnd(at: lastKnownTime)
    }

    func sessionManager(_: GCKSessionManager, didEnd _: GCKCastSession, withError _: Error?) {
        delegate?.remoteSessionDidEnd(at: lastKnownTime)
    }
}
