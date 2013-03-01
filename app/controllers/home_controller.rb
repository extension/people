# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

class HomeController < ApplicationController
  skip_before_filter :signin_required, only: [:index]
  before_filter :set_tab

  def index
  end

  def help
  end


  private

  def set_tab
    @selected_tab = 'home'
  end
  
end