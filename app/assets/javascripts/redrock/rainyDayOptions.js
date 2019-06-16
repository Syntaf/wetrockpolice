function RainyDayController(options) {
    this.options = $.extend(options, {
        'mp': {
            'widgetSelector': '#mountainProjectWidget',
            'defaultZoom': 11,
            'height': 500,
            'urlBase': 'https://www.mountainproject.com/widget'
        },
        'cragListSelector': 'li[data-role="crag-list"]',
        'activeSelector': '.active'
    });

    this.initView();
}

RainyDayController.prototype.initView = function () {
    var $activeLocation = $(this.options.activeSelector);

    if ($activeLocation.length < 1)
    {
        console.error('No active list element found');
        return;
    }

    this.updateMountainProjectWidget($activeLocation);
}

RainyDayController.prototype.updateMountainProjectWidget = function ($activeElement) {
    var longitude = $activeElement.data('lon');
    var latitude = $activeElement.data('lat');
    var zoom = $activeElement.data('mtz') ? $activeElement.data('mtz') : this.options.mp.defaultZoom;

    var newUrl = this.buildMountainProjectUrl(longitude, latitude, zoom);
    $(this.options.mp.widgetSelector).attr('src', newUrl);
}

RainyDayController.prototype.buildMountainProjectUrl = function (longitude, latitude, zoom) {
    return this.options.mp.urlBase + '?loc=fixed&' +
        'x=' + longitude + '&' +
        'y=' + latitude + '&' +
        'z=' + zoom + '&' +
        'h=' + this.options.mp.height
}