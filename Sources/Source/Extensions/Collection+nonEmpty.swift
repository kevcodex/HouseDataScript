//
//  Collection+nonEmpty.swift
//  Source
//
//  Created by Kirby on 10/14/18.
//

import Foundation

extension Collection {
    var nonEmpty: Self? {
        return !isEmpty ? self : nil
    }
}
