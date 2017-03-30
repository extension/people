class FixSignupStatus < ActiveRecord::Migration
  def up
    # status can't be zero - so set it back to 7
    execute "UPDATE people SET account_status = #{Person::STATUS_SIGNUP} where account_status = 0"
  end
end
