import '../core/utils/json_helpers.dart';

class OrderShippingAddressDto {
  const OrderShippingAddressDto({
    required this.name,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.province,
    required this.district,
    required this.commune,
    required this.streetAddress,
  });

  final String name;
  final String fullName;
  final String firstName;
  final String lastName;
  final String phone;
  final String province;
  final String? district;
  final String? commune;
  final String streetAddress;

  String get displayName {
    if (fullName.trim().isNotEmpty) {
      return fullName.trim();
    }
    if (name.trim().isNotEmpty) {
      return name.trim();
    }
    return '$firstName $lastName'.trim();
  }

  String get displayRegion {
    final parts = <String>[
      if (commune != null && commune!.trim().isNotEmpty) commune!.trim(),
      if (district != null && district!.trim().isNotEmpty) district!.trim(),
      if (province.trim().isNotEmpty) province.trim(),
    ];
    return parts.join(', ');
  }

  factory OrderShippingAddressDto.fromJson(Map<String, dynamic> json) {
    final first = asString(json['first_name']);
    final last = asString(json['last_name']);
    final nameVal = asString(json['name'], fallback: '$first $last'.trim());
    return OrderShippingAddressDto(
      name: nameVal,
      fullName: asString(json['full_name'], fallback: nameVal),
      firstName: first,
      lastName: last,
      phone: asString(json['phone']),
      province: asString(json['province']),
      district: asNullableString(json['district']),
      commune: asNullableString(json['commune']),
      streetAddress: asString(json['street_address']),
    );
  }
}

class OrderItemDto {
  const OrderItemDto({
    required this.id,
    required this.productVariantId,
    required this.productSlug,
    required this.imageUrl,
    required this.productName,
    required this.productNameEn,
    required this.productNameKm,
    required this.variantLabel,
    required this.sku,
    required this.priceCents,
    required this.formattedPrice,
    required this.quantity,
    required this.subtotalCents,
    required this.formattedSubtotal,
  });

  final int id;
  final int? productVariantId;
  final String? productSlug;
  final String? imageUrl;
  final String productName;
  final String productNameEn;
  final String? productNameKm;
  final String variantLabel;
  final String sku;
  final int priceCents;
  final String formattedPrice;
  final int quantity;
  final int subtotalCents;
  final String formattedSubtotal;

  factory OrderItemDto.fromJson(Map<String, dynamic> json) {
    return OrderItemDto(
      id: asInt(json['id']),
      productVariantId: asNullableInt(json['product_variant_id']),
      productSlug: asNullableString(json['product_slug']),
      imageUrl: asNullableString(json['image_url']),
      productName: asString(json['product_name']),
      productNameEn: asString(
        json['product_name_en'],
        fallback: asString(json['product_name']),
      ),
      productNameKm: asNullableString(json['product_name_km']),
      variantLabel: asString(json['variant_label']),
      sku: asString(json['sku']),
      priceCents: asInt(json['price_cents']),
      formattedPrice: asString(json['formatted_price']),
      quantity: asInt(json['quantity'], fallback: 1),
      subtotalCents: asInt(json['subtotal_cents']),
      formattedSubtotal: asString(json['formatted_subtotal']),
    );
  }
}

class OrderStatusStepDto {
  const OrderStatusStepDto({
    required this.key,
    required this.label,
    required this.completed,
    required this.active,
    required this.timestamp,
  });

  final String key;
  final String label;
  final bool completed;
  final bool active;
  final String? timestamp;

  factory OrderStatusStepDto.fromJson(Map<String, dynamic> json) {
    return OrderStatusStepDto(
      key: asString(json['key']),
      label: asString(json['label']),
      completed: asBool(json['completed']),
      active: asBool(json['active']),
      timestamp: asNullableString(json['timestamp']),
    );
  }
}

