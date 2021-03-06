//
//  SKLDLog.swift
//  SKLogDebuggerDemo
//
//  Created by yukithehero on 2017/04/20.
//  Copyright © 2017年 yukithehero. All rights reserved.
//

import Foundation

class SKLDLog: NSObject {
    var action = ""
    var createdAt = ""

    var rawString = ""
    var index = ""
    
    init(action: String, string: String) {
        self.action = action
        
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "HH:mm:ss.SSSS"
        createdAt = df.string(from: Date())
        
        rawString = string
        
        index = "\(action)::\(rawString)"
    }
}
