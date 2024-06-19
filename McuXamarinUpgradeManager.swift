//
//  McuXamarinUpgradeManager.swift
//  iOSMcuManagerLibrary
//
//  Created by Boris Sclauzero on 19/06/24.
//

import Foundation

@objc final class McuXamarinUpgradeManager: NSObject {
    
    @objc public init(peripheral: CBPeripheral, firmwareUpgradeDelegare: FirmwareUpgradeDelegate, logDelegate: McuMgrLogDelegate) {
        self.firmwareUpgradeDelegare = firmwareUpgradeDelegare
        self.logDelegate = logDelegate
        self.transporter = McuMgrBleTransport(peripheral)
    }
    
    private var firmwareUpgradeDelegare: FirmwareUpgradeDelegate
    private var logDelegate: McuMgrLogDelegate
    private var package: McuMgrPackage?
    private var envelope: McuMgrSuitEnvelope?
    private var dfuManager: FirmwareUpgradeManager!
    
    private var dfuManagerConfiguration = FirmwareUpgradeConfiguration(
        estimatedSwapTime: 10.0, eraseAppSettings: false, pipelineDepth: 3, byteAlignment: .fourByte)
    
    var transporter: McuMgrBleTransport! {
        didSet {
            dfuManager = FirmwareUpgradeManager(transporter: transporter, delegate: self.firmwareUpgradeDelegare)
            dfuManager.logDelegate = self.logDelegate
        }
    }
    
    @objc public func startUpgradeFromUrl(url: URL) {
        self.loadImageFileFromUrl(url: URL)
        self.start()
    }
    
    private func loadImageFileFromUrl(url: URL) {
        self.package = nil
        self.envelope = nil
        
        switch parseAsMcuMgrPackage(url) {
        case .success(let package):
            self.package = package
        case .failure(let error):
            if error is McuMgrPackage.Error {
                switch parseAsSuitEnvelope(url) {
                case .success(let envelope):
                    self.envelope = envelope
                case .failure(let error):
                    onParseError(error, for: url)
                }
            } else {
                onParseError(error, for: url)
            }
        }
        (parent as! ImageController).innerViewReloaded()
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
//            status.textColor = .systemRed
//            status.text = error.localizedDescription
//            actionStart.isEnabled = false
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
//            status.textColor = .systemRed
//            status.text = error.localizedDescription
//            actionStart.isEnabled = false
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
    
    func parseAsSuitEnvelope(_ url: URL) -> Result<McuMgrSuitEnvelope, Error> {
        do {
            let envelope = try McuMgrSuitEnvelope(from: url)
            return .success(envelope)
        } catch {
            return .failure(error)
        }
    }
    
    func onParseError(_ error: Error, for url: URL) {
        self.package = nil
        self.envelope = nil
    }
}

