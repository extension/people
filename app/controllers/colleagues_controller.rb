# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  see LICENSE file

class ColleaguesController < ApplicationController

  def show
    @colleague = Person.find(params[:id])
  end

end

