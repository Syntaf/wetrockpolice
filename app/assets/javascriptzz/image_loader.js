function ImageLoader(options) {
    this.options = $.extend({
        'imageContainerSelector': '',
        'imageLoadedClass': ''
    }, options);

    if (!('addEventListener' in window)) {
        console.error('Unsupported browser for lazy image loading...');
    }
}

ImageLoader.prototype.load = function() {
    var imagePath = this.fetchImageToLoad();

    if (!imagePath) {
        console.warn('ImageLoader called but no style rule found for: \'' + this.options.imageContainerSelector + this.options.imageLoadedClass + '\'');
        return;
    }

    var $imageContainer = $(this.options.imageContainerSelector);

    if ($imageContainer.length && imagePath) {
        var newImage = new Image();

        newImage.onload = function () {
            $imageContainer.addClass(this.options.imageLoadedClass.substr(1));
        }.bind(this);

        newImage.src = imagePath;
    }
}

ImageLoader.prototype.fetchImageToLoad = function () {
    var styles = document.querySelector('style').sheet.cssRules;
    var imagePath = '';

    for (i = 0; i < styles.length; i++) {
        if (this.isStyleContainingImageRule(styles[i])) {
            imagePath = styles[i].style.backgroundImage;
            break;
        }
    }

    if (imagePath !== '') {
        return this.formatBackgroundRule(imagePath);
    }
    
    return null;
}

ImageLoader.prototype.isStyleContainingImageRule = function(style) {
    return style.selectorText && style.selectorText == this.options.imageContainerSelector + this.options.imageLoadedClass;
}

ImageLoader.prototype.formatBackgroundRule = function(bgRule) {
    return bgRule.match(/(?:\(['|"]?)(.*?)(?:['|"]?\))/)[1];
}
