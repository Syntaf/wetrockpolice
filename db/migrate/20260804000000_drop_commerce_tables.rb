# frozen_string_literal: true

# Phase 1 of the stack modernization: the memberships/raffle/TicketSource
# feature cluster is deleted as code AND data (owner decision, 2026-08-03).
# Records are not retained, so this migration is deliberately one-way — a
# reversal would recreate empty tables and quietly imply the data came back.
#
# Drop order follows the foreign key: shirt_orders references
# joint_membership_applications.
class DropCommerceTables < ActiveRecord::Migration[7.1]
  def up
    drop_table :shirt_orders
    drop_table :joint_membership_applications
    drop_table :raffle_entries
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          'Commerce tables were dropped with their data; there is nothing to ' \
          'restore. Recover from a database backup if this was a mistake.'
  end
end
