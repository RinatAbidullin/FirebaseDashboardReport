//
//  Table.swift
//  FirebaseDashboardReport
//
//  Created by Rinat Abidullin on 05.08.2021.
//

import Foundation

enum TableError: LocalizedError {
    case numberOfTitlesDoesNotMatchNumberOfColumns
    case numberOfRowEntriesDoesNotMatchNumberOfColumns
    
    var errorDescription: String? {
        switch self {
        case .numberOfRowEntriesDoesNotMatchNumberOfColumns:
            return "Number of row entriess does not match number of columns"
        case .numberOfTitlesDoesNotMatchNumberOfColumns:
            return "Number of titles does not match number of columns"
        }
    }
}

protocol RowEntry {
    var stringRepresentation: String { get }
}

protocol Row {
    var rowRepresentation: [RowEntry] { get }
}

struct EmptyRowEntry: RowEntry {
    var stringRepresentation: String { "" }
}

class Table {
    typealias SingleRow = [RowEntry]
    
    private let tableTitle: String?
    private let columnCount: Int
    private var columnTitles = [String]()
    private var rows = [SingleRow]()
    
    private let crossing = "+"
    private let horisontalLine = "-"
    private let verticalLine = "|"
    private let newLine = "\n"
    
    private let isInsertMargins: Bool
    private let isBorderAround: Bool
    private let isSeparateRows: Bool
    private let accuracy: Int?
    
    init(
        columnCount: Int,
        tableTitle: String? = nil,
        accuracy: Int? = nil,
        isInsertMargins: Bool = true,
        isBorderAround: Bool = true,
        isSeparateRows: Bool = true
    ) {
        self.columnCount = columnCount
        self.tableTitle = tableTitle
        self.accuracy = accuracy
        self.isInsertMargins = isInsertMargins
        self.isBorderAround = isBorderAround
        self.isSeparateRows = isSeparateRows
    }
    
    func set(columnTitles: [String]) throws {
        guard columnTitles.count == columnCount else {
            throw TableError.numberOfTitlesDoesNotMatchNumberOfColumns
        }
        
        self.columnTitles.removeAll()
        
        for title in columnTitles {
            self.columnTitles.append(title)
        }
    }
    
    func append(row: Row) throws {
        let rowEntries = row.rowRepresentation
        guard rowEntries.count == columnCount else {
            throw TableError.numberOfRowEntriesDoesNotMatchNumberOfColumns
        }
        
        self.rows.append(rowEntries)
    }
    
    func append(rows: [Row]) throws {
        try rows.forEach { row in
            try append(row: row)
        }
    }
    
    // MARK: - Вывод на экран
    
    func print() {
        Swift.print(asString)
    }
    
    var asString: String {
        var tableWithStringRows = tableWithStringRows
        var columnMaxWidths = columnMaxWidths(for: tableWithStringRows)
        
        tableWithStringRows = insertEntriesWhitespaces(
            for: tableWithStringRows,
            considering: columnMaxWidths
        )
        
        tableWithStringRows = insertMargins(for: tableWithStringRows)
        
        var flatStringRows = flatStringRows(for: tableWithStringRows)
        flatStringRows = flatStringRows.map({ row in
            if isBorderAround {
                return verticalLine + row + verticalLine
            }
            return row
        })
        
        columnMaxWidths = self.columnMaxWidths(for: tableWithStringRows)
        
        let separateLine = separateLine(columnMaxWidths: columnMaxWidths)
        
        if columnTitles.count != 0 {
            if isSeparateRows {
                flatStringRows = Array(flatStringRows.map { [$0] }.joined(separator: [separateLine]))
            } else {
                flatStringRows.insert(separateLine, at: 1)
            }
        }
        
        if isBorderAround {
            flatStringRows.insert(separateLine, at: 0)
            flatStringRows.append(separateLine)
        }
        
        let tableBody = flatStringRows.joined(separator: newLine)
        
        if let tableTitle = tableTitle {
            return tableTitle + newLine + tableBody
        } else {
            return tableBody
        }
    }
    
