function NewMembershipController(options) {
    this.options = $.extend(options, {
        'paymentContainer': '#paypal',
        'validationButton': 'button[data-role="validate"]',
        'form': '#membership-form',
        'orderIdField': 'input[data-role="orderId"]',
        'shirtCheckboxes': '[data-role="shirtCheckbox"]',
        'shirtSizeField': 'select',
        'priceLabel': 'strong[data-role="price"]',
        'paymentView': '[data-page="2"]',
        'editAgainButton': '[data-role="editAgain"]',
        'membershipFee': 35,
        'shirtPrice': 15
    });

    this.$form = $(this.options.form);
    this.$shirtCheckboxes = $(this.options.shirtCheckboxes);
    this.$disabledShirtFields = $(this.options.shirtSizeField);
    this.$orderIdField = $(this.options.orderIdField);
    this.$totalPrice = $(this.options.priceLabel);
    this.$paymentView = $(this.options.paymentView);
    this.$editAgainButton = $(this.options.editAgainButton);
    this.$validationButton = $(this.options.validationButton);

    $('#joint_membership_application_phone_number').usPhoneFormat({
        'format': '(xxx) xxx-xxxx'
    });

    this.initValidationListener();
    this.initShirtCheckboxListeners();
    this.initPaymentView();
    this.initPayPal();

    $('.order-note').click(function () {
        this.submitMembership('1234fFFF');
    }.bind(this));
}

NewMembershipController.prototype.initValidationListener = function () {
    this.$validationButton.click(this.validateFormFields.bind(this));
}

NewMembershipController.prototype.validateFormFields = function (event) {
    event.preventDefault();

    this.removeExistingValidationErrors();

    this.showPaymentView();
    // this.submitValidateForm()
    //     .done(this.showPaymentView.bind(this))
    //     .fail(this.showValidationErrors.bind(this));
}

NewMembershipController.prototype.removeExistingValidationErrors = function () {
    $('form input, form select').removeClass('is-invalid');
    $('[data-role="errorContainer"]').addClass('d-none');
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

NewMembershipController.prototype.showValidationErrors = function (errors) {
    errors = errors.responseJSON['errors'];

    for (var invalid_field of Object.keys(errors)) {
        this.invalidateField(invalid_field);
    }
}

NewMembershipController.prototype.initShirtCheckboxListeners = function () {
    this.$shirtCheckboxes.change(
        this.swapDisabledFieldState.bind(this)
    );
}

NewMembershipController.prototype.swapDisabledFieldState = function ($shirtCheckboxes) {
    var shirtCheckedCount = $(this.options.shirtCheckboxes + ':checked').length;

    if (shirtCheckedCount > 0) {
        this.$disabledShirtFields.prop('disabled', false);
    } else {
        this.$disabledShirtFields.prop('disabled', true);
    }

    this.updatePrice(shirtCheckedCount);
}

NewMembershipController.prototype.updatePrice = function (shirtCheckedCount) {
    var newPrice = shirtCheckedCount * this.options.shirtPrice + this.options.membershipFee;

    this.$totalPrice.html('$' + newPrice);
}

NewMembershipController.prototype.initPaymentView = function () {
    this.$editAgainButton.click(this.hidePaymentView.bind(this));
}

NewMembershipController.prototype.showPaymentView = function (response) {
    this.$paymentView.show();
    this.scrollTo(this.$paymentView)
        .then(this.disableForm.bind(this));
}

NewMembershipController.prototype.hidePaymentView = function () {
    this.scrollTo(this.$form)
        .then(this.$paymentView.slideUp.bind(this.$paymentView));

    this.$validationButton.prop('disabled', false);
    this.enableForm();
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
    this.$orderIdField.val(orderId);

    $.ajax({
        'type': 'POST',
        'url': this.$form.attr('action'),
        'data': this.$form.serialize(),
        'success': this.onSubmitSuccess.bind(this),
        'error': this.onSubmitError.bind(this)
    });
}

NewMembershipController.prototype.onSubmitSuccess = function (res) {
    console.log(res);
}

NewMembershipController.prototype.onSubmitError = function (res) {
    var response = res.responseJSON;

    switch (response['status']) {
        case 'validation_errors':
            this.showValidationErrors(res);
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

NewMembershipController.prototype.animateIntoView = function ($element) {
    var df = $.Deferred();

    $element.show();
    df.resolve();
    // $element.slideDown({
    //     'complete': function () { df.resolve(); }
    // });

    return df;
}

NewMembershipController.prototype.scrollTo = function ($element) {
    var df = $.Deferred();

    $('html, body').animate({
        'scrollTop': $element.offset().top,
    }, {
        'duration': 1000,
        'complete': function () { df.resolve(); }
    });

    return df;
}

NewMembershipController.prototype.disableForm = function () {
    $('form input, form select').prop('disabled', true);
    this.$validationButton.prop('disabled', true);
}

NewMembershipController.prototype.enableForm = function () {
    $('form input, form select').prop('disabled', false);
    this.$validationButton.prop('disabled', false);
    this.swapDisabledFieldState();
}