//
//  AppDelegate.swift
//  swift tap
//
//  Created by Gordon Childs on 11/11/2015.
//  Copyright © 2015 Gordon Childs. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	var player: AVPlayer?

	let tapInit: @convention(c) (MTAudioProcessingTap, UnsafeMutablePointer<Void>, UnsafeMutablePointer<UnsafeMutablePointer<Void>>) -> Void = {
		(tap, clientInfo, tapStorageOut) -> Void in
		print("init \(tap, clientInfo, tapStorageOut)\n")
		//			tapStorageOut.assignFrom(source:clientInfo, count: 1)
		//			tapStorageOut.init(clientInfo)
	}
	
	let tapFinalize: @convention(c) (MTAudioProcessingTap) -> Void = {
		(tap) -> Void in
		print("finalize \(tap)\n")
	}
	
	let tapPrepare: @convention(c) (MTAudioProcessingTap, CMItemCount, UnsafePointer<AudioStreamBasicDescription>) -> Void = {
		(tap, b, c) -> Void in
		print("prepare: \(tap, b, c)\n")
	}
	
	let tapUnprepare: @convention(c) (MTAudioProcessingTap) -> Void = {
		(tap) -> Void in
		print("unprepare \(tap)\n")
	}
	
	let tapProcess: @convention(c) (MTAudioProcessingTap, CMItemCount, MTAudioProcessingTapFlags, UnsafeMutablePointer<AudioBufferList>, UnsafeMutablePointer<CMItemCount>, UnsafeMutablePointer<MTAudioProcessingTapFlags>) -> Void = {
		(tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut) -> Void in
		print("callback \(tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut)\n")
		
		let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)
		print("get audio: \(status)\n")
	}

	func doit() {
		let url = NSURL(string: "http://live-radio01.mediahubaustralia.com/2LRW/mp3/")!
		let playerItem = AVPlayerItem(URL: url)
		
		
		
		var callbacks = MTAudioProcessingTapCallbacks(
			version: kMTAudioProcessingTapCallbacksVersion_0,
			clientInfo: UnsafeMutablePointer(Unmanaged.passUnretained(self).toOpaque()),
			`init`: tapInit,
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
		
		let audioTrack = playerItem.asset.tracksWithMediaType(AVMediaTypeAudio).first!
		let inputParams = AVMutableAudioMixInputParameters(track: audioTrack)
		inputParams.audioTapProcessor = tap?.takeUnretainedValue()
		
		// print("inputParms: \(inputParams), \(inputParams.audioTapProcessor)\n")
		let audioMix = AVMutableAudioMix()
		audioMix.inputParameters = [inputParams]
		
		playerItem.audioMix = audioMix
		
		player = AVPlayer(playerItem: playerItem)
		player?.play()
	}

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		// Override point for customization after application launch.
		doit()
		return true
	}

}

