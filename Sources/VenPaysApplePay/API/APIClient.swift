import Foundation

/// URLSession-based client for VenPays native Apple Pay SDK endpoints.
final class APIClient: Sendable {
    private let configuration: VenPaysConfiguration
    private let session: URLSession
    private let logger: Logger
    private let maxTransportRetries: Int

    init(
        configuration: VenPaysConfiguration,
        urlSession: URLSession? = nil,
        logger: Logger = Logger(enabled: false),
        maxTransportRetries: Int = 1
    ) {
        self.configuration = configuration
        self.logger = logger
        self.maxTransportRetries = maxTransportRetries

        if let urlSession {
            self.session = urlSession
        } else {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = configuration.requestTimeout
            config.timeoutIntervalForResource = configuration.requestTimeout
            self.session = URLSession(configuration: config)
        }
    }

    func authorize(
        session paymentSession: VenPaysNativePaymentSession,
        token: EncodedApplePayToken,
        idempotencyKey: String
    ) async throws -> AuthorizePaymentOutcome {
        let body = try AuthorizePaymentRequest(token: token).jsonData()
        let requestID = RequestID.generate()
        let apiRequest = APIRequest(
            endpoint: .authorize(trackID: paymentSession.trackID),
            bearerToken: paymentSession.nativeSessionToken,
            idempotencyKey: idempotencyKey,
            requestID: requestID,
            body: body
        )

        let response = try await perform(apiRequest, reuseIdempotencyOnRetry: true)
        return try decodeAuthorizeResponse(response)
    }

    func fetchStatus(
        session paymentSession: VenPaysNativePaymentSession
    ) async throws -> VenPaysPaymentResult {
        let requestID = RequestID.generate()
        let apiRequest = APIRequest(
            endpoint: .paymentStatus(trackID: paymentSession.trackID),
            bearerToken: paymentSession.nativeSessionToken,
            idempotencyKey: nil,
            requestID: requestID,
            body: nil
        )
        let response = try await perform(apiRequest, reuseIdempotencyOnRetry: false)
        return try decodeStatusResponse(response)
    }

    private func perform(
        _ apiRequest: APIRequest,
        reuseIdempotencyOnRetry: Bool
    ) async throws -> APIResponse {
        let urlRequest = try apiRequest.urlRequest(
            baseURL: configuration.environment.baseURL,
            timeout: configuration.requestTimeout
        )

        logger.info(
            "HTTP \(apiRequest.endpoint.method.rawValue) \(apiRequest.endpoint.path) requestID=\(apiRequest.requestID)"
        )

        var lastError: VenPaysError?
        let attempts = 1 + maxTransportRetries

        for attempt in 1...attempts {
            do {
                let (data, response) = try await session.data(for: urlRequest)
                guard let http = response as? HTTPURLResponse else {
                    throw VenPaysError(
                        code: .invalidBackendResponse,
                        message: "Response was not an HTTPURLResponse.",
                        requestID: apiRequest.requestID
                    )
                }
                logger.info(
                    "HTTP status=\(http.statusCode) requestID=\(apiRequest.requestID) attempt=\(attempt)"
                )
                return APIResponse(statusCode: http.statusCode, data: data, requestID: apiRequest.requestID)
            } catch let error as VenPaysError {
                throw error
            } catch let urlError as URLError {
                let mapped = mapURLError(urlError, requestID: apiRequest.requestID)
                lastError = mapped
                let shouldRetry = reuseIdempotencyOnRetry
                    && attempt < attempts
                    && mapped.isRetryable
                if shouldRetry {
                    logger.info("Transport retry attempt=\(attempt + 1) requestID=\(apiRequest.requestID)")
                    continue
                }
                throw mapped
            } catch is CancellationError {
                throw VenPaysError(
                    code: .paymentCancelled,
                    message: "The network request was cancelled.",
                    requestID: apiRequest.requestID
                )
            } catch {
                throw VenPaysError(
                    code: .networkUnavailable,
                    message: "A network error occurred.",
                    requestID: apiRequest.requestID,
                    isRetryable: true,
                    underlyingDescription: String(describing: type(of: error))
                )
            }
        }

        throw lastError ?? VenPaysError(
            code: .networkUnavailable,
            message: "A network error occurred.",
            requestID: apiRequest.requestID,
            isRetryable: true
        )
    }

