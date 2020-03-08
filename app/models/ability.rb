# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user&.admin?

    can :access, :rails_admin
    can :read, :dashboard

    # Only allow admins to view watched areas (Red Rock / Castle Rock)
    can :read,
        WatchedArea,
        WatchedArea.where(:id => user.manages),
        &:present?

    # Allow Admins to manage models related to the watched areas they belong
    can :manage,
        RainyDayArea,
        RainyDayArea.where(:watched_area => user.manages),
        &:present?

    can :manage,
        ClimbingArea,
        ClimbingArea.joins(:watched_areas)
                    .where(:watched_areas => { id: user.manages }),
        &:present?

    can :manage,
        Location,
        Location.joins(:watched_areas)
                .where(:watched_areas => { id: user.manages }),
        &:present?

    can :manage, JointMembershipApplication

    # Give super admins (me) full access to everything
    can :manage, :all if user.super_admin?
  end
end
