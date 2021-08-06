//
//  ParsingError.swift
//  playGroundTest
//
//  Created by job zhao on 2021/8/5.
//

import Foundation

public enum ParsingError: LocalizedError {
    case attributedTextGeneration(text: String)
    case latexGeneration(text: String)

    public var errorDescription: String? {
        switch self {
        case let .attributedTextGeneration(text):
            return "Error Generating Attributed Text: " + text
        case let .latexGeneration(text):
            return "Error Generating Latex: " + text
        }
    }
}
