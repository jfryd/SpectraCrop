//  BluetoothManager.swift
//  SpectraCrop
//
//  Created by SpectraCrop Development Team
//  Copyright © 2026 SpectraCrop. All rights reserved.
//

import Foundation
import SwiftUI
import CoreBluetooth
import Combine

// MARK: - BluetoothDevice

struct BluetoothDevice: Identifiable {
    let id: UUID
    let peripheral: CBPeripheral
    let name: String
    let identifier: UUID
    var rssi: Int
    var isConnected: Bool
    var isConnecting: Bool
    
    init(peripheral: CBPeripheral, rssi: Int) {
        self.id = UUID()
        self.peripheral = peripheral
        self.name = peripheral.name ?? "Unknown Device"
        self.identifier = peripheral.identifier
        self.rssi = rssi
        self.isConnected = false
        self.isConnecting = false
    }
}

// MARK: - BluetoothManager Protocol

protocol BluetoothManagerProtocol: ObservableObject {
    var devices: [BluetoothDevice] { get }
    var connectedDevice: BluetoothDevice? { get }
    var isScanning: Bool { get }
    var isEnabled: Bool { get }
    var error: Error? { get }
    
    func initialize()
    func startScan()
    func stopScan()
    func connect(to device: BluetoothDevice)
    func disconnect()
    func sendData(_ data: Data)
}

// MARK: - BluetoothManager Implementation

