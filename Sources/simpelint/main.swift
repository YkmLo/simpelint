import Foundation
import SwiftSyntax

class Visitor: SyntaxVisitor {
    private let file: String
    private let sourceFileSyntax: SourceFileSyntax
    
    private lazy var converter: SourceLocationConverter = {
        return SourceLocationConverter(file: file, tree: sourceFileSyntax)
    }()
    
    private var errors: [String] = []
    
    init(file: String, sourceFileSyntax: SourceFileSyntax) {
        self.file = file
        self.sourceFileSyntax = sourceFileSyntax
        
        super.init()
    }
    
    func traverse() {
        self.walk(sourceFileSyntax)
        print(errors)
    }
    
    override func visitPost(_ node: AsExprSyntax) {
        if let mark = node.questionOrExclamationMark, mark.text == "!" {
            errors.append("no ! allowed at \(mark.getLocation(converter))")
            print("no ! allowed")
        }
    }
    
    override func visitPost(_ node: TryExprSyntax) {
        if let mark = node.questionOrExclamationMark, mark.text == "!" {
            print("no ! allowed")
        }
    }
    
    override func visitPost(_ node: FunctionDeclSyntax) {
        if let modifiers = node.modifiers {
            var iterator = modifiers.makeIterator()
            var isACLFound = false
            let acl: [TokenKind] = [.privateKeyword, .publicKeyword, .fileprivateKeyword, .internalKeyword, .identifier("open")]
            while let syntax = iterator.next() {
                if acl.contains(syntax.name.tokenKind) {
                    isACLFound = true
                }
            }
            if isACLFound {
                print("acl found")
            }
        }
    }
    
    override func visitPost(_ node: VariableDeclSyntax) {
        var isIBOutlet = false
        if let attributes = node.attributes {
            var iterator = attributes.makeIterator()
            while let syntax = iterator.next() {
                if let attribute = AttributeSyntax(syntax),
                    attribute.attributeName.tokenKind == .identifier("IBOutlet") {
                        isIBOutlet = true
                }
            }
        }
        
        if isIBOutlet {
            if let modifiers = node.modifiers {
                var iterator = modifiers.makeIterator()
                var isPrivate = false
                while let syntax = iterator.next() {
                    if syntax.name.tokenKind == .privateKeyword {
                        isPrivate = true
                    }
                }
                if !isPrivate {
                    print("iboutlet must be private!")
                }
            }
        }
    }
}

extension SyntaxProtocol {
    func getLocation(_ converter: SourceLocationConverter) -> String {
        let location = startLocation(converter: converter)
        var line = 0, column = 0
        if let lineNumber = location.line {
            line = lineNumber
        }
        if let columnNumber = location.column {
            column = columnNumber
        }
        
        return "line \(line), column \(column)"
    }
}

let file = CommandLine.arguments[1]
let url = URL(fileURLWithPath: file)
let sourceFile = try SyntaxParser.parse(url)
Visitor(file: file, sourceFileSyntax: sourceFile).traverse()
