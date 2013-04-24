class DataSubdomain  
  def self.matches?(request)  
    request.subdomain.present? && request.subdomain == 'data'  
  end  
end  