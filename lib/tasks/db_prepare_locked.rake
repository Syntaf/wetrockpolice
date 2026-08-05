# frozen_string_literal: true

# `db:prepare` for bin/docker-entrypoint, serialized across replicas.
#
# On the migration path concurrent replicas already serialize on Active
# Record's migration advisory lock, but on a *fresh* database `db:prepare`
# takes the schema-load path (`load_schema` + `load_seed`), which Active
# Record does not lock at all: two replicas booting at once race
# `ActiveRecord::Schema.define` and crash-loop on duplicate-relation
# errors. So this wrapper takes its own Postgres advisory lock around the
# whole run.
#
# The lock lives on a raw PG session against the `postgres` maintenance
# database — the same database Rails itself connects to when it needs to
# create the app database — so it exists before the app database does,
# and nothing `db:prepare` does to Active Record's connection pools can
# release it early. Ending the session releases the lock, even if the
# process dies mid-prepare.
namespace :db do
  desc 'db:prepare, serialized across concurrent containers'
  task prepare_locked: :environment do
    require 'pg'

    # Arbitrary fixed bigint; every replica must use the same key.
    lock_key = 7_245_912

    config = ActiveRecord::Base.connection_db_config.configuration_hash
    lock_connection = PG.connect(
      host: config[:host],
      port: config[:port] || 5432,
      user: config[:username],
      password: config[:password],
      dbname: 'postgres'
    )
    lock_connection.exec("SELECT pg_advisory_lock(#{lock_key})")

    begin
      Rake::Task['db:prepare'].invoke
    ensure
      lock_connection.close
    end
  end
end
