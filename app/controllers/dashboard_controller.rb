class DashboardController < ApplicationController
  def show
    @referrals_count = current_user.referred_users.count
  end
end