class PaymentDto {
  const PaymentDto({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.provider,
    required this.md5,
    required this.qrString,
    required this.accountId,
    required this.merchantName,
    required this.amount,
    required this.currency,
    required this.formattedAmount,
    required this.khrAmount,
    required this.formattedKhrAmount,
    required this.usdAmount,
    required this.formattedUsdAmount,
    required this.exchangeRate,
    required this.status,
    required this.statusLabel,
    required this.expiresAt,
    required this.timeRemainingSeconds,
    required this.paidAt,
    required this.bakongMock,
    required this.deeplinkUrl,
  });

  final int id;
  final int orderId;
  final String orderNumber;
  final String provider;
  final String md5;
  final String qrString;
  final String accountId;
  final String merchantName;
  final double amount;
  final String currency;
  final String formattedAmount;
  final int khrAmount;
  final String formattedKhrAmount;
  final double usdAmount;
  final String formattedUsdAmount;
  final int exchangeRate;
  final String status;
  final String statusLabel;
  final String expiresAt;
  final int timeRemainingSeconds;
  final String? paidAt;
  final bool bakongMock;
  final String deeplinkUrl;

  bool get isPaid => status == 'paid';
  bool get isExpired => status == 'expired';
  bool get isPending => status == 'pending';

  factory PaymentDto.fromJson(Map<String, dynamic> json) {
    return PaymentDto(
      id: asInt(json['id']),
      orderId: asInt(json['order_id']),
      orderNumber: asString(json['order_number']),
      provider: asString(json['provider'], fallback: 'bakong_khqr'),
      md5: asString(json['md5']),
      qrString: asString(json['qr_string']),
      accountId: asString(json['account_id']),
      merchantName: asString(json['merchant_name'], fallback: 'RESET Store'),
      amount: asDouble(json['amount']),
      currency: asString(json['currency'], fallback: 'KHR'),
      formattedAmount: asString(json['formatted_amount']),
      khrAmount: asInt(json['khr_amount']),
      formattedKhrAmount: asString(json['formatted_khr_amount']),
      usdAmount: asDouble(json['usd_amount']),
      formattedUsdAmount: asString(json['formatted_usd_amount']),
      exchangeRate: asInt(json['exchange_rate'], fallback: 4100),
      status: asString(json['status'], fallback: 'pending'),
      statusLabel: asString(json['status_label']),
      expiresAt: asString(json['expires_at']),
      timeRemainingSeconds: asInt(json['time_remaining_seconds']),
      paidAt: asNullableString(json['paid_at']),
      bakongMock: asBool(json['bakong_mock']),
      deeplinkUrl: asString(json['deeplink_url']),
    );
  }
}

class OrderSummaryDto {
  const OrderSummaryDto({
    required this.id,
    required this.number,
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    required this.currency,
    required this.exchangeRate,
    required this.subtotalCents,
    required this.formattedSubtotal,
    required this.discountCents,
    required this.formattedDiscount,
    required this.discountCode,
    required this.shippingFeeCents,
    required this.formattedShipping,
    required this.shippingMethod,
    required this.totalCents,
    required this.formattedTotal,
    required this.totalChargedCurrencyAmount,
    required this.formattedChargedTotal,
    required this.equivalentKhrAmount,
    required this.formattedEquivalentKhr,
    required this.equivalentUsdAmount,
    required this.formattedEquivalentUsd,
    required this.itemsCount,
    required this.previewItemNames,
    required this.canPayNow,
    required this.createdAt,
    required this.formattedCreatedAt,
    required this.paidAt,
  });

  final int id;
  final String number;
  final String status;
  final String statusLabel;
  final String statusColor;
  final String currency;
  final int exchangeRate;
  final int subtotalCents;
  final String formattedSubtotal;
  final int discountCents;
  final String formattedDiscount;
  final String? discountCode;
  final int shippingFeeCents;
  final String formattedShipping;
  final String shippingMethod;
  final int totalCents;
  final String formattedTotal;
  final double totalChargedCurrencyAmount;
  final String formattedChargedTotal;
  final int equivalentKhrAmount;
  final String formattedEquivalentKhr;
  final double equivalentUsdAmount;
  final String formattedEquivalentUsd;
  final int itemsCount;
  final List<String> previewItemNames;
  final bool canPayNow;
  final String createdAt;
  final String formattedCreatedAt;
  final String? paidAt;

