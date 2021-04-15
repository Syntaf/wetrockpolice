function RafflesController(options) {
    this.options = $.extend(options, {
        'paymentContainer': '#paypal',
        'validationButtons': 'button[data-role="validate"]',
        'form': '#raffles-form',
        'orderIdField': 'input[data-role="orderId"]',
        'amountPaidField': 'input[data-role="amountPaidField"]',
        'paymentView': '[data-page="2"]',
        'editAgainButton': '[data-role="editAgain"]',
        'loaderIndicator': '[data-role="loader"]',
        'payProcessingFeeCheckbox': '[data-role="coverFeeCheckbox"]'
    })

    this.price = 0;

    this.$form = $(this.options.form);
    this.$orderIdField = $(this.options.orderIdField);
    this.$amountPaidfield = $(this.options.amountPaidField);
    this.$payCashButton = $(this.options.cashButton);
    this.$paymentView = $(this.options.paymentView);
    this.$editAgainButton = $(this.options.editAgainButton);
    this.$validationButtons = $(this.options.validationButtons);
    this.$loaderIndicator = $(this.options.loaderIndicator);
    this.$payProcessingFeeCheckbox = $(this.options.payProcessingFeeCheckbox);

    $('#raffle_entry_phone_number').usPhoneFormat({
        'format': '(xxx) xxx-xxxx'
    });

    this.initValidationListener();
    this.initPaymentView();
    this.initPayPal();
    this.initPayProcessingFeeCheckbox();
}

RafflesController.prototype.initValidationListener = function () {
    this.$validationButtons.click(this.validateFormFields.bind(this));
}

RafflesController.prototype.validateFormFields = function (event) {
    event.preventDefault();

    this.removeExistingValidationErrors();

    this.price = $(event.target).closest('button').attr('data-price');

    this.submitValidateForm()
        .done(this.showPaymentView.bind(this))
        .fail(this.showValidationErrors.bind(this));
}

RafflesController.prototype.removeExistingValidationErrors = function () {
    $('form input, form select').removeClass('is-invalid');
    $('[data-role="errorContainer"]').addClass('d-none');
}

RafflesController.prototype.submitValidateForm = function () {
    var validationEndpoint = this.$form.attr('action') + '/validate';
    var df = $.Deferred();

    var data = this.$form.serialize();

    $.ajax({
        'type': 'POST',
        'url': validationEndpoint,
        'data': data,
        'success': function (response) { df.resolve(response); },
        'error': function (response) { df.reject(response); }
    });

    return df;
}

RafflesController.prototype.showValidationErrors = function (errors) {
    errors = errors.responseJSON['errors'];

    $.each(Object.keys(errors), function (index, invalid_field) {
        this.getFieldByName(invalid_field).addClass('is-invalid');
    }.bind(this));

    this.scrollTo(this.$form, -50);
}

RafflesController.prototype.initPaymentView = function () {
    this.$editAgainButton.click(this.hidePaymentView.bind(this));
}

RafflesController.prototype.showPaymentView = function (response) {
    this.$paymentView.show();
    this.scrollTo(this.$paymentView, 0)
        .then(this.disableForm.bind(this));
}

RafflesController.prototype.hidePaymentView = function () {
    this.scrollTo($('.header'), 0)
        .then(this.$paymentView.slideUp.bind(this.$paymentView));

    this.$validationButtons.prop('disabled', false);
    this.enableForm();
}

RafflesController.prototype.initPayPal = function () {
    paypal.Buttons({
        createOrder: this.orderConfigurator.bind(this),
        onApprove: this.onApproval.bind(this)
    }).render(this.options.paymentContainer);
}

RafflesController.prototype.orderConfigurator = function (data, actions) {
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

RafflesController.prototype.onApproval = function (data, actions) {
    var orderId = data.orderID;

    actions.order.capture().then(this.submitRaffle.bind(this, orderId));
}

RafflesController.prototype.submitRaffle = function (orderId, details) {
    this.enableForm();

    if (orderId) {
        this.$orderIdField.val(orderId);
    }

    this.$amountPaidfield.val(this.price);

    var data = this.$form.serialize();

    $.ajax({
        'type': 'POST',
        'url': this.$form.attr('action'),
        'data': data,
        'success': this.onSubmitSuccess.bind(this),
        'error': this.onSubmitError.bind(this)
    });

    this.disableForm();
}

RafflesController.prototype.onSubmitSuccess = function (response) {
    var confirmationModal = response['modal'];

    this.$loaderIndicator.hide();

    $('body').append(confirmationModal);
    $('.modal').modal('show');
}

RafflesController.prototype.onSubmitError = function (res) {
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

RafflesController.prototype.displayErrorText = function (errorText) {
    $('[data-role="errorContainer"]').removeClass('d-none');
    $('[data-role="errorText"]').html(errorText);
}

RafflesController.prototype.scrollTo = function ($element, offset) {
    var df = $.Deferred();

    $('html, body').animate({
        'scrollTop': $element.offset().top + offset,
    }, {
        'duration': 1000,
        'complete': function () { df.resolve(); }
    });

    return df;
}

RafflesController.prototype.getFieldByName = function (field) {
    var name = this.translateFieldToName(field);

    return $(name);
}

RafflesController.prototype.disableForm = function () {
    $('form input, form select').not('input[type="hidden"]').prop('disabled', true);
    this.$validationButtons.prop('disabled', true);
}

RafflesController.prototype.enableForm = function () {
    $('form input, form select').not('input[type="hidden"]').prop('disabled', false);
    this.$validationButtons.prop('disabled', false);
}

RafflesController.prototype.translateFieldToName = function (field) {
    var parts = field.split('.');

    return '[name="raffle_entry[' + parts[0] + ']"]';
}

RafflesController.prototype.initPayProcessingFeeCheckbox = function (field) {
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