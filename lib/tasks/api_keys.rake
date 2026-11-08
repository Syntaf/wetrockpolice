# frozen_string_literal: true

namespace :api_keys do
  # Creates a partner key and prints it once; only its digest is stored.
  #
  #   bin/rails "api_keys:create[Mountain Project]"
  #
  # Revoke it later by unticking `active` in Rails Admin (API keys).
  desc 'Create a partner API key (printed once)'
  task :create, [:name] => :environment do |_task, args|
    abort 'usage: bin/rails "api_keys:create[Partner name]"' if args[:name].blank?

    api_key, token = ApiKey.generate!(name: args[:name])
    puts "Created API key ##{api_key.id} for #{api_key.name}. Give them this key; it can't be shown again:"
    puts
    puts "  #{token}"
  end

  desc 'List partner API keys'
  task list: :environment do
    ApiKey.order(:id).each do |key|
      used = key.last_used_at ? "last used #{key.last_used_at.utc.iso8601}" : 'never used'
      puts format('#%-4d %-30s %-8s %s', key.id, key.name, key.active ? 'active' : 'REVOKED', used)
    end
  end
end
