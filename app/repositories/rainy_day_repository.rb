class RainyDayRepository
    def get_watched_area(slug)
        areas = WatchedArea.find_by(slug: slug)

        return areas
    end
end