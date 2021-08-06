//
//  RichTextView.swift
//  playGroundTest
//
//  Created by job zhao on 2021/8/5.
//


import SnapKit
public class RichTextView: UIView {
    public private(set) var input: String
    private(set) var richTextParser: RichTextParser
    private(set) var textColor: UIColor
    private(set) var errors: [ParsingError]?
    public init(input: String = "",
                latexParser: LatexParserProtocol = LatexParser(),
                font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize),
                textColor: UIColor = UIColor.black,
                latexTextBaselineOffset: CGFloat = 0,
                frame: CGRect,
                completion: (([ParsingError]?) -> Void)? = nil){
        self.input = input
        self.richTextParser = RichTextParser(
            latexParser: latexParser,
            font: font,
            textColor: textColor,
            latexTextBaselineOffset: latexTextBaselineOffset
        )
        self.textColor = textColor
        super.init(frame: frame)
        self.setupSubViews()
        completion?(self.errors)
    }

    public required init?(coder aDecoder: NSCoder) {
        self.input = ""
        self.richTextParser = RichTextParser()
        self.textColor = UIColor.black
        super.init(coder: aDecoder)
        self.setupSubViews()

    }

    public func update(input: String? = nil,
                       latexParser: LatexParserProtocol? = nil,
                       font: UIFont? = nil,
                       textColor: UIColor? = nil,
                       latexTextBaselineOffset: CGFloat? = nil,
                       completion: (([ParsingError]?) -> Void)? = nil) {
        self.input = input ?? self.input
        self.richTextParser = RichTextParser(
            latexParser: latexParser ?? self.richTextParser.latexParser,
            font: font ?? self.richTextParser.font,
            textColor: textColor ?? self.textColor,
            latexTextBaselineOffset: latexTextBaselineOffset ?? self.richTextParser.latexTextBaselineOffset
            )
        self.setupSubViews()
        completion?(self.errors)
    }

    private func setupSubViews() {
        let subviews = self.generateViews()
        for (index, subview) in subviews.enumerated() {
            self.addSubview(subview)
            subview.snp.makeConstraints { make in
                if index == 0 {
                    make.top.equalTo(self)
                } else {
                    make.top.equalTo(subviews[index - 1].snp.bottom)
                }
                make.width.equalTo(self)
                make.centerX.equalTo(self)
                if index == subviews.count - 1 {
                    make.bottom.equalTo(self)
                }
            }
        }
        self.enableAccessibility()
    }

    func generateViews() -> [UIView] {
        return self.richTextParser.getRichDataTypes(from: self.input).compactMap { (RichDataType: RichDataType) -> UIView? in
            return UITextViewGenerator.getTextView(from: RichDataType.richText, font: RichDataType.font, textColor: self.textColor)
        }
    }

    private func enableAccessibility() {
        self.isAccessibilityElement = true
        self.accessibilityValue = nil
        for view in self.subviews {
            if let accessibilityValue = view.accessibilityValue, !accessibilityValue.isEmpty {
                if self.accessibilityValue == nil {
                    self.accessibilityValue = accessibilityValue
                } else {
                    self.accessibilityValue?.append(accessibilityValue)
                }
            }
        }

    }
}
