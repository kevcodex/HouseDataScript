//
//  App.swift
//  Source
//
//  Created by Kevin Chen on 6/26/18.

import Foundation
import MiniNe
import Kanna

public class App {
    
    static let jsonDecoder: JSONDecoder = {
        return JSONDecoder()
    }()
    
    public static func start() {
        let client = MiniNeClient()
        let request = TruliaRequest(path: "/property-sitemap/CA/San-Diego-County-06073/92130/Carmel_Vista_Rd/")
        
        let runner = SwiftScriptRunner()
        
        // Get all the properties list
        runner.lock()
        var urlStringPaths: [String] = []
        client.send(request: request) { (result) in
            switch result {
                
            case .success(let response):
                if let doc = try? HTML(html: response.data, encoding: .utf8) {
                    let allLinks = doc.xpath("//a[@class='clickable h7 ']")
                    for link in allLinks {
                        if let urlString = link["href"],
                            let url = URL(string: urlString) {
                            urlStringPaths.append(url.path)
                        }
                    }
                }
            case .failure(let error):
                print(error)
            }
            
            runner.unlock()
        }
        
        runner.wait()
        
        
        // Fetch listing ID for each property
        
        var listingIds: [String] = []
        
        for houseURLPath in urlStringPaths {
            let propertyRequest = TruliaRequest(path: houseURLPath)
            
            // TODO: - temp
            if listingIds.count > 3 {
                break
            }
            
            runner.lock()
            client.send(request: propertyRequest) { (result) in
                
                switch result {
                    
                case .success(let response):
                    let string = String(data: response.data, encoding: .utf8) ?? ""

                    let pattern = "(?<=listingId:\\s)(\\S+)"

                    let reg = try? NSRegularExpression(pattern: pattern, options: [])
                    
                    var newListingID = ""
                    
                    if let match = reg?.firstMatch(
                        in: string,
                        options: [.withTransparentBounds],
                        range: NSRange(location: 0, length: string.count)),
                        let range = Range(match.range, in: string) {
                        
                        let rawListingID = String(string[range])
                        
                        // TODO: - Fix
                        let listingID = rawListingID.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: ",", with: "")
                        
                        if !listingID.isEmpty {
                            newListingID = listingID
                        }
                    }
                    
                    // backup regex, cleanup all of this
//                    if newListingID.isEmpty {
//
//                        let backupPattern = "(?<=\"listingID\":)(.+?(?=,))"
//
//                        let regBackup = try? NSRegularExpression(pattern: backupPattern, options: [])
//
//                        if let match = regBackup?.firstMatch(
//                            in: string,
//                            options: [.withTransparentBounds],
//                            range: NSRange(location: 0, length: string.count)),
//                            let range = Range(match.range, in: string) {
//
//                            let rawListingID = String(string[range])
//
//                            if !rawListingID.isEmpty {
//                                newListingID = rawListingID
//                            }
//                        }
//                    }
                    
                    if !newListingID.isEmpty {
                        listingIds.append(newListingID)
                    }
         
                case .failure(let error):
                    print(error)
                }
                
                runner.unlock()
            }
            
            runner.wait()
        }
        
        // Make API call to get real info for each listing
        // Parse info
        // Put info into CSV
        
        let workingDirectory = FileManager.default.currentDirectoryPath
        let csvFilePath = workingDirectory + "/homeData.csv"
        let csvFileURL = URL(fileURLWithPath: csvFilePath)
        
        for listingID in listingIds {
            
            let parameters = ["id": listingID]
            let headers = ["User-Agent": "tr-src/IphoneApp tr-ver/11.0 tr-osv/12.0"]
            
            let request = TruliaAPIRequest(path: "/app/v8/detail",
                                           method: .get,
                                           parameters: parameters,
                                           headers: headers)
            
            runner.lock()
            
            client.send(request: request) { (result) in
                switch result {
                    
                case .success(let response):
                    do {
                        let houseMetadata = try App.jsonDecoder.decode(HouseMetadata.self,
                                                                from: response.data)
                        
                        let result = houseMetadata.result
                        
                        if let priceHistorys = houseMetadata.result.priceHistorys {
                            for priceHistory in priceHistorys {
                                
                                guard priceHistory.eventType == .sold else {
                                    continue
                                }
                                // address - sell type - year - sq ft-  bd - br - sell price - url
                                
                                let address = result.fullStreetAddress
                                let eventType = priceHistory.eventType ?? .unknown
                                let year = priceHistory.date
                                let sqft = result.sqft ?? 0
                                let bed = result.bed ?? 0
                                let bath = result.bath ?? 0
                                let sellPrice = priceHistory.price
                                let url = result.urlString ?? ""
                                
                                let stringConvertibleArray: [CustomStringConvertible] = [address, eventType, year, sqft, bed, bath, sellPrice, url]
                                    
                                try CSVWriter.addNewRowWithItems(stringConvertibleArray, to: csvFileURL)
                            }
                        }
                        

                    } catch {
                        print(error)
                    }
                    
                case .failure(let error):
                    print(error)
                }
                
                runner.unlock()
            }

            runner.wait()
        }
    }
}

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
