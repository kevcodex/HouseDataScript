//
//  HouseMetadata.swift
//  Source
//
//  Created by Kirby on 10/13/18.
//

import Foundation

struct HouseMetadata: Codable {
    let result: Result
    
    struct Result: Codable {
        let sqft: Int?
        let streetNumber: String
        let street: String
        let apt: String?
        
        let urlString: String?
        
        let bed: Double?
        let bath: Double?
        
        let priceHistorys: [PriceHistory]?
        
        var fullStreetAddress: String {
            return streetNumber + " " + street + " #" + (apt ?? "")
        }
        
        enum CodingKeys: String, CodingKey {
            case sqft = "sq"
            case streetNumber = "stn"
            case street = "str"
            case apt
            
            case urlString = "murl"
            
            case bed = "bd"
            case bath = "ba"
            
            case priceHistorys = "prh"
        }
        
        struct PriceHistory: Codable {
            let date: String
            let price: String
            let eventType: EventType?
            
            init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: Keys.self)
                
                date = try values.decode(String.self, forKey: .date)
                price = try values.decode(String.self, forKey: .price)
                
                let typeString = try values.decode(String.self, forKey: .eventType)
                eventType = EventType(string: typeString)
            }
            
            enum Keys: String, CodingKey {
                case date
                case price
                case eventType = "type"
            }
            
            enum EventType: String, CustomStringConvertible, Codable {
                case active
                case pending
                case sold
                case unknown
                
                init?(string: String?) {
                    
                    guard let string = string else {
                        return nil
                    }
                    
                    let lowercased = string.lowercased()
                    
//                    // Different strings of potential active types
//                    let activeArrayStrings = ["active", "listed", "changed"]
//
//                    for string in activeArrayStrings {
//                        if lowercased.contains(string) {
//                            self = .active
//                            return
//                        }
//                    }
//
//                    if lowercased.contains("pending") {
//                        self = .pending
//                    } else
                    if lowercased.contains("sold") {
                        self = .sold
                    } else {
                        self = .unknown
                    }
                }
                
                var description: String {
                    switch self {
                        
                    case .active:
                        return "Active"
                    case .pending:
                        return "Pending"
                    case .sold:
                        return "Sold"
                    case .unknown:
                        return "Unknown"
                    }
                }
            }
        }
    }
}
