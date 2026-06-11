//
//  DemoCloudClient.swift
//  SampleApp
//

// MARK: - Cloud client

import Apollo
import ApolloAPI
import ApolloSQLite
import DemoCloud
import Foundation
import TrainingKit

enum DemoCloudClient {
    @MainActor
    static var shared: ApolloClient = {
        let cache: NormalizedCache

        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let documentsURL = URL(fileURLWithPath: documentsPath)
        let sqliteFileURL = documentsURL.appendingPathComponent("test_apollo_db.sqlite")

        do {
            cache = try SQLiteNormalizedCache(fileURL: sqliteFileURL)
        } catch {
            cache = InMemoryNormalizedCache()
        }

        let store = ApolloStore(cache: cache)

        var url = URL(string: "https://server.com/graphql")!
        let provider = DemoNetworkInterceptorProvider()
        let urlSession = URLSession.shared

        let transport = RequestChainNetworkTransport(urlSession: urlSession, interceptorProvider: provider, store: store, endpointURL: url)

        return ApolloClient(networkTransport: transport, store: store)
    }()
}

// MARK: - Interceptors

struct DemoNetworkInterceptorProvider: InterceptorProvider {
    /// Provide HTTP interceptors (URLRequest/HTTPResponse processing)
    func httpInterceptors(for operation: some GraphQLOperation) -> [any HTTPInterceptor] {
        DefaultInterceptorProvider.shared.httpInterceptors(for: operation) + [
            DemoHeadersAddingInterceptor(),
        ]
    }
}

final class DemoHeadersAddingInterceptor: HTTPInterceptor {
    let id: String = UUID().uuidString

    func intercept(request: URLRequest, next: @Sendable (URLRequest) async throws -> Apollo.HTTPResponse) async throws -> Apollo.HTTPResponse {
        var newRequest = request
        newRequest.addValue(TrainingKitConfig.deviceId(), forHTTPHeaderField: "X-WorkoutKit-Device")

        return try await next(newRequest)
    }
}
