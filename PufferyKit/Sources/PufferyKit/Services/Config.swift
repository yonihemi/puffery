//
//  Config.swift
//  Puffery
//
//  Created by Valentin Knabel on 25.04.20.
//  Copyright © 2020 Valentin Knabel. All rights reserved.
//

import Foundation

public struct Config {
    public var apiURL: URL

    public var ackeeDomainID: String
    public var ackeeServerURL: URL
    public var ackeeAppURL: URL
}

extension Config {
    public static func prod() -> Config {
        Config(
            apiURL: URL(string: Bundle.main.infoDictionary!["PUFFERY_API_URL"] as! String)!,
            ackeeDomainID: Bundle.main.infoDictionary!["ACKEE_DOMAIN_ID"] as! String,
            ackeeServerURL: URL(string: Bundle.main.infoDictionary!["ACKEE_SERVER_URL"] as! String)!,
            ackeeAppURL: URL(string: Bundle.main.infoDictionary!["ACKEE_APP_URL"] as! String)!
        )
    }
}
