//
//  NSMutableAttributedStringExtension.swift
//  playGroundTest
//
//  Created by job zhao on 2021/8/6.
//

import Foundation
extension NSMutableAttributedString {
    func trimmingTrailingNewLinesAndWItespaces() -> NSMutableAttributedString {
        let invertedSet = CharacterSet.whitespacesAndNewlines.inverted

        let range = (self.string as NSString).rangeOfCharacter(from: invertedSet, options: .backwards)
        let length = range.location == NSNotFound ? 0 : NSMaxRange(range)

        return NSMutableAttributedString(attributedString: self.attributedSubstring(from: NSRange(location: 0, length: length)))
    }
    func trimmingTrailingNewLines() -> NSMutableAttributedString {
        let invertedSet = CharacterSet.whitespacesAndNewlines.subtracting(CharacterSet.whitespaces).inverted

        let range = (self.string as NSString).rangeOfCharacter(from: invertedSet, options: .backwards)
        let length = range.location == NSNotFound ? 0 : NSMaxRange(range)

        return NSMutableAttributedString(attributedString: self.attributedSubstring(from: NSRange(location: 0, length: length)))
    }

}
