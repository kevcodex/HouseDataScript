//
//  FetchHouseMetadataOperation.swift
//  Source
//
//  Created by Kirby on 10/21/18.
//

import Foundation
import ScriptHelpers
import MiniNe

class FetchHouseMetadataOperation: AsyncOperation {
    
    // Inputs
    let listingID: String
    
    init(listingID: String) {
        self.listingID = listingID
    }
    
    private let client = MiniNeClient()
    
    // Outputs
    var result: Result<HouseMetadata, MiniNeError>?
    
    
    override func execute() {
        guard canExecute() else {
            finish()
            return
        }
        
        let parameters = ["id": listingID]
        let headers = ["User-Agent": "tr-src/IphoneApp tr-ver/11.0 tr-osv/12.0"]
        
        let request = TruliaAPIRequest(path: "/app/v8/detail",
                                       method: .get,
                                       parameters: parameters,
                                       headers: headers)
        
        client.send(request: request) { [weak self] (result) in
            
            guard let strongSelf = self, strongSelf.canExecute() else {
                self?.finish()
                return
            }
            
            switch result {
                
            case .success(let response):
                do {
                    let houseMetadata = try App.jsonDecoder.decode(HouseMetadata.self,
                                                                   from: response.data)
                    
                    strongSelf.result = Result(value: houseMetadata)
                    
                } catch {
                    // TODO: - Improve
                    strongSelf.result = Result(error: .unknown)
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
