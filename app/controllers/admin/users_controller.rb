module Admin
  class UsersController < AdminController

    # Displays the users
    # This should be used in test only
    def index
      @users = User.all
      render :template => "admin/users"
    end

    def participation_details
      render :partial => "admin/user", :object =>  User.find(params[:id])
    end
  end
end