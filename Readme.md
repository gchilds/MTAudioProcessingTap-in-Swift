## A minimal example of an `MTAudioProcessingTap` audio “tap” in Swift 4.2. 

Audio taps seem to be arcane knowledge these days. There was a WWDC 2012 session and there are a few code samples around, but none in Swift (maybe for a good reason, see below) nor any that show how to take the the tap down.

The hopeful tap beginner is full of enthusiasm, but there are many perplexities on your path - hours googling how to declare c callbacks in Swift, hours googling how to take a pointer to an `Unmanaged<T>` , converting between `Unmanaged` raw opaque pointers and Swift classes, retain counts, the inexplicable double indirection on `clientInfo`, stopping the tap and dealing with the inevitable race between tap finalize and your `clientInfo` class `deinit`.

This sample includes 

   * deallocating/taking down the tap
   * safely dealing with `self` going out of scope before the `MTAudioProcessingTap` (possible and likely) 
   * attaching an `MTAudioProcessingTap` to an `AVPlayer`
   * callbacks into swift from c
   * casting self to and from `UnsafeMutableRawPointer`

Not included:

   * doing anything with the tapped audio data `AudioBufferList`

**Limitations**: According to a [devforum answer](https://forums.developer.apple.com/thread/45966) `MTAudioProcessingTap` does not work with HTTP Live Streaming.
It also appears to no longer work shoutcast streams. In these cases the remote `AVAsset` always has zero tracks. It does work on an mp3 served from s3. Maybe content-length is important?
I've tried waiting for tracks and ready status on the `AVPlayerItem`, but the thing that seems to matter most is the underlying `AVAsset`'s tracks.  
Annoyingly, the graphical counterpart of an audio tap, `AVPlayerItemVideoOutput`, does work with HLS. 

# Why you shouldn't use this code
[The consensus seems to be that you shouldn't use swift for realtime audio](http://atastypixel.com/blog/four-common-mistakes-in-audio-development/).
The documentation for `MTAudioProcessingTapProcessCallback` says:

> A processing tap is a real-time operation, so the general Core Audio limitations for real-time processing apply.  For example, care should be taken not to allocate memory or call into blocking system calls, as this will interfere with the real-time nature of audio playback.

The API goes out of its way to make sure you don't do any memory management in the process callback by giving your prepare/unprepare callbacks, so they really do mean it. In practice, I've seen large, independent of the I/O buffer duration 8-10ms tap buffers, however, as the article above says, thanks to priority inversion there's no safe minimal amount of time to hold a lock on an audio thread, so equivalently, no safe maximal buffer size. So in the worst case, your swift tap could cause audio dropouts. However in practice it seems to be fine.

