//
//  AppDelegate.swift
//  swift tap
//
//  Created by Gordon Childs on 11/11/2015.
//  Copyright © 2015 Gordon Childs. All rights reserved.
//

import UIKit
import AVFoundation
import MediaToolbox

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	var window: UIWindow?
	
	var player: AVPlayer?
	var playerItem: AVPlayerItem! = nil
	
	// looks like you can't stop an audio tap synchronously, so it's possible for your clientInfo/tapStorage
	// refCon/cookie object to go out of scope while the tap process callback is still being called.
	// As a solution wrap your object of interest as a weak reference that can be guarded against
	// inside an object (cookie) whose scope we do control.
	class TapCookie {
		weak var content: AnyObject?
		
		init(content: AnyObject) {
			self.content = content
		}
		
		deinit {
			print("TapCookie deinit")	// should appear after finalize
		}
	}
	
	let tapInit: MTAudioProcessingTapInitCallback = {
		(tap, clientInfo, tapStorageOut) in
		
		// Make tap storage the same as clientInfo. I guess you might want them to be different.
		tapStorageOut.pointee = clientInfo
	}
	
	let tapProcess: MTAudioProcessingTapProcessCallback = {
		(tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut) in
		print("callback \(tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut)\n")
		
		let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)
		if noErr != status {
			print("get audio: \(status)\n")
		}
		
		let cookie = Unmanaged<TapCookie>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).takeUnretainedValue()
		guard let cookieContent = cookie.content else {
			print("Tap callback: cookie content was deallocated!")
			return
		}
		
		let appDelegateSelf = cookieContent as! AppDelegate
		print("cookie content \(appDelegateSelf)")
	}
	
	let tapFinalize: MTAudioProcessingTapFinalizeCallback = {
		(tap) in
		print("finalize \(tap)\n")
		
		// release cookie
		Unmanaged<TapCookie>.fromOpaque(MTAudioProcessingTapGetStorage(tap)).release()
	}
	
	var tracksObserver: NSKeyValueObservation? = nil
	var statusObservation: NSKeyValueObservation? = nil
	
	// assumes tracks are loaded
	func installTap(playerItem: AVPlayerItem) {
		let cookie = TapCookie(content: self)
		
		var callbacks = MTAudioProcessingTapCallbacks(
			version: kMTAudioProcessingTapCallbacksVersion_0,
			clientInfo: UnsafeMutableRawPointer(Unmanaged.passRetained(cookie).toOpaque()),
			init: tapInit,
			finalize: tapFinalize,
			prepare: nil,
			unprepare: nil,
			process: tapProcess)
		
		var tap: Unmanaged<MTAudioProcessingTap>?
		let err = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
		assert(noErr == err);
		
		// let audioTrack = playerItem.tracks.first!.assetTrack!
		let audioTrack = playerItem.asset.tracks(withMediaType: AVMediaType.audio).first!
		let inputParams = AVMutableAudioMixInputParameters(track: audioTrack)
		inputParams.audioTapProcessor = tap?.takeRetainedValue()
		
		let audioMix = AVMutableAudioMix()
		audioMix.inputParameters = [inputParams]
		
		playerItem.audioMix = audioMix
	}
	
	func doit() {
		// some remote resources work. maybe those with ContentLength?
		let s = "https://bsrr00.s3.amazonaws.com/98iN.mp3"  // has tracks
		// let s = "http://live-radio01.mediahubaustralia.com/2LRW/mp3/"	// doesn't work any more
		let url = URL(string: s)!
		//		let url = Bundle.main.url(forResource: "foo", withExtension: "m4a")!     // local resource works
		
		self.playerItem = AVPlayerItem(url: url)
		self.player = AVPlayer(playerItem: self.playerItem)
		
		self.tracksObserver = playerItem.observe(\AVPlayerItem.tracks) {
			[unowned self] item, change in
			NSLog("tracks change \(item.tracks)")
			NSLog("asset tracks (btw) \(item.asset.tracks)")
			self.installTap(playerItem: self.playerItem)
		}
		
		self.statusObservation = playerItem.observe(\AVPlayerItem.status) {
			[unowned self] object, change in
			NSLog("playerItem status change \(object.status.rawValue)")
			if object.status == .readyToPlay {
				self.player?.play()
				
				// indirectly stop and dealloc tap to test finalize and cookie code.
				DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
					print("\"deallocating\" tap")
					self.playerItem = nil
					self.player = nil
				}
				
			}
		}
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		doit()
		return true
	}
}