    private func separateLine(columnMaxWidths: [Int]) -> String {
        var line = ""
        
        for (index, width) in columnMaxWidths.enumerated() {
            if index == 0 && isBorderAround {
                line.append(crossing)
            }
            
            line.append(String(repeating: horisontalLine, count: width))
            
            if index < columnMaxWidths.count - 1 {
                line.append(crossing)
            }
            
            if index == columnMaxWidths.count - 1 && isBorderAround {
                line.append(crossing)
            }
        }
        return line
    }
    
    // Преобразованная таблица, в которой все элементы приведены к строкам
    private var tableWithStringRows: [[String]] {
        var table = [[String]]()
        
        table.append(columnTitles)
        
        rows.forEach { singleRow in
            let stringArrayRow = singleRow.map { rowEntry in
                roundIfPossible(entry: rowEntry.stringRepresentation)
            }
            table.append(stringArrayRow)
        }
        
        return table
    }
    
    private func columnMaxWidths(for table: [[String]]) -> [Int] {
        var widths = [Int].init(repeating: 0, count: columnCount)
        
        table.forEach { row in
            for (index, entry) in row.enumerated() {
                widths[index] = max(widths[index], entry.count)
            }
        }
        
        return widths
    }
    
    private func insertEntriesWhitespaces(for table: [[String]], considering maxWidth: [Int]) -> [[String]] {
        func addRightWhitespacesIfNeeded(to string: String, and maxCount: Int) -> String {
            var string = string
            if string.count < maxCount {
                string.append(String(repeating: " ", count: maxCount - string.count))
            }
            return string
        }
        
        var newTable = [[String]]()

        table.forEach { row in
            var newRow = [String]()
            for (columnIndex, entry) in row.enumerated() {
                newRow.append(addRightWhitespacesIfNeeded(to: entry, and: maxWidth[columnIndex]))
            }
            newTable.append(newRow)
        }
        
        return newTable
    }
    
    private func insertMargins(for table: [[String]]) -> [[String]] {
        var newTable = [[String]]()
        
        table.forEach { row in
            var newRow = [String]()
            for (columnIndex, entry) in row.enumerated() {
                var newEntry = entry
                if needToAppendWhitespaceAtBeginningOfEntry(at: columnIndex) {
                    newEntry = " " + newEntry
                }
                if needToAppendWhitespaceAtEndOfEntry(at: columnIndex) {
                    newEntry.append(" ")
                }
                newRow.append(newEntry)
            }
            newTable.append(newRow)
        }
        
        return newTable
    }
    
    private func flatStringRows(for table: [[String]]) -> [String] {
        table.map { row -> String in
            row.joined(separator: verticalLine)
        }
    }
    
    private func needToAppendWhitespaceAtBeginningOfEntry(at index: Int) -> Bool {
        if isInsertMargins {
            if !isBorderAround && index == 0 {
                return false
            } else {
                return true
            }
        } else {
            return false
        }
    }
    
    private func needToAppendWhitespaceAtEndOfEntry(at index: Int) -> Bool {
        if isInsertMargins {
            if !isBorderAround && index == columnCount - 1 {
                return false
            } else {
                return true
            }
        } else {
            return false
        }
    }
    
    private func roundIfPossible(entry: String) -> String {
        guard let accuracy = accuracy else {
            return entry
        }
        
        guard !entry.isEmpty else {
            return entry
        }
        
        if Int(entry) != nil {
            return entry
        }
        
        guard let double = Double(entry) else {
            return entry
        }
        
        let rounded = (double * pow(10, Double(accuracy))).rounded() / pow(10, Double(accuracy))
        
        return String(rounded)
    }
}

extension String: RowEntry {
    var stringRepresentation: String {
        return self
    }
}

extension Int: RowEntry {
    var stringRepresentation: String {
        return String(self)
    }
}

extension Double: RowEntry {
    var stringRepresentation: String {
        return String(self)
    }
}
