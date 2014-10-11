//
//  DRDispatchSafeObject.swift
//  Dragon Dispatch
//
//  Created by George Green on 27/09/2014.
//  Copyright (c) 2014 The Swift Guru. All rights reserved.
//

import Foundation

/// A class used to wrap any type of object in a way that makes accessing it thread safe.
/// An internal semaphore is used to ensure that the object to be protected is not accessed more than the
/// specified number of times concurrently.
public class DRDispatchProtectedObject<T> {
	
	// MARK: - Private Variables
	
	private let _semaphore: DRDispatchSemaphore
	internal var _protectedObject: T
	
	// MARK: - Object Lifecycle Methods
	
	/// Create a new protected object.
	/// @param object The object to be protected.
	/// @param maxConcurrentAccessors Optional parameter used to specify the maximum number of times the protected object can
	/// be accessed concurrently.
	public init(object: T, maxConcurrentAccessors: Int = 1) {
		// Create a semaphore to protect the object
		_semaphore = DRDispatchSemaphore(maxEntrants: maxConcurrentAccessors)
		// Keep hold of the object to protect
		_protectedObject = object
	}
	
	// MARK: - Public Action Methods
	
	/// Request safe access to the protected object. This method will wait until other accessors of the object are done,
	/// before returning the object to be used safely.
	/// @param timeout An optional parameter to specify the time period to wait for it to become safe to use the object.
	/// Defaults to nil to specify to wait indefinetely for the object to become safe.
	/// @return The protected object if it becomes safe to use before the timeout is reached, nil if the timeout is reached
	/// before the object is safe.
	/// @discussion Once you are done with the object, you must call done() so that any other code that wants access
	/// may be allowed access. If you fail to call done() the object may become permanently unavailable for use.
	/// If this method returns nil, there is no need to call done.
	/// Use of the with(block, timeout) method is reccommended for access to protected objects.
	public func requestAccess(timeout: DRTimeInterval? = nil) -> T? {
		if _semaphore.wait(timeout: timeout) { return _protectedObject }
		else { return nil }
	}
	
	/// Indicate that you no longer need access to the protected object. After calling this, you should no longer make
	/// any use of the protected object that was returned by a previous call to requestAccess(timeout).
	/// This method should not be called if the respective call to requestAccess(timeout) returned nil.
	/// Use of the with(block, timeout) method is reccommended for access to protected objects.
	public func done() {
		_semaphore.signal()
	}
	
	/// Execute a block of code which is guaranteed to have thread safe access to the protected object.
	/// @param block The block of code to be executed. The block will be passed a reference to the protected object
	/// on execution.
	/// @param timeout An optional parameter to specify the maximum amount of time to be waited for the protected object to become safe to use. Defaults to nil, to wait indeninately for the object to become safe.
	/// @return true if the object becomes safe to use before the timeout is reached, false if the timeout is reached before
	/// the object became safe to use.
	/// @discussion In the event of a true return value, the block will have been executed with safe access to the protected
	/// object. If the method returned false, the block was not executed.
	public func with(block: (inout protectedObject: T) -> Void, timeout: DRTimeInterval? = nil) -> Bool {
		return _semaphore.execute({ () -> Void in
			block(protectedObject: &self._protectedObject)
		}, timeout: timeout)
	}
	
}