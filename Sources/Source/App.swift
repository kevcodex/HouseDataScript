//
//  App.swift
//  Source
//
//  Created by Kevin Chen on 6/26/18.

import Foundation
import MiniNe
import Kanna
import ScriptHelpers

public class App {
    
    static let jsonDecoder: JSONDecoder = {
        return JSONDecoder()
    }()
    
    public init() { }
    
    public func start() {
        
        // MARK: - Get all the properties list URLs
        Console.writeMessage("**Fetching all property URLs")
        guard let urlStringPaths = fetchAllPropertyURLs() else {
            Console.writeMessage("Failed to get all properties in area", styled: .red)
            exit(1)
        }
        
        // MARK: - Fetch listing ID for each property
        Console.writeMessage("**Fetching all listing IDs")
        guard let listingIDs = fetchListingIDs(urlStringPaths: urlStringPaths,
                                               maxCount: .limited(count: 5)) else {
            Console.writeMessage("Failed to get any listing IDs", styled: .red)
            exit(1)
        }
        
        
        // MARK: - Fetch house metadata for each listingID
        Console.writeMessage("**Fetching all House Metdata")
        guard let allHouseMetadata = fetchAllHouseMetadata(listingIDs: listingIDs) else {
            Console.writeMessage("Failed to get any house metadata", styled: .red)
            exit(1)
        }
        
        // MARK: - Put house metadata into CSV
        Console.writeMessage("**Writing data to CSV")
        let workingDirectory = FileManager.default.currentDirectoryPath
        let csvFilePath = workingDirectory + "/homeData.csv"
        let csvFileURL = URL(fileURLWithPath: csvFilePath)
        
        writeToCSV(houseMetadatas: allHouseMetadata, csvURL: csvFileURL)
    }
}

// MARK: - Steps
extension App {
    
    // MARK: Fetch All Property URLs Helper
    func fetchAllPropertyURLs() -> [String]? {
        let request = TruliaRequest(path: "/property-sitemap/CA/San-Diego-County-06073/92130/Carmel_Vista_Rd/")
        
        var urlStringPaths: [String] = []
        sendRequest(request) { (result) in
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
        }
        
        return urlStringPaths.nonEmpty
    }
    
    // MARK: Fetch Listing IDs helper
    /// Fetch all the listing ids which is obtained from the raw html in link.
    /// - Parameter urlStringPaths: All the url string paths (not including the base path).
    /// - Parameter maxCount: The maximum amount of ids to fetch. Set to limited with specified count in which only that amount will be fetched
    func fetchListingIDs(urlStringPaths: [String], maxCount: MaxCount = .all) -> [String]? {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 5
        
        var listingIds: [String] = []
        
        for houseURLPath in urlStringPaths {

            let fetchListingIDOperation = FetchListingIDOperation(houseURLPath: houseURLPath)
            
            let completionBlock = BlockOperation { [weak fetchListingIDOperation] in
                guard let result = fetchListingIDOperation?.result else {
                    return
                }
                
                if case let MaxCount.limited(count) = maxCount {
                    if listingIds.count >= count {
                        operationQueue.cancelAllOperations()
                        return
                    }
                }
                
                switch result {
                    
                case .success(let listingID):
                    listingIds.append(listingID)
                case .failure(let error):
                    print(error)
                }
            }
            
            completionBlock.addDependency(fetchListingIDOperation)
            
            operationQueue.addOperations([fetchListingIDOperation,
                                          completionBlock],
                                         waitUntilFinished: false)
        }
        
        operationQueue.waitUntilAllOperationsAreFinished()
        
        return listingIds.nonEmpty
    }
    
    func fetchAllHouseMetadata(listingIDs: [String]) -> [HouseMetadata]? {
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 5
        
        var houseMetadatas: [HouseMetadata] = []
        
        for listingID in listingIDs {
            
            let fetchHouseMetadata = FetchHouseMetadataOperation(listingID: listingID)
            
            let completionBlock = BlockOperation { [weak fetchHouseMetadata] in
                guard let result = fetchHouseMetadata?.result else {
                    return
                }
                
                switch result {
                    
                case .success(let metadata):
                    houseMetadatas.append(metadata)
                case .failure(let error):
                    print(error)
                }
            }
            
            completionBlock.addDependency(fetchHouseMetadata)
            
            operationQueue.addOperations([fetchHouseMetadata,
                                          completionBlock],
                                         waitUntilFinished: false)
        }
        
        operationQueue.waitUntilAllOperationsAreFinished()
        
        return houseMetadatas.nonEmpty
    }
    
