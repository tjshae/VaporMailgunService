import Vapor
import Foundation


// MARK: - Service

public protocol MailgunProvider: Service {
  var apiKey: String { get }
  var domain: String { get }
  func send(_ content: Mailgun.Message, on container: Container) throws -> Future<Response>
  func setup(forwarding: RouteSetup, with container: Container) throws -> Future<Response>
}

// MARK: - Engine

public struct Mailgun: MailgunProvider {
  
  public enum Error: Debuggable {
    
    /// Encoding problem
    case encodingProblem
    
    /// Failed authentication
    case authenticationFailed
    
    /// Failed to send email (with error message)
    case unableToSendEmail(ErrorResponse)
    
    /// Generic error
    case unknownError(Response)
    
    /// Identifier
    public var identifier: String {
      switch self {
      case .encodingProblem:
        return "mailgun.encoding_error"
      case .authenticationFailed:
        return "mailgun.auth_failed"
      case .unableToSendEmail:
        return "mailgun.send_email_failed"
      case .unknownError:
        return "mailgun.unknown_error"
      }
    }
    
    /// Reason
    public var reason: String {
      switch self {
      case .encodingProblem:
        return "Encoding problem"
      case .authenticationFailed:
        return "Failed authentication"
      case .unableToSendEmail(let err):
        return "Failed to send email (\(err.message))"
      case .unknownError:
        return "Generic error"
      }
    }
  }
  
  /// Error response object
  public struct ErrorResponse: Decodable {
    
    /// Error messsage
    public let message: String
    
  }
  
  /// API key (including "key-" prefix)
  public let apiKey: String
  
  /// Domain
  public let domain: String
  
  // MARK: Initialization
  
  
  /// Initializer
  ///
  /// - Parameters:
  ///   - apiKey: API key including "key-" prefix
  ///   - domain: API domain
  public init(apiKey: String, domain: String) {
    self.apiKey = apiKey
    self.domain = domain
  }
  
  // MARK: Send message
  
  /// Send message
  ///
  /// - Parameters:
  ///   - content: Message
  ///   - container: Container
  /// - Returns: Future<Response>
  public func send(_ content: Message, on container: Container) throws -> Future<Response> {
    // If we have a recipient variables, we need to package the payload differently
    if content.recipientVariables != nil {
      return try sendWithRecipientVariabless(content, on: container)
    }
    
    let authKeyEncoded = try encode(apiKey: self.apiKey)
    
    var headers = HTTPHeaders([])
    headers.add(name: HTTPHeaderName.authorization, value: "Basic \(authKeyEncoded)")
    
    let mailgunURL = "https://api.mailgun.net/v3/\(domain)/messages"
    
    let client = try container.make(Client.self)
    
    return client.post(mailgunURL, headers: headers) { req in
      try req.content.encode(content)
      }.map(to: Response.self) { response in
        try self.process(response)
    }
  }

  /// Send message with template
  ///
  /// - Parameters:
  ///   - content: Message
  ///   - container: Container
  /// - Returns: Future<Response>
  public func sendWithRecipientVariabless(_ content: Message, on container: Container) throws -> Future<Response> {
    let authKeyEncoded = try encode(apiKey: self.apiKey)
    
    var headers = HTTPHeaders([])
    headers.add(name: HTTPHeaderName.authorization, value: "Basic \(authKeyEncoded)")
    
    let mailgunURL = "https://api.mailgun.net/v3/\(domain)/messages"

    let request = Request(http: HTTPRequest(method: .GET, url: mailgunURL, headers: headers),
                                  using: container)
    try request.content.encode(content, as: .json)
    try request.query.encode(content)
    let client = try container.make(Client.self)
    return client.send(request).map { response in
        try self.process(response)
    }
  }

  
  /// Setup forwarding
  ///
  /// - Parameters:
  ///   - setup: RouteSetup
  ///   - container: Container
  /// - Returns: Future<Response>
  public func setup(forwarding setup: RouteSetup, with container: Container) throws -> Future<Response> {
    let authKeyEncoded = try encode(apiKey: self.apiKey)
    
    var headers = HTTPHeaders([])
    headers.add(name: HTTPHeaderName.authorization, value: "Basic \(authKeyEncoded)")
    
    let mailgunURL = "https://api.mailgun.net/v3/routes"
    
    let client = try container.make(Client.self)
    
    return client.post(mailgunURL, headers: headers) { req in
      try req.content.encode(setup)
      }.map(to: Response.self) { (response) in
        try self.process(response)
    }
  }
}

// MARK: Private

fileprivate extension Mailgun {
  
  func encode(apiKey: String) throws -> String {
    guard let apiKeyData = "api:\(apiKey)".data(using: .utf8) else {
      throw Error.encodingProblem
    }
    let authKey = apiKeyData.base64EncodedData()
    guard let authKeyEncoded = String.init(data: authKey, encoding: .utf8) else {
      throw Error.encodingProblem
    }
    
    return authKeyEncoded
  }
  
  private func process(_ response: Response) throws -> Response {
    switch true {
    case response.http.status.code == HTTPStatus.ok.code:
      return response
    case response.http.status.code == HTTPStatus.unauthorized.code:
      throw Error.authenticationFailed
    default:
      if let data = response.http.body.data, let err = (try? JSONDecoder().decode(ErrorResponse.self, from: data)) {
        throw Error.unableToSendEmail(err)
      }
      throw Error.unknownError(response)
    }
  }
  
}

// MARK: - Conversions

extension Array where Element == Mailgun.Message.FullEmail {
  
  var stringArray: [String] {
    return map { entry -> String in
      guard let name = entry.name else {
        return entry.email
      }
      return "\"\(name) <\(entry.email)>\""
    }
  }
}

