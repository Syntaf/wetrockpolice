function NewMembershipController(options) {
    this.options = $.extend(options, {
        'paymentContainer': '#paypal',
        'validationButton': 'button[data-role="validate"]',
        'form': '#membership-form',
        'orderIdField': 'input[data-role="orderId"]',
        'disabledShirtFields': 'select[data-role="shirtSizeSelect"]',
        'shirtCheckboxes': '[data-role="shirtCheckbox"]',
        'shirtSizeField': 'select[data-role="shirtSizeSelect"]',
        'stoneColorField': 'input[data-role="stoneColorField"]',
        'purpleColorField': 'input[data-role="purpleColorField"]',
        'paidCashField': 'input[data-role="paidCashField"]',
        'amountPaidField': 'input[data-role="amountPaidField"]',
        'priceLabel': 'strong[data-role="price"]',
        'paymentView': '[data-page="2"]',
        'editAgainButton': '[data-role="editAgain"]',
        'loaderIndicator': '[data-role="loader"]',
        'cashButton': 'button[data-role="cashPayment"]',
        'membershipFee': 35,
        'shirtPrice': 15,
        'payProcessingFeeCheckbox': '[data-role="coverFeeCheckbox"]'
    });

    this.price = this.options.membershipFee;

    this.$form = $(this.options.form);
    this.$shirtCheckboxes = $(this.options.shirtCheckboxes);
    this.$disabledShirtFields = $(this.options.disabledShirtFields);
    this.$shirtSizeField = $(this.options.shirtSizeField);
    this.$stoneColorField = $(this.options.stoneColorField);
    this.$purpleColorField = $(this.options.purpleColorField);
    this.$orderIdField = $(this.options.orderIdField);
    this.$paidCashField = $(this.options.paidCashField);
    this.$amountPaidfield = $(this.options.amountPaidField);
    this.$payCashButton = $(this.options.cashButton);
    this.$totalPrice = $(this.options.priceLabel);
    this.$paymentView = $(this.options.paymentView);
    this.$editAgainButton = $(this.options.editAgainButton);
    this.$validationButton = $(this.options.validationButton);
    this.$loaderIndicator = $(this.options.loaderIndicator);
    this.$payProcessingFeeCheckbox = $(this.options.payProcessingFeeCheckbox)

    $('#joint_membership_application_phone_number').usPhoneFormat({
        'format': '(xxx) xxx-xxxx'
    });

    this.initValidationListener();
    this.initShirtCheckboxListeners();
    this.initShirtSizeListener();
    this.initPaymentView();
    this.initPayPal();
    this.initCashPayments();
    this.initPayProcessingFeeCheckbox();
}

NewMembershipController.prototype.initValidationListener = function () {
    this.$validationButton.click(this.validateFormFields.bind(this));
}

NewMembershipController.prototype.validateFormFields = function (event) {
    event.preventDefault();

    this.removeExistingValidationErrors();

    this.submitValidateForm()
        .done(this.showPaymentView.bind(this))
        .fail(this.showValidationErrors.bind(this));
}

NewMembershipController.prototype.removeExistingValidationErrors = function () {
    $('form input, form select').removeClass('is-invalid');
    $('[data-role="errorContainer"]').addClass('d-none');
}

NewMembershipController.prototype.submitValidateForm = function () {
    var validationEndpoint = this.$form.attr('action') + '/validate';
    var df = $.Deferred();

    var data = this.$form.serialize();
    data += '&joint_membership_application%5Ddelivery_method%5D=Local+Pickup+-+Refuge'

    $.ajax({
        'type': 'POST',
        'url': validationEndpoint,
        'data': data,
        'success': function (response) { df.resolve(response); },
        'error': function (response) { df.reject(response); }
    });

    return df;
}

NewMembershipController.prototype.showValidationErrors = function (errors) {
    errors = errors.responseJSON['errors'];

    var aboveFoldFields = ['first_name', 'last_name', 'email', 'phone_number'];
    var scrollBelowFold = true;

    $.each(Object.keys(errors), function (index, invalid_field) {
        if ('shirt_orders' == invalid_field) return;

        this.getFieldByName(invalid_field).addClass('is-invalid');

        if ($.inArray(invalid_field, aboveFoldFields) > -1) {
            scrollBelowFold = false;
        }
    }.bind(this));

    var $elementToScrollTo = scrollBelowFold ?
        $(this.getFieldByName('street_line_one').closest('.form-group')).find('label') :
        this.$form;

    this.scrollTo($elementToScrollTo, -50);
}

NewMembershipController.prototype.initShirtCheckboxListeners = function () {
    this.$shirtCheckboxes.change(
        this.swapDisabledFieldState.bind(this)
    );

    this.swapDisabledFieldState();
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
    this.price = newPrice;
}

