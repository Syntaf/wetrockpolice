import { Controller } from "@hotwired/stimulus";
//  the Mountain Project map should change to reflect the new area 
// and the information below should change to reflect the area I clicked.


export default class extends Controller {
  static targets = ["area", "description"]; // we now have a this.sourceTarget or a this.sourceTargets array
  
  initialize(watchedAreaSlug, options) {
/*****Function for setting options object*/
// function RainyDayController(watchedAreaSlug, options) {
//   this.watchedAreaSlug = watchedAreaSlug;
//   this.options = $.extend(options, {
//       'mp': {
//           'widgetSelector': '#mountainProjectWidget',
//           'defaultZoom': 11,
//           'height': 500,
//           'urlBase': 'https://www.mountainproject.com/widget'
//       },
//       'areaListElementSelector': '[data-role="rainy-day-list-option"]',
//       'activeSelectorClass': 'active',
//       'activeLabelSelector': '[data-role="active-title"]'
//   });

//   this.initView();
// }

// RainyDayController(watchedAreaSlug, options) {
  this.watchedAreaSlug = watchedAreaSlug
  this.options = Object.assign({}, options, {
          'mp': {
              'widgetSelector': '#mountainProjectWidget',
              'defaultZoom': 11,
              'height': 500,
              'urlBase': 'https://www.mountainproject.com/widget'
          },
          'areaListElementSelector': '[data-role="rainy-day-list-option"]',
                'activeSelectorClass': 'active',
                'activeLabelSelector': '[data-role="active-title"]'
    })
    this.initView();
// }
  }














  connect() {
    console.log('Hello, rainy day controller!');
    }
    // const element = this.sourceTargets //Is an array of all 'source' targets in the controller's scope
    
    /* 
      construct the URL using the data- attributes (<li> tag)
      select the iFrame id
      replace the src value with a new url

      Use the dat-target attribute to have the below method interact with the tag
      */

/**********The below commented-out function is what I used to make the UrlBuilder */
// RainyDayController.prototype.buildMountainProjectUrl = function (longitude, latitude, zoom) {
//   return this.options.mp.urlBase + '?loc=fixed&' +
//       'x=' + longitude + '&' +
//       'y=' + latitude + '&' +
//       'z=' + zoom + '&' +
//       'h=' + this.options.mp.height
// }

mountainProjectUrlBuilder = function() {
  const baseUrl = "https://www.mountainproject.com/widget?loc=fixed&";
  const item = document.querySelector('li[data-role="rainy-day-list-option"]') 
  const x = item.dataset.lat; //Replace const x = $activeElement.data('lat');
  const y = item.dataset.lon; //Replace const y = $activeElement.data('lon');
  const z = item.dataset.mtz ? item.data.mtz : this.options.mp.height //Replace const z = $activeElement.data('mtz') ? $activeElement.data('mtz') : this.options.mp.defaultZoom;
  const h = this.options.mp.height //Replace const h = this.options.mp.height
return `${baseUrl}x=${x}&y=${y}&z=${z}&h=${h}`
}
/********Used this functions to make the mountainProjectUrlBuilder function***********/
    
    // RainyDayController.prototype.updateMountainProjectWidget = function ($activeElement) {
    //   var longitude = $activeElement.data('lon');
    //   var latitude = $activeElement.data('lat');
    //   var zoom = $activeElement.data('mtz') ? $activeElement.data('mtz') : this.options.mp.defaultZoom;
    
