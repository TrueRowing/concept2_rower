//
//  PeripheralDelegate.swift
//  Pods
//
//  Created by Jesse Curry on 9/30/15.
//  Edited by Paul Aschmann on 08/06/2020
//  Copyright © 2015 Bout Fitness, LLC. All rights reserved.
//

import CoreBluetooth
import Logging

final class PeripheralDelegate: NSObject, CBPeripheralDelegate {
    let logger = Logger(label: "concept2.PeripheralDelegate")

    weak var performanceMonitor:PerformanceMonitor?
    
    // MARK: Services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        logger.info("didDiscoverServices:")
        peripheral.services?.forEach({ (service:CBService) -> () in
            logger.info("\t* \(service.description)")
            
            if let svc = Service(uuid: service.uuid) {
                peripheral.discoverCharacteristics(svc.characteristicUUIDs,
                                                   for:  service)
            }
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        logger.debug("didDiscoverIncludedServicesForService")
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didModifyServices
        invalidatedServices: [CBService]) {
        logger.debug("didModifyServices")
    }
    
    // MARK: Characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        logger.info("didDiscoverCharacteristicsForService \(service) \(error?.localizedDescription ?? "")")
        service.characteristics?.forEach({ (characteristic:CBCharacteristic) -> () in
            if characteristic.properties.contains(.notify), !characteristic.isNotifying {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        })
        
        if let error, let pm = PerformanceMonitorStore.sharedInstance.performanceMonitorWithPeripheral(peripheral: peripheral) {
            pm.lastError = error
            pm.sendUpdateStateNotification()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        logger.debug("didDiscoverDescriptorsForCharacteristic \(characteristic) \(error?.localizedDescription ?? "")")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        logger.debug("didUpdateValueForCharacteristic: \(characteristic) \(error?.localizedDescription ?? "")")
        if let serviceUuid = characteristic.service?.uuid,  let svc = Service(uuid: characteristic.service!.uuid) {
            if let c = svc.characteristic(uuid: characteristic.uuid) {
                if let cm = c.parse(data: characteristic.value as NSData?) {
                    logger.debug("\(String(describing: cm))")
                    if let pm = performanceMonitor {
                        cm.updatePerformanceMonitor(performanceMonitor: pm)
                    }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        logger.debug("didUpdateValueForDescriptor")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        logger.debug("didWriteValueForCharacteristic")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        logger.debug("didWriteValueForDescriptor")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        logger.debug("didUpdateNotificationStateForCharacteristic")
    }
    
    // MARK: Signal Strength
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        logger.debug("didUpdateRSSI")
    }
    
    // MARK: Name
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        logger.debug("didUpdateName")
        
        if let pm = PerformanceMonitorStore.sharedInstance.performanceMonitorWithPeripheral(peripheral: peripheral) {
            pm.sendUpdateStateNotification()
        }
    }
}
