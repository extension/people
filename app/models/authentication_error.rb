# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class AuthenticationError < StandardError
  attr :error_code
  attr :person_id

  def initialize(options = {})
    @error_code = options[:error_code]
    @person_id = options[:person_id]
  end

end