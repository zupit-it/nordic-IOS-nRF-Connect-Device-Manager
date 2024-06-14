//
//  FirmwareUpgradeController.swift
//  McuManager
//
//  Created by Aleksander Nowakowski on 05/07/2018.
//  Copyright © 2018 Runtime. All rights reserved.
//

import Foundation

@objc public protocol FirmwareUpgradeController {
    
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
}
