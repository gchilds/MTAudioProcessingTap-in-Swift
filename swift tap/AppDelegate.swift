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
	
	let tapInit: MTAudioProcessingTapInitCallback = {
		(tap, clientInfo, tapStorageOut) in
		
		// Make tap storage the same as clientInfo. I guess you might want them to be different.
		tapStorageOut.pointee = clientInfo
	}
	
	let tapProcess: MTAudioProcessingTapProcessCallback = {
		(tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut) in
		print("callback \(tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut)\n")
		
		let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)
		print("get audio: \(status)\n")
		
		let pointer = Unmanaged<AppDelegate>.fromOpaque(MTAudioProcessingTapGetStorage(tap))
		let vc = pointer.takeUnretainedValue()
		print("viewController \(vc)")
	}
	
	let tapFinalize: MTAudioProcessingTapFinalizeCallback = {
		(tap) in
		print("finalize \(tap)\n")
	}
	
	var tracksObserver: NSKeyValueObservation? = nil
	var statusObservation: NSKeyValueObservation? = nil
	
	// assumes tracks are loaded
	func installTap(playerItem: AVPlayerItem) {
		var callbacks = MTAudioProcessingTapCallbacks(
			version: kMTAudioProcessingTapCallbacksVersion_0,
			clientInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
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
//		let s = "http://live-radio01.mediahubaustralia.com/2LRW/mp3/"	// doesn't work any more
		let url = URL(string: s)!
//		 let url = Bundle.main.url(forResource: "foo", withExtension: "m4a")!	 // local resource works
		
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
			}
		}
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		doit()
		return true
	}
}

