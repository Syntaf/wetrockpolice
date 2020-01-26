class MembershipsController < ApplicationController
    def new
        @watched_area = WatchedArea.find_by(id: params[:watched_area_id])
        @joint_membership = JointMembershipApplication.new
    end

    def create
        @membership_app = JointMembershipApplication.create(params.require(:joint_membership_application).permit(
            :first_name,
            :last_name,
            :email,
            :phone_number,
            :street_line_one,
            :street_line_two,
            :city,
            :state,
            :zipcode,
            :shirt_size))
    end
end
