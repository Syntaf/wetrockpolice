# frozen_string_literal: true

# turbo-rails rides in as a transitive dependency of rails_admin, and its
# engine ships app/channels/turbo/streams_channel.rb, which subclasses
# ActionCable::Channel::Base. With Action Cable no longer loaded (see
# config/application.rb) eager loading that file raises NameError — which only
# bites in production, the one environment with eager_load on.
#
# Turbo Streams over websockets is used nowhere in this app; only Turbo Drive
# is, and that ships from the npm package. So the engine's channel directory is
# hidden from the autoloader. Two details matter here:
#
#   * the `turbo` subdirectory is ignored rather than `app/channels` itself,
#     because `app/channels` is a Zeitwerk root directory and Zeitwerk does not
#     honour `ignore` on its own roots;
#   * the paths of gem-provided engines live on the `once` loader, not `main`.
#     Both are covered so this keeps working if that ever changes.
#
# `ignore` has to be declared before the loaders are set up, which config
# initializers still precede.
#
# Phase 2 adopts turbo-rails as a first-class dependency and can revisit this.
if defined?(Turbo::Engine)
  turbo_channels = Turbo::Engine.root.join('app/channels/turbo')

  Rails.autoloaders.main.ignore(turbo_channels)
  Rails.autoloaders.once.ignore(turbo_channels)
end
