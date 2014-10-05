//
//  DRSet.swift
//  Dragon Dispatch
//
//  Created by George Green on 27/09/2014.
//  Copyright (c) 2014 The Swift Guru. All rights reserved.
//

import Foundation

internal class DRSet<T: Equatable>: SequenceType {
	private var _values: [T] = []
	
	/// Add a value to the set, if it is not already there.
	/// @param The new value to be added to the set.
	/// @return true if the new value was added to the set, false if the new value already existed in the set.
	func add(newValue: T) -> Bool {
		if let currentValue = find(_values, newValue) {
			return false
		} else {
			_values.append(newValue)
			return true
		}
	}
	
	/// Looks for a value in the set and if it is found, removes it.
	/// @param value The value to be removed if it is found.
	/// @return true if the value was found and removed, false if the value was not found.
	func remove(value: T) -> Bool {
		if let index = find(_values, value) {
			_values.removeAtIndex(index)
			return true
		}
		return false
	}
	
	/// Looks for a value in the set.
	/// @param value The value to look for.
	/// @return true if the value is found, false if the value is not found.
	func containsValue(value: T) -> Bool {
		if let value = find(_values, value) {
			return true
		}
		return false
	}
	
	// MARK: - SequenceType Methods
	
	func generate() -> GeneratorOf<T> {
		var index = 0
		return GeneratorOf<T> {
			if index < self._values.count {
				return self._values[index]
			} else {
				return nil
			}
		}
	}
}
