//
//  DataTransfer.swift
//  LigFinder WatchKit Extension
//
//  Created by Emil Neirup Jensen on 29/04/2021.
//

import WatchKit
import SwiftyJSON
import Alamofire


class DataTransfer: NSObject {
    let locationFetcher = Location()
    
    func getConnStatus(watchId: Int32) {

        AF.request("https://ligefinder.norre.cc/api/Watch/getWatchConnection/\(watchId)", parameters: nil, encoding: JSONEncoding.default, headers: nil).validate(statusCode: 200 ..< 299).responseJSON { AFdata in
            do {
                let json = try JSON(data: AFdata.data!)
                if let isConnected = json["isConnected"].bool {
                    print(isConnected)
                }
            } catch {
                print("Error: Trying to convert JSON data to string")
                return
            }
        }
    }
    
    func updateStatus(watchId: Int32, status: Int32, signType: Int32, hasSign: Bool) {
        
        locationFetcher.start()
        
        if let location = locationFetcher.lastKnownLocation {
            let locLong = location.longitude
            let locLait = location.latitude
            
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            let dateString = formatter.string(from: now)
            
            
            let params: Parameters = [
                "id": watchId,
                  "lastSignAndStatus": dateString,
                  "status": status,
                  "signType": signType,
                  "hasSign": hasSign,
                  "lastLatitude": locLait,
                  "lastLongitude": locLong
            ]
            let Headers: HTTPHeaders = [
                "Content-Type": "application/json",
                "Accept": "text/plain"
            ]

            AF.request("https://ligefinder.norre.cc/api/Watch/update", method: .put, parameters: params, encoding: JSONEncoding.default, headers: Headers).validate(statusCode: 200 ..< 299).responseData { AFdata in
                do {
                    let data = try AFdata.data
                } catch {
                    print("Error")
                    return
                }
            }
        }
        
    }
}
