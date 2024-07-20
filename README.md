# WetRockPolice ![](/docs/police-logo.png)

[![test](https://github.com/Syntaf/wetrockpolice/actions/workflows/tests.yml/badge.svg?branch=master)](https://github.com/Syntaf/wetrockpolice/actions/workflows/tests.yml)
[![build](https://github.com/Syntaf/wetrockpolice/actions/workflows/build.yml/badge.svg)](https://github.com/Syntaf/wetrockpolice/actions/workflows/build.yml)

## Table of Contents

- [Overview](#Overview)
  - [Dependencies](##Dependencies)
  - [Running Locally](##Running-Locally-with-RVM-&-Docker)
- [Contributing](#Contributing-Guide)
  - [Coding Standards](#Coding-Standards)
- [Development Guide](#Development-Guide)
  - [Model Overview](#Creating-a-New-Watched-Area-Site-Section)
  - [Frontend Assets](#Models-Overview)
  - [Creating or Updating Landing Page Images](#Creating-or-Updating-Hero-Images)
# Overview

Wetrockpolice is an open source project built with the Ruby on Rails framework. The site backed by a Postgresql database and hosted on a DOKS kubernetes cluster (digital ocean's managed cluster offering). The project has three key goals:

- Highlight the safety and ethics of climbing on wet rock within at-risk areas.
- Display historical and real-time rain information to help climbers make informed decisions.
- Help climbers find alternative climbing destinations in the event of poor weather.

Contibutors are welcome! Please visit the [issues](https://github.com/Syntaf/wetrockpolice/issues) tab for ideas on how to contribute.

## Dependencies

To work with wetrockpolice locally you'll need the following dependencies installed on your system:

- [Docker Compose](https://docs.docker.com/compose/install/) for running postgres & redis containers locally
- [RVM](https://rvm.io/rvm/install) for managing your local ruby version (http server)
- [NVM](https://github.com/nvm-sh/nvm?tab=readme-ov-file#installing-and-updating) for managing your local node version (webpack server)
- [VSCode](https://code.visualstudio.com/download) or your own preferred IDE

## Running Locally with RVM & Docker

The easiest way to work with wetrockpolice locally is to leverage Docker for your persistence layer
dependencies (postgres & redis) and run your own http & webpack services via a native ruby
installation (like via RVM)

1. Install the required ruby version (`3.1.4`) via [RVM's installation docs](https://rvm.io/rubies/installing)
   ```
   rvm install 3.1.4
   rvm use 3.1.4
   ```
  
2. Install the required node version (`20.13.1`) via [NVM's installation docs](https://github.com/nvm-sh/nvm?tab=readme-ov-file#usage)
   ```
   nvm install 20.13.1
   nvm use 20.13.1
   ```

3. Clone the repository
    ```
    git clone git@github.com:Syntaf/wetrockpolice.git
    ```

4. Copy over the example environment. **Note:** You shouldn't need to change any configuration from
   `.env.example` initially
   ```
   cd wetrockpolice
   cp .env.example .env
   ```

5. Start up your `postgres` and `redis` containers to run in the background
    ```
    make up
    ```

6. Install required gems & packages for running your webpack & http servers
   ```
   make install
   ```

7. Setup your database, run migrations & seed data
   ```
   make reset-db
   ```

8. Start your http & webpack servers
   ```
   ./bin/dev
   ```

9. Visit http://localhost:3001

## Running Locally on OSX -- Recommended

1. Install RVM and the required ruby version (`3.1.4`) via [RVM's installation docs](https://rvm.io/rubies/installing)
   ```
   rvm install 2.6
   rvm use 2.6
   ```

2. Install the required node version (`20.13.1`) via [NVM's installation docs](https://github.com/nvm-sh/nvm?tab=readme-ov-file#usage)
   ```
   nvm install 20.13.1
   nvm use 20.13.1
   ```

3. Install & start local postgres & redis instances via `brew`
   ```
   brew install postgresql@15
   brew install redis
   brew services start postgresql@15
   brew services start redis
   ```

1. Clone the repository
    ```
    git clone git@github.com:Syntaf/wetrockpolice.git
    ```

2. Copy over the example environment, no initial modifications should be required
   ```
   cd wetrockpolice
   cp .env.example .env
   ```

3. Update your `.env` to point towards your locally running services
   ```
   # .env.example

   # Job configuration
   # ------------------------------------
   REDIS_URL=redis://0.0.0.0:6379/0
   JOB_WORKER_URL=redis://0.0.0.0:6379/0

   # Database configuration
   # ------------------------------------
   POSTGRES_PASSWORD=dev
   POSTGRES_USER=wrp
   POSTGRES_DB=wetrockpolice_development
   POSTGRES_TEST_DB=wetrockpolice_test
   POSTGRES_HOST=0.0.0.0
   ```

4. Install dependencies
   ```
   make install
   ```

5. Setup your database
   ```
   make init
   ```

6. Seed data
   ```
   make db-seed
   ```
   
7. Start your servers
   ```
   make dev
   ```

6. Visit http://localhost:3001


# Contributing

This repository uses [Github Actions](https://github.com/features/actions) for continuous integration. Before a pull request can be merged into master it must pass all existing / new tests *as well* as linting (Rubocop). Using a rubocop extension is **highly** recommended.

#### Using Rubocop on Visual Studio Code:

Download the following extensions which should come pre-configured in the included `.vscode/settings.json`

- [Shopify LSP](https://marketplace.visualstudio.com/items?itemName=Shopify.ruby-lsp)
- [Ruby Debugger](https://marketplace.visualstudio.com/items?itemName=KoichiSasada.vscode-rdbg)
- [ERB Formatter](https://marketplace.visualstudio.com/items?itemName=aliariff.vscode-erb-beautify)

  **Note: If your solargraph server ever crashes and VSCode stops linting your work, use the developer window reload command to restart it.

#### Using Rubocop from the command line

If you're opposed to VSCode or prefer using a different editor, you can always run rubocop from the command line inside the project:

```
~$: cd wetrockpolice
~$: rubocop
```

By default the configuration files should be detected and used, so no arguments are needed.

## Coding Standards

For a full manifesto on coding standards, Rubocop will adhere mostly to the [Ruby Style Guide](https://rubystyle.guide/). In short, keep these key things in mind:

- Keep lines under **80** characters
- Use standard `snake_case` for varible and method naming
- Use `do end` instead of `{ }` when writing multi-line blocks
- Keep the length of blocks under **25** lines.
- Don't put business logic inside controllers. Skinny controllers, fat models

While WRP only supports Red Rock currently, the backend is designed to support multiple areas in the future and that should be kept in mind during development. Make sure any changes made consider a future where there are many active areas that can display precipitation data.


# Development Guide

## Models Overview

The database is designed to support a site that one day may have many watched areas (Red Rock, Moe's Valley, Etc). Below is an Entity Relationship Diagram that can be used to gain an understanding of the models defined in this project.

![ERB via LucidChards](/docs/erd.png)

#### LocalClimbingOrg

A not-for-profit climbing coalition managing one or more watched areas. The **slug** field is used for displaying the coalitions membership signup form within the watched area, i.e. `/redrock/sncc` where `sncc` is the slug of the climbing org instance.

#### WatchedArea

Represents an area being monitored for rain. Uses it's `slug` field to define a unique "microsite" within WRP consisting of a:
- Landing page (`/redrock`)
- Rainy day options page (`/redrock/rainy-day-options`)
- FAQ page (`/redrock/faq`)
- Membership signup page (`/redrock/sncc`)

Fields like `info_bubble_excerpt` and `park_type_word` allow for dynamic content on the landing page depending on the current watched area being rendered.

#### RainyDayArea

Links a climbing area to a watched area. Does not contain any information itself, just serves to define relationships between climbing areas and a watched area.

#### ClimbingArea

A climbing crag / area. Does not contain any associations to a watched area so that the same climbing area can be a "rainy day option" for multiple watched areas if needed.

#### Location

Contains a pair of coodinates in the EPSG:3857 WGS 84 / Pseudo-Mercator system, and an optional zoom attribute.

#### User

A standard devise-based user model. The one unique thing worth mentioning is the _manages_ attribute, which contains an array of watched area IDs. I.e. `user.manages == [1]` means the user can manage all db data relating to Red Rock.

## Frontend Structure

The asset pipeline is kept very simple intentionally. All assets are compressed, loaded and cached on a users first page visit, meaning there are no *page specific* JS/SCSS files.

JS code is encapsulated into vanilla "controllers"; each controller is responsible for managing the functionality on a given type of page. Since all of these controllers are loaded globally, you can immeditely use them at the bottom of your view template:

```erb
<!-- area/rainy_day_options/index.html.erb -->

<div class="rainy-day-content">
  <!-- ... -->
</div>
<script>
    // All controllers are loaded and in global scope
    var pageController = new RainyDayController({ /* ... */ });
</script>
```

## Creating or Updating Hero Images

This repository uses a custom strategy for loading large background images on the client to ensure the first-load experience isn't poor. Without this strategy, the page would load with the large image missing, then slowly load the image top-down as if the page was being printed out.

On page load, the browser will first load and display an extremely small version of the image (20x20 pixels for example) and apply a large gussian blur to distort the pixel borders. In the background, javascript is used to fetch the fully sized background image; once finished the full image will be swapped for the blurred image with a fade-in transition. The end result is a page load that looks like the background image is just being animated into view rather than slowly loaded.

Because of this strategy however, updating landing page images can be a little more involved. Follow these steps for creating or updating hero images:

1. Create two copies of your desired hero image: One which is the original (high quality) image and another which has had it's size dramatically scaled down (less then 50x50 pixels). Ensure you've maintained the aspect ratio when scaling the image down.

2. Move your two copies into `app/assets/images/watched-area-slug`, calling the original image `hero-image.jpg` and the small image `hero-image-small.jpg`.

3. Go to https://www.base64-image.de/ and load your small image to receive a base64 encoded string. Copy that string to your clipboard and open `application.html.erb`. In the custom style block at the head, add two new SCSS rules:
    ```css
      /* Watched Area */
      .hero-header.<slug> {
        background: url("data:image/jpeg;base64,/9j/4AAQSkZJ...");
        background-repeat: no-repeat;
        background-position: center center;
        background-size: cover;
      }
      .hero-header.<slug>.hero-header-loaded {
        background-image: url(<%= asset_path 'watchedarea/hero-image.jpg' %>);
      }
    ```

    Where `<slug>` refers to the slug of the watched area, e.g. `redrock` or `castlerock`.
    Since the initial background is a base64 encoded image, the page will almost always load with it already painted (albeit heavily blurred). The second rule will swap the background image while the image has been successfully loaded in the background (avoiding the top-down loading view).

4. Load the page and ensure your page transitions from the small image to large image. If you're having trouble determing if the small image is loading properly you can comment out `imageLoader.load()` in `views/area/watched_area/index.html.erb`, this will cause the page to load with only the small image

## Deploying to Kubernetes

Wetrockpolice is hosted on a digital ocean kubernetes cluster, deploying to this cluster (with credentials) is done through `Makefile` commands and `helm`. (k9s)[https://k9scli.io/] is a highly recommended tool.

The order of commands should be `commit`, `build`, `push`, the finally `deploy`