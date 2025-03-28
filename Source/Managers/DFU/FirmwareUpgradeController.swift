//
//  FirmwareUpgradeController.swift
//  nRF Connect Device Manager
//
//  Created by Aleksander Nowakowski on 05/07/2018.
//  Copyright © 2024 Nordic Semiconductor ASA.
//

import Foundation

// MARK: - FirmwareUpgradeController

@objc public protocol FirmwareUpgradeController: AnyObject {
    
    /// Pause the firmware upgrade.
    @objc func pause()
    
    /// Resume a paused firmware upgrade.
    @objc func resume()
    
    /// Cancel the firmware upgrade.
    @objc func cancel()
    
    /// Returns true if the upload has been paused.
    @objc func isPaused() -> Bool
    
    /// Returns true if the upload is in progress.
    @objc func isInProgress() -> Bool
    
    /**
     Firmware upgrades on SUIT (Software Update for the Internet of Things) devices might request a ``FirmwareUpgradeResource`` to continue via callback. When that happens, this API allows you to provide said resource.
     */
    @objc func uploadResource(_ resource: FirmwareUpgradeResource, data: Data) -> Void
}

// MARK: FirmwareUpgradeResource

/*
public enum FirmwareUpgradeResource: CustomStringConvertible {
    case file(name: String)
    
    // MARK: Init
    
    public init?(_ resourceID: String) {
        guard let filename = resourceID.components(separatedBy: "//").last else {
            return nil
        }
        self = .file(name: String(filename))
    }
    
    // MARK: CustomStringConvertible
    
    public var description: String {
        switch self {
        case .file(let name):
            return "file://\(name)"
        }
    }
}
*/

// Waring: Converted by Copilot !

@objc public enum FirmwareUpgradeResource: Int, CustomStringConvertible {
    case file
    
    private static var filenames: [FirmwareUpgradeResource: String] = [:]
    
    public var filename: String? {
        get {
            return FirmwareUpgradeResource.filenames[self]
        }
        set {
            FirmwareUpgradeResource.filenames[self] = newValue
        }
    }
    
    // MARK: Init
    
    public init?(resourceID: String) {
        guard let filename = resourceID.components(separatedBy: "//").last else {
            return nil
        }
        self = .file
        self.filename = filename
    }
    
    // MARK: CustomStringConvertible
    
    public var description: String {
        switch self {
        case .file:
            if let name = self.filename {
                return "file://\(name)"
            } else {
                return "file://unknown"
            }
        }
    }
}
