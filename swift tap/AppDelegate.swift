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

	var player: AVPlayer

	override init() {
		let playerItem = AVPlayerItem(URL: NSURL(string: "http://abc.net.au/res/streaming/audio/mp3/local_sydney.pls")!)
		
		let processCallback : @convention(c) (MTAudioProcessingTap, CMItemCount, MTAudioProcessingTapFlags, UnsafeMutablePointer<AudioBufferList>, UnsafeMutablePointer<CMItemCount>, UnsafeMutablePointer<MTAudioProcessingTapFlags>) -> Void = {
			(tap, itemCount, flags, bufferListPtr, itemCountPtr, flagsPtr) -> Void in
			print("CALLBACK")
		}
		
		var callbacks = MTAudioProcessingTapCallbacks(
			version: kMTAudioProcessingTapCallbacksVersion_0,
			clientInfo: nil,
			`init`: nil,
			finalize: nil,
			prepare: nil,
			unprepare: nil,
			process: processCallback)
		
		var tap: Unmanaged<MTAudioProcessingTap>?
		let err = MTAudioProcessingTapCreate(nil, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
		
		print("err: \(err)\n")
		if err == noErr {
			
		}

		let inputParams = AVMutableAudioMixInputParameters()
		inputParams.audioTapProcessor = tap?.takeUnretainedValue()
		
		let audioMix = AVMutableAudioMix()
		audioMix.inputParameters = [inputParams]
		
		playerItem.audioMix = audioMix
		
		player = AVPlayer(playerItem: playerItem)
		player.play()
	}

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		// Override point for customization after application launch.
		return true
	}

	func applicationWillResignActive(application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

