import Foundation

/// Maps structured VenPays backend error codes to stable SDK errors.
enum BackendErrorMapper {
    static func map(
        backendCode: String,
        message: String,
        httpStatus: Int?,
        requestID: String?
    ) -> VenPaysError {
        let code = mapCode(backendCode, httpStatus: httpStatus)
        return VenPaysError(
            code: code,
            message: message.isEmpty ? defaultMessage(for: code) : message,
            requestID: requestID,
            httpStatus: httpStatus,
            isRetryable: isRetryable(code: code, httpStatus: httpStatus)
        )
    }

    static func mapHTTPStatus(
        _ status: Int,
        body: Data,
        requestID: String?
    ) -> VenPaysError {
        if let parsed = try? JSONDecoder().decode(BackendErrorResponse.self, from: body) {
            return map(
                backendCode: parsed.error.code,
                message: parsed.error.message,
                httpStatus: status,
                requestID: parsed.error.requestID ?? requestID
            )
        }

        let code: VenPaysErrorCode
        switch status {
        case 401, 403:
            code = .unauthorized
        case 409:
            code = .idempotencyConflict
        case 410:
            code = .sessionExpired
        case 422:
            code = .invalidBackendResponse
        case 429:
            code = .rateLimited
        case 408:
            code = .requestTimeout
        case 500, 502:
            code = .internalError
        case 503:
            code = .processorUnavailable
        case 504:
            code = .requestTimeout
        default:
            code = .invalidBackendResponse
        }

        return VenPaysError(
            code: code,
            message: defaultMessage(for: code),
            requestID: requestID,
            httpStatus: status,
            isRetryable: isRetryable(code: code, httpStatus: status)
        )
    }

    static func mapCode(_ backendCode: String, httpStatus: Int?) -> VenPaysErrorCode {
        switch backendCode {
        case "invalid_payment_token":
            return .invalidApplePayToken
        case "idempotency_key_required", "idempotency_conflict":
            return .idempotencyConflict
        case "unauthorized", "invalid_native_session":
            return .unauthorized
        case "native_session_expired":
            return .sessionExpired
        case "wrong_track_id":
            return .invalidSession
        case "apple_pay_not_enabled":
            return .invalidApplePayConfiguration
        case "payment_already_processing":
            return .paymentAlreadyProcessing
        case "payment_already_completed":
            return .paymentAlreadyCompleted
        case "processor_declined":
            return .processorDeclined
        case "processor_unavailable":
            return .processorUnavailable
        case "processor_timeout":
            return .requestTimeout
        case "internal_error":
            return .internalError
        default:
            if httpStatus == 401 || httpStatus == 403 { return .unauthorized }
            if httpStatus == 429 { return .rateLimited }
            return .invalidBackendResponse
        }
    }

    static func isRetryable(code: VenPaysErrorCode, httpStatus: Int?) -> Bool {
        switch code {
        case .requestTimeout, .networkUnavailable, .processorUnavailable, .rateLimited, .internalError:
            return true
        case .paymentAlreadyProcessing:
            return true
        default:
            if let httpStatus, (500...599).contains(httpStatus) {
                return true
            }
            return false
        }
    }

    static func defaultMessage(for code: VenPaysErrorCode) -> String {
        switch code {
        case .invalidConfiguration:
            return "The SDK configuration is invalid."
        case .invalidSession:
            return "The payment session is invalid."
        case .sessionExpired:
            return "The native session token has expired."
        case .invalidAmount:
            return "The payment amount is invalid."
        case .unsupportedCurrency:
            return "The currency is unsupported."
        case .applePayUnsupported:
            return "Apple Pay is not supported on this device."
        case .noSupportedCard:
            return "No supported card is configured for Apple Pay."
        case .invalidApplePayConfiguration:
            return "Apple Pay configuration is invalid."
        case .presentationFailed:
            return "The Apple Pay sheet failed to present."
        case .paymentCancelled:
            return "The payment was cancelled."
        case .invalidApplePayToken:
            return "The Apple Pay token is invalid."
        case .invalidBackendResponse:
            return "The backend response was invalid."
        case .unauthorized:
            return "The native session is unauthorized."
        case .paymentAlreadyProcessing:
            return "The payment is already processing."
        case .paymentAlreadyCompleted:
            return "The payment has already been completed."
        case .processorDeclined:
            return "The payment was declined by the processor."
        case .processorUnavailable:
            return "The payment processor is unavailable."
        case .requestTimeout:
            return "The request timed out."
        case .networkUnavailable:
            return "The network is unavailable."
        case .rateLimited:
            return "Too many requests. Please retry later."
        case .idempotencyConflict:
            return "An idempotency conflict occurred."
        case .paymentStatusUnknown:
            return "The payment status could not be determined."
        case .internalError:
            return "An internal error occurred."
        }
    }
}
