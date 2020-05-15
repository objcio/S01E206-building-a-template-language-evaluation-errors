//
//  File.swift
//  
//
//  Created by Florian Kugler on 13-05-2020.
//

import Foundation

public enum TemplateValue: Hashable {
    case string(String)
    case rawHTML(String)
}

public struct EvaluationContext {
    public init(values: [String : TemplateValue] = [:]) {
        self.values = values
    }
    
    public var values: [String: TemplateValue]
}

public struct EvaluationError: Error, Hashable {
    public var range: Range<String.Index>
    public var reason: Reason
    
    public enum Reason: Hashable {
        case variableMissing(String)
    }
}

extension EvaluationContext {
    public func evaluate(_ expr: AnnotatedExpression) throws -> TemplateValue {
        switch expr.expression {
        case .variable(name: let name):
            guard let value = values[name] else {
                throw EvaluationError(range: expr.range, reason: .variableMissing(name))
            }
            return value
        case .tag(let name, let attributes, let body):
            let bodyValues = try body.map { try self.evaluate($0) }
            var bodyString = bodyValues.map { value in
                switch value {
                case let .string(str): return str.escaped
                case let .rawHTML(html): return html
                }
            }.joined()
            
            var result = "<\(name)>\(bodyString)</\(name)>"
            return .rawHTML(result)
        }
    }
}

extension String {
    // todo verify that this is secure
    var escaped: String {
        self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
