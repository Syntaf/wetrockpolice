# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user&.admin?

    can :access, :rails_admin
    can :read, :dashboard

    # Hash conditions, not a relation + block: cancancan derives BOTH the
    # `accessible_by` scope AND single-record `can?` checks from the same
    # conditions, so direct rails_admin member URLs are scoped by `manages`
    # exactly like the index screens. (The old relation + `&:present?` form
    # left instance checks unscoped; a bare relation without the block is
    # rejected outright by cancancan for `can?` — hash conditions are the
    # supported way to close the gap.)

    # Only allow admins to view watched areas (Red Rock / Castle Rock)
    can :manage, WatchedArea, id: user.manages

    # Allow Admins to manage models related to the watched areas they belong
    can :manage, RainyDayArea, watched_area_id: user.manages

    can :manage, ClimbingArea, watched_areas: { id: user.manages }

    can :manage, Location, watched_areas: { id: user.manages }

    # Give super admins (me) full access to everything
    can :manage, :all if user.super_admin?
  end
end
