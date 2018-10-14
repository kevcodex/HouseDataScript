//
//  CSVWriter.swift
//  Source
//
//  Created by Kirby on 8/25/18.
//

import Foundation

struct CSVWriter {
    
    /// Adds a new column at the end. Append new columns by breaking out each row and then add each column in columns to the end of each row. Then rewrites the entire CSV with the new modified rows.
    /// - parameter columns: The new columns to be added. Takes in any object that conforms to CustomStringConvertible.
    /// - complexity: O(4n)? where n is the number of rows in the CSV.
    static func addNewColumns(_ columns: [CustomStringConvertible], to url: URL) throws {

        let columnsAsStrings = columns.map { $0.description }
        
        var csvString = ""
        if FileManager.default.fileExists(atPath: url.path) {
            csvString = try String(contentsOf: url, encoding: .utf8)
        }
        
        // Works, but could be better
        var csvRows: [String] = []
        if csvString.contains("\r\n") {
            csvRows = csvString.split(separator: "\r\n").map { String($0) }
        } else if csvString.contains("\n") {
            csvRows = csvString.split(separator: "\n").map { String($0) }
        }

        var newCSVRows: [String] = []
        
        if csvRows.isEmpty {
            newCSVRows.append(contentsOf: columnsAsStrings)
        } else {
            csvRows.enumerated().forEach { (index, rowString) in
                var newRowString = rowString
                let newColumn = columnsAsStrings[index]
                newRowString.append(",\(newColumn)")
                newCSVRows.append(newRowString)
            }
        }
        
        let newCSVString = newCSVRows.joined(separator: "\n")
        
        guard let data = newCSVString.data(using: .utf8) else {
            return
        }
        
        try data.write(to: url, options: .atomic)
    }
    
    /// Add new rows at the end of the file.
    /// - parameter rows: The new rows to be added. Takes in any object that conforms to CustomStringConvertible.
    /// - complexity: O(n) where n is the number of rows to add
    static func addNewRows(_ rows: [CustomStringConvertible], to url: URL) throws {
        
        for row in rows {
            guard let data = row.description.data(using: .utf8) else {
                continue
            }
            
            if let fileHandle = FileHandle(forWritingAtPath: url.path) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                try data.write(to: url, options: .atomic)
            }
        }
    }
}
