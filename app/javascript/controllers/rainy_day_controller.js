import { Controller } from "@hotwired/stimulus";


export default class extends Controller {
  static targets = ["link"]; // we now have a this.sourceTarget or a this.sourceTargets array
  
  static options = {
         "mp": {
             'widgetSelector': '#mountainProjectWidget',
             'defaultZoom': 11,
             'height': 500,
             'urlBase': 'https://www.mountainproject.com/widget'
         },
         'areaListElementSelector': '[data-role="rainy-day-list-option"]',
               'activeSelectorClass': 'active',
               'activeLabelSelector': '[data-role="active-title"]'
   }
  connect() {
    // this.watchedAreaSlug = watchedAreaSlug // Using this context allows for the below properties to be globally accessible
    }


updateMountainProjectWidgetDropDown(event) {
  const baseUrl = "https://www.mountainproject.com/widget?loc=fixed&";
  const target = event.currentTarget
  const x = target.dataset.lon; //Replace const y = $activeElement.data('lon');
  const y = target.dataset.lat; //Replace const x = $activeElement.data('lat');
  const z = target.dataset.mtz ? target.dataset.mtz : this.constructor.options.mp.defaultZoom //Replace const z = $activeElement.data('mtz') ? $activeElement.data('mtz') : this.options.mp.defaultZoom;
  const h = this.constructor.options.mp.height //Replace const h = this.options.mp.height
  const url =  `${baseUrl}x=${x}&y=${y}&z=${z}&h=${h}`

  const iFrame = document.querySelector("iframe")
  if (url === iFrame.src) return

  return iFrame.setAttribute("src", url)
 }
          
updateMountainProjectWidgetListItem(event) {
  const baseUrl = "https://www.mountainproject.com/widget?loc=fixed&";
  const target = event.currentTarget

  const x = target.dataset.lon; //Replace const y = $activeElement.data('lon');
  const y = target.dataset.lat; //Replace const x = $activeElement.data('lat');
  const z = target.dataset.mtz ? target.dataset.mtz : this.constructor.options.mp.defaultZoom //Replace const z = $activeElement.data('mtz') ? $activeElement.data('mtz') : this.options.mp.defaultZoom;
  const h = this.constructor.options.mp.height //Replace const h = this.options.mp.height
  const url =  `${baseUrl}x=${x}&y=${y}&z=${z}&h=${h}`

  const iFrame = document.querySelector("iframe")
  if (url === iFrame.src) return

  return iFrame.setAttribute("src", url)
  }


/*********This function fetches the area attributes and replaces the old ones with these***********/
    async fetchArea (event) {
      const href = this.linkTarget.getAttribute("href")
      let url = href + '/rainy-day-options/'; 

    const response = await fetch(url + event.currentTarget.dataset.id)
        if (!response.ok) {
          throw new Error('Network response error')
        }
        const data = await response.json()
     
        // We need to select the attributes from fetch
        const description = data.climbing_area.description
        const rockType = data.climbing_area.rock_type
        // const drivingTime = data.driving_time

        // We need to select the elements/attributes to replace
        const areaDescription = document.querySelector('p[data-role="area-description"]')
        areaDescription.innerHTML = description

        const rockTypeElement = document.querySelector('strong[data-role="area-rock-type"]')
        rockTypeElement.innerHTML = rockType
        // const drivingTimeElement = document.querySelector('strong[data-role="area-drive-time"]')
      }

// We need to figure out why the drop down menu is not working.



















// Might use these funcs for inspiration...
/*************This Function is for setting the display area (NOT CURRENTLY USED) *************/
// displayArea(newActiveListItem, response) {
//   if (!response || response.length == 0) {
//     console.error('Issue connecting to the server')
//   }
//   this.swapActiveClass(newActiveListItem);
//   this.updatePageInformation(response);
//   this.updateMountainProjectWidget(newActiveListItem);

//   this.activeLocation = newActiveListItem
// }

/*****************DON'T NEED THE SWAP FUNC */
// swapActiveClass(newActiveListItem) {
//   this.activeLocation.removeClass(this.options.activeSelectorClass);
//   newActiveListItem.addClass(this.options.activeSelectorClass);
//   // Why don't we just use setAttibute() to set a new class?
// }


/***************FUNCTINO FOR UPDATING PAGE INFO (NOT CURRENTLY USED) */
// updatePageInformation(newAreaInfo) {
// this.areaDescription.innerHtml(newAreaInfo['climbing_area']['description']);
// this.rockType.html(newAreaInfo['climbing_area']['rock_type']);
// this.driveTime.html(newAreaInfo['driving_time'] + 'minutes');
// this.activeLabel.html(newAreaInfo[climbing_area]['name']);
// }

// }

}