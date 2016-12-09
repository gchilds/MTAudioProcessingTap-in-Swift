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

	let tapInit: MTAudioProcessingTapInitCallback = {
		(tap, clientInfo, tapStorageOut) in
		
		let nonOptionalSelf = clientInfo!.assumingMemoryBound(to: AppDelegate.self).pointee
		
		print("init \(tap, clientInfo, tapStorageOut, nonOptionalSelf)\n")
		//			tapStorageOut.assignFrom(source:clientInfo, count: 1)
		//			tapStorageOut.init(clientInfo)
	}
	
	let tapFinalize: MTAudioProcessingTapFinalizeCallback = {
		(tap) in
		print("finalize \(tap)\n")
	}
	
	let tapPrepare: MTAudioProcessingTapPrepareCallback = {
		(tap, b, c) in
		print("prepare: \(tap, b, c)\n")
	}
	
	let tapUnprepare: MTAudioProcessingTapUnprepareCallback = {
		(tap) in
		print("unprepare \(tap)\n")
	}
	
	let tapProcess: MTAudioProcessingTapProcessCallback = {
		(tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut) in
		print("callback \(tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut)\n")
		
		let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)
		print("get audio: \(status)\n")
	}

	func doit() {
		let url = URL(string: "http://live-radio01.mediahubaustralia.com/2LRW/mp3/")!
		let playerItem = AVPlayerItem(url: url)
		
		var callbacks = MTAudioProcessingTapCallbacks(
			version: kMTAudioProcessingTapCallbacksVersion_0,
			clientInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
			init: tapInit,
			finalize: tapFinalize,
			prepare: tapPrepare,
			unprepare: tapUnprepare,
			process: tapProcess)
		
		var tap: Unmanaged<MTAudioProcessingTap>?
		let err = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
		
		print("err: \(err)\n")
		if err == noErr {
		}

		print("tracks? \(playerItem.asset.tracks)\n")
		
		let audioTrack = playerItem.asset.tracks(withMediaType: AVMediaTypeAudio).first!
		let inputParams = AVMutableAudioMixInputParameters(track: audioTrack)
		inputParams.audioTapProcessor = tap?.takeUnretainedValue()
		
		// print("inputParms: \(inputParams), \(inputParams.audioTapProcessor)\n")
		let audioMix = AVMutableAudioMix()
		audioMix.inputParameters = [inputParams]
		
		playerItem.audioMix = audioMix
		
		player = AVPlayer(playerItem: playerItem)
		player?.play()
	}

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		doit()
		return true
	}

}

