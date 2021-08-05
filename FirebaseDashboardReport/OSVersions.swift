//
//  OSVersions.swift
//  FirebaseDashboardReport
//
//  Created by Rinat Abidullin on 05.08.2021.
//

import ArgumentParser
import Foundation

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

            func printOsVersion() {
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
                
                class TableRaw {
                    var os: String
                    var users: String
                    var percentOfAllUsers: String
                    var percentOfiOS: String
                    var percentOfAndroid: String
                    
                    init(
                        os: String,
                        users: String,
                        percentOfAllUsers: String,
                        percentOfiOS: String,
                        percentOfAndroid: String
                    ) {
                        self.os = os
                        self.users = users
                        self.percentOfAllUsers = percentOfAllUsers
                        self.percentOfiOS = percentOfiOS
                        self.percentOfAndroid = percentOfAndroid
                    }
                    
                    var description: String {
                        return "\(os)"
                    }
                }
                
                var table = [TableRaw]()
                table.append(TableRaw(
                    os: "OS Version",
                    users: "Users",
                    percentOfAllUsers: "% of all users",
                    percentOfiOS: "% of iOS",
                    percentOfAndroid: "% of Android"
                ))
                
                for osVersion in sortedOsVersions {
                    let percentOfAllUsers = ((Double(osVersion.userCount) / Double(allUsersCount) * 1000).rounded() / 10.0)
                    let percentOfiOS = osVersion.platform == "iOS" ? ((Double(osVersion.userCount) / Double(iosUsersCount) * 1000).rounded() / 10.0) : 0
                    let percentOfAndroid = osVersion.platform == "Android" ?  ((Double(osVersion.userCount) / Double(androidUsersCount) * 1000).rounded() / 10.0) : 0
                    
                    let tableRaw = TableRaw(
                        os: osVersion.platform + " " + String(osVersion.majorVersion),
                        users: String(osVersion.userCount),
                        percentOfAllUsers: String(percentOfAllUsers),
                        percentOfiOS: percentOfiOS != 0 ? String(percentOfiOS) : "",
                        percentOfAndroid: percentOfAndroid != 0 ? String(percentOfAndroid) : ""
                    )
                    table.append(tableRaw)
                }
                
                let maxLettersOS = table.map({ $0.os.count }).max()!
                let maxLettersUsers = table.map({ $0.users.count }).max()!
                let maxLettersPercentOfAllUsers = table.map({ $0.percentOfAllUsers.count }).max()!
                let maxLettersPercentOfiOS = table.map({ $0.percentOfiOS.count }).max()!
                let maxLettersPercentOfAndroid = table.map({ $0.percentOfAndroid.count }).max()!
                
                func addWhitespaceIfNeeded(to string: String, and maxCount: Int) -> String {
                    var string = string
                    if string.count < maxLettersOS {
                        string.append(String(repeating: " ", count: maxCount - string.count))
                    }
                    return string
                }
                
                func printLine() {
                    let node = "+"
                    let border = "-"
                    print(
                        node + String(repeating: border, count: maxLettersOS + 2) +
                        node + String(repeating: border, count: maxLettersUsers + 2) +
                        node + String(repeating: border, count: maxLettersPercentOfAllUsers + 2) +
                        node + String(repeating: border, count: maxLettersPercentOfiOS + 2) +
                        node + String(repeating: border, count: maxLettersPercentOfAndroid + 2) +
                        node
                    )
                }
                
                printLine()
                for raw in table {
                    let os = addWhitespaceIfNeeded(to: raw.os, and: maxLettersOS)
                    let users = addWhitespaceIfNeeded(to: raw.users, and: maxLettersUsers)
                    let percentAllUsers = addWhitespaceIfNeeded(to: raw.percentOfAllUsers, and: maxLettersPercentOfAllUsers)
                    let percentiOSUsers = addWhitespaceIfNeeded(to: raw.percentOfiOS, and: maxLettersPercentOfiOS)
                    let percentAndroidUsers = addWhitespaceIfNeeded(to: raw.percentOfAndroid, and: maxLettersPercentOfAndroid)
                    print("""
                        | \(os) | \(users) | \(percentAllUsers) | \(percentiOSUsers) | \(percentAndroidUsers) |
                        """)
                    printLine()
                }
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            
            let dateFormatterPrint = DateFormatter()
            dateFormatterPrint.dateFormat = "dd.MM.yyyy"
            
            print("From \(dateFormatterPrint.string(from: dateFormatter.date(from: startDate)!)) to \(dateFormatterPrint.string(from: dateFormatter.date(from: endDate)!))")
            printOsVersion()
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

enum CommandError: Error {
    case with(info: String)

    public var errorDescription: String? {
        switch self {
        case .with(let info):
            return info
        }
    }
}
