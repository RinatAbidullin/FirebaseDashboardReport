//
//  OSVersions.swift
//  FirebaseDashboardReport
//
//  Created by Rinat Abidullin on 05.08.2021.
//

import ArgumentParser
import Foundation

enum CommandError: LocalizedError {
    case with(info: String)

    public var errorDescription: String? {
        switch self {
        case .with(let info):
            return info
        }
    }
}

extension Command {
    struct OSVersions: ParsableCommand {
        static var configuration: CommandConfiguration {
            .init(
                commandName: "osversions",
                abstract: "Table view with OS versions"
            )
        }
        
        @Argument(help: "The first number")
        var csvfilepath: String
        
        @Flag(name: .long)
        var join: Bool = false
        
        func run() throws {
            // Чтение csv файла
            guard let content = try? String(contentsOfFile: csvfilepath, encoding: .utf8) else {
                throw CommandError.with(info: "The csv file was not found on the passed path")
            }
            
            let parser = FirebaseDashboardReportParser(csvRawContent: content)
            let versions = parser.osVersions()
            
            do {
                if join {
                    let tableTitle = """
                    \nFrom \(versions.startDate) to \(versions.endDate)
                    """
                    
                    let table = Table(
                        columnCount: 5,
                        tableTitle: tableTitle,
                        accuracy: 1,
                        isInsertMargins: true,
                        isBorderAround: true,
                        isSeparateRows: false
                    )
                    
                    try table.set(columnTitles: [
                        "OS version",
                        "Users",
                        "% of all users",
                        "% of iOS",
                        "% of Android"
                    ])
                    
                    let rows = versions.versions.compactMap { osVersion -> Row? in
                        if osVersion.platform.hasPrefix("iOS") {
                            return CommonIOSVersionRow(
                                osVersion: osVersion,
                                allUsersCount: versions.allUsersCount,
                                iOSUsersCount: versions.iOSUsersCount
                            )
                        } else if osVersion.platform.hasPrefix("Android") {
                            return CommonAndroidVersionRow(
                                osVersion: osVersion,
                                allUsersCount: versions.allUsersCount,
                                androidUsersCount: versions.androidUsersCount
                            )
                        }
                        return nil
                    }
                    
                    try table.append(rows: rows)
                    table.print()
                } else {
                    // Две отдельные таблицы
                    
                    // iOS
                    let iOSUsersPercent = versions.iOSUsersPersent(accuracy: 1)
                    
                    let iOSTableTitle = """
                    \nFrom \(versions.startDate) to \(versions.endDate)
                    iOS is used by \(iOSUsersPercent)% of users
                    """
                    
                    let iOSTable = Table(
                        columnCount: 3,
                        tableTitle: iOSTableTitle,
                        accuracy: 1,
                        isInsertMargins: true,
                        isBorderAround: true,
                        isSeparateRows: false
                    )
                    
                    try iOSTable.set(columnTitles: [
                        "OS version",
                        "Users",
                        "%"
                    ])
                    
                    let iOSRows = versions.versions.compactMap { osVersion -> Row? in
                        if osVersion.platform.hasPrefix("iOS") {
                            return SplitIOSVersionRow(
                                osVersion: osVersion,
                                allUsersCount: versions.allUsersCount,
                                iOSUsersCount: versions.iOSUsersCount
                            )
                        }
                        return nil
                    }
                    
                    try iOSTable.append(rows: iOSRows)
                    iOSTable.print()
                    
                    // Android
                    let androidUsersPercent = versions.androidUsersPersent(accuracy: 1)
                    
                    let androidTableTitle = """
                    \nFrom \(versions.startDate) to \(versions.endDate)
                    Android is used by \(androidUsersPercent)% of users
                    """
                    
                    let androidTable = Table(
                        columnCount: 3,
                        tableTitle: androidTableTitle,
                        accuracy: 1,
                        isInsertMargins: true,
                        isBorderAround: true,
                        isSeparateRows: false
                    )
                    
                    try androidTable.set(columnTitles: [
                        "OS version",
                        "Users",
                        "%"
                    ])
                    
                    let androidRows = versions.versions.compactMap { osVersion -> Row? in
                        if osVersion.platform.hasPrefix("Android") {
                            return SplitAndroidVersionRow(
                                osVersion: osVersion,
                                allUsersCount: versions.allUsersCount,
                                androidUsersCount: versions.androidUsersCount
                            )
                        }
                        return nil
                    }
                    
                    try androidTable.append(rows: androidRows)
                    androidTable.print()
                }
            } catch {
                throw error
            }
            print("")
        }
    }
}

struct CommonIOSVersionRow: Row {
    let osVersion: OsVersion
    let allUsersCount: Int
    let iOSUsersCount: Int
    
    var rowRepresentation: [RowEntry] {
        [
            "\(osVersion.platform) \(osVersion.majorVersion)",
            osVersion.userCount,
            Double(osVersion.userCount) / Double(allUsersCount) * 100,
            Double(osVersion.userCount) / Double(iOSUsersCount) * 100,
            EmptyRowEntry()
        ]
    }
}

struct CommonAndroidVersionRow: Row {
    let osVersion: OsVersion
    let allUsersCount: Int
    let androidUsersCount: Int
    
    var rowRepresentation: [RowEntry] {
        [
            "\(osVersion.platform) \(osVersion.majorVersion)",
            osVersion.userCount,
            Double(osVersion.userCount) / Double(allUsersCount) * 100,
            EmptyRowEntry(),
            Double(osVersion.userCount) / Double(androidUsersCount) * 100
        ]
    }
}

struct SplitIOSVersionRow: Row {
    let osVersion: OsVersion
    let allUsersCount: Int
    let iOSUsersCount: Int
    
    var rowRepresentation: [RowEntry] {
        [
            "\(osVersion.platform) \(osVersion.majorVersion)",
            osVersion.userCount,
            Double(osVersion.userCount) / Double(iOSUsersCount) * 100,
        ]
    }
}

struct SplitAndroidVersionRow: Row {
    let osVersion: OsVersion
    let allUsersCount: Int
    let androidUsersCount: Int
    
    var rowRepresentation: [RowEntry] {
        [
            "\(osVersion.platform) \(osVersion.majorVersion)",
            osVersion.userCount,
            Double(osVersion.userCount) / Double(androidUsersCount) * 100
        ]
    }
}