  factory OrderSummaryDto.fromJson(Map<String, dynamic> json) {
    return OrderSummaryDto(
      id: asInt(json['id']),
      number: asString(json['number']),
      status: asString(json['status']),
      statusLabel: asString(json['status_label']),
      statusColor: asString(json['status_color'], fallback: 'gray'),
      currency: asString(json['currency'], fallback: 'KHR'),
      exchangeRate: asInt(json['exchange_rate'], fallback: 4100),
      subtotalCents: asInt(json['subtotal_cents']),
      formattedSubtotal: asString(json['formatted_subtotal']),
      discountCents: asInt(json['discount_cents']),
      formattedDiscount: asString(json['formatted_discount']),
      discountCode: asNullableString(json['discount_code']),
      shippingFeeCents: asInt(json['shipping_fee_cents']),
      formattedShipping: asString(json['formatted_shipping']),
      shippingMethod: asString(json['shipping_method'], fallback: 'standard'),
      totalCents: asInt(json['total_cents']),
      formattedTotal: asString(json['formatted_total']),
      totalChargedCurrencyAmount: asDouble(json['total_charged_currency_amount']),
      formattedChargedTotal: asString(json['formatted_charged_total']),
      equivalentKhrAmount: asInt(json['equivalent_khr_amount']),
      formattedEquivalentKhr: asString(json['formatted_equivalent_khr']),
      equivalentUsdAmount: asDouble(json['equivalent_usd_amount']),
      formattedEquivalentUsd: asString(json['formatted_equivalent_usd']),
      itemsCount: asInt(json['items_count']),
      previewItemNames: asStringList(json['preview_item_names']),
      canPayNow: asBool(json['can_pay_now']),
      createdAt: asString(json['created_at']),
      formattedCreatedAt: asString(json['formatted_created_at']),
      paidAt: asNullableString(json['paid_at']),
    );
  }
}

class OrderDetailDto extends OrderSummaryDto {
  const OrderDetailDto({
    required super.id,
    required super.number,
    required super.status,
    required super.statusLabel,
    required super.statusColor,
    required super.currency,
    required super.exchangeRate,
    required super.subtotalCents,
    required super.formattedSubtotal,
    required super.discountCents,
    required super.formattedDiscount,
    required super.discountCode,
    required super.shippingFeeCents,
    required super.formattedShipping,
    required super.shippingMethod,
    required super.totalCents,
    required super.formattedTotal,
    required super.totalChargedCurrencyAmount,
    required super.formattedChargedTotal,
    required super.equivalentKhrAmount,
    required super.formattedEquivalentKhr,
    required super.equivalentUsdAmount,
    required super.formattedEquivalentUsd,
    required super.itemsCount,
    required super.previewItemNames,
    required super.canPayNow,
    required super.createdAt,
    required super.formattedCreatedAt,
    required super.paidAt,
    required this.email,
    required this.phone,
    required this.shippingAddress,
    required this.billingAddress,
    required this.trackingNumber,
    required this.shippingCarrier,
    required this.customerNotes,
    required this.shippedAt,
    required this.deliveredAt,
    required this.cancelledAt,
    required this.items,
    required this.latestPayment,
    required this.statusTimeline,
  });

  final String email;
  final String phone;
  final OrderShippingAddressDto shippingAddress;
  final OrderShippingAddressDto billingAddress;
  final String? trackingNumber;
  final String? shippingCarrier;
  final String? customerNotes;
  final String? shippedAt;
  final String? deliveredAt;
  final String? cancelledAt;
  final List<OrderItemDto> items;
  final PaymentDto? latestPayment;
  final List<OrderStatusStepDto> statusTimeline;

  bool get isTerminalNegative =>
      status == 'cancelled' || status == 'expired' || status == 'refunded';

