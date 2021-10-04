//
//  Puls.swift
//  LigFinder WatchKit Extension
//
//  Created by Emil Neirup Jensen on 29/04/2021.
//

import WatchKit
import HealthKit
import WatchKit

class Puls: NSObject {
    private var value = 0
    let sendData = DataTransfer()
    
    private var healthStore = HKHealthStore()
    let heartRateQuantity = HKUnit(from: "count/min")
    
    func start(watchId: Int32)-> Int {
        autorizeHealthKit()
        startHeartRateQuery(quantityTypeIdentifier: .heartRate, watchId: watchId)
        return Int(self.value)
    }
    
    func autorizeHealthKit() {
        let healthKitTypes: Set = [
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!]

        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { _, _ in }
    }
    
    private func startHeartRateQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier, watchId: Int32) {
        
        
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            query, samples, deletedObjects, queryAnchor, error in
            
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }
                
            self.process(samples, type: quantityTypeIdentifier, watchId: watchId)
        }
        
        let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!, predicate: devicePredicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler)
        
        query.updateHandler = updateHandler
        
        healthStore.execute(query)
    }
    
    private func process(_ samples: [HKQuantitySample], type: HKQuantityTypeIdentifier, watchId: Int32) -> Int {
        var lastHeartRate = 0.0
        
        for sample in samples {
            if type == .heartRate {
                lastHeartRate = sample.quantity.doubleValue(for: heartRateQuantity)
            }
            
            self.value = Int(lastHeartRate)
            if self.value < 10 {
                sendData.updateStatus(watchId: watchId, status: 1, signType: 2, hasSign: false)
                
                let level = WKInterfaceDevice.current().batteryState.rawValue
                
                if level == 1 {sendData.updateStatus(watchId: watchId, status: 2, signType: 2, hasSign: false)}
                else if level == 2 || level == 3 {
                    Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true, block: { timer in
                        let level = WKInterfaceDevice.current().batteryState.rawValue
                        
                        if level == 1 {self.sendData.updateStatus(watchId: watchId, status: 1, signType: 2, hasSign: false)}
                        else if level == 2 || level == 3 {self.sendData.updateStatus(watchId: watchId, status: 2, signType: 2, hasSign: false)}
                        else {self.sendData.updateStatus(watchId: watchId, status: 0, signType: 2, hasSign: false)}
                    })
                }
                else {sendData.updateStatus(watchId: watchId, status: 0, signType: 2, hasSign: false)}
            }
        }
        return Int(self.value)
    }
}
