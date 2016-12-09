An example of how to get going with `MTAudioProcessingTap` audio “taps” in Swift 3. The tap itself is not particularly difficult, but the c-callbacks and casts in Swift can take many hours of googling and trawling [stackoverflow](https://stackoverflow.com) (at least for me).

Includes attaching an `MTAudioProcessingTap` to a remote `AVPlayer`, c callbacks in swift, casting self to and from `UnsafeMutableRawPointer`, `MTAudioProcessingTapCreate`, `AVMutableAudioMixInputParameters `.
