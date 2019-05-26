// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require particles
//= require aos
//= require moment
//= require chart
//= require rails-ujs
//= require jquery
//= require popper
//= require bootstrap
//= require material
//= require_tree .

Number.prototype.toFixedDown = function(digits) {
    var re = new RegExp("(\\d+\\.\\d{" + digits + "})(\\d)"),
        m = this.toString().match(re);
    return m ? parseFloat(m[1]) : this.valueOf();
};

window.onload = function loadStuff() {
    if (!('addEventListener' in window)) {
        return;
    }

    var backgroundImageSrc = (function () {
        var styles = document.querySelector('style').sheet.cssRules;
        var fetchImage = (function () {
            var bgStyle, i, stylesLength = styles.length;

            for (i = 0; i < stylesLength; i++) {
                if (styles[i].selectorText && styles[i].selectorText == '.hero-header.hero-header-loaded') {
                    bgStyle = styles[i].style.backgroundImage;
                    break;
                }
            }

            return bgStyle;
        }());

        return fetchImage && fetchImage.match(/(?:\(['|"]?)(.*?)(?:['|"]?\))/)[1];
    }());

    var image = new Image();
    var heroHeader = document.querySelector('.hero-header');

    if (heroHeader)
    {
        image.onload = function () {
            heroHeader.className += ' ' + 'hero-header-loaded';
        };
    
        if (backgroundImageSrc) {
            image.src = backgroundImageSrc;
            window.dispatchEvent(new Event('lazyLoadFinished'));
        }
    }
};