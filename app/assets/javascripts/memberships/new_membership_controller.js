function NewMembershipController(options) {
    this.options = $.extend(options, {
        'containerSelector': '#paypal',
        'formSelector': '#membership-form',
        'orderIdFieldSelector': 'input[data-role="orderId"]',
        'totalSelector': 'strong[data-role="total"]',
        'membershipFee': 35,
        'shirtPrice': 15
    });

    $('#joint_membership_application_phone_number').usPhoneFormat({
        'format': '(xxx) xxx-xxxx'
    });

    this.initPayPal();
    this.initShirtCheckboxListeners();

    $('.order-note').click(function () {
        console.log('yes');
        this.submitMembership('123456FFF');
    }.bind(this));
}

NewMembershipController.prototype.initShirtCheckboxListeners = function () {
    this.$shirtCheckboxes = $('[data-role="shirtCheckbox"]');
    this.$disabledShirtField = $('select[disabled]');

    this.$shirtCheckboxes.change(
        this.swapDisabledFieldState.bind(this)
    );
}

NewMembershipController.prototype.swapDisabledFieldState = function ($shirtCheckboxes, $disabledShirtField) {
    var shirtCheckedCount = $(this.$shirtCheckboxes.selector + ':checked').length;

    if (shirtCheckedCount > 0) {
        this.$disabledShirtField.prop('disabled', false);
    } else {
        this.$disabledShirtFields.prop('disabled', true);
    }

    // this.updateCheckboxValues();
    this.updatePrice(shirtCheckedCount);
}

NewMembershipController.prototype.updateCheckboxValues = function () {
    this.$shirtCheckboxes.val(0);

    var $checked = $(this.$shirtCheckboxes.selector + ':checked');

    $checked.val(1);
    $checked.parent().find('input[type="hidden"]').val(1);
}

NewMembershipController.prototype.updatePrice = function (shirtCheckedCount) {
    var $totalPrice = $('[data-role="price"]');
    var newPrice = shirtCheckedCount * this.options.shirtPrice + this.options.membershipFee;

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

    actions.order.capture().then(this.submitMembership.bind(this, orderId));
}

NewMembershipController.prototype.submitMembership = function (orderId, details) {
    var $form = $(this.options.formSelector);
    var $orderIdField = $form.find(this.options.orderIdFieldSelector);

    $orderIdField.val(orderId);

    $.ajax({
        'type': 'POST',
        'url': $form.attr('action'),
        'data': $form.serialize(),
        'success': this.onSubmitSuccess.bind(this),
        'error': this.onSubmitError.bind(this)
    });

    this.removeInvalidClasses();
}

NewMembershipController.prototype.removeInvalidClasses = function () {
    $('form input').removeClass('is-invalid');
}

NewMembershipController.prototype.onSubmitSuccess = function (res) {
    console.log(res);
}

NewMembershipController.prototype.onSubmitError = function (res) {
    var response = res.responseJSON;

    switch (response['status']) {
        case 'validation_errors':
            this.highlightInvalidFields(response['errors']);
            break;
        case 'unhandled_error':
        default:
            this.displayErrorText('Something went wrong :( Please show this to the desk');
    }
}

NewMembershipController.prototype.highlightInvalidFields = function (error) {
    for (var invalid_field of Object.keys(error)) {
        this.invalidateField(invalid_field);
    }
}

NewMembershipController.prototype.invalidateField = function (field) {
    var $field = $('input[name="joint_membership_application[' + field + ']"]');

    $field.addClass('is-invalid');
}

NewMembershipController.prototype.displayErrorText = function (errorText) {
    $('[data-role="errorContainer"]').removeClass('invisible');
    $('[data-role="errorText"]').html(errorText);
}