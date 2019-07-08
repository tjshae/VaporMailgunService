import Vapor

extension Mailgun {
  public struct Message: Content {
    public static var defaultContentType: MediaType = MediaType.formData
    
    public typealias FullEmail = (email: String, name: String?)
    
    public let from: String
    public let to: String
    public let replyTo: String?
    public let cc: String?
    public let bcc: String?
    public let subject: String
    public let text: String?
    public let html: String?
    public let attachment: [File]?
    public let template: String?
    public let recipientVarsJSONString: String?
    public let tag: String?
    public let userId: String = "%recipient.user_id%"
    public let tracking: Bool = true
    public let trackingClicks: Bool = true
    public let trackingOpens: Bool = true

    private enum CodingKeys : String, CodingKey {
      case from,to, replyTo = "h:Reply-To", cc, bcc, subject, text, html, attachment, template, recipientVarsJSONString = "recipient-variables", tag = "o:tag", userId = "v:user_id", tracking = "o:tracking", trackingClicks = "o:tracking-clicks", trackingOpens = "o:tracking-opens"
    }
    
    public init(from: String, to: String, replyTo: String? = nil, cc: String? = nil, bcc: String? = nil, subject: String, text: String? = nil, html: String? = nil, attachments: [File]? = nil, template: String? = nil, recipientVarsJSONString: String? = nil, tag: String? = nil) {
      self.from = from
      self.to = to
      self.replyTo = replyTo
      self.cc = cc
      self.bcc = bcc
      self.subject = subject
      self.text = text
      self.html = html
      self.attachment = attachments
      self.template = template
      self.recipientVarsJSONString = recipientVarsJSONString
      self.tag = tag
    }
    
    public init(from: String, to: [String], replyTo: String? = nil, cc: [String]? = nil, bcc: [String]? = nil, subject: String, text: String? = nil, html: String? = nil, attachments: [File]? = nil, template: String? = nil, recipientVarsJSONString: String? = nil, tag: String? = nil) {
      self.from = from
      self.to = to.joined(separator: ",")
      self.replyTo = replyTo
      self.cc = cc?.joined(separator: ",")
      self.bcc = bcc?.joined(separator: ",")
      self.subject = subject
      self.text = text
      self.html = html
      self.attachment = attachments
      self.template = template
      self.recipientVarsJSONString = recipientVarsJSONString
      self.tag = tag
    }
    
    public init(from: String, to: [FullEmail], replyTo: String? = nil, cc: [FullEmail]? = nil, bcc: [FullEmail]? = nil, subject: String, text: String? = nil, html: String? = nil, attachments: [File]? = nil, template: String? = nil, recipientVarsJSONString: String? = nil, tag: String? = nil) {
      self.from = from
      self.to = to.stringArray.joined(separator: ",")
      self.replyTo = replyTo
      self.cc = cc?.stringArray.joined(separator: ",")
      self.bcc = bcc?.stringArray.joined(separator: ",")
      self.subject = subject
      self.text = text
      self.html = html
      self.attachment = attachments
      self.template = template
      self.recipientVarsJSONString = recipientVarsJSONString
      self.tag = tag
    }
  }
}


