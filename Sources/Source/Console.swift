//
//  Console.swift
//  hello-scriptPackageDescription
//
//  Created by Kirby on 11/19/17.
//

import Foundation

enum OutputStyle {
    case black
    case purple
    case blue
    case green
    case red
}

class Console {
    static func writeMessage(_ message: String, styled: OutputStyle = .black) {
        let textColorReset = "\u{001B}[;m"
        
        switch styled {
        case .black:
            print("\u{001B}[;m\(message)")
            
        case .purple:
            print("\u{001B}[0;35m\(message)", textColorReset)
            
        case .blue:
            print("\u{001B}[0;34m\(message)", textColorReset)
            
        case .green:
            print("\u{001B}[0;32m\(message)", textColorReset)
            
        case .red:
            
            print("\u{001B}[0;31m\(message)", textColorReset)
            // Below outputs to the STDERR
            // Kinda like nslog
            //      fputs("\u{001B}[0;31m\(message)\n", stderr)
        }
    }
    
    static func writeSpacer() {
        Console.writeMessage("=================================== \n")
    }
    
    static func getInput() -> String {
        let keyboard = FileHandle.standardInput
        let inputData = keyboard.availableData
        
        guard let strData = String(data: inputData, encoding: String.Encoding.utf8) else {
            fatalError("Could not convert to string")
        }
        
        return strData.trimmingCharacters(in: CharacterSet.newlines)
    }
}
