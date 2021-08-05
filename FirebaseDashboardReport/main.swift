//
//  main.swift
//  FirebaseDashboardReport
//
//  Created by Rinat Abidullin on 05.08.2021.
//

import ArgumentParser

enum Command {}

extension Command {
    struct Main: ParsableCommand {
        static var configuration: CommandConfiguration {
            .init(
                commandName: "fdr",
                abstract: "A program to parse .csv file contains Firebase dashboard report",
                version: "0.0.1",
                subcommands: [
                    Command.OSVersions.self
                ]
            )
        }
    }
}

Command.Main.main()
