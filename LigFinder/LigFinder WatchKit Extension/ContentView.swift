//
//  ContentView.swift
//  LigFinder WatchKit Extension
//
//  Created by Emil Neirup Jensen on 14/04/2021.
//

import SwiftUI
import HealthKit
import CoreLocation
import CoreData
import SwiftyJSON
import Alamofire
import WatchKit

var container: NSPersistentContainer!


struct ContentView: View {
    var managedObjectContext = (WKExtension.shared().delegate as! ExtensionDelegate).persistentContainer.viewContext
    
    var body: some View {
        SubView().environment(\.managedObjectContext, managedObjectContext)
        
    }
}

struct SubView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(entity: WatchInfo.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]) var watchData: FetchedResults<WatchInfo>
    
    var body: some View {
        let sendData = DataTransfer()
        let pulsScan = Puls()
        
        if watchData.count > 0 && watchData[0].isConnected == true {
            
            Button(action: {
                sendData.updateStatus(watchId: watchData[0].id, status: 1, signType: 1, hasSign: true)
                
            }, label: {
                VStack {
                    Image("cardiogram")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30.0, height: 30.0)
                    Text("Send tegn >")
                }
                .frame(width: 150.0, height: 150.0)
            })
            .background(Color(red: 34 / 255, green: 108 / 255, blue: 224 / 255))
            .clipShape(Circle())
            .onAppear{
                pulsScan.start(watchId: watchData[0].id)
                
                Timer.scheduledTimer(withTimeInterval: 20, repeats: true, block: { timer in
                    WKInterfaceDevice.current().isBatteryMonitoringEnabled = true
                    let puls = pulsScan.start(watchId: watchData[0].id)
                    
                    if puls > 9 {sendData.updateStatus(watchId: watchData[0].id, status: 1, signType: 2, hasSign: true)}
                    else {
                        let level = WKInterfaceDevice.current().batteryState.rawValue
                        
                        if level == 1 {sendData.updateStatus(watchId: watchData[0].id, status: 2, signType: 2, hasSign: false)}
                        else if level == 2 || level == 3 {
                            Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true, block: { timer in
                                
                                let level = WKInterfaceDevice.current().batteryState.rawValue
                                
                                if level == 1 {sendData.updateStatus(watchId: watchData[0].id, status: 1, signType: 2, hasSign: false)}
                                else if level == 2 || level == 3 {sendData.updateStatus(watchId: watchData[0].id, status: 2, signType: 2, hasSign: false)}
                                else {sendData.updateStatus(watchId: watchData[0].id, status: 0, signType: 2, hasSign: false)}
                            })
                        }
                        else {sendData.updateStatus(watchId: watchData[0].id, status: 0, signType: 2, hasSign: false)}
                    }
                })
            }
        }
        if watchData.count == 0 || watchData[0].isConnected == false {
            VStack(spacing: 20) {
                HStack {
                    Image("cardiogram-1")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30.0, height: 30.0)
                    Text("LigeFinder")
                        .foregroundColor(Color(red: 34 / 255, green: 108 / 255, blue: 224 / 255))
                        .font(.system(size: 25))
                }
                ForEach(watchData, id: \.self) { watchInfo in
                    Text("\(watchInfo.name) - \(watchInfo.id)")
                        .font(.system(size: 15))
                        .onAppear{
                            if watchData.count > 0 {
                                AF.request("https://ligefinder.norre.cc/api/Watch/getWatchConnection/\(watchInfo.id)", parameters: nil, encoding: JSONEncoding.default, headers: nil).validate(statusCode: 200 ..< 299).responseJSON { AFdata in
                                    do {
                                        let json = try JSON(data: AFdata.data!)
                                        if let isConnected = json["isConnected"].bool {
                                            
                                            do {
                                                watchInfo.isConnected = isConnected
                                                try self.managedObjectContext.save()
                                                
                                            } catch {
                                                print(error)
                                            }
                                        }
                                    } catch {
                                        print("Error: Trying to convert JSON data to string")
                                        return
                                    }
                                }
                            }
                           
                        }
                }
                if watchData.count == 0{
                    Button(action: {
                        let watchName = UUID().uuidString
                        let params: Parameters = [
                            "watchName": "\(watchName)"
                        ]
                        let Headers: HTTPHeaders = [
                            "Content-Type": "application/json",
                            "Accept": "text/plain"
                        ]
                        
                        AF.request("https://ligefinder.norre.cc/api/Watch/register", method: .put, parameters: params, encoding: JSONEncoding.default, headers: Headers).validate(statusCode: 200 ..< 299).responseJSON { AFdata in
                            do {
                                let json = try JSON(data: AFdata.data!)
                                if let id = json["id"].int32 {
                                    print(id)
                                    
                                    let watchInfo = WatchInfo(context: self.managedObjectContext)
                                    watchInfo.name = watchName
                                    watchInfo.id = id
                                    watchInfo.isConnected = false
                                    
                                    do {
                                        try self.managedObjectContext.save()
                                        
                                    } catch {
                                        print(error)
                                    }
                                }
                            } catch {
                                print("Error: Trying to convert JSON data to string")
                                return
                            }
                        }
    
                        }){
                            Text("Register ur")
                        }
                }
                
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
