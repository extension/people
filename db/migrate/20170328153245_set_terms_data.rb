class SetTermsData < ActiveRecord::Migration
  def change
    # change tou_status_date column
    rename_column(:people, :tou_status_date, :tou_accepted_at)
    remove_column(:people, :tou_status)

    # account status manipulation
    # status: old retired,invalidemail,invalidemail from signup - throw back into tou_pending - cleans up minimally used states
    execute "UPDATE people SET account_status = #{Person::STATUS_TOU_PENDING} where account_status IN (5,6,8)"
    # change signup status code
    execute "UPDATE people SET account_status = #{Person::STATUS_SIGNUP} where account_status = 7"
    # for anyone in old participant or current contributor status, set to tou_pending
    execute "UPDATE people SET account_status = #{Person::STATUS_TOU_PENDING} where account_status IN (4,42)"

    # change tou_accepted_at to nil
    execute "UPDATE people SET tou_accepted_at = NULL where 1"

  end

end
