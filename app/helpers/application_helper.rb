module ApplicationHelper
  def current_faq_path(watched_area)
    "/#{watched_area.slug}/faq"
  end

  def current_rainy_day_options_path(watched_area)
    "/#{watched_area.slug}/rainy-day-options"
  end
end
