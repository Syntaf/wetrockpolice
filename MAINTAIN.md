# Overview of WetRockPolice Infrastructure

WetRockPolice is a standard rails >5 project using postgres for it's database.

Asset packaging is kept very simple: all assets are compressed, loaded and cached initially on a users first page visit. This means there is no page-by-page basis for loading JS and SCSS, instead JS code is logically separated into controllers to be used by the current view:

```erb
<div class="rainy-day-content">
  <!-- ... -->
</div>
<script>
    // All controllers are loaded and in global scope
    var pageController = new RainyDayController({ /* ... */ });
</script>
```

## Template & Controller Layout

If I could go back in time I'd change the base structure of this project, but alas. 

`WatchedAreaController` is a base controller which implements all basic functionality needed for a sub-site section like `/redrock`. Watched areas (like Red Rock) then have their own controller and inherit from the base controller. The child controller only needs supply basic page text.

### Creating a new site section (i.e. /redrock)

1. Ensure you have created a new watched area entry in the database

2. Create a new controller which will represent you new watched area, for example `rails g controller NewWatchedArea`.

3. Define the routes needed for the new site section. Replace `:newwatchedarea` with the _slug_ of your watched area and `id` with the _id_ of your watched area:
```rb
# config/routes.rb
Rails.application.routes.draw do
  # ...

  namespace :newwatchedarea, defaults: { watched_area_id: id } do
    get '/', to: '/newwatchedarea#index'
    get '/faq', to: '/newwatchedarea#faq'
    get '/rainy-day-options', to: '/newwatchedarea#rainy_day_options'
    get '/climbing_area', to: '/newwatchedarea#climbing_area'
  end
end
```

4. Copy all view templates from an existing watched area to your new controllers views. Not an ideal solution, but works for now while there are very little watched areas (one at this time).

5. Load the site section and start modifying the copied templates as needed.

### Creating or Updating a lazy-loaded hero image

WetRockPolice uses it's own custom strategy for loading large background images to ensure the first-load experience isn't poor. Without this strategy, the page would load with the large image missing and slowly load the image top-down as if the page was being printed out.

To avoid this, WRP will first load an extremely small version of the image (20x20 pixels for example) and apply a large gussian blur to distort the pixel borders and give the impression that the image exists but is heavily blurred. Once the actual large image has been loaded in the background the images are swapped out with a blur transition applied. The end results makes it seem like the large image was loaded immeditely on view, and blurred into view without the viewer knowing there were actually two images at play.

To update or create a new lazy-loaded image:


## Entities

![ERB via LucidChards](/docs/WetRockPolice_ERD.png)

The database layout is designed to handle more than just Red Rock in the future. While it might initially feel like unnecessary abstraction it will allow the site to support other coalitions in the future with minimal development work required.

#### WatchedArea

Represents the area being monitored for rain (big picture). Red Rock is one such watched area

#### ClimbingArea

A climbing crag / area. Does not contain any associations to a watched area so that the same climbing area can be a "rainy day option" for multiple watched areas if needed. This avoids the need to duplicate climbing crags.

#### RainyDayArea

Links a climbing area to a watched area. Does not contain any information itself, just serves to define relationships between climbing areas and a watched area.

#### Location

Contains a pair of coodinates in the EPSG:3857 WGS 84 / Pseudo-Mercator system, and an optional zoom attribute.

#### User

A standard devise-based user model. The one unique thing worth mentioning is the _manages_ attribute, which contains an array of watched area IDs. I.e. `user.manages == [1]` means the user can manage all db data relating to Red Rock.