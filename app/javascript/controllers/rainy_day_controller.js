import { Controller } from "@hotwired/stimulus";
//  the Mountain Project map should change to reflect the new area 
// and the information below should change to reflect the area I clicked.


export default class extends Controller {
  static targets = ["area", "description"]; // we now have a this.sourceTarget or a this.sourceTargets array
  
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

mountainProjectUrlBuilder() {
  const baseUrl = "https://www.mountainproject.com/widget?loc=fixed&"; //Replace const x = $activeElement.data('lat');
  const item = document.querySelector('li[data-role="rainy-day-list-option"]') //Replace const y = $activeElement.data('lon');
  const x = item.dataset.lat;
  const y = item.dataset.lon;
  const z = item.dataset.mtz ? item.data.mtz : 11 //Replace const z = $activeElement.data('mtz') ? $activeElement.data('mtz') : this.options.mp.defaultZoom;
  const h = 500 //Replace const h = this.options.mp.height
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

mountainProjectUrlUpdater() {
  console.log("POOOOOOO")
//  const iFrame = document.querySelector("iframe#mountainProjectwiWidget")
  const iFrame = this.areaTargets
  return iFrame.forEach(element => {
    element.setAttribute("src", this.mountainProjectUrlBuilder())
  })
}










  // Rebuild the old JQuery based functionality here

};

/********Do we need to remake the RainyDayController function?************/
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




// RainyDayController.prototype.initView = function () {
//   $(this.options.areaListElementSelector).click(this.handleAreaSelection.bind(this));

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

// RainyDayController.prototype.fetchArea = function (id) {
//   var url = '/' + this.watchedAreaSlug + '/rainy-day-options/';
//   return $.get(url + id);
// }

// RainyDayController.prototype.displayArea = function ($newActiveListItem, response) {
//   if (!response || response.length == 0) {
//       console.error('Issue connecting to server :(');
//   }

//   this.swapActiveClass($newActiveListItem);
//   this.updatePageInformation(response);
//   this.updateMountainProjectWidget($newActiveListItem);

//   this.$activeLocation = $newActiveListItem;
// }

// RainyDayController.prototype.swapActiveClass = function($newActiveListItem) {
//   this.$activeLocation.removeClass(this.options.activeSelectorClass);
//   $newActiveListItem.addClass(this.options.activeSelectorClass);
// }

// RainyDayController.prototype.updatePageInformation = function(newAreaInformation) {
//   this.$description.html(newAreaInformation['climbing_area']['description']);
//   this.$rockType.html(newAreaInformation['climbing_area']['rock_type']);
//   this.$driveTime.html(newAreaInformation['driving_time'] + ' minutes');
//   this.$activeLabel.html(newAreaInformation['climbing_area']['name']);
// }