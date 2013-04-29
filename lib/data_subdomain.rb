class DataSubdomain  
  def self.matches?(request)  
    request.subdomain.present? && (request.subdomain == 'data' || request.subdomain == 'dev.data')
  end  
end  