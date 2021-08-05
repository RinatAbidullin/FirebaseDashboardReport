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
        
        func run() throws {
            // Чтение csv файла
            guard let contents = try? String(contentsOfFile: csvfilepath, encoding: .utf8) else {
                throw CommandError.with(info: "The csv file was not found on the passed path")
            }
            
            // Выделяем строки с версиями OS
            var osVersionsRawWithTitles = [String]()
            let contentLines = contents.components(separatedBy: "\n")
            var startFound = false
            for (index, line) in contentLines.enumerated() {
                let line = line.trimmingCharacters(in: .newlines)
                if line.hasPrefix("OS with version,Users") {
                    osVersionsRawWithTitles.append(
                        contentLines[index - 2].trimmingCharacters(in: .newlines)
                    )
                    osVersionsRawWithTitles.append(
                        contentLines[index - 1].trimmingCharacters(in: .newlines)
                    )
                    startFound = true
                }
                if startFound && !line.isEmpty {
                    osVersionsRawWithTitles.append(
                        line.trimmingCharacters(in: .newlines)
                    )
                } else if startFound && line.isEmpty {
                    break
                }
            }
            
            var osVersions = [OsVersion]()

            let startDate = osVersionsRawWithTitles[0].components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces)
            let endDate = osVersionsRawWithTitles[1].components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces)
            let osVersionsRaw = osVersionsRawWithTitles[3...].joined(separator: "\n")
            
            let lines = osVersionsRaw.components(separatedBy: "\n")

            for line in lines {
                // iOS 12.3.2, 1
                // Android 4.2.2, 1
                let osComponents = line.components(separatedBy: ",") // iOS 12.3.2, 1
                let osNameWithVersion = osComponents[0] // iOS 12.3.2
                let userCount = Int(osComponents[1])! // 1
                
                let osNameWithVersionComponents = osNameWithVersion.components(separatedBy: " ") // iOS 12.3.2
                let osName = osNameWithVersionComponents[0] // iOS
                let osVersion = osNameWithVersionComponents[1] // 12.3.2

                let osVersionComponents = osVersion.components(separatedBy: ".") // 12.3.2
                let osVersionMajor = Int(osVersionComponents[0])! // 12
                
                if let existedOsVersion = osVersions.filter(
                    { $0.platform == osName && $0.majorVersion == osVersionMajor }
                ).first {
                    existedOsVersion.userCount += userCount
                } else {
                    osVersions.append(OsVersion(platform: osName, majorVersion: osVersionMajor, userCount: userCount))
                }
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            
            let dateFormatterPrint = DateFormatter()
            dateFormatterPrint.dateFormat = "dd.MM.yyyy"
            
            let tableTitle = "From \(dateFormatterPrint.string(from: dateFormatter.date(from: startDate)!)) to \(dateFormatterPrint.string(from: dateFormatter.date(from: endDate)!))"
            
            let table = Table(
                columnCount: 5,
                tableTitle: tableTitle,
                accuracy: 1,
                isInsertMargins: true,
                isBorderAround: true,
                isSeparateRows: false
            )
            
            do {
                try table.set(columnTitles: [
                    "OS version",
                    "Users",
                    "% of all users",
                    "% of iOS",
                    "% of Android"
                ])
                
                let allUsersCount = osVersions
                    .map { $0.userCount }.reduce(0, +)
                let iosUsersCount = osVersions
                    .filter({ $0.platform == "iOS" })
                    .map { $0.userCount }.reduce(0, +)
                let androidUsersCount = osVersions
                    .filter({ $0.platform == "Android" })
                    .map { $0.userCount }.reduce(0, +)
                
                let sortedOsVersions = osVersions.sorted {
                    if $0.platform != $1.platform {
                        return $0.platform > $1.platform
                    } else {
                        return $0.majorVersion > $1.majorVersion
                    }
                }
                
                let rows = sortedOsVersions.compactMap { osVersion -> Row? in
                    if osVersion.platform.hasPrefix("iOS") {
                        return CommonIOSVersionRow(
                            osVersion: osVersion,
                            allUsersCount: allUsersCount,
                            iOSUsersCount: iosUsersCount
                        )
                    } else if osVersion.platform.hasPrefix("Android") {
                        return CommonAndroidVersionRow(
                            osVersion: osVersion,
                            allUsersCount: allUsersCount,
                            androidUsersCount: androidUsersCount
                        )
                    }
                    return nil
                }
                
                try table.append(rows: rows)
            } catch {
                throw error
            }
            
            table.print()
        }
    }
}

class OsVersion {
    let platform: String
    let majorVersion: Int
    var userCount: Int
    
    init(platform: String, majorVersion: Int, userCount: Int) {
        self.platform = platform
        self.majorVersion = majorVersion
        self.userCount = userCount
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
