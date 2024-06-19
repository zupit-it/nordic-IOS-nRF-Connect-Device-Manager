//
//  McuXamarinUpgradeManager.swift
//  iOSMcuManagerLibrary
//
//  Created by Boris Sclauzero on 19/06/24.
//

import Foundation
import CoreBluetooth

@objc public class McuXamarinUpgradeManager: NSObject {
    
    @objc public init(peripheral: CBPeripheral, firmwareUpgradeDelegare: FirmwareUpgradeDelegate, logDelegate: McuMgrLogDelegate) {
        self.firmwareUpgradeDelegare = firmwareUpgradeDelegare
        self.logDelegate = logDelegate
        self.transporter = McuMgrBleTransport(peripheral)
        self.dfuManager = FirmwareUpgradeManager(transporter: transporter, delegate: self.firmwareUpgradeDelegare)
        self.dfuManager.logDelegate = logDelegate
        self.logDelegate.log(String("McuXamarinUpgradeManager init() completed"), ofCategory: .basic, atLevel: .application)
    }
    
    private var firmwareUpgradeDelegare: FirmwareUpgradeDelegate
    private var logDelegate: McuMgrLogDelegate
    private var transporter: McuMgrBleTransport!
    private var package: McuMgrPackage?
    private var envelope: McuMgrSuitEnvelope?
    private var dfuManager: FirmwareUpgradeManager!
    
    private var dfuManagerConfiguration = FirmwareUpgradeConfiguration(
        estimatedSwapTime: 10.0, eraseAppSettings: false, pipelineDepth: 3, byteAlignment: .fourByte)
    
    
    @objc public func startUpgrade(url: URL) throws {
        self.logDelegate.log(String("McuXamarinUpgradeManager startUpgrade()"), ofCategory: .basic, atLevel: .application)
        self.loadImageFileFromUrl(url: url)
        self.logDelegate.log(String("McuXamarinUpgradeManager loadImageFileFromUrl() completed"), ofCategory: .basic, atLevel: .application)
        self.start()
    }
    
    private func loadImageFileFromUrl(url: URL) {
        self.package = nil
        self.envelope = nil
        
        let message = String("Reading file: " + url.absoluteString)
        self.logDelegate.log(message, ofCategory: .basic, atLevel: .application)
        
        switch parseAsMcuMgrPackage(url) {
        case .success(let package):
            self.package = package
        case .failure(let error):
            onParseError(error, for: url)
        }
    }
    
    
    private func start() {
        if let package {
            // selectMode(for: package)
            self.dfuManagerConfiguration.eraseAppSettings = true
            self.dfuManagerConfiguration.upgradeMode = .confirmOnly
            self.startFirmwareUpgrade(package: package)
        } else if let envelope {
            // SUIT has "no mode" to select
            // (We use modes in the code only, but SUIT has no concept of upload modes)
            self.startFirmwareUpgrade(envelope: envelope)
        }
    }
    
    private func startFirmwareUpgrade(package: McuMgrPackage) {
        do {
            dfuManagerConfiguration.suitMode = false
            try dfuManager.start(images: package.images, using: dfuManagerConfiguration)
        } catch {
            self.logDelegate.log(String("startFirmwareUpgrade(package) error()"), ofCategory: .basic, atLevel: .error)
        }
    }
    
    private func startFirmwareUpgrade(envelope: McuMgrSuitEnvelope) {
        do {
            // sha256 is the currently only supported mode.
            // The rest are optional to implement in SUIT.
            guard let sha256Hash = envelope.digest.hash(for: .sha256) else {
                throw McuMgrSuitParseError.supportedAlgorithmNotFound
            }
            
            dfuManagerConfiguration.suitMode = true
            dfuManagerConfiguration.upgradeMode = .uploadOnly
            try dfuManager.start(hash: sha256Hash, data: envelope.data, using: dfuManagerConfiguration)
        } catch {
            self.logDelegate.log(String("startFirmwareUpgrade(envelope) error()"), ofCategory: .basic, atLevel: .error)
        }
    }
    
    
    
    // MARK: - Private
    
    func parseAsMcuMgrPackage(_ url: URL) -> Result<McuMgrPackage, Error> {
        do {
            let package = try McuMgrPackage(from: url)
            return .success(package)
        } catch {
            return .failure(error)
        }
    }
    
//    func parseAsSuitEnvelope(_ url: URL) -> Result<McuMgrSuitEnvelope, Error> {
//        do {
//            let envelope = try McuMgrSuitEnvelope(from: url)
//            return .success(envelope)
//        } catch {
//            return .failure(error)
//        }
//    }
    
    func onParseError(_ error: Error, for url: URL) {
        self.package = nil
        self.envelope = nil
        let message = String("Error reading file: " + url.absoluteString)
        self.logDelegate.log(message, ofCategory: .basic, atLevel: .error)
        self.firmwareUpgradeDelegare.upgradeDidFail(inState: .none, with: error)
    }
}

