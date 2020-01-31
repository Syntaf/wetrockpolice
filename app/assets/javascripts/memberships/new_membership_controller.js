function NewMembershipController(options) {
    this.options = $.extend(options, {
        'containerSelector': '#paypal',
        'formSelector': '#membership-form',
        'orderIdFieldSelector': 'input[data-role="orderId"]',
        'membershipFee': 35.00
    });
    
    this.initPayPal();
}

NewMembershipController.prototype.initPayPal = function () {
    paypal.Buttons({
        createOrder: this.orderConfigurator.bind(this),
        onApprove: this.onApproval.bind(this)
    }).render(this.options.containerSelector);
}

NewMembershipController.prototype.orderConfigurator = function (data, actions) {
    const config = {
        'purchase_units': [{
            'amount': {
                'value': this.options.membershipFee
            }
        }]
    };

    return actions.order.create(config);
}

NewMembershipController.prototype.onApproval = function (data, actions) {
    const orderId = data.orderID;

    return actions.order.capture().then(this.submitMembership.bind(this, orderId));
}

NewMembershipController.prototype.submitMembership = function (orderId, details) {
    const form = $(this.options.formSelector);
    const orderIdField = form.find(this.options.orderIdFieldSelector);

    orderIdField.val(orderId);
    form.submit();
}