//
//  RichTextParser.swift
//  playGroundTest
//
//  Created by job zhao on 2021/8/5.
//

import SwiftUI
import Down
class RichTextParser {
    enum ParserConstants {
        static let mathTagName = "math"
        static let latexRegex = "\\[\(ParserConstants.mathTagName)\\](.*?)\\[\\/\(ParserConstants.mathTagName)\\]"
        static let latexSubscriptCharacter = "_"
        static let latexRegexCaptureGroupIndex = 0
        static let listOpeningHTMLString = "</style></head><body><ul"
        static let listClosingHTMLString = "</ul></body></html>"
        static let defaultSubScriptOffset: CGFloat = 2.66
        typealias RichTextWithErrors = (output: NSAttributedString, errors: [ParsingError]?)
        private static let tAPlaceholderPrefix = "{RichTextView-TextAttachmentPosition"
        private static let tAPlaceholderSuffix = "}"
        static let textAttachmentPlaceholderAssigner = "="
        static let textAttachmentPlaceholderRegex =
        "\\\(ParserConstants.tAPlaceholderPrefix)\(ParserConstants.textAttachmentPlaceholderAssigner)[0-9]+?\\\(ParserConstants.tAPlaceholderSuffix)"
        static let textAttachmentPlaceholder =
        "\(ParserConstants.tAPlaceholderPrefix)\(ParserConstants.textAttachmentPlaceholderAssigner)%d\(ParserConstants.tAPlaceholderSuffix)"
    }

    let latexParser: LatexParserProtocol
    let font: UIFont
    let textColor: UIColor
    let latexTextBaselineOffset: CGFloat

