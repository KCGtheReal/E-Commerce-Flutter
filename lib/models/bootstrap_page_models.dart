import '../core/utils/json_helpers.dart';
import 'auth_account_models.dart';
import 'cart_models.dart';
import 'catalog_models.dart';

class SizeGuideRowDto {
  const SizeGuideRowDto({
    required this.size,
    required this.chestCm,
    required this.lengthCm,
    required this.shoulderCm,
    required this.sleeveCm,
  });

  final String size;
  final int chestCm;
  final int lengthCm;
  final int shoulderCm;
  final int sleeveCm;

  factory SizeGuideRowDto.fromJson(Map<String, dynamic> json) {
    return SizeGuideRowDto(
      size: asString(json['size']),
      chestCm: asInt(json['chest_cm']),
      lengthCm: asInt(json['length_cm']),
      shoulderCm: asInt(json['shoulder_cm']),
      sleeveCm: asInt(json['sleeve_cm']),
    );
  }
}

class SizeGuideColumnsDto {
  const SizeGuideColumnsDto({
    required this.size,
    required this.chest,
    required this.length,
    required this.shoulder,
    required this.sleeve,
  });

  final String size;
  final String chest;
  final String length;
  final String shoulder;
  final String sleeve;

  factory SizeGuideColumnsDto.fromJson(Map<String, dynamic> json) {
    return SizeGuideColumnsDto(
      size: asString(json['size'], fallback: 'Size'),
      chest: asString(json['chest'], fallback: 'Chest'),
      length: asString(json['length'], fallback: 'Length'),
      shoulder: asString(json['shoulder'], fallback: 'Shoulder'),
      sleeve: asString(json['sleeve'], fallback: 'Sleeve'),
    );
  }
}

class SizeGuideTableDto {
  const SizeGuideTableDto({
    required this.id,
    required this.title,
    required this.columns,
    required this.rows,
  });

  final String id;
  final String title;
  final SizeGuideColumnsDto columns;
  final List<SizeGuideRowDto> rows;

  factory SizeGuideTableDto.fromJson(Map<String, dynamic> json) {
    return SizeGuideTableDto(
      id: asString(json['id'], fallback: 'tees'),
      title: asString(json['title']),
      columns: SizeGuideColumnsDto.fromJson(asMap(json['columns'])),
      rows: asList(json['rows'])
          .map((e) => SizeGuideRowDto.fromJson(asMap(e)))
          .toList(),
    );
  }
}

class SizeGuideMeasureInstructionDto {
  const SizeGuideMeasureInstructionDto({
    required this.key,
    required this.label,
    required this.description,
  });

  final String key;
  final String label;
  final String description;

  factory SizeGuideMeasureInstructionDto.fromJson(Map<String, dynamic> json) {
    return SizeGuideMeasureInstructionDto(
      key: asString(json['key']),
      label: asString(json['label']),
      description: asString(json['description']),
    );
  }
}

class SizeGuideDataDto {
  const SizeGuideDataDto({
    required this.title,
    required this.subtitle,
    required this.fitNoteTitle,
    required this.fitNoteBody,
    required this.tip,
    required this.tables,
    required this.howToMeasureTitle,
    required this.howToMeasure,
  });

  final String title;
  final String subtitle;
  final String fitNoteTitle;
  final String fitNoteBody;
  final String tip;
  final List<SizeGuideTableDto> tables;
  final String howToMeasureTitle;
  final List<SizeGuideMeasureInstructionDto> howToMeasure;

  factory SizeGuideDataDto.fromJson(Map<String, dynamic> json) {
    return SizeGuideDataDto(
      title: asString(json['title'], fallback: 'Garment Measurements'),
      subtitle: asString(
        json['subtitle'],
        fallback:
            'All measurements are taken flat across the garment in centimeters (cm).',
      ),
      fitNoteTitle: asString(json['fit_note_title']),
      fitNoteBody: asString(json['fit_note_body']),
      tip: asString(json['tip']),
      tables: asList(json['tables'])
          .map((e) => SizeGuideTableDto.fromJson(asMap(e)))
          .toList(),
      howToMeasureTitle: asString(json['how_to_measure_title']),
      howToMeasure: asList(json['how_to_measure'])
          .map((e) => SizeGuideMeasureInstructionDto.fromJson(asMap(e)))
          .toList(),
    );
  }
}

class PageSummaryDto {
  const PageSummaryDto({
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.endpoint,
  });

  final String slug;
  final String title;
  final String? subtitle;
  final String endpoint;

  factory PageSummaryDto.fromJson(Map<String, dynamic> json) {
    return PageSummaryDto(
      slug: asString(json['slug']),
      title: asString(json['title']),
      subtitle: asNullableString(json['subtitle']),
      endpoint: asString(json['endpoint']),
    );
  }
}

class StructuredPageSectionItemDto {
  const StructuredPageSectionItemDto({
    this.question,
    this.answer,
    this.label,
    this.title,
    this.description,
  });

  final String? question;
  final String? answer;
  final String? label;
  final String? title;
  final String? description;

