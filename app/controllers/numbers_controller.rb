# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  see LICENSE file

class NumbersController < ApplicationController
  before_filter :set_tab


  def index
  end


  private

  def set_tab
    @selected_tab = 'numbers'
  end

end