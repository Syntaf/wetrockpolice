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

    }
          
updateMountainProjectWidget(event) {
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

showArea(event) {
this.updateMountainProjectWidget(event);
this.fetchArea(event)
this.handleAreaSelection(event)
}

// Add a method for keeping the 

handleAreaSelection(event){

  // const dropdownItems = document.querySelectorAll('.dropdown-toggle');
  
  // dropdownItems.forEach(item => {
  //   item.addEventListener('click', (event) => {
  //     event.preventDefault(); // Prevent the default link behavior
  //     const selectedText = item.getAttribute('data-value');
  //     dropdownButton.textContent = selectedText; // Update button text
  //   });
  // });
  const menuInfo = document.getElementById("dropdownMenuButton")
  let menuInfoText = menuInfo.innerHTML
  
  const target = event.currentTarget;
  menuInfoText = target.dataset.
  
}

}