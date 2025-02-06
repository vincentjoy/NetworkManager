
import Foundation
import Combine

enum HttpMethods: String {
    case GET, POST, PUT, PATCH, DELETE
}

enum NetworkError: Error {
    case invalidUrl
    case requestFailed(String)
    case invalidResponse
    case decodingFailed(String)
    case noData
    
    var message: String {
        switch self {
        case .invalidUrl:
            return "Invalid URL"
        case .requestFailed(let message):
            return "Request failed : \(message)"
        case .invalidResponse:
            return "Invalid response"
        case .decodingFailed(let message):
            return "Decoding failed : \(message)"
        case .noData:
            return "No data received from the server"
        }
    }
}

enum ApiPaths: String {
    case fish = "test/fish"
    case birds = "test/birds"
}

class NetworkManager {
    
    private var baseUrl: String
    private let commonHeaders: [String: String] = [
        "Accept": "application/json",
        "Content-Type": "application/json"
    ]
    
    init(baseUrl: String = "api.example.com") {
        self.baseUrl = baseUrl
    }
    
    private func getUrlRequest<T: Decodable>(
        pathUrl: ApiPaths,
        httpMethod: HttpMethods,
        additionalHeaders: [String: String]? = nil,
        queryParameters: [String: String]? = nil,
        bodyParams: [String: Any]? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) -> URLRequest? {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseUrl
        urlComponents.path = pathUrl.rawValue
        
        if let queryParameters {
            urlComponents.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let requestUrl = urlComponents.url else {
            completion(.failure(.invalidUrl))
            return nil
        }
        
        var urlRequest = URLRequest(url: requestUrl)
        urlRequest.httpMethod = httpMethod.rawValue
        
        var headers = commonHeaders
        if let additionalHeaders {
            headers.merge(additionalHeaders) { (_, new) in new }
        }
        
        for (key, value) in headers {
            urlRequest.addValue(value, forHTTPHeaderField: key)
        }
        
        if let bodyParams {
            do {
                let body = try JSONSerialization.data(withJSONObject: bodyParams, options: [])
                urlRequest.httpBody = body
            } catch {
                completion(.failure(.requestFailed("Failed to encode body params")))
            }
        }
        
        return urlRequest
    }
    
    func request<T: Decodable>(
        pathUrl: ApiPaths,
        httpMethod: HttpMethods,
        resultType: T.Type,
        additionalHeaders: [String: String]? = nil,
        queryParameters: [String: String]? = nil,
        bodyParams: [String: Any]? = nil,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        
        guard let urlRequest = getUrlRequest(pathUrl: pathUrl, httpMethod: httpMethod, completion: completion) else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error {
                completion(.failure(.requestFailed(error.localizedDescription)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard (200...209).contains(httpResponse.statusCode) else {
                completion(.failure(.requestFailed("Failure - \(httpResponse.statusCode)")))
                return
            }
            
            guard let data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                completion(.failure(.decodingFailed(error.localizedDescription)))
            }
        }
        task.resume()
    }
    
    func combineRequest<T: Decodable>(
        pathUrl: ApiPaths,
        httpMethod: HttpMethods,
        resultType: T.Type,
        additionalHeaders: [String: String]? = nil,
        queryParameters: [String: String]? = nil,
        bodyParams: [String: Any]? = nil
    ) -> AnyPublisher<T, NetworkError> {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseUrl
        urlComponents.path = pathUrl.rawValue
        
        if let queryParameters {
            urlComponents.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let requestUrl = urlComponents.url else {
            return Fail(error: NetworkError.invalidUrl).eraseToAnyPublisher()
        }
        
        var urlRequest = URLRequest(url: requestUrl)
        urlRequest.httpMethod = httpMethod.rawValue
        
        var headers = commonHeaders
        if let additionalHeaders {
            headers.merge(additionalHeaders) { _, new in
                new
            }
        }
        
        for (key, value) in headers {
            urlRequest.addValue(value, forHTTPHeaderField: key)
        }
        
        if let bodyParams {
            do {
                let bodyData = try JSONSerialization.data(withJSONObject: bodyParams, options: [])
                urlRequest.httpBody = bodyData
            } catch {
                return Fail(error: NetworkError.requestFailed("Failed to encode body parameters.")).eraseToAnyPublisher()
            }
        }
        
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { output -> Data in
                guard let response = output.response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                    throw NetworkError.invalidResponse
                }
                return output.data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                return NetworkError.requestFailed(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
}

struct Birds: Codable {
    let name: String
    let colour: String
}

class Sample1 {
    
    func start() {
        let manager = NetworkManager()
        manager.request(pathUrl: .birds, httpMethod: .POST, resultType: Birds.self) { result in
            switch result {
            case .success(let birds):
                print(birds)
            case .failure(let error):
                print(error)
            }
        }
    }
}