  factory OrderDetailDto.fromJson(Map<String, dynamic> json) {
    final summary = OrderSummaryDto.fromJson(json);
    final latestPaymentRaw = json['latest_payment'];
    return OrderDetailDto(
      id: summary.id,
      number: summary.number,
      status: summary.status,
      statusLabel: summary.statusLabel,
      statusColor: summary.statusColor,
      currency: summary.currency,
      exchangeRate: summary.exchangeRate,
      subtotalCents: summary.subtotalCents,
      formattedSubtotal: summary.formattedSubtotal,
      discountCents: summary.discountCents,
      formattedDiscount: summary.formattedDiscount,
      discountCode: summary.discountCode,
      shippingFeeCents: summary.shippingFeeCents,
      formattedShipping: summary.formattedShipping,
      shippingMethod: summary.shippingMethod,
      totalCents: summary.totalCents,
      formattedTotal: summary.formattedTotal,
      totalChargedCurrencyAmount: summary.totalChargedCurrencyAmount,
      formattedChargedTotal: summary.formattedChargedTotal,
      equivalentKhrAmount: summary.equivalentKhrAmount,
      formattedEquivalentKhr: summary.formattedEquivalentKhr,
      equivalentUsdAmount: summary.equivalentUsdAmount,
      formattedEquivalentUsd: summary.formattedEquivalentUsd,
      itemsCount: summary.itemsCount,
      previewItemNames: summary.previewItemNames,
      canPayNow: summary.canPayNow,
      createdAt: summary.createdAt,
      formattedCreatedAt: summary.formattedCreatedAt,
      paidAt: summary.paidAt,
      email: asString(json['email']),
      phone: asString(json['phone']),
      shippingAddress: OrderShippingAddressDto.fromJson(
        asMap(json['shipping_address']),
      ),
      billingAddress: OrderShippingAddressDto.fromJson(
        asMap(json['billing_address']),
      ),
      trackingNumber: asNullableString(json['tracking_number']),
      shippingCarrier: asNullableString(json['shipping_carrier']),
      customerNotes: asNullableString(json['customer_notes']),
      shippedAt: asNullableString(json['shipped_at']),
      deliveredAt: asNullableString(json['delivered_at']),
      cancelledAt: asNullableString(json['cancelled_at']),
      items: asList(json['items'])
          .map((e) => OrderItemDto.fromJson(asMap(e)))
          .toList(),
      latestPayment: latestPaymentRaw == null
          ? null
          : PaymentDto.fromJson(asMap(latestPaymentRaw)),
      statusTimeline: asList(json['status_timeline'])
          .map((e) => OrderStatusStepDto.fromJson(asMap(e)))
          .toList(),
    );
  }
}

class InvoiceStoreInfoDto {
  const InvoiceStoreInfoDto({
    required this.name,
    required this.tagline,
    required this.address,
    required this.phone,
    required this.email,
  });

  final String name;
  final String tagline;
  final String address;
  final String phone;
  final String email;

  factory InvoiceStoreInfoDto.fromJson(Map<String, dynamic> json) {
    return InvoiceStoreInfoDto(
      name: asString(json['name'], fallback: 'RESET Store'),
      tagline: asString(json['tagline'], fallback: 'Start fresh.'),
      address: asString(json['address'], fallback: 'Phnom Penh, Cambodia'),
      phone: asString(json['phone'], fallback: '+855 23 999 123'),
      email: asString(json['email'], fallback: 'support@reset.store'),
    );
  }
}

class TaxInvoiceDto {
  const TaxInvoiceDto({
    required this.invoiceNumber,
    required this.issuedDate,
    required this.paymentMethodLabel,
    required this.storeInfo,
    required this.order,
    required this.payment,
  });

  final String invoiceNumber;
  final String issuedDate;
  final String paymentMethodLabel;
  final InvoiceStoreInfoDto storeInfo;
  final OrderDetailDto order;
  final PaymentDto? payment;

