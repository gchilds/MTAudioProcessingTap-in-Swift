An minimal example of an`MTAudioProcessingTap` audio “tap” in Swift 4.2. The tap itself is not particularly difficult, but the c-callbacks and casts in Swift can take many hours of googling and trawling [stackoverflow](https://stackoverflow.com) (at least for me).

Includes attaching an `MTAudioProcessingTap` to a remote `AVPlayer`, c callbacks in swift, casting self to and from `UnsafeMutableRawPointer`, `MTAudioProcessingTapCreate`, `AVMutableAudioMixInputParameters `.

Limitations: the tap does not seem to work with most remote audio assets. There are zero tracks. It does seem to work with a remote file (maybe content-length is important?).
I've tried waiting for tracks and ready status on the `AVPlayerItem`, but the thing that seems to matter most is the underlying `AVAsset`'s tracks.

**N.B** It's not clear that it's even a good idea to implement your audio tap in Swift. The documentation for `MTAudioProcessingTapProcessCallback` says:

> A processing tap is a real-time operation, so the general Core Audio limitations for real-time processing apply.  For example, care should be taken not to allocate memory or call into blocking system calls, as this will interfere with the real-time nature of audio playback.

I'm pretty sure that means using swift could cause you clicks and pops. Besides, Swift makes getting at the samples fairly tedious. [More info here](http://atastypixel.com/blog/four-common-mistakes-in-audio-development/). 
