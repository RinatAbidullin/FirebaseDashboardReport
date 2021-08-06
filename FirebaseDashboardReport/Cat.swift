//
//  Cat.swift
//  FirebaseDashboardReport
//
//  Created by Rinat Abidullin on 07.08.2021.
//

import ArgumentParser
import Foundation

extension Command {
    struct Cat: ParsableCommand {
        static var configuration: CommandConfiguration {
            .init(
                commandName: "cat",
                abstract: "You can be sad together with a cat"
            )
        }
        
        func run() throws {
            let cat = """
            
            　　　　　／＞　 フ
            　　　　　| 　_　 _|
            　 　　　／`ミ _x 彡
            　　 　 /　　　 　 |
            　　　 /　 ヽ　　 ﾉ
            　／￣|　　 |　|　|
            　| (￣ヽ＿_ヽ_)_)
            　＼二つ

            """
            
            print(cat)
        }
    }
}
