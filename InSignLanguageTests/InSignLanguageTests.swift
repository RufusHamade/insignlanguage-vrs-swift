//
//  InSignLanguageTests.swift
//  InSignLanguageTests
//
//  Created by Yvonne Eva Hannah Louise DeBrett on 17/04/2017.
//
//

import XCTest
@testable import InSignLanguage

class InSignLanguageTests: XCTestCase {
    
    let semaphore = DispatchSemaphore(value: 0)
    
    func callback() {
        print("xxxx got gere")
        //self.semaphore.signal()
    }
    
    //MARK: SessionModel tests
    func testInit() {
        let sm = SessionModel.sharedInstance
        sm.setName("Micky Mouse")
    }
}