    //   var newUrl = this.buildMountainProjectUrl(longitude, latitude, zoom);
    //   $(this.options.mp.widgetSelector).attr('src', newUrl);
    // }

updateMountainProjectWidget() {
  console.log("Helloooooo!")
//  const iFrame = document.querySelector("iframe#mountainProjectwiWidget")
  const iFrame = this.areaTargets
  return iFrame.forEach(element => {
    element.setAttribute("src", this.mountainProjectUrlBuilder())
  })
}

/*************Use this function to set the initView *********/
// RainyDayController.prototype.initView = function () {
//   $(this.options.areaListElementSelector).click(this.handleAreaSelection.bind(this)); // areaListElementSelector = [data-role="rainy-day-list-option"]'

//   this.$activeLocation = $('.' + this.options.activeSelectorClass); //activeSelectorClass = 'active'
//   this.$activeLabel = $(this.options.activeLabelSelector); // activeLabelSelector = '[data-role="active-title"]'
//   this.$description = $('p[data-role="area-description"]');
//   this.$rockType = $('strong[data-role="area-rock-type"]');
//   this.$driveTime = $('strong[data-role="area-drive-time"]');

//   if (this.$activeLocation.length < 1)
//   {
//       console.error('No active list element found');
//       return;
//   }

//   this.updateMountainProjectWidget(this.$activeLocation);
// }


setInitView() {
const rainyDayListOption = document.querySelector(this.options.areaListElementSelector);
const activeLocation = document.querySelector(this.options.activeLabelSelector);
const description = document.querySelector('[data-role="area-description"]');
const rockType = document.querySelector('[data-role="area-rock-type"]');
const driveTime = document.querySelector('[data-role="area-drive-time"]')

if (activeLocation.length < 1) {
  // console.error('No active list element found')
  throw new Error("No active list element found")
}
this.updateMountainProjectWidget()
}

/*********For rebuilding the area selection function ********/
// RainyDayController.prototype.handleAreaSelection = function (ev) {
//   var $target = $(ev.target);
//   var areaId = $target.data('id');
//   var $selectedItems = $('[data-id="' + $target.data('id') + '"]');

//   // Do nothing if the clicked element is already active
//   if ($target.hasClass(this.options.activeSelectorClass))
//   {
//       return;
//   }

//   this.fetchArea(areaId)
//       .then(this.displayArea.bind(this, $selectedItems));
// }


handleAreaSelection(event) {
  // let target = document.querySelector(event)
  let areaId = event
  let element = document.querySelectorAll(`[data-id="${areaId}"]`)

  if (this.areaTarget) {
    return
  }
  this.fetchArea(areaId)
    .then(this.displayArea(() => {
      element
    }))

/*********Used this function to make an async function for getting url */
    // RainyDayController.prototype.fetchArea = function (id) {
    //   var url = '/' + this.watchedAreaSlug + '/rainy-day-options/';
    //   return $.get(url + id);
    // }
    };
    
    fetchArea(id){
    let url = '/' + this.watchedAreaSlug + '/rainy-day-options/';
    return fetch(url + id)
      .then(response => {
        if (!response.ok) {
          throw new Error('Network response error')
        }
        return response.json()
      })
    }

    // RainyDayController.prototype.displayArea = function ($newActiveListItem, response) {
    //   if (!response || response.length == 0) {
    //       console.error('Issue connecting to server :(');
    //   }
    //   this.swapActiveClass($newActiveListItem);
    //   this.updatePageInformation(response);
    //   this.updateMountainProjectWidget($newActiveListItem);
    
    //   this.$activeLocation = $newActiveListItem;
    // }

displayArea(newActiveListItem, response) {
  if (!response || response.length == 0) {
    console.error('Issue connecting to the server')
  }
  this.swapActiveClass(newActiveListItem);
  this.updatePageInformation(response);
  this.updateMountainProjectWidget(newActiveListItem);

  this.activeLocation = newActiveListItem
}


// RainyDayController.prototype.swapActiveClass = function($newActiveListItem) {
//   this.$activeLocation.removeClass(this.options.activeSelectorClass);
//   $newActiveListItem.addClass(this.options.activeSelectorClass);
// }
swapActiveClass(newActiveListItem) {
  this.activeLocation.removeClass(this.options.activeSelectorClass);
  newActiveListItem.addClass(this.options.activeSelectorClass);

  // Why don't we just use setAttibute() to set a new class?
}

// RainyDayController.prototype.updatePageInformation = function(newAreaInformation) {
//   this.$description.html(newAreaInformation['climbing_area']['description']);
//   this.$rockType.html(newAreaInformation['climbing_area']['rock_type']);
//   this.$driveTime.html(newAreaInformation['driving_time'] + ' minutes');
//   this.$activeLabel.html(newAreaInformation['climbing_area']['name']);
// }

updatePageInformation(newAreaInfo) {
this.description.html(newAreaInfo['climbing_area']['description']);
this.rockType.html(newAreaInfo['climbing_area']['rock_type']);
this.driveTime.html(newAreaInfo['driving_time'] + 'minutes');
this.activeLabel.html(newAreaInfo[climbing_area]['name']);
}

}