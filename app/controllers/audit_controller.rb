# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  see LICENSE file
class AuditController < ApplicationController
  before_filter :set_tab

  def index
  end


  def admins
  end

  def aliases
  end

  private

  def set_tab
    @selected_tab = 'aliases'
  end

end