final class BluetoothManager: NSObject, BluetoothManagerProtocol, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - Singleton
    
    static let shared = BluetoothManager()
    
    // MARK: - Published Properties
    
    @Published var devices: [BluetoothDevice] = []
    @Published var connectedDevice: BluetoothDevice?
    @Published var isScanning = false
    @Published var isEnabled = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    private var centralManager: CBCentralManager!
    private var dataCharacteristic: CBCharacteristic?
    private var writeCharacteristic: CBCharacteristic?
    private var responseData = Data()
    private var expectedLength = 0
    private var waitingForResponse = false
    private var completionHandlers: [String: (Result<Data, Error>) -> Void] = [:]
    
    // SpectraCrop BLE UUIDs
    private let mldpServiceUUID = CBUUID(string: "00035B03-58E6-07DD-021A-08123A000300")
    private let dataWriteUUID = CBUUID(string: "00035B03-58E6-07DD-021A-08123A000301")
    private let dataNotifyUUID = CBUUID(string: "00035B03-58E6-07DD-021A-08123A000302")
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func initialize() {
        // Already initialized in init
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            switch central.state {
            case .poweredOn:
                self.isEnabled = true
                self.error = nil
            case .poweredOff:
                self.isEnabled = false
                self.error = BluetoothError.poweredOff
            case .unauthorized:
                self.isEnabled = false
                self.error = BluetoothError.unauthorized
            case .unsupported:
                self.isEnabled = false
                self.error = BluetoothError.unsupported
            case .resetting, .unknown:
                self.isEnabled = false
                self.error = BluetoothError.unknown
            @unknown default:
                self.isEnabled = false
                self.error = BluetoothError.unknown
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Check if this is a SpectraCrop device
        guard let peripheralName = peripheral.name,
              peripheralName.contains("SpectraCrop") || advertisementData[CBAdvertisementDataLocalNameKey] as? String == "SpectraCrop" else {
            return
        }
        
        // Check if we already have this device
        if devices.contains(where: { $0.identifier == peripheral.identifier }) {
            return
        }
        
        DispatchQueue.main.async {
            let device = BluetoothDevice(peripheral: peripheral, rssi: RSSI.intValue)
            self.devices.append(device)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([mldpServiceUUID])
        
        DispatchQueue.main.async {
            if let index = self.devices.firstIndex(where: { $0.identifier == peripheral.identifier }) {
                self.devices[index].isConnected = true
                self.devices[index].isConnecting = false
                self.connectedDevice = self.devices[index]
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            if let index = self.devices.firstIndex(where: { $0.identifier == peripheral.identifier }) {
                self.devices[index].isConnecting = false
            }
            self.error = error ?? BluetoothError.connectionFailed
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            if let index = self.devices.firstIndex(where: { $0.identifier == peripheral.identifier }) {
                self.devices[index].isConnected = false
            }
            self.connectedDevice = nil
            self.dataCharacteristic = nil
            self.error = error
        }
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == mldpServiceUUID {
                peripheral.discoverCharacteristics([dataWriteUUID, dataNotifyUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == dataWriteUUID {
                // This is the write characteristic
                writeCharacteristic = characteristic
            } else if characteristic.uuid == dataNotifyUUID {
                // This is the notify characteristic
                dataCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        // Handle incoming data
        handleIncomingData(data)
    }
    
    // MARK: - Public Methods
    
    func startScan() {
        guard isEnabled else { return }
        
        devices.removeAll()
        isScanning = true
        centralManager.scanForPeripherals(withServices: [mldpServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func stopScan() {
        centralManager.stopScan()
        isScanning = false
    }
    
    func connect(to device: BluetoothDevice) {
        guard isEnabled, !device.isConnected, !device.isConnecting else { return }
        
        DispatchQueue.main.async {
            if let index = self.devices.firstIndex(where: { $0.id == device.id }) {
                self.devices[index].isConnecting = true
            }
        }
        
        centralManager.connect(device.peripheral, options: nil)
    }
    
    func disconnect() {
        guard let connectedDevice = connectedDevice else { return }
        centralManager.cancelPeripheralConnection(connectedDevice.peripheral)
    }
    
    func sendData(_ data: Data) {
        guard let connectedDevice = connectedDevice, let writeCharacteristic = writeCharacteristic else { return }
        
        connectedDevice.peripheral.writeValue(data, for: writeCharacteristic, type: .withResponse)
    }
    
    // MARK: - Data Handling
    
    private func handleIncomingData(_ data: Data) {
        // Handle the incoming data from the device
        // This would parse the spectral data and create a Reading
        
        // For now, just print the data
        print("Received data: \(data as NSData)")
        
        // In a real implementation, this would:
        // 1. Parse the binary data
        // 2. Extract spectral values (F0, FMax, TimeToFMax, FvDivFMax, etc.)
        // 3. Create a Reading object
        // 4. Notify the DataManager to save it
    }
}

// MARK: - Bluetooth Error

enum BluetoothError: Error {
    case poweredOff
    case unauthorized
    case unsupported
    case unknown
    case connectionFailed
    case connectionLost
    case dataError
    
    var localizedDescription: String {
        switch self {
        case .poweredOff: return "Bluetooth is powered off"
        case .unauthorized: return "Bluetooth permission denied"
        case .unsupported: return "Bluetooth is not supported on this device"
        case .unknown: return "Bluetooth state unknown"
        case .connectionFailed: return "Failed to connect to device"
        case .connectionLost: return "Connection to device lost"
        case .dataError: return "Error receiving data from device"
        }
    }
}

// MARK: - Mock BluetoothManager for Testing

#if DEBUG
class MockBluetoothManager: BluetoothManagerProtocol, ObservableObject {
    @Published var devices: [BluetoothDevice] = []
    @Published var connectedDevice: BluetoothDevice?
    @Published var isScanning = false
    @Published var isEnabled = true
    @Published var error: Error?
    
    func initialize() {}
    
    func startScan() {
        isScanning = true
        devices = [
            BluetoothDevice(peripheral: MockCBPeripheral(), rssi: -50),
            BluetoothDevice(peripheral: MockCBPeripheral(), rssi: -70)
        ]
    }
    
    func stopScan() {
        isScanning = false
        devices = []
    }
    
    func connect(to device: BluetoothDevice) {
        connectedDevice = device
    }
    
    func disconnect() {
        connectedDevice = nil
    }
    
    func sendData(_ data: Data) {}
}

// Mock CBPeripheral for testing
class MockCBPeripheral: CBPeripheral {
    private let _identifier: UUID
    
    override init() {
        _identifier = UUID()
        super.init()
    }
    
    override var identifier: UUID { _identifier }
    override var name: String? { "Mock SpectraCrop" }
}
#endif
