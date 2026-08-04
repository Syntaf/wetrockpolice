// rails_admin importmap entry point. Resolved by the bare
// `pin "rails_admin", preload: true` in config/importmap.rails_admin.rb and
// served by Propshaft (importmap-rails puts app/javascript on the asset
// paths). Everything it imports comes from the CDN pins in that file.
import "rails_admin/src/rails_admin/base";