    func writeToCSV(houseMetadatas: [HouseMetadata], csvURL: URL) {
        
        for houseMetadata in houseMetadatas {
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
                    
                    do {
                        try CSVWriter.addNewRowWithItems(stringConvertibleArray, to: csvURL)
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
}

// MARK: - Helpers
extension App {
    
    /// Perform some async block without the script finishing.
    /// Call completion when async block is done
    private func performBlockingAsyncMethod( asyncBlock: (_ completion: @escaping () -> Void) -> Void) {
        let runner = SwiftScriptRunner()
        runner.lock()
        
        asyncBlock {
            runner.unlock()
        }
        
        runner.wait()
    }
    
    /// Send network request async and block until done
    private func sendRequest<Request: NetworkRequest>(_ request: Request,
                                                      completion: @escaping (Result<Response, MiniNeError>) -> Void) {
        
        let runner = SwiftScriptRunner()
        let client = MiniNeClient()
        
        runner.lock()
        
        client.send(request: request) { (result) in
            
            completion(result)
            
            runner.unlock()
        }
        
        runner.wait()
    }
}

extension App {
    enum MaxCount: Equatable {
        case all
        case limited(count: Int)
    }
}




/// Fetch all the listing ids which is obtained from the raw html in link.
/// - Parameter urlStringPaths: All the url string paths (not including the base path).
/// - Parameter maxCount: The maximum amount of ids to fetch. Set to limited with specified count in which only that amount will be fetched
//    func fetchListingIDs(urlStringPaths: [String], maxCount: MaxCount = .all) -> [String]? {
//
//        var listingIds: [String] = []
//
//        for houseURLPath in urlStringPaths {
//            let propertyRequest = TruliaRequest(path: houseURLPath)
//
//            if case let MaxCount.limited(count) = maxCount {
//                if listingIds.count >= count {
//                    break
//                }
//            }
//
//            sendRequest(propertyRequest) { (result) in
//
//                switch result {
//
//                case .success(let response):
//                    let string = String(data: response.data, encoding: .utf8) ?? ""
//
//                    let pattern = "(?<=listingId:\\s)(\\S+)"
//
//                    let reg = try? NSRegularExpression(pattern: pattern, options: [])
//
//                    var newListingID = ""
//
//                    if let match = reg?.firstMatch(
//                        in: string,
//                        options: [.withTransparentBounds],
//                        range: NSRange(location: 0, length: string.count)),
//                        let range = Range(match.range, in: string) {
//
//                        let rawListingID = String(string[range])
//
//                        // TODO: - Fix
//                        let listingID = rawListingID.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: ",", with: "")
//
//                        if !listingID.isEmpty {
//                            newListingID = listingID
//                        }
//                    }
//
//                    // backup regex, cleanup all of this
//                    //                    if newListingID.isEmpty {
//                    //
//                    //                        let backupPattern = "(?<=\"listingID\":)(.+?(?=,))"
//                    //
//                    //                        let regBackup = try? NSRegularExpression(pattern: backupPattern, options: [])
//                    //
//                    //                        if let match = regBackup?.firstMatch(
//                    //                            in: string,
//                    //                            options: [.withTransparentBounds],
//                    //                            range: NSRange(location: 0, length: string.count)),
//                    //                            let range = Range(match.range, in: string) {
//                    //
//                    //                            let rawListingID = String(string[range])
//                    //
//                    //                            if !rawListingID.isEmpty {
//                    //                                newListingID = rawListingID
//                    //                            }
//                    //                        }
//                    //                    }
//
//                    if !newListingID.isEmpty {
//                        listingIds.append(newListingID)
//                    }
//
//                case .failure(let error):
//                    print(error)
//                }
//            }
//        }
//
//        return listingIds.nonEmpty
//    }
