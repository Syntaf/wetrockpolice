## Table of Contents

- [Overview](#Overview)
  - [Frontend Structure](#Frontend-Structure)
  - [Entity Overview](#Entity-Overview)
- [Development Guide](#Development-Guide)
  - [Coding Standards](#Coding-Standards)
  - [Creating a New Watched Area Site Section](#Creating-a-New-Watched-Area-Site-Section)
  - [Creating or Updating Hero Images](#Creating-or-Updating-Hero-Images)
# Overview

WetRockPolice is a standard rails >5 project using postgres for it's database. Heroku is used for hosting the application.

## Frontend Structure

The asset pipeline is kept very simple intentionally. All assets are compressed, loaded and cached on a users first page visit, meaning there are no page specific JS/SCSS files. JS code is logically separated into controllers, which manage all functionality on a given type of page. Since all of these controllers are loaded globally, you can immeditely use them at the bottom of your view template:

```erb
<!-- rainy_day_options.html.erb -->

<div class="rainy-day-content">
  <!-- ... -->
</div>
<script>
    // All controllers are loaded and in global scope
    var pageController = new RainyDayController({ /* ... */ });
</script>
```

## Entity Overview

The database is designed to support a site that one day may have many watched areas (Red Rock, Moe's Valley, Etc). Below is an Entity Relationship Diagram that can be used to gain an understanding of the models defined in this project.

![ERB via LucidChards](/docs/WetRockPolice_ERD.png)

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
## Template & Controller Layout

If I could go back in time I'd change the base structure of this project, but alas. 

`WatchedAreaController` is a base controller which implements all basic functionality needed for a sub-site section like `/redrock`. Watched areas (like Red Rock) then have their own controller and inherit from the base controller. The child controller only needs supply basic page text.

# Development Guide

## Coding Standards

## Creating a New Watched Area Site Section

To create a new site section similar to `/redrock`, follow these steps:

1. Create a new watched area entry in the database via `/admin`

2. Run `rails g controller <watched-area>` to create a new controller for the site section

3. Route requests to the slug to the new controller. Replace `:watchedarea` with the _slug_ of your watched area and `id` with the _id_ of your watched area:
```rb
# config/routes.rb

Rails.application.routes.draw do
  # ...

  namespace :watchedarea, defaults: { watched_area_id: id } do
    get '/', to: '/watchedarea#index'
    get '/faq', to: '/watchedarea#faq'
    get '/rainy-day-options', to: '/watchedarea#rainy_day_options'
    get '/climbing_area', to: '/watchedarea#climbing_area'
  end
end
```

4. Copy all view templates from an existing watched area to your new controllers views directly. This is obviously not an ideal workflow, but suffices for now while there are very little watched areas (one at this time).

5. Load the site section and start modifying the copied templates as needed.

## Creating or Updating Hero Images

WetRockPolice uses it's own custom strategy for loading large background images to ensure the first-load experience isn't poor. Without this strategy, the page would load with the large image missing, then slowly load the image top-down as if the page was being printed out.

To avoid this, WRP will first load an extremely small version of the image (20x20 pixels for example) and apply a large gussian blur to distort the pixel borders. Once the actual large image has been loaded in the background the images are swapped out with a blur transition applied. The end results makes it seem like the large image was loaded immeditely on view, and blurred into view without the viewer knowing there were actually two images at play.

Follow these steps for creating or updating hero images:

1. Create two copies of your desired hero image: One which is the original (high quality) image and another which has had it's size dramatically scaled down (less then 50x50 pixels). Ensure you've maintained the aspect ratio when scaling the image down.

2. Move your two copies into `app/assets/images/yourwachedarea`, calling the original image `hero-image.jpg` and the small image `hero-image-small.jpg`.

3. Go to https://www.base64-image.de/ and load your small image to receive a base64 encoded string. Copy that string to your clipboard and open `application.html.erb`. In the custom style block at the head, add (or change) the following SCSS rules:
    ```css
      /* Watched Area */
      .hero-header.watchedarea {
        background: url("data:image/jpeg;base64,/9j/4AAQSkZJ...");
        background-repeat: no-repeat;
        background-position: center center;
        background-size: cover;
      }
      .hero-header.watchedarea.hero-header-loaded {
        background-image: url(<%= asset_path 'watchedarea/hero-image.jpg' %>);
      }
    ```
    Since the initial background is a base64 encoded image, the page will almost always load with it already painted (albeit heavily blurred). The second rule will swap the background image while the image has been successfully loaded in the background (avoiding the top-down loading view).

4. Load the page and ensure your page transitions from the small image to large image. If you're having trouble determing if the small image is loading properly you can comment out `imageLoader.load()` in `views/watcharea/index.html.erb`, this will cause the page to load with only the small image
