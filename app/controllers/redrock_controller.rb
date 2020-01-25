class RedrockController < WatchedAreaController
  def base_keywords
    super + ", Las Vegas, Nevada"
  end

  def index
    super
  end

  def faq
    super
    @page_description = "Generally, you should avoid climbing on wet sandstone at Red Rock for anywhere between 24 and 72 hours, depending on the amount of sunlight and temperature in the following days."
  end

  def rainy_day_options
    super
    @page_description = "The Las Vegas area contains a multitude high quality crags suitable for any weather, be it rain sleet or snow. Integrated with mountain project and curated by locals, these crags are great options for rainy days in the city."
  end

  def climbing_area
    super
  end

  def sncc
    @jointMembership = JointMembershipApplication.new
  end
end
