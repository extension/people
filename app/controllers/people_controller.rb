# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  see LICENSE file

class PeopleController < ApplicationController
  before_filter :set_tab

  def show
    @person = Person.find(params[:id])
  end


  def index
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

  private

  def set_tab
    @selected_tab = 'colleagues'
  end


end

