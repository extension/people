# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  see LICENSE file
class AuditsController < ApplicationController
  before_filter :set_tab

  def index
  end


  def admins
  end

  def aliases
  end

  def google_apps_email
  end

  def google_groups
  end

  def account_status
    @status_counts = Person.not_system.not_retired.group(:account_status).count
  end

  def account_status_list
    @status_label = Person::STATUS_STRINGS[params[:account_status].to_i]
    @account_list = Person.not_system.not_retired.where(account_status: params[:account_status]).page(params[:page]).order('last_name ASC')
  end

  def publish_sites
  end

  private

  def set_tab
    @selected_tab = 'audits'
  end

end