    private func decodeAuthorizeResponse(_ response: APIResponse) throws -> AuthorizePaymentOutcome {
        switch response.statusCode {
        case 200, 202:
            guard !response.data.isEmpty else {
                throw VenPaysError(
                    code: .invalidBackendResponse,
                    message: "Authorize response body was empty.",
                    requestID: response.requestID,
                    httpStatus: response.statusCode
                )
            }
            do {
                let decoded = try JSONDecoder().decode(AuthorizePaymentResponse.self, from: response.data)
                let result = decoded.toPaymentResult(requestID: response.requestID)
                let requiresRecovery = response.statusCode == 202 || result.status == .processing
                return AuthorizePaymentOutcome(
                    result: result,
                    httpStatus: response.statusCode,
                    requiresRecovery: requiresRecovery,
                    authorizationMayHaveReachedBackend: true
                )
            } catch {
                throw VenPaysError(
                    code: .invalidBackendResponse,
                    message: "Authorize response JSON was malformed.",
                    requestID: response.requestID,
                    httpStatus: response.statusCode,
                    // Request may have reached the backend; recovery should be attempted.
                    isRetryable: true
                )
            }
        default:
            throw BackendErrorMapper.mapHTTPStatus(
                response.statusCode,
                body: response.data,
                requestID: response.requestID
            )
        }
    }

    private func decodeStatusResponse(_ response: APIResponse) throws -> VenPaysPaymentResult {
        switch response.statusCode {
        case 200:
            guard !response.data.isEmpty else {
                throw VenPaysError(
                    code: .invalidBackendResponse,
                    message: "Status response body was empty.",
                    requestID: response.requestID,
                    httpStatus: response.statusCode
                )
            }
            do {
                let decoded = try JSONDecoder().decode(PaymentStatusResponse.self, from: response.data)
                return decoded.toPaymentResult(requestID: response.requestID)
            } catch {
                throw VenPaysError(
                    code: .invalidBackendResponse,
                    message: "Status response JSON was malformed.",
                    requestID: response.requestID,
                    httpStatus: response.statusCode
                )
            }
        default:
            throw BackendErrorMapper.mapHTTPStatus(
                response.statusCode,
                body: response.data,
                requestID: response.requestID
            )
        }
    }

    private func mapURLError(_ error: URLError, requestID: String) -> VenPaysError {
        switch error.code {
        case .timedOut:
            return VenPaysError(
                code: .requestTimeout,
                message: "The request timed out.",
                requestID: requestID,
                isRetryable: true,
                underlyingDescription: "URLError.timedOut"
            )
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return VenPaysError(
                code: .networkUnavailable,
                message: "The network is unavailable.",
                requestID: requestID,
                isRetryable: true,
                underlyingDescription: "URLError.\(error.code.rawValue)"
            )
        case .cancelled:
            return VenPaysError(
                code: .paymentCancelled,
                message: "The network request was cancelled.",
                requestID: requestID,
                underlyingDescription: "URLError.cancelled"
            )
        case .secureConnectionFailed, .serverCertificateUntrusted, .clientCertificateRejected:
            return VenPaysError(
                code: .networkUnavailable,
                message: "A TLS failure occurred.",
                requestID: requestID,
                isRetryable: false,
                underlyingDescription: "URLError.\(error.code.rawValue)"
            )
        default:
            return VenPaysError(
                code: .networkUnavailable,
                message: "A network error occurred.",
                requestID: requestID,
                isRetryable: true,
                underlyingDescription: "URLError.\(error.code.rawValue)"
            )
        }
    }
}

extension APIClient: ApplePayPaymentAuthorizing {}