  factory StructuredPageSectionItemDto.fromJson(Map<String, dynamic> json) {
    return StructuredPageSectionItemDto(
      question: asNullableString(json['question']),
      answer: asNullableString(json['answer']),
      label: asNullableString(json['label']),
      title: asNullableString(json['title']),
      description: asNullableString(json['description']),
    );
  }
}

class StructuredPageSectionDto {
  const StructuredPageSectionDto({
    required this.id,
    this.eyebrow,
    required this.title,
    this.paragraphs = const <String>[],
    this.bullets = const <String>[],
    this.items = const <StructuredPageSectionItemDto>[],
  });

  final String id;
  final String? eyebrow;
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;
  final List<StructuredPageSectionItemDto> items;

  factory StructuredPageSectionDto.fromJson(Map<String, dynamic> json) {
    return StructuredPageSectionDto(
      id: asString(json['id']),
      eyebrow: asNullableString(json['eyebrow']),
      title: asString(json['title']),
      paragraphs: asStringList(json['paragraphs']),
      bullets: asStringList(json['bullets']),
      items: asList(json['items'])
          .map((e) => StructuredPageSectionItemDto.fromJson(asMap(e)))
          .toList(),
    );
  }
}

class StructuredPageTableDto {
  const StructuredPageTableDto({
    required this.title,
    required this.headers,
    required this.rows,
  });

  final String title;
  final List<String> headers;
  final List<List<String>> rows;

  factory StructuredPageTableDto.fromJson(Map<String, dynamic> json) {
    return StructuredPageTableDto(
      title: asString(json['title']),
      headers: asStringList(json['headers']),
      rows: asList(json['rows']).map((row) => asStringList(row)).toList(),
    );
  }
}

class StudioInfoDto {
  const StudioInfoDto({
    required this.studioTitle,
    required this.street,
    required this.cityCountry,
    required this.hours,
    required this.telegramHandle,
    required this.telegramUrl,
    required this.email,
    required this.phone,
  });

  final String studioTitle;
  final String street;
  final String cityCountry;
  final String hours;
  final String telegramHandle;
  final String telegramUrl;
  final String email;
  final String phone;

  factory StudioInfoDto.fromJson(Map<String, dynamic> json) {
    return StudioInfoDto(
      studioTitle: asString(json['studio_title']),
      street: asString(json['street']),
      cityCountry: asString(json['city_country']),
      hours: asString(json['hours']),
      telegramHandle: asString(json['telegram_handle']),
      telegramUrl: asString(json['telegram_url']),
      email: asString(json['email']),
      phone: asString(json['phone']),
    );
  }
}

class StructuredInfoPageDto {
  const StructuredInfoPageDto({
    required this.slug,
    required this.locale,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.updatedAt,
    required this.sections,
    required this.tables,
    required this.sizeGuide,
    required this.studioInfo,
  });

  final String slug;
  final String locale;
  final String? badge;
  final String title;
  final String? subtitle;
  final String? updatedAt;
  final List<StructuredPageSectionDto> sections;
  final List<StructuredPageTableDto> tables;
  final SizeGuideDataDto? sizeGuide;
  final StudioInfoDto? studioInfo;

  factory StructuredInfoPageDto.fromJson(Map<String, dynamic> json) {
    final sizeGuideRaw = json['size_guide'];
    final studioRaw = json['studio_info'];
    return StructuredInfoPageDto(
      slug: asString(json['slug']),
      locale: asString(json['locale'], fallback: 'en'),
      badge: asNullableString(json['badge']),
      title: asString(json['title']),
      subtitle: asNullableString(json['subtitle']),
      updatedAt: asNullableString(json['updated_at']),
      sections: asList(json['sections'])
          .map((e) => StructuredPageSectionDto.fromJson(asMap(e)))
          .toList(),
      tables: asList(json['tables'])
          .map((e) => StructuredPageTableDto.fromJson(asMap(e)))
          .toList(),
      sizeGuide: sizeGuideRaw == null
          ? null
          : SizeGuideDataDto.fromJson(asMap(sizeGuideRaw)),
      studioInfo: studioRaw == null
          ? null
          : StudioInfoDto.fromJson(asMap(studioRaw)),
    );
  }
}

class StoreBootstrapSettingsDto {
  const StoreBootstrapSettingsDto({
    required this.storeName,
    required this.storeTagline,
    required this.storeTaglineKm,
    required this.storeEmail,
    required this.storePhone,
    required this.storeAddress,
    required this.announcementBannerEn,
    required this.announcementBannerKm,
    required this.announcementBanner,
    required this.exchangeRate,
    required this.freeShippingThreshold,
    required this.formattedFreeShippingThreshold,
    required this.expressShippingFeeKhr,
    required this.expressShippingProvince,
    required this.provinceShippingFees,
    required this.provinces,
    required this.bakongMock,
    required this.bakongCurrency,
    required this.qrTtlSeconds,
  });