NewMembershipController.prototype.initShirtSizeListener = function () {
    this.$shirtSizeField.change(this.enableColorValueForSize.bind(this));
}

NewMembershipController.prototype.enableColorValueForSize = function (e) {
    var selectedShirtSize = e.target.value;
    var gender = selectedShirtSize.charAt(0);

    if (gender === "M") {
        this.$stoneColorField.prop('disabled', false);
        this.$purpleColorField.prop('disabled', true);
    } else {
        this.$stoneColorField.prop('disabled', true);
        this.$purpleColorField.prop('disabled', false);
    }
}

NewMembershipController.prototype.initPaymentView = function () {
    this.$editAgainButton.click(this.hidePaymentView.bind(this));
}

NewMembershipController.prototype.showPaymentView = function (response) {
    this.$paymentView.show();
    this.scrollTo(this.$paymentView, 0)
        .then(this.disableForm.bind(this));
}

NewMembershipController.prototype.hidePaymentView = function () {
    this.scrollTo(this.$form, 0)
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
    var url = new URL(window.location.href);
    var price = url.searchParams.get('pzt');

    if (!price) {
        price = this.price;
    }

    var config = {
        'purchase_units': [{
            'amount': {
                'value': price
            }
        }]
    };

    this.$loaderIndicator.show();

    return actions.order.create(config);
}

NewMembershipController.prototype.onApproval = function (data, actions) {
    var orderId = data.orderID;

    actions.order.capture().then(this.submitMembership.bind(this, orderId));
}

NewMembershipController.prototype.submitMembership = function (orderId, details) {
    this.enableForm();

    if (orderId) {
        this.$orderIdField.val(orderId);
    }

    this.$amountPaidfield.val(this.price);

    var data = this.$form.serialize();
    data += '&joint_membership_application%5Ddelivery_method%5D=Local+Pickup+-+Refuge'

    $.ajax({
        'type': 'POST',
        'url': this.$form.attr('action'),
        'data': data,
        'success': this.onSubmitSuccess.bind(this),
        'error': this.onSubmitError.bind(this)
    });

    this.disableForm();
}

NewMembershipController.prototype.onSubmitSuccess = function (response) {
    var confirmationModal = response['modal'];

    this.$loaderIndicator.hide();

    $('body').append(confirmationModal);
    $('.modal').modal('show');
}

NewMembershipController.prototype.onSubmitError = function (res) {
    var response = res.responseJSON;

    this.$loaderIndicator.hide();

    switch (response['status']) {
        case 'validation_errors':
            this.showValidationErrors(res);
            break;
        case 'unhandled_error':
        default:
            this.displayErrorText('Something went wrong :(');
    }
}

NewMembershipController.prototype.initCashPayments = function () {
    this.$payCashButton.click(this.submitMembershipWithCash.bind(this));
}

NewMembershipController.prototype.submitMembershipWithCash = function () {
    this.$paidCashField.val('true');
    this.$loaderIndicator.show();
    this.submitMembership();
}

NewMembershipController.prototype.displayErrorText = function (errorText) {
    $('[data-role="errorContainer"]').removeClass('d-none');
    $('[data-role="errorText"]').html(errorText);
}

NewMembershipController.prototype.scrollTo = function ($element, offset) {
    var df = $.Deferred();

    $('html, body').animate({
        'scrollTop': $element.offset().top + offset,
    }, {
        'duration': 1000,
        'complete': function () { df.resolve(); }
    });

    return df;
}

NewMembershipController.prototype.getFieldByName = function (field) {
    var name = this.translateFieldToName(field);

    return $(name);
}

NewMembershipController.prototype.disableForm = function () {
    $('form input, form select').not('input[type="hidden"]').prop('disabled', true);
    this.$validationButton.prop('disabled', true);
}

NewMembershipController.prototype.enableForm = function () {
    $('form input, form select').not('input[type="hidden"]').prop('disabled', false);
    this.$validationButton.prop('disabled', false);
    this.swapDisabledFieldState();
}

NewMembershipController.prototype.translateFieldToName = function (field) {
    // Nested attributes will have two parts, normal attributes will have one
    var parts = field.split('.');

    if (parts.length === 2) {
        return '[name="joint_membership_application[shirt_orders_attributes][0][' + parts[1] + ']"]';
    }

    return '[name="joint_membership_application[' + parts[0] + ']"]';
}

NewMembershipController.prototype.initPayProcessingFeeCheckbox = function (field) {
    this.$payProcessingFeeCheckbox.change(
        function () {
            var newPrice = this.price;

            if ($(this.options.payProcessingFeeCheckbox + ':checked').length > 0) {
                newPrice += 2;
            } else {
                newPrice -= 2;
            }

            this.$totalPrice.html('$' + newPrice);
            this.price = newPrice;
        }.bind(this)
    );
}