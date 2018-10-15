//
//  TruliaRequests.swift
//  Source
//
//  Created by Kirby on 10/14/18.
//

import MiniNe
import Foundation


struct TruliaRequest: NetworkRequest {
    var baseURL: URL? {
        return URL(string: "https://www.trulia.com")
    }
    
    let path: String
    
    let method: HTTPMethod
    
    let parameters: [String : Any]?
    
    let headers: [String : Any]?
    
    init(path: String,
         method: HTTPMethod = .get,
         parameters: [String : Any]? = nil,
         headers: [String : Any]? = nil) {
        
        self.path = path
        self.method = method
        self.parameters = parameters
        self.headers = headers
    }
}

struct TruliaAPIRequest: NetworkRequest {
    var baseURL: URL? {
        return URL(string: "https://origin-api.trulia.com")
    }
    
    let path: String
    
    let method: HTTPMethod
    
    let parameters: [String : Any]?
    
    let headers: [String : Any]?
    
    init(path: String,
         method: HTTPMethod = .get,
         parameters: [String : Any]? = nil,
         headers: [String : Any]? = nil) {
        
        self.path = path
        self.method = method
        self.parameters = parameters
        self.headers = headers
    }
}
