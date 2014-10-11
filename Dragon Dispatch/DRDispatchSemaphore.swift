//
//  DRDispatchSemaphore.swift
//  Dragon Dispatch
//
//  Created by George Green on 27/09/2014.
//  Copyright (c) 2014 The Swift Guru. All rights reserved.
//

import Foundation

/// This class represents a counting semaphore object.
public class DRDispatchSemaphore {
	
	// MARK: - Private Variables
	
	/// The underlying semaphore object.
	private let _semaphore: dispatch_semaphore_t
	
	// MARK: - Public Variables
	
	private var _maxEntrants: Int
	/// The maximum number of entrants allowed to code protected by this semaphore.
	/// (The manimum number of times that code protected by this semaphore can be executed concurrently.)
	public var maxEntrants: Int {
		get {
			return _maxEntrants
		}
	}
	
	// MARK: - Object Lifecycle Methods
	
	/// Create a new semaphore object with the specified maximum number of entrants.
	/// @param maxEntrants An optional parameter to specify the maximum number of entrants allowed to any code
	/// protected by this semaphore. Defaults to 1.
	public init(maxEntrants: Int = 1) {
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
	/// @return true if the block of code was executed, false if the specified timeout was reached before the block
	/// was executed.
	public func execute(block: DRDispatchBlock, timeout: DRTimeInterval? = nil) -> Bool {
		let waitTime = dispatchTimeFromTimeInterval(timeout)
		if dispatch_semaphore_wait(_semaphore, waitTime) == 0 {
			block()
			dispatch_semaphore_signal(_semaphore)
			return true
		}
		return false
	}
	
	/// Decrements the internal count of the semaphore. If the semaphore is now less than 0 this method will not return until the value once more reaches 0.
	/// @param timeout An optional parameter to specify how long to wait for the semaphore to reach 0.
	/// @return true if the semaphore reaches 0 before the timeout, false if the timeout is reached before the 
	/// semaphore reaches 0. If this method returns false, protected code should NOT be executed.
	/// @warning This method is provided for API completness, its use is NOT reccommended. Instead use the execute(block, timeout) method to safely execute a block of code.
	public func wait(timeout: DRTimeInterval? = nil) -> Bool {
		let waitTime = dispatchTimeFromTimeInterval(timeout)
		return dispatch_semaphore_wait(_semaphore, waitTime) == 0
	}
	
	/// Increments the internal count of the semaphore. Calling this will allow the next entrant currently waiting at a wait() call to continue.
	/// @return true if a another waiting entrant was allowed to continue as a result of this call, otherwise false
	/// @warning This method is provided for API completness, its use is NOT reccommended. Instead use the execute(block, timeout) method to safely execute a block of code.
	public func signal() -> Bool {
		return dispatch_semaphore_signal(_semaphore) == 0
	}
	
}