# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)

    if user && user.admin?
      can :access, :rails_admin
      can :read, :dashboard

      # Only allow admins to view watched areas (Red Rock / Castle Rock)
      can :read, WatchedArea, WatchedArea.where(:id => user.manages) do |watched_area|
        watched_area.present?
      end

      # Allow Admins to manage models related to the watched areas they manage
      can :manage, RainyDayArea, RainyDayArea.where(:watched_area => user.manages) do |area|
        area.present?
      end

      can :manage, ClimbingArea, ClimbingArea.joins(:watched_areas).where(:watched_areas => { :id => user.manages }) do |climbing_area|
        climbing_area.present?
      end

      can :manage, Location, Location.joins(:watched_areas).where(:watched_areas => { :id => user.manages }) do |location|
        location.present?
      end

      # Give super admins (me) full access to everything
      if user.super_admin?
        can :manage, :all
      end
    end
  end
end
