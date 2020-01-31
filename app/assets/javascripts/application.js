//= require particles
//= require aos
//= require moment
//= require chart
//= require rails-ujs
//= require jquery
//= require popper
//= require bootstrap
//= require material
//= require init
//= require image_loader
//= require landing_controller
//= require rainy_day_controller
//= require memberships/new_membership_controller

Number.prototype.toFixedDown = function(digits) {
    var re = new RegExp("(\\d+\\.\\d{" + digits + "})(\\d)"),
        m = this.toString().match(re);
    return m ? parseFloat(m[1]) : this.valueOf();
};