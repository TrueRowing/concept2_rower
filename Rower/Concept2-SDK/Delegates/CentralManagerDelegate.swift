//
//  CentralManagerDelegate.swift
//  Pods
//
//  Created by Jesse Curry on 9/30/15.
//  Edited by Paul Aschmann on 08/06/2020
//  Copyright © 2015 Bout Fitness, LLC. All rights reserved.
//

import Foundation
import CoreBluetooth
import Logging

final class CentralManagerDelegate:NSObject, CBCentralManagerDelegate {
    
    let logger = Logger(label: "concept2.CentralManagerDelegate")
    
    // MARK: Central Manager Status
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        switch central.state {
        case .unknown:
            logger.info("state: unknown")
            break
        case .resetting:
            logger.info("state: resetting")
            break
        case .unsupported:
            logger.info("state: not available")
            break
        case .unauthorized:
            logger.info("state: not authorized")
            break
        case .poweredOff:
            logger.info("state: powered off")
            break
        case .poweredOn:
            logger.info("state: powered on")
            break
        @unknown default:
            logger.info("state: unknown")
        }
        
        BluetoothManager.isReady.value = (central.state == .poweredOn)
    }
    
    // MARK: Peripheral Discovery
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        logger.debug("didDiscoverPeripheral \(peripheral) adv: \(advertisementData)")
        
        if let pm = PerformanceMonitorStore.sharedInstance.performanceMonitorWithPeripheral(peripheral: peripheral) {
            pm.lastDiscovered = Date()
            pm.sendUpdateStateNotification()

        } else {
            PerformanceMonitorStore.sharedInstance.addPerformanceMonitor(
                performanceMonitor: PerformanceMonitor(withPeripheral: peripheral)
            )
        }
        
    }
    
    // MARK: Peripheral Connections
    func centralManager(_ central: CBCentralManager,
                        didConnect
        peripheral: CBPeripheral)
    {
        logger.info("didConnectPeripheral \(peripheral)")
        peripheral.discoverServices([
            Service.DeviceDiscovery.UUID,
            Service.DeviceInformation.UUID,
            Service.Control.UUID,
            Service.Rowing.UUID])

        postPerformanceMonitorNotificationForPeripheral(peripheral: peripheral, lastError: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.info("didFailToConnectPeripheral \(peripheral) \(error?.localizedDescription ?? "")")
        postPerformanceMonitorNotificationForPeripheral(peripheral: peripheral, lastError: error)
    }    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.info("didDisconnectPeripheral \(peripheral) \(error?.localizedDescription ?? "")")
        postPerformanceMonitorNotificationForPeripheral(peripheral: peripheral, lastError: error)
    }
    
    // MARK: -
    
    private func postPerformanceMonitorNotificationForPeripheral(peripheral:CBPeripheral, lastError: Error?) {
        let performanceMonitorStore = PerformanceMonitorStore.sharedInstance
        if let pm = performanceMonitorStore.performanceMonitorWithPeripheral(peripheral: peripheral) {
            pm.lastError = lastError
//            pm.updatePeripheralObservers()
            pm.sendUpdateStateNotification()
        }
    }
}