    init(latexParser: LatexParserProtocol = LatexParser(),
         font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize),
         textColor: UIColor = UIColor.black,
         latexTextBaselineOffset: CGFloat = 0) {
        self.latexParser = latexParser
        self.font = font
        self.textColor = textColor
        self.latexTextBaselineOffset = latexTextBaselineOffset
    }

    func getRichDataTypes(from input: String) -> [RichDataType] {
        if input.isEmpty {
            return [RichDataType(richText: NSAttributedString(string: ""), font: self.font, errors: nil)]
        }
        var errors: [ParsingError]?
        let results = self.getRichTextWithErrors(from: input)
        if errors == nil {
            errors = results.errors
        } else if let resultErrors = results.errors {
            errors?.append(contentsOf: resultErrors)
        }

        return [RichDataType(richText: results.output, font: self.font, errors: errors)]
    }

    func getRichTextWithErrors(from input: String) -> ParserConstants.RichTextWithErrors {
        let inputAsMutableAttributedString = NSMutableAttributedString(string: input)
        let richTextWithSpecialDataTypesHandled = self.getRichTextWithSpecialDataTypesHandled(fromString: inputAsMutableAttributedString)
        let textAttachmentAttributesInRichText = self.extractTextAttachmentAttributedsInOrder(fromAttributedString: richTextWithSpecialDataTypesHandled.output)
        let richTextWithHTML = self.getRichTextWithHTMLAndMarkdownHandled(
            formString: self.replaceTextAttachmentWithPlaceHolderInfo(inAttributedString: richTextWithSpecialDataTypesHandled.output)
        )
        let outputRichText = self.mergeSpecialDataAndHtmlAttribute(
            htmlString: NSMutableAttributedString(attributedString: richTextWithHTML.output),
            specialDataTypesString: richTextWithSpecialDataTypesHandled.output,
            textAttachmentAttributes: textAttachmentAttributesInRichText).trimmingTrailingNewLines()
        if richTextWithSpecialDataTypesHandled.errors == nil, richTextWithHTML.errors == nil {
            return (outputRichText, nil)
        }

        let outputErrors = (richTextWithSpecialDataTypesHandled.errors ?? [ParsingError]()) +
            (richTextWithHTML.errors ?? [ParsingError]())
        return (outputRichText, outputErrors)

    }
    private func mergeSpecialDataAndHtmlAttribute(htmlString: NSMutableAttributedString,
                                                  specialDataTypesString: NSAttributedString,
                                                  textAttachmentAttributes: [[NSAttributedString.Key: Any]]) -> NSMutableAttributedString {
        let outputString = self.mergeTextAttachmentsAndHTMLAttributes(
            htmlString: htmlString,
            textAttachmentAttributes: textAttachmentAttributes
        )
        print("te",specialDataTypesString)
        let rangeOfSepcialDataString = NSRange(location: 0, length: specialDataTypesString.length)
        specialDataTypesString.enumerateAttributes(in: rangeOfSepcialDataString) { (attributes, range, _) in
            print("before",range.lowerBound, range.upperBound)
            if attributes.isEmpty || attributes[.attachment] == nil {
                return
            }
            let specialDataSubstring = specialDataTypesString.string[
                max(range.lowerBound, 0)..<min(range.upperBound, specialDataTypesString.string.count)
            ]
            print(specialDataSubstring)
            let rangeOfSubstringInOutputString = (outputString.string as NSString).range(of: specialDataSubstring)
            if rangeOfSubstringInOutputString.location == NSNotFound ||
                rangeOfSubstringInOutputString.location < 0 ||
                rangeOfSubstringInOutputString.location + rangeOfSubstringInOutputString.length > outputString.length {
                return
            }
            let newOutputSubstring = NSMutableAttributedString(attributedString: outputString.attributedSubstring(from: rangeOfSubstringInOutputString))
            newOutputSubstring.addAttributes(attributes, range: NSRange(location: 0, length: newOutputSubstring.length))
            newOutputSubstring.replaceCharacters(in: NSRange(location: 0, length: newOutputSubstring.length), with: specialDataSubstring)
            outputString.replaceCharacters(in: rangeOfSubstringInOutputString, with: newOutputSubstring)
        }
        return outputString
    }
    private func mergeTextAttachmentsAndHTMLAttributes(htmlString: NSMutableAttributedString, textAttachmentAttributes: [[NSAttributedString.Key: Any]]) -> NSMutableAttributedString {
        let textAttachmentRegex = try? NSRegularExpression(pattern: ParserConstants.textAttachmentPlaceholder, options: [])
        let inputRange = NSRange(location: 0, length: htmlString.length)
        guard let textAttachmentMatches = textAttachmentRegex?.matches(in: htmlString.string, options: [], range: inputRange) else {
            return htmlString
        }

        for match in textAttachmentMatches.reversed() {
            let matechedSubsting = htmlString.attributedSubstring(from: match.range).string
            let matchedComponentsSeparatedByAssigner = matechedSubsting.components(
                separatedBy: ParserConstants.textAttachmentPlaceholderAssigner
            )
            let decimalCharacters = CharacterSet.decimalDigits.inverted
            guard let textAttachmentPositionAsSubstring = matchedComponentsSeparatedByAssigner.last?.components(separatedBy: decimalCharacters).joined(),
                  let textAttachmentPosition = Int(textAttachmentPositionAsSubstring), textAttachmentAttributes.indices.contains(textAttachmentPosition) else {
                continue
            }
            let textAttachmentAttributes = textAttachmentAttributes[textAttachmentPosition]
            guard let textAttachment = textAttachmentAttributes[.attachment] as? NSTextAttachment else {
                continue
            }
            let textAttachmentAttributedString = NSMutableAttributedString(attachment: textAttachment)
            textAttachmentAttributedString.addAttributes(
                textAttachmentAttributes,
                range: NSRange(location: 0, length: textAttachmentAttributedString.length)
            )
            htmlString.replaceCharacters(in: match.range, with: textAttachmentAttributedString)
        }
        return htmlString
    }
    private func replaceTextAttachmentWithPlaceHolderInfo(inAttributedString input: NSAttributedString) -> NSMutableAttributedString {
        let output = NSMutableAttributedString(attributedString: input)
        let range = NSRange(location: 0, length: input.length)
        var position = 0
        input.enumerateAttributes(in: range, options: [.reverse]) { (attributes, range, _) in
            guard attributes.keys.contains(.attachment) else {
                return
            }
            output.replaceCharacters(in: range, with: String(format: ParserConstants.textAttachmentPlaceholder, position))
            position += 1
        }
        return output
    }
    private func getRichTextWithHTMLAndMarkdownHandled(formString mutableAttributedString: NSMutableAttributedString) -> ParserConstants.RichTextWithErrors {
        let inputString = mutableAttributedString.string
        let inputStringWithoutBreadingSpaces = inputString.replaceLeadingWhiteSpaceWithNonBreakingSpace().replaceTrailingWhiteSpaceWithNonBreakingSpace()
        guard let htmlData = unescapeHTML(from: inputStringWithoutBreadingSpaces).data(using: .utf16) else{
            return (mutableAttributedString.trimmingTrailingNewLines(), [ParsingError.attributedTextGeneration(text: inputString)])
        }
        let parsedAttributedString = self.getParsedHTMLAttributedString(from: htmlData)
        guard let parsedHTMLAttributedString = parsedAttributedString else {
            return (mutableAttributedString.trimmingTrailingNewLines(), [ParsingError.attributedTextGeneration(text: inputString)])
        }
        //let parsedMutableAttributedString = NSMutableAttributedString(attributedString: parsedHTMLAttributedString)
        return (parsedHTMLAttributedString, nil)
    }

    private func getParsedHTMLAttributedString(from data: Data) -> NSAttributedString? {
        var attributedString: NSAttributedString?
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if Thread.isMainThread {
            attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil)
        } else {
            DispatchQueue.main.sync {
                attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil)
            }
        }
        return attributedString
    }

    private func extractPositions(fromRanges ranges: [Range<String.Index>]) -> [String.Index] {
        return ranges.flatMap { [$0.lowerBound, $0.upperBound] }.sorted()
    }
    private func unescapeHTML(from input: String) -> String {
        return input.replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }

    private func getRichTextWithSpecialDataTypesHandled(fromString mutableAttributedString: NSMutableAttributedString) -> ParserConstants.RichTextWithErrors {
        let latexPositions = self.extractPositions(fromRanges: self.getLatexRanges(inText: mutableAttributedString.string))
        if latexPositions.isEmpty {
            return (mutableAttributedString,nil)
        }
        return self.mergeSpecialDataComponentsAndReturnRichText(self.split(mutableAttributedString: mutableAttributedString, onPositions: latexPositions))
    }
    private func mergeSpecialDataComponentsAndReturnRichText (_ components: [NSAttributedString]) -> ParserConstants.RichTextWithErrors {
        let output = NSMutableAttributedString()
        var parsingErrors: [ParsingError]?
        components.forEach { attributedString in
            if self.isTextLatex(attributedString.string) {
                if let attributedLatexString = self.extractLatex(from: attributedString.string) {
                    output.append(attributedLatexString)
                    return
                }
                if parsingErrors == nil {
                    parsingErrors = [ParsingError]()
                }
                output.append(attributedString)
                parsingErrors?.append(ParsingError.latexGeneration(text: attributedString.string))
                return
            }
            output.append(attributedString)
        }
        return(output, parsingErrors)
    }
    private func getLatexRanges(inText text: String) -> [Range<String.Index>] {
        guard let regex = try? NSRegularExpression(pattern: ParserConstants.latexRegex, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return []
        }
        let range = NSRange(location: 0, length: text.count)
        let matches = regex.matches(in: text, range: range)
        return matches.compactMap { match in
            return Range<String.Index>(match.range(at: ParserConstants.latexRegexCaptureGroupIndex),in: text)
        }
    }
    private func split(mutableAttributedString: NSMutableAttributedString, onPositions positions: [String.Index]) -> [NSAttributedString] {
        let splitStrings = mutableAttributedString.string.split(atPositions: positions)
        var output = [NSAttributedString]()
        for string in splitStrings {
            let range = (mutableAttributedString.string as NSString).range(of: string)
            let attributedString = mutableAttributedString.attributedSubstring(from: range)
            output.append(attributedString)
        }
        return output
    }
    func isTextLatex(_ text: String) ->Bool {
        return !self.getLatexRanges(inText: text).isEmpty
    }
    func extractLatex(from input: String) -> NSAttributedString? {
        return self.latexParser.extractLatex(
            from: input,
            textColor: self.textColor,
            baselineOffset: self.latexTextBaselineOffset,
            fontSize: self.font.pointSize,
            height: self.calculateContentHeight()
        )
    }
    private func calculateContentHeight() -> CGFloat {
        let frame = NSString(string: "").boundingRect(with: CGSize(width: 0, height: .max), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: [.font: self.font], context: nil)
        return frame.size.height
    }
    private func extractTextAttachmentAttributedsInOrder(fromAttributedString input: NSAttributedString) -> [[NSAttributedString.Key: Any]] {
        var output = [[NSAttributedString.Key: Any]]()
        let range = NSRange(location: 0, length: input.length)
        input.enumerateAttributes(in: range, options: [.reverse]) { (attributes, _, _) in
            guard attributes.keys.contains(.attachment) else {
                return
            }
            output.append(attributes)
        }
        return output
    }
}
