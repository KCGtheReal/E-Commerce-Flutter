import '../core/utils/json_helpers.dart';

class CartItemDto {
  const CartItemDto({
    required this.id,
    required this.productId,
    required this.productSlug,
    required this.productVariantId,
    required this.productName,
    required this.productNameEn,
    required this.productNameKm,
    required this.variantLabel,
    required this.sku,
    required this.size,
    required this.color,
    required this.colorCode,
    required this.imageUrl,
    required this.priceCents,
    required this.formattedPrice,
    required this.convertedPrice,
    required this.quantity,
    required this.maxStock,
    required this.subtotalCents,
    required this.formattedSubtotal,
    required this.convertedSubtotal,
  });

  final int id;
  final int productId;
  final String productSlug;
  final int productVariantId;
  final String productName;
  final String productNameEn;
  final String? productNameKm;
  final String variantLabel;
  final String sku;
  final String size;
  final String color;
  final String colorCode;
  final String imageUrl;
  final int priceCents;
  final String formattedPrice;
  final double convertedPrice;
  final int quantity;
  final int maxStock;
  final int subtotalCents;
  final String formattedSubtotal;
  final double convertedSubtotal;

  factory CartItemDto.fromJson(Map<String, dynamic> json) {
    return CartItemDto(
      id: asInt(json['id']),
      productId: asInt(json['product_id']),
      productSlug: asString(json['product_slug']),
      productVariantId: asInt(json['product_variant_id']),
      productName: asString(json['product_name']),
      productNameEn: asString(
        json['product_name_en'],
        fallback: asString(json['product_name']),
      ),
      productNameKm: asNullableString(json['product_name_km']),
      variantLabel: asString(json['variant_label']),
      sku: asString(json['sku']),
      size: asString(json['size']),
      color: asString(json['color']),
      colorCode: asString(json['color_code'], fallback: '#111111'),
      imageUrl: asString(json['image_url']),
      priceCents: asInt(json['price_cents']),
      formattedPrice: asString(json['formatted_price']),
      convertedPrice: asDouble(json['converted_price']),
      quantity: asInt(json['quantity'], fallback: 1),
      maxStock: asInt(json['max_stock'], fallback: 20),
      subtotalCents: asInt(json['subtotal_cents']),
      formattedSubtotal: asString(json['formatted_subtotal']),
      convertedSubtotal: asDouble(json['converted_subtotal']),
    );
  }
}

class CartDiscountDto {
  const CartDiscountDto({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.formattedValue,
    required this.minSpendCents,
  });

  final int id;
  final String code;
  final String type;
  final int value;
  final String formattedValue;
  final int minSpendCents;

  factory CartDiscountDto.fromJson(Map<String, dynamic> json) {
    return CartDiscountDto(
      id: asInt(json['id']),
      code: asString(json['code']),
      type: asString(json['type']),
      value: asInt(json['value']),
      formattedValue: asString(json['formatted_value']),
      minSpendCents: asInt(json['min_spend_cents']),
    );
  }
}

class CartPayloadDto {
  const CartPayloadDto({
    required this.currency,
    required this.exchangeRate,
    required this.province,
    required this.shippingMethod,
    required this.subtotalCents,
    required this.formattedSubtotal,
    required this.discountCents,
    required this.formattedDiscount,
    required this.shippingFeeCents,
    required this.formattedShipping,
    required this.totalCents,
    required this.formattedTotal,
    required this.convertedTotal,
    required this.freeShippingThresholdCents,
    required this.formattedFreeShippingThreshold,
    required this.freeShippingQualified,
    required this.freeShippingRemainingCents,
    required this.freeShippingRemainingFormatted,
    required this.freeShippingProgressPercent,
    required this.cartToken,
    required this.itemCount,
    required this.items,
    required this.discountCode,
    required this.discount,
  });

