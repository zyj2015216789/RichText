//
//  UITextViewGenerator.swift
//  playGroundTest
//
//  Created by job zhao on 2021/8/6.
//

import SwiftUI
class UITextViewGenerator {
    private init() {}
    static func getTextView(from input: NSAttributedString, font: UIFont, textColor: UIColor) -> UITextView {
        let textView = UITextView()
        let mutableInput = NSMutableAttributedString(attributedString: input)
        textView.attributedText = mutableInput
        textView.accessibilityValue = input.string
        textView.textContainerInset = .zero //??
        textView.textContainer.lineFragmentPadding = 0
        if #available(iOS 10.0, *) {
            textView.adjustsFontForContentSizeCategory = true
        }
        return textView
    }
}
