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

  def find
    if (!params[:q].blank?) 
      @colleagues = Person.patternsearch(params[:q]).order('last_name,first_name').page(params[:page])
      if @colleagues.blank?
        flash[:warning] = "No colleagues were found that matched your search term"
      end
    end
    
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

