class DevelopmentMailInterceptor  
  def self.delivering_email(message)  
    message.subject = "[#{message.to}] #{message.subject}"  
    message.to = "systemsreplies@extension.org"
    message.cc = nil
    message.bcc = nil  
  end  
end 