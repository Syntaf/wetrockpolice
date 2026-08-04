# frozen_string_literal: true

# turbo-rails rides in as a transitive dependency of rails_admin, and its
# engine ships app/channels/turbo/streams_channel.rb, which subclasses
# ActionCable::Channel::Base. With Action Cable no longer loaded (see
# config/application.rb) eager loading that file raises
# `NameError: uninitialized constant ActionCable`.
#
# turbo-rails 1.5.0 has its own guard for this, but it does not fire here:
#
#   initializer "turbo.no_action_cable", before: :set_eager_load_paths do
#     config.eager_load_paths.delete("#{root}/app/channels") unless defined?(ActionCable)
#   end
#
# It deletes from `config.eager_load_paths`, but the engine also exposes that
# directory through `paths.eager_load` (the `app/*` glob), and
# `all_eager_load_paths` is `eager_load_paths + paths.eager_load`. So
# `ActiveSupport::Dependencies.eager_load?(dir)` is still true, railties never
# reaches its `autoloader.do_not_eager_load(path)` branch, and the directory is
# eager loaded regardless. Verified: delete this file and
# `bin/rails zeitwerk:check` fails with the NameError above.
#
# Turbo Streams over websockets is used nowhere in this app; only Turbo Drive
# is, and that ships from the npm package. So the channel directory is hidden
# from the autoloader instead.
#
# The directory lives on `Rails.autoloaders.once` (turbo declares it in
# `config.autoload_once_paths`), which `:setup_once_autoloader` has already set
# up by the time config initializers run. That is fine: `ignore` only has to
# precede *eager loading*, which happens later, in the finisher's
# `:eager_load!`. `main` is covered too, in case those paths ever move.
#
# Phase 2 adopts turbo-rails as a first-class dependency and can revisit this.
if defined?(Turbo::Engine)
  turbo_channels = Turbo::Engine.root.join('app/channels/turbo')

  Rails.autoloaders.main.ignore(turbo_channels)
  Rails.autoloaders.once.ignore(turbo_channels)
end
