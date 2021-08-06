//
//  RichDataType.swift
//  playGroundTest
//
//  Created by job zhao on 2021/8/5.
//
// 所有都需要引用吗，每一次？？
import SwiftUI
import Foundation
struct RichDataType {
    let richText: NSAttributedString
    let font: UIFont
    let errors: [ParsingError]?
}