  final String storeName;
  final String storeTagline;
  final String storeTaglineKm;
  final String storeEmail;
  final String storePhone;
  final String storeAddress;
  final String announcementBannerEn;
  final String announcementBannerKm;
  final String announcementBanner;
  final int exchangeRate;
  final int freeShippingThreshold;
  final String formattedFreeShippingThreshold;
  final int expressShippingFeeKhr;
  final String expressShippingProvince;
  final Map<String, int> provinceShippingFees;
  final List<String> provinces;
  final bool bakongMock;
  final String bakongCurrency;
  final int qrTtlSeconds;

  factory StoreBootstrapSettingsDto.fromJson(Map<String, dynamic> json) {
    final feesMap = <String, int>{};
    asMap(json['province_shipping_fees']).forEach((key, value) {
      feesMap[key] = asInt(value);
    });
    return StoreBootstrapSettingsDto(
      storeName: asString(json['store_name'], fallback: 'RESET Store'),
      storeTagline: asString(json['store_tagline'], fallback: 'Start fresh.'),
      storeTaglineKm: asString(
        json['store_tagline_km'],
        fallback: 'ចាប់ផ្តើមថ្មី។',
      ),
      storeEmail: asString(json['store_email'], fallback: 'support@reset.store'),
      storePhone: asString(json['store_phone'], fallback: '+855 23 999 123'),
      storeAddress: asString(
        json['store_address'],
        fallback: 'Street 178, Daun Penh, Phnom Penh, Cambodia',
      ),
      announcementBannerEn: asString(json['announcement_banner_en']),
      announcementBannerKm: asString(json['announcement_banner_km']),
      announcementBanner: asString(json['announcement_banner']),
      exchangeRate: asInt(json['exchange_rate'], fallback: 4100),
      freeShippingThreshold: asInt(
        json['free_shipping_threshold'],
        fallback: 200000,
      ),
      formattedFreeShippingThreshold: asString(
        json['formatted_free_shipping_threshold'],
        fallback: '200,000 ៛',
      ),
      expressShippingFeeKhr: asInt(
        json['express_shipping_fee_khr'],
        fallback: 12000,
      ),
      expressShippingProvince: asString(
        json['express_shipping_province'],
        fallback: 'Phnom Penh',
      ),
      provinceShippingFees: feesMap,
      provinces: asStringList(json['provinces']),
      bakongMock: asBool(json['bakong_mock']),
      bakongCurrency: asString(json['bakong_currency'], fallback: 'KHR'),
      qrTtlSeconds: asInt(json['qr_ttl_seconds'], fallback: 300),
    );
  }
}

class BootstrapResponse {
  const BootstrapResponse({
    required this.locale,
    required this.currency,
    required this.settings,
    required this.categories,
    required this.sizeGuide,
    required this.pages,
    required this.authenticated,
    required this.user,
    required this.cart,
  });

  final String locale;
  final String currency;
  final StoreBootstrapSettingsDto settings;
  final List<CategoryDto> categories;
  final SizeGuideDataDto sizeGuide;
  final List<PageSummaryDto> pages;
  final bool authenticated;
  final UserDto? user;
  final CartPayloadDto? cart;

  factory BootstrapResponse.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    final cartRaw = json['cart'];
    return BootstrapResponse(
      locale: asString(json['locale'], fallback: 'en'),
      currency: asString(json['currency'], fallback: 'KHR'),
      settings: StoreBootstrapSettingsDto.fromJson(asMap(json['settings'])),
      categories: asList(json['categories'])
          .map((e) => CategoryDto.fromJson(asMap(e)))
          .toList(),
      sizeGuide: SizeGuideDataDto.fromJson(asMap(json['size_guide'])),
      pages: asList(json['pages'])
          .map((e) => PageSummaryDto.fromJson(asMap(e)))
          .toList(),
      authenticated: asBool(json['authenticated']),
      user: userRaw == null ? null : UserDto.fromJson(asMap(userRaw)),
      cart: cartRaw == null ? null : CartPayloadDto.fromJson(asMap(cartRaw)),
    );
  }
}

class ContactRequest {
  const ContactRequest({
    required this.name,
    required this.email,
    this.subject,
    required this.message,
  });

  final String name;
  final String email;
  final String? subject;
  final String message;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        if (subject != null && subject!.trim().isNotEmpty)
          'subject': subject!.trim(),
        'message': message.trim(),
      };
}

class ContactResponse {
  const ContactResponse({
    required this.message,
    required this.contactMessageId,
  });

  final String message;
  final int contactMessageId;

  factory ContactResponse.fromJson(Map<String, dynamic> json) {
    return ContactResponse(
      message: asString(json['message']),
      contactMessageId: asInt(json['contact_message_id']),
    );
  }
}

class NewsletterResponse {
  const NewsletterResponse({
    required this.message,
    required this.email,
    required this.isActive,
  });

  final String message;
  final String email;
  final bool isActive;

  factory NewsletterResponse.fromJson(Map<String, dynamic> json) {
    return NewsletterResponse(
      message: asString(json['message']),
      email: asString(json['email']),
      isActive: asBool(json['is_active'], fallback: true),
    );
  }
}
