import '../core/utils/json_helpers.dart';
import 'cart_models.dart';
import 'common_models.dart';
import 'order_payment_models.dart';

class UserDto {
  const UserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.emailVerifiedAt,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? emailVerifiedAt;
  final String createdAt;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: asInt(json['id']),
      name: asString(json['name']),
      email: asString(json['email']),
      phone: asNullableString(json['phone']),
      role: asString(json['role'], fallback: 'customer'),
      emailVerifiedAt: asNullableString(json['email_verified_at']),
      createdAt: asString(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'email_verified_at': emailVerifiedAt,
        'created_at': createdAt,
      };
}

class AddressDto {
  const AddressDto({
    required this.id,
    required this.type,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.phone,
    required this.province,
    required this.district,
    required this.commune,
    required this.streetAddress,
    required this.postalCode,
    required this.formattedAddress,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String type;
  final String firstName;
  final String lastName;
  final String fullName;
  final String phone;
  final String province;
  final String? district;
  final String? commune;
  final String streetAddress;
  final String? postalCode;
  final String formattedAddress;
  final bool isDefault;
  final String createdAt;
  final String updatedAt;

  factory AddressDto.fromJson(Map<String, dynamic> json) {
    final first = asString(json['first_name']);
    final last = asString(json['last_name']);
    final fallbackFull = '$first $last'.trim();
    return AddressDto(
      id: asInt(json['id']),
      type: asString(json['type'], fallback: 'shipping'),
      firstName: first,
      lastName: last,
      fullName: asString(json['full_name'], fallback: fallbackFull),
      phone: asString(json['phone']),
      province: asString(json['province']),
      district: asNullableString(json['district']),
      commune: asNullableString(json['commune']),
      streetAddress: asString(json['street_address']),
      postalCode: asNullableString(json['postal_code']),
      formattedAddress: asString(json['formatted_address']),
      isDefault: asBool(json['is_default']),
      createdAt: asString(json['created_at']),
      updatedAt: asString(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type,
        'first_name': firstName,
        'last_name': lastName,
        'full_name': fullName,
        'phone': phone,
        'province': province,
        'district': district,
        'commune': commune,
        'street_address': streetAddress,
        'postal_code': postalCode,
        'formatted_address': formattedAddress,
        'is_default': isDefault,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

class RegisterRequest {
  const RegisterRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
    this.deviceName = 'flutter-app',
  });

  final String name;
  final String email;
  final String phone;
  final String password;
  final String passwordConfirmation;
  final String deviceName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_name': deviceName,
      };
}

class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
    this.deviceName = 'flutter-app',
  });

  final String email;
  final String password;
  final String deviceName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'email': email,
        'password': password,
        'device_name': deviceName,
      };
}

class AuthResponse {
  const AuthResponse({
    required this.token,
    required this.tokenType,
    required this.expiresAt,
    required this.user,
    required this.cart,
  });

  final String token;
  final String tokenType;
  final String? expiresAt;
  final UserDto user;
  final CartPayloadDto cart;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: asString(json['token']),
      tokenType: asString(json['token_type'], fallback: 'Bearer'),
      expiresAt: asNullableString(json['expires_at']),
      user: UserDto.fromJson(asMap(json['user'])),
      cart: CartPayloadDto.fromJson(asMap(json['cart'])),
    );
  }
}

class ForgotPasswordResponse {
  const ForgotPasswordResponse({
    required this.message,
    required this.status,
  });

  final String message;
  final String status;

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      message: asString(json['message']),
      status: asString(json['status']),
    );
  }
}

class AccountProfileResponse {
  const AccountProfileResponse({
    required this.user,
    required this.defaultShippingAddress,
  });

  final UserDto user;
  final AddressDto? defaultShippingAddress;

  factory AccountProfileResponse.fromJson(Map<String, dynamic> json) {
    final addrRaw = json['default_shipping_address'];
    return AccountProfileResponse(
      user: UserDto.fromJson(asMap(json['user'])),
      defaultShippingAddress: addrRaw == null
          ? null
          : AddressDto.fromJson(asMap(addrRaw)),
    );
  }
}

class UpdateProfileRequest {
  const UpdateProfileRequest({
    required this.name,
    this.phone,
  });

  final String name;
  final String? phone;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'phone': phone,
      };
}

class UpdateProfileResponse {
  const UpdateProfileResponse({
    required this.message,
    required this.user,
  });

  final String message;
  final UserDto user;

  factory UpdateProfileResponse.fromJson(Map<String, dynamic> json) {
    return UpdateProfileResponse(
      message: asString(json['message']),
      user: UserDto.fromJson(asMap(json['user'])),
    );
  }
}

class UpdatePasswordRequest {
  const UpdatePasswordRequest({
    required this.currentPassword,
    required this.password,
    required this.passwordConfirmation,
  });

  final String currentPassword;
  final String password;
  final String passwordConfirmation;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      };
}

class AccountOrdersResponse extends PaginatedResponse<OrderSummaryDto> {
  const AccountOrdersResponse({
    required super.data,
    required super.meta,
  });

  factory AccountOrdersResponse.fromJson(Map<String, dynamic> json) {
    return AccountOrdersResponse(
      data: asList(json['data'])
          .map((e) => OrderSummaryDto.fromJson(asMap(e)))
          .toList(),
      meta: PaginationMeta.fromJson(asMap(json['meta'])),
    );
  }
}

class AccountAddressesResponse {
  const AccountAddressesResponse({
    required this.addresses,
    required this.provinces,
  });

  final List<AddressDto> addresses;
  final List<String> provinces;

  factory AccountAddressesResponse.fromJson(Map<String, dynamic> json) {
    return AccountAddressesResponse(
      addresses: asList(json['addresses'])
          .map((e) => AddressDto.fromJson(asMap(e)))
          .toList(),
      provinces: asStringList(json['provinces']),
    );
  }
}

class UpsertAddressRequest {
  const UpsertAddressRequest({
    this.name,
    this.firstName,
    this.lastName,
    required this.phone,
    required this.province,
    this.district,
    this.commune,
    required this.streetAddress,
    this.postalCode,
    this.isDefault = false,
  });

  final String? name;
  final String? firstName;
  final String? lastName;
  final String phone;
  final String province;
  final String? district;
  final String? commune;
  final String streetAddress;
  final String? postalCode;
  final bool isDefault;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (name != null) 'name': name,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        'phone': phone,
        'province': province,
        'district': district,
        'commune': commune,
        'street_address': streetAddress,
        'postal_code': postalCode,
        'is_default': isDefault,
      };
}

class AccountAddressMutationResponse {
  const AccountAddressMutationResponse({
    required this.message,
    required this.address,
  });

  final String message;
  final AddressDto address;

  factory AccountAddressMutationResponse.fromJson(Map<String, dynamic> json) {
    return AccountAddressMutationResponse(
      message: asString(json['message']),
      address: AddressDto.fromJson(asMap(json['address'])),
    );
  }
}
