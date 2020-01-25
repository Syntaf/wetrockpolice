class MembershipsController < ApplicationController
    def new
        @watched_area = WatchedArea.find_by(id: params[:watched_area_id])
        @jointMembership = JointMembershipApplication.new
        
    end

    def create
        @membershipApp = JointMembershipApplication.create(params.require(:joint_membership_application).permit(
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