  factory TaxInvoiceDto.fromJson(Map<String, dynamic> json) {
    final paymentRaw = json['payment'];
    return TaxInvoiceDto(
      invoiceNumber: asString(json['invoice_number']),
      issuedDate: asString(json['issued_date']),
      paymentMethodLabel: asString(
        json['payment_method_label'],
        fallback: 'Bakong KHQR',
      ),
      storeInfo: InvoiceStoreInfoDto.fromJson(asMap(json['store_info'])),
      order: OrderDetailDto.fromJson(asMap(json['order'])),
      payment: paymentRaw == null ? null : PaymentDto.fromJson(asMap(paymentRaw)),
    );
  }
}

class CheckoutRequest {
  const CheckoutRequest({
    required this.name,
    this.firstName,
    this.lastName,
    required this.email,
    required this.phone,
    required this.province,
    this.district,
    this.commune,
    required this.streetAddress,
    required this.shippingMethod,
    this.notes,
  });

  final String name;
  final String? firstName;
  final String? lastName;
  final String email;
  final String phone;
  final String province;
  final String? district;
  final String? commune;
  final String streetAddress;
  final String shippingMethod;
  final String? notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name.trim(),
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        'email': email.trim(),
        'phone': phone.trim(),
        'province': province,
        'district': district?.trim(),
        'commune': commune?.trim(),
        'street_address': streetAddress.trim(),
        'shipping_method': shippingMethod,
        'notes': notes?.trim(),
      };
}

class CheckoutResponse {
  const CheckoutResponse({
    required this.message,
    required this.order,
    required this.payment,
    required this.orderAccessToken,
  });

  final String message;
  final OrderDetailDto order;
  final PaymentDto payment;
  final String orderAccessToken;

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      message: asString(json['message']),
      order: OrderDetailDto.fromJson(asMap(json['order'])),
      payment: PaymentDto.fromJson(asMap(json['payment'])),
      orderAccessToken: asString(json['order_access_token']),
    );
  }
}

class OrderPaymentResponse {
  const OrderPaymentResponse({
    required this.order,
    required this.payment,
  });

  final OrderDetailDto order;
  final PaymentDto payment;

  factory OrderPaymentResponse.fromJson(Map<String, dynamic> json) {
    return OrderPaymentResponse(
      order: OrderDetailDto.fromJson(asMap(json['order'])),
      payment: PaymentDto.fromJson(asMap(json['payment'])),
    );
  }
}

class PaymentStatusResponse {
  const PaymentStatusResponse({
    required this.paymentId,
    required this.orderNumber,
    required this.orderStatus,
    required this.status,
    required this.timeRemainingSeconds,
    required this.paidAt,
    required this.message,
  });

  final int paymentId;
  final String orderNumber;
  final String orderStatus;
  final String status;
  final int timeRemainingSeconds;
  final String? paidAt;
  final String? message;

  factory PaymentStatusResponse.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResponse(
      paymentId: asInt(json['payment_id']),
      orderNumber: asString(json['order_number']),
      orderStatus: asString(json['order_status']),
      status: asString(json['status']),
      timeRemainingSeconds: asInt(json['time_remaining_seconds']),
      paidAt: asNullableString(json['paid_at']),
      message: asNullableString(json['message']),
    );
  }
}

class RegenerateQrResponse {
  const RegenerateQrResponse({
    required this.message,
    required this.order,
    required this.payment,
  });

  final String message;
  final OrderDetailDto order;
  final PaymentDto payment;

  factory RegenerateQrResponse.fromJson(Map<String, dynamic> json) {
    return RegenerateQrResponse(
      message: asString(json['message']),
      order: OrderDetailDto.fromJson(asMap(json['order'])),
      payment: PaymentDto.fromJson(asMap(json['payment'])),
    );
  }
}

class SimulatePayResponse {
  const SimulatePayResponse({
    required this.success,
    required this.message,
    required this.order,
    required this.payment,
  });

  final bool success;
  final String message;
  final OrderDetailDto order;
  final PaymentDto payment;

  factory SimulatePayResponse.fromJson(Map<String, dynamic> json) {
    return SimulatePayResponse(
      success: asBool(json['success'], fallback: true),
      message: asString(json['message']),
      order: OrderDetailDto.fromJson(asMap(json['order'])),
      payment: PaymentDto.fromJson(asMap(json['payment'])),
    );
  }
}
