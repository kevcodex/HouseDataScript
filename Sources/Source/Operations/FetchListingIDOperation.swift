//
//  FetchListingIDOperation.swift
//  Source
//
//  Created by Kirby on 10/15/18.
//

import ScriptHelpers
import MiniNe
import Foundation

class FetchListingIDOperation: AsyncOperation {
    
    // Inputs
    let houseURLPath: String
    
    init(houseURLPath: String) {
        self.houseURLPath = houseURLPath
    }
    
    private let client = MiniNeClient()
    
    // Outputs
    var result: Result<String, MiniNeError>?
    
    
    override func execute() {
        guard canExecute() else {
            finish()
            return
        }
        
        let request = TruliaRequest(path: houseURLPath)
        
        client.send(request: request) { [weak self] (result) in
            
            guard let strongSelf = self, strongSelf.canExecute() else {
                self?.finish()
                return
            }
            
            switch result {
                
            case .success(let response):
                let string = String(data: response.data, encoding: .utf8) ?? ""
                
                let pattern = "(?<=listingId:\\s)(\\S+)"
                
                let reg = try? NSRegularExpression(pattern: pattern, options: [])
                
                
                if let match = reg?.firstMatch(in: string,
                                               options: [.withTransparentBounds],
                                               range: NSRange(location: 0, length: string.count)),
                    let range = Range(match.range, in: string) {
                    
                    let rawListingID = String(string[range])
                    
                    // TODO: - Fix
                    let listingID = rawListingID.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: ",", with: "")
                    
                    if !listingID.isEmpty {
                        strongSelf.result = Result(value: listingID)
                    }
                }
                
            case .failure(let error):
                strongSelf.result = Result(error: error)
            }
            
            strongSelf.finish()
        }
    }
    
    override func cancel() {
        client.invalidateAndCancel()

        super.cancel()
    }
}
