import { Controller } from "@hotwired/stimulus";

/*
 * Asychronously loads a provided imageUrl and swaps the background of
 * the imageContainer on load. We use this on landing pages like /redrock
 * 
 * Loading images high resolution, especially on low bandwidth, can take time
 * and lead to a poor visual experience when you first visit the page. Instead
 * of using a lower quality image, we:
 *
 *  1) Initially set the background to a base64 encoded tiny 12x12px image with
 *     a gaussian blur applied to distort the pixels and make it seem high-res
 * 
 *  2) Use this controller to asynchronously load the image and replace the
 *    background once the image has loaded.
 */
export default class extends Controller {
  static targets = [
    'imageContainer'
  ];

  static values = {
    'imageUrl': String
  };

  get LOADED_CLASS () { return 'hero-header-loaded'; }

  connect() {
    const asyncImage = new Image();

    // On load, set the background image of the target container and add a loaded
    // class which removes the blur & filters initially applied to the container.
    asyncImage.onload = () => {
        this.imageContainerTarget.style.backgroundImage = `url(${asyncImage.src})`;
        this.imageContainerTarget.classList.add(this.LOADED_CLASS);
    };

    asyncImage.src = this.imageUrlValue;
  }
}