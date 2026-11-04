# frozen_string_literal: true

require 'test_helper'

# Pins the authorization matrix produced by app/models/ability.rb.
#
# Its main job is to guard the YAML-serialized `users.manages` column: every
# grant below is a hash condition keyed on `user.manages`, so a serialization
# change (Rails defaults bump, explicit `coder:`) that turns `manages` into a
# String or nil would silently widen or void admin access.
class AbilityTest < ActiveSupport::TestCase
  def setup
    @redrock = watched_areas(:redrock)
    @castlerock = watched_areas(:castlerock)
    @managed_area = climbing_areas(:area1)
    @unmanaged_area = climbing_areas(:area3)
  end

  # --- super admin -------------------------------------------------------

  test 'super admin can access rails_admin and the dashboard' do
    ability = Ability.new(users(:super_admin))

    assert ability.can?(:access, :rails_admin)
    assert ability.can?(:read, :dashboard)
  end

  test 'super admin can manage every model regardless of manages' do
    user = users(:super_admin)
    assert_empty user.manages, 'fixture guard: super admin manages nothing explicitly'

    ability = Ability.new(user)

    assert ability.can?(:manage, @redrock)
    assert ability.can?(:manage, @castlerock)
    assert ability.can?(:manage, @unmanaged_area)
    assert ability.can?(:manage, users(:plain_user))
    assert ability.can?(:manage, Faq.new)
  end

  test 'super admin sees every record through accessible_by' do
    ability = Ability.new(users(:super_admin))

    assert_equal %w[castlerock redrock],
                 WatchedArea.accessible_by(ability).pluck(:slug).sort
    assert_equal %w[area1 area2 area3],
                 ClimbingArea.accessible_by(ability).pluck(:name).sort
  end

  # --- scoped (non-super) admin -----------------------------------------

  test 'scoped admin can access rails_admin and the dashboard' do
    ability = Ability.new(users(:area_admin))

    assert ability.can?(:access, :rails_admin)
    assert ability.can?(:read, :dashboard)
  end

  test 'manages deserializes to an array of watched area ids' do
    manages = users(:area_admin).manages

    assert_kind_of Array, manages
    assert_equal [@redrock.id], manages
  end

  test 'manages survives a save-and-reload round trip through the coder' do
    user = users(:area_admin)
    user.update!(manages: [@redrock.id, @castlerock.id])

    reloaded = User.find(user.id).manages

    assert_kind_of Array, reloaded
    assert_equal [@redrock.id, @castlerock.id], reloaded
  end

  test 'scoped admin accessible_by is limited to the watched areas in manages' do
    ability = Ability.new(users(:area_admin))

    assert_equal %w[redrock], WatchedArea.accessible_by(ability).pluck(:slug)
    assert_equal %w[area1 area2],
                 ClimbingArea.accessible_by(ability).pluck(:name).sort
    assert_equal [rainy_day_areas(:area1_redrock).id,
                  rainy_day_areas(:area2_redrock).id].sort,
                 RainyDayArea.accessible_by(ability).pluck(:id).sort
    assert_equal [locations(:area1_location).id,
                  locations(:area2_location).id].sort,
                 Location.accessible_by(ability).pluck(:id).sort
  end

  test 'an admin whose manages is empty can reach no records' do
    ability = Ability.new(User.new(admin: true, approved: true, manages: []))

    assert_empty WatchedArea.accessible_by(ability)
    assert_empty ClimbingArea.accessible_by(ability)
    assert_empty RainyDayArea.accessible_by(ability)
    assert_empty Location.accessible_by(ability)
  end

  test 'scoped admin cannot manage models outside the watched-area grants' do
    ability = Ability.new(users(:area_admin))

    assert ability.cannot?(:manage, users(:plain_user))
    assert ability.cannot?(:manage, Faq.new)
  end

  # Closes the gap deliberately asserted here since Phase 0: Ability used to
  # pass both a relation AND the block `&:present?` to `can`, so `can?` on a
  # single record called the block and any persisted record passed. Grants
  # are now hash conditions, which cancancan uses for BOTH `accessible_by`
  # and single-record checks — so direct rails_admin member URLs (edit,
  # update, delete) are scoped by `manages` exactly like the index screens.
  # The engine-level smoke lives in test/integration/rails_admin_access_test.rb.
  test 'scoped admin instance checks are scoped by manages' do
    ability = Ability.new(users(:area_admin))

    assert ability.can?(:manage, @redrock)
    assert ability.cannot?(:manage, @castlerock)
    assert ability.cannot?(:manage, @unmanaged_area)
  end

  test 'scoped admin instance checks are scoped on every granted model' do
    ability = Ability.new(users(:area_admin))

    assert ability.can?(:manage, @managed_area)
    assert ability.can?(:manage, rainy_day_areas(:area1_redrock))
    assert ability.cannot?(:manage, rainy_day_areas(:area3_castlerock))
    assert ability.can?(:manage, locations(:area1_location))
    assert ability.cannot?(:manage, locations(:area3_location))
  end

  # --- non-admins --------------------------------------------------------

  test 'an approved non-admin user is granted nothing' do
    ability = Ability.new(users(:plain_user))

    assert ability.cannot?(:access, :rails_admin)
    assert ability.cannot?(:read, :dashboard)
    assert ability.cannot?(:manage, @redrock)
    assert ability.cannot?(:manage, @managed_area)
    assert_empty WatchedArea.accessible_by(ability)
  end

  test 'an unapproved user is granted nothing' do
    ability = Ability.new(users(:unapproved_user))

    assert ability.cannot?(:access, :rails_admin)
    assert ability.cannot?(:read, :dashboard)
    assert ability.cannot?(:manage, @redrock)
    assert_empty WatchedArea.accessible_by(ability)
  end

  test 'a nil user is granted nothing' do
    ability = Ability.new(nil)

    assert ability.cannot?(:access, :rails_admin)
    assert ability.cannot?(:read, :dashboard)
    assert ability.cannot?(:manage, @redrock)
  end
end
