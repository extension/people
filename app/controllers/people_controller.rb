# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  see LICENSE file

class PeopleController < ApplicationController

  def show
    @person = Person.find(params[:id])
  end


  def index
    #TODO
  end

  # def public
  #   #TODO
  # end

  # def account
  #   #TODO
  # end

  # def communities
  #   #TODO
  # end

  # def recent
  #   #TODO
  # end

  # def password
  #   #TODO
  # end


end

