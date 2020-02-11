function NewMembershipController(options) {
    this.options = $.extend(options, {
        'containerSelector': '#paypal',
        'formSelector': '#membership-form',
        'orderIdFieldSelector': 'input[data-role="orderId"]',
        'totalSelector': 'strong[data-role="total"]',
        'membershipFee': 35.00
    });

    this.initPayPal();
    this.initShirtCheckboxListeners();
    this.initTotalListener();
}

NewMembershipController.prototype.initShirtCheckboxListeners = function () {
    var $shirtCheckboxes = $('[data-role="shirtCheckbox"]');
    var $disabledShirtFields = $('select[disabled]');

    $shirtCheckboxes.change(this.swapDisabledFieldState.bind(this, $shirtCheckboxes, $disabledShirtFields));
}

NewMembershipController.prototype.swapDisabledFieldState = function ($shirtCheckboxes, $disabledShirtFields) {
    var shirtCheckedCount = $($shirtCheckboxes.selector + ':checked').length;

    if (shirtCheckedCount > 0) {
        $disabledShirtFields.prop('disabled', false);
    } else {
        $disabledShirtFields.prop('disabled', true);
    }

    this.updatePrice(shirtCheckedCount);
}

NewMembershipController.prototype.updatePrice = function (shirtCheckedCount) {
    var $totalPrice = $('[data-role="price"]');
    var newPrice = shirtCheckedCount * 15 + 35;

    $totalPrice.html('$' + newPrice);
}

NewMembershipController.prototype.initPayPal = function () {
    paypal.Buttons({
        createOrder: this.orderConfigurator.bind(this),
        onApprove: this.onApproval.bind(this)
    }).render(this.options.containerSelector);
}

NewMembershipController.prototype.orderConfigurator = function (data, actions) {
    var config = {
        'purchase_units': [{
            'amount': {
                'value': this.options.membershipFee
            }
        }]
    };

    return actions.order.create(config);
}

NewMembershipController.prototype.onApproval = function (data, actions) {
    var orderId = data.orderID;

    return actions.order.capture().then(this.submitMembership.bind(this, orderId));
}

NewMembershipController.prototype.submitMembership = function (orderId, details) {
    var form = $(this.options.formSelector);
    var orderIdField = form.find(this.options.orderIdFieldSelector);

    orderIdField.val(orderId);
    form.submit();
}