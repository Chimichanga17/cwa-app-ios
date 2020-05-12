//
//  ExposureSubmissionService.swift
//  ENA
//
//  Created by Zildzic, Adnan on 01.05.20.
//  Copyright © 2020 SAP SE. All rights reserved.
//

import Foundation
import ExposureNotification

protocol ExposureSubmissionService {
    typealias ExposureSubmissionHandler = (_ error: ExposureSubmissionError?) -> Void

    func submitSelfExposure(tan: String, completionHandler: @escaping ExposureSubmissionHandler)
}

class ExposureSubmissionServiceImpl: ExposureSubmissionService {
    let manager: ExposureManager
    let client: Client

    init(manager: ExposureManager, client: Client) {
        self.manager = manager
        self.client = client
    }

    func submitSelfExposure(tan: String, completionHandler: @escaping  ExposureSubmissionHandler) {
        log(message: "Started self exposure submission...")

        manager.activate { [weak self] error in
            guard let self = self else { return }

            if nil != error {
                log(message: "Exposure notification service not activated.", level: .warning)
                completionHandler(.notActivated)
                return
            }

            self.manager.accessDiagnosisKeys { keys, error in
                if let error = error {
                    logError(message: "Error while retrieving diagnosis keys: \(error.localizedDescription)")
                    completionHandler(self.parseError(error))
                    return
                }

                guard let keys = keys else {
                    completionHandler(.noKeys)
                    return
                }

                self.client.submit(keys: keys, tan: tan) { error in
                    if let error = error {
                        logError(message: "Error while submiting diagnosis keys: \(error.localizedDescription)")
                        completionHandler(self.parseError(error))
                        return
                    }
                    completionHandler(nil)
                }
            }
        }
    }

    private func parseError(_ error: Error) -> ExposureSubmissionError {
        return .other
    }
}

enum ExposureSubmissionError: Error {
    case notActivated
    case noKeys
    case other
}
