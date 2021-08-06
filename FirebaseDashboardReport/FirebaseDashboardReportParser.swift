//
//  FirebaseDashboardReportParser.swift
//  FirebaseDashboardReport
//
//  Created by Rinat Abidullin on 06.08.2021.
//

import Foundation

struct FirebaseDashboardReportConstants {
    static let rowOSWithVersionUsers = "OS with version,Users"
}

struct FirebaseDashboardReportParser {
    let csvRawContent: String
}

extension FirebaseDashboardReportParser {
    func osVersions(dateFormatter: DateFormatter? = nil) -> OsVersions {
        // Выделяем строки с версиями OS
        var osVersionsRawWithTitles = [String]()
        let contentLines = csvRawContent.components(separatedBy: "\n")
        var startFound = false
        for (index, line) in contentLines.enumerated() {
            let line = line.trimmingCharacters(in: .newlines)
            if line.hasPrefix(FirebaseDashboardReportConstants.rowOSWithVersionUsers) {
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
        
        // Диапазон дат
        
        let startDate = osVersionsRawWithTitles[0].components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces)
        let endDate = osVersionsRawWithTitles[1].components(separatedBy: ":")[1].trimmingCharacters(in: .whitespaces)
        let osVersionsRaw = osVersionsRawWithTitles[3...].joined(separator: "\n")
        
        let dateFormatterForReadCSV = DateFormatter()
        dateFormatterForReadCSV.dateFormat = "yyyyMMdd"
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "dd.MM.yyyy"
        
        let startDateString = dateFormatterPrint.string(from: dateFormatterForReadCSV.date(from: startDate)!)
        let endDateString = dateFormatterPrint.string(from: dateFormatterForReadCSV.date(from: endDate)!)
        
        // Строки с версиями OS
        
        var osVersions = [OsVersion]()
        
        let lines = osVersionsRaw.components(separatedBy: "\n")

        for line in lines {
            // iOS 12.3.2, 1
            // Android 4.2.2, 1
            let osComponents = line.components(separatedBy: ",") // iOS 12.3.2, 1
            let osNameWithVersion = osComponents[0].trimmingCharacters(in: .whitespacesAndNewlines) // iOS 12.3.2
            let userCount = Int(osComponents[1].trimmingCharacters(in: .whitespacesAndNewlines))! // 1
            
            let osNameWithVersionComponents = osNameWithVersion.components(separatedBy: " ") // iOS 12.3.2
            let osName = osNameWithVersionComponents[0].trimmingCharacters(in: .whitespacesAndNewlines) // iOS
            let osVersion = osNameWithVersionComponents[1].trimmingCharacters(in: .whitespacesAndNewlines) // 12.3.2

            let osVersionComponents = osVersion.components(separatedBy: ".") // 12.3.2
            let osVersionMajor = Int(osVersionComponents[0].trimmingCharacters(in: .whitespacesAndNewlines))! // 12
            
            if let existedOsVersion = osVersions.filter(
                { $0.platform == osName && $0.majorVersion == osVersionMajor }
            ).first {
                existedOsVersion.userCount += userCount
            } else {
                osVersions.append(OsVersion(platform: osName, majorVersion: osVersionMajor, userCount: userCount))
            }
        }
        
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
        
        let resultVersions = OsVersions(
            versions: sortedOsVersions,
            allUsersCount: allUsersCount,
            iOSUsersCount: iosUsersCount,
            androidUsersCount: androidUsersCount,
            startDate: startDateString,
            endDate: endDateString
        )
        
        return resultVersions
    }
}

struct OsVersions {
    let versions: [OsVersion]
    let allUsersCount: Int
    let iOSUsersCount: Int
    let androidUsersCount: Int
    let startDate: String
    let endDate: String
    
    var iOSUsersPersent: Double {
        Double(iOSUsersCount) / Double(allUsersCount) * 100
    }
    
    var androidUsersPersent: Double {
        Double(androidUsersCount) / Double(allUsersCount) * 100
    }
    
    func iOSUsersPersent(accuracy: Int) -> Double {
        (iOSUsersPersent * pow(10, Double(accuracy))).rounded() / pow(10, Double(accuracy))
    }
    
    func androidUsersPersent(accuracy: Int) -> Double {
        (androidUsersPersent * pow(10, Double(accuracy))).rounded() / pow(10, Double(accuracy))
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

enum OSPlatform: String {
    case iOS = "iOS"
    case Android = "Android"
}
