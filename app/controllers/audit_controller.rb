# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  see LICENSE file
class AuditController < ApplicationController
  before_filter :set_tab
  before_filter :admin_required



  def index
  end


  def admins
  end

  private

  def set_tab
    @selected_tab = 'communities'
  end

end
