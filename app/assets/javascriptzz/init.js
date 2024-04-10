function App() { 
    // no-op
}

App.prototype.init = function () {
    // Animate on scroll
    AOS.init({
        'duration': 1000
    });

    $('[data-role="tooltip"]').tooltip();
}

$(document).ready(function () {
    var app = new App();

    app.init();
});