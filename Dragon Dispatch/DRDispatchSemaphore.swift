//
//  DRDispatchSemaphore.swift
//  Dragon Dispatch
//
//  Created by George Green on 27/09/2014.
//  Copyright (c) 2014 The Swift Guru. All rights reserved.
//

import Foundation

class DRDispatchSemaphore {
	
	// MARK: - Private Variables
	
	/// The underlying semaphore object.
	private let _semaphore: dispatch_semaphore_t
	
	// MARK: - Public Variables
	
	private var _maxEntrants: Int
	/// The maximum number of entrants allowed to code protected by this semaphore.
	/// (The manimum number of times that code protected by this semaphore can be executed concurrently.)
	var maxEntrants: Int {
		get {
			return _maxEntrants
		}
	}
	
	// MARK: - Object Lifecycle Methods
	
	/// Create a new semaphore object with the specified maximum number of entrants.
	/// @param maxEntrants An optional parameter to specify the maximum number of entrants allowed to any code
	/// protected by this semaphore. Defaults to 1.
	init(maxEntrants: Int = 1) {
		// Create the semaphore object
		_semaphore = dispatch_semaphore_create(maxEntrants)
		// Keep hold of the value
		_maxEntrants = maxEntrants
	}
	
	// MARK: - Public Action Methods
	
	/// Safely execute a block of code protected by this semaphore.
	/// This method will not return until the block has been safely executed.
	/// @param block The block of code to be safely executed.
	/// @param timeout An optional parameter used to specify how long the code should wait before deciding not to execute.
	/// Defaults to nil, to specify to wait forever.
	func execute(block: DRDispatchBlock, timeout: DRTimeInterval? = nil) {
		let waitTime = (timeout == nil) ? DISPATCH_TIME_FOREVER : dispatchTimeFromTimeInterval(timeout!)
		if dispatch_semaphore_wait(_semaphore, waitTime) == 0 {
			block()
			dispatch_semaphore_signal(_semaphore)
		}
	}
	
}