//
//  DictionaryUnionExtension.swift
//  bio-blast
//
//  Created by Alex Bussan on 6/17/16.
//  Copyright © 2016 AlexBussan. All rights reserved.
//

import Foundation

extension Dictionary {
    mutating func unionInPlace(
        dictionary: Dictionary<Key, Value>) {
        for (key, value) in dictionary {
            self[key] = value
        }
    }
}

extension Dictionary {
    mutating func subtractThis(dictionary: Dictionary<Key, Value>) {
        for (key, _) in dictionary {
            self.removeValueForKey(key)
        }
    }
}

