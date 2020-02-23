function NewMembershipController(options) {
    this.options = $.extend(options, {
        'paymentContainer': '#paypal',
        'validationButton': 'button[data-role="validate"]',
        'formSelector': '#membership-form',
        'orderIdFieldSelector': 'input[data-role="orderId"]',
        'totalSelector': 'strong[data-role="total"]',
        'membershipFee': 35,
        'shirtPrice': 15
    });

    this.$form = $(this.options.formSelector);

    $('#joint_membership_application_phone_number').usPhoneFormat({
        'format': '(xxx) xxx-xxxx'
    });

    $('[data-page="2"]').hide();

    this.initValidationListener();
    this.initPayPal();
    this.initShirtCheckboxListeners();

    $('.order-note').click(function () {
        this.submitMembership('1234fFFF');
    }.bind(this));
}

NewMembershipController.prototype.initValidationListener = function () {
    $(this.options.validationButton).click(this.validateFormFields.bind(this));
}

NewMembershipController.prototype.validateFormFields = function (event) {
    event.preventDefault();

    this.submitValidateForm()
        .done(this.showPaymentView.bind(this))
        .fail(this.showValidationErrors.bind(this));
}

NewMembershipController.prototype.submitValidateForm = function () {
    var validationEndpoint = this.$form.attr('action') + '/validate';
    var df = $.Deferred();

    $.ajax({
        'type': 'POST',
        'url': validationEndpoint,
        'data': this.$form.serialize(),
        'success': function (response) { df.resolve(response); },
        'error': function (response) { df.reject(response); }
    });

    return df;
}

NewMembershipController.prototype.showPaymentView = function (response) {
    alert('Showing page 2!');
}

NewMembershipController.prototype.showValidationErrors = function (errors) {
    errors = errors.responseJSON['errors'];

    for (var invalid_field of Object.keys(errors)) {
        this.invalidateField(invalid_field);
    }
}

NewMembershipController.prototype.initShirtCheckboxListeners = function () {
    this.$shirtCheckboxes = $('[data-role="shirtCheckbox"]');
    this.$disabledShirtFields = $('select[disabled]');

    this.$shirtCheckboxes.change(
        this.swapDisabledFieldState.bind(this)
    );
}

NewMembershipController.prototype.swapDisabledFieldState = function ($shirtCheckboxes) {
    var shirtCheckedCount = $(this.$shirtCheckboxes.selector + ':checked').length;

    if (shirtCheckedCount > 0) {
        this.$disabledShirtFields.prop('disabled', false);
    } else {
        this.$disabledShirtFields.prop('disabled', true);
    }

    this.updatePrice(shirtCheckedCount);
}

NewMembershipController.prototype.updatePrice = function (shirtCheckedCount) {
    var $totalPrice = $('[data-role="price"]');
    var newPrice = shirtCheckedCount * this.options.shirtPrice + this.options.membershipFee;

    $totalPrice.html('$' + newPrice);
}



NewMembershipController.prototype.markValid = function () {
    this.isFormValid = true;
    $(this.options.paymentContainer).trigger('click');
}

NewMembershipController.prototype.initPayPal = function () {
    paypal.Buttons({
        createOrder: this.orderConfigurator.bind(this),
        onApprove: this.onApproval.bind(this)
    }).render(this.options.paymentContainer);
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
    $('form input, form select').removeClass('is-invalid');
    $('[data-role="errorContainer"]').addClass('d-none');
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
            this.displayErrorText('Something went wrong :(');
    }
}

NewMembershipController.prototype.invalidateField = function (field) {
    var $field = $('[name="joint_membership_application[' + field + ']"]');

    $field.addClass('is-invalid');
}

NewMembershipController.prototype.displayErrorText = function (errorText) {
    $('[data-role="errorContainer"]').removeClass('d-none');
    $('[data-role="errorText"]').html(errorText);
}