  final String currency;
  final int exchangeRate;
  final String province;
  final String shippingMethod;
  final int subtotalCents;
  final String formattedSubtotal;
  final int discountCents;
  final String formattedDiscount;
  final int shippingFeeCents;
  final String formattedShipping;
  final int totalCents;
  final String formattedTotal;
  final double convertedTotal;
  final int freeShippingThresholdCents;
  final String formattedFreeShippingThreshold;
  final bool freeShippingQualified;
  final int freeShippingRemainingCents;
  final String freeShippingRemainingFormatted;
  final double freeShippingProgressPercent;
  final String? cartToken;
  final int itemCount;
  final List<CartItemDto> items;
  final String? discountCode;
  final CartDiscountDto? discount;

  bool get isEmpty => items.isEmpty;

  factory CartPayloadDto.fromJson(Map<String, dynamic> json) {
    final discountRaw = json['discount'];
    return CartPayloadDto(
      currency: asString(json['currency'], fallback: 'KHR'),
      exchangeRate: asInt(json['exchange_rate'], fallback: 4100),
      province: asString(json['province'], fallback: 'Phnom Penh'),
      shippingMethod: asString(json['shipping_method'], fallback: 'standard'),
      subtotalCents: asInt(json['subtotal_cents']),
      formattedSubtotal: asString(json['formatted_subtotal']),
      discountCents: asInt(json['discount_cents']),
      formattedDiscount: asString(json['formatted_discount']),
      shippingFeeCents: asInt(json['shipping_fee_cents']),
      formattedShipping: asString(json['formatted_shipping']),
      totalCents: asInt(json['total_cents']),
      formattedTotal: asString(json['formatted_total']),
      convertedTotal: asDouble(json['converted_total']),
      freeShippingThresholdCents: asInt(
        json['free_shipping_threshold_cents'],
        fallback: 200000,
      ),
      formattedFreeShippingThreshold: asString(
        json['formatted_free_shipping_threshold'],
      ),
      freeShippingQualified: asBool(json['free_shipping_qualified']),
      freeShippingRemainingCents: asInt(json['free_shipping_remaining_cents']),
      freeShippingRemainingFormatted: asString(
        json['free_shipping_remaining_formatted'],
      ),
      freeShippingProgressPercent: asDouble(
        json['free_shipping_progress_percent'],
      ),
      cartToken: asNullableString(json['cart_token']),
      itemCount: asInt(json['item_count']),
      items: asList(json['items'])
          .map((e) => CartItemDto.fromJson(asMap(e)))
          .toList(),
      discountCode: asNullableString(json['discount_code']),
      discount: discountRaw == null
          ? null
          : CartDiscountDto.fromJson(asMap(discountRaw)),
    );
  }
}

class AddCartItemRequest {
  const AddCartItemRequest({
    required this.productVariantId,
    required this.quantity,
    this.province,
    this.shippingMethod,
  });

  final int productVariantId;
  final int quantity;
  final String? province;
  final String? shippingMethod;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'product_variant_id': productVariantId,
        'quantity': quantity,
        if (province != null) 'province': province,
        if (shippingMethod != null) 'shipping_method': shippingMethod,
      };
}

class UpdateCartItemRequest {
  const UpdateCartItemRequest({
    required this.quantity,
    this.province,
    this.shippingMethod,
  });

  final int quantity;
  final String? province;
  final String? shippingMethod;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'quantity': quantity,
        if (province != null) 'province': province,
        if (shippingMethod != null) 'shipping_method': shippingMethod,
      };
}

class ApplyDiscountRequest {
  const ApplyDiscountRequest({
    required this.code,
    this.province,
    this.shippingMethod,
  });

  final String code;
  final String? province;
  final String? shippingMethod;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code.trim().toUpperCase(),
        if (province != null) 'province': province,
        if (shippingMethod != null) 'shipping_method': shippingMethod,
      };
}

class CartMutationResponse {
  const CartMutationResponse({
    required this.message,
    required this.cart,
  });

  final String message;
  final CartPayloadDto cart;

  factory CartMutationResponse.fromJson(Map<String, dynamic> json) {
    return CartMutationResponse(
      message: asString(json['message']),
      cart: CartPayloadDto.fromJson(asMap(json['cart'])),
    );
  }
}
