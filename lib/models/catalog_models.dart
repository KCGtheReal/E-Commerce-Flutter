import '../core/utils/json_helpers.dart';
import 'common_models.dart';

class CategorySummaryDto {
  const CategorySummaryDto({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.nameKm,
    required this.slug,
  });

  final int id;
  final String name;
  final String nameEn;
  final String? nameKm;
  final String slug;

  factory CategorySummaryDto.fromJson(Map<String, dynamic> json) {
    return CategorySummaryDto(
      id: asInt(json['id']),
      name: asString(json['name']),
      nameEn: asString(json['name_en'], fallback: asString(json['name'])),
      nameKm: asNullableString(json['name_km']),
      slug: asString(json['slug']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'name_en': nameEn,
        'name_km': nameKm,
        'slug': slug,
      };
}

class CategoryDto extends CategorySummaryDto {
  const CategoryDto({
    required super.id,
    required super.name,
    required super.nameEn,
    required super.nameKm,
    required super.slug,
    required this.description,
    required this.descriptionEn,
    required this.descriptionKm,
    required this.imageUrl,
    required this.sortOrder,
    this.productsCount,
  });

  final String? description;
  final String? descriptionEn;
  final String? descriptionKm;
  final String? imageUrl;
  final int sortOrder;
  final int? productsCount;

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: asInt(json['id']),
      name: asString(json['name']),
      nameEn: asString(json['name_en'], fallback: asString(json['name'])),
      nameKm: asNullableString(json['name_km']),
      slug: asString(json['slug']),
      description: asNullableString(json['description']),
      descriptionEn: asNullableString(json['description_en']),
      descriptionKm: asNullableString(json['description_km']),
      imageUrl: asNullableString(json['image_url']),
      sortOrder: asInt(json['sort_order']),
      productsCount: asNullableInt(json['products_count']),
    );
  }
}

class ProductImageDto {
  const ProductImageDto({
    required this.id,
    required this.imageUrl,
    required this.altText,
    required this.isPrimary,
    required this.sortOrder,
  });

  final int id;
  final String imageUrl;
  final String? altText;
  final bool isPrimary;
  final int sortOrder;

  factory ProductImageDto.fromJson(Map<String, dynamic> json) {
    return ProductImageDto(
      id: asInt(json['id']),
      imageUrl: asString(json['image_url']),
      altText: asNullableString(json['alt_text']),
      isPrimary: asBool(json['is_primary']),
      sortOrder: asInt(json['sort_order']),
    );
  }
}

class ProductColorSwatchDto {
  const ProductColorSwatchDto({
    required this.name,
    required this.code,
  });

  final String name;
  final String code;

  factory ProductColorSwatchDto.fromJson(Map<String, dynamic> json) {
    return ProductColorSwatchDto(
      name: asString(json['name']),
      code: asString(json['code'], fallback: '#111111'),
    );
  }
}

class ProductVariantDto {
  const ProductVariantDto({
    required this.id,
    required this.productId,
    required this.sku,
    required this.size,
    required this.color,
    required this.colorCode,
    required this.label,
    required this.priceCents,
    required this.formattedPrice,
    required this.convertedPrice,
    required this.stockQuantity,
    required this.reservedQuantity,
    required this.availableStock,
    required this.isInStock,
  });

  final int id;
  final int productId;
  final String sku;
  final String size;
  final String color;
  final String colorCode;
  final String label;
  final int priceCents;
  final String formattedPrice;
  final double convertedPrice;
  final int stockQuantity;
  final int reservedQuantity;
  final int availableStock;
  final bool isInStock;

  factory ProductVariantDto.fromJson(Map<String, dynamic> json) {
    final stockQty = asInt(json['stock_quantity']);
    final reservedQty = asInt(json['reserved_quantity']);
    final available = json.containsKey('available_stock')
        ? asInt(json['available_stock'])
        : (stockQty - reservedQty).clamp(0, 999999);
    return ProductVariantDto(
      id: asInt(json['id']),
      productId: asInt(json['product_id']),
      sku: asString(json['sku']),
      size: asString(json['size']),
      color: asString(json['color']),
      colorCode: asString(json['color_code'], fallback: '#111111'),
      label: asString(json['label']),
      priceCents: asInt(json['price_cents']),
      formattedPrice: asString(json['formatted_price']),
      convertedPrice: asDouble(json['converted_price']),
      stockQuantity: stockQty,
      reservedQuantity: reservedQty,
      availableStock: available,
      isInStock: json.containsKey('is_in_stock')
          ? asBool(json['is_in_stock'])
          : available > 0,
    );
  }
}

class ProductDetailsRawDto {
  const ProductDetailsRawDto({
    required this.fabric,
    required this.care,
    required this.fit,
    required this.shipping,
  });

  final String? fabric;
  final String? care;
  final String? fit;
  final String? shipping;

  factory ProductDetailsRawDto.fromJson(Map<String, dynamic> json) {
    return ProductDetailsRawDto(
      fabric: asNullableString(json['fabric']),
      care: asNullableString(json['care']),
      fit: asNullableString(json['fit']),
      shipping: asNullableString(json['shipping']),
    );
  }
}

class ProductDetailTabDto {
  const ProductDetailTabDto({
    required this.key,
    required this.title,
    required this.content,
  });

  final String key;
  final String title;
  final String content;

  factory ProductDetailTabDto.fromJson(Map<String, dynamic> json) {
    return ProductDetailTabDto(
      key: asString(json['key']),
      title: asString(json['title']),
      content: asString(json['content']),
    );
  }
}

class ReviewDto {
  const ReviewDto({
    required this.id,
    required this.productId,
    required this.userId,
    required this.authorName,
    required this.rating,
    required this.title,
    required this.body,
    required this.isVerifiedPurchase,
    required this.createdAt,
    required this.formattedDate,
  });

  final int id;
  final int productId;
  final int userId;
  final String authorName;
  final int rating;
  final String? title;
  final String body;
  final bool isVerifiedPurchase;
  final String createdAt;
  final String formattedDate;

  factory ReviewDto.fromJson(Map<String, dynamic> json) {
    return ReviewDto(
      id: asInt(json['id']),
      productId: asInt(json['product_id']),
      userId: asInt(json['user_id']),
      authorName: asString(json['author_name']),
      rating: asInt(json['rating'], fallback: 5).clamp(1, 5),
      title: asNullableString(json['title']),
      body: asString(json['body']),
      isVerifiedPurchase: asBool(json['is_verified_purchase']),
      createdAt: asString(json['created_at']),
      formattedDate: asString(json['formatted_date']),
    );
  }
}

class ProductCardDto {
  const ProductCardDto({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.nameKm,
    required this.slug,
    required this.skuPrefix,
    required this.tagline,
    required this.taglineEn,
    required this.taglineKm,
    required this.category,
    required this.primaryImageUrl,
    required this.basePriceCents,
    required this.compareAtPriceCents,
    required this.formattedPrice,
    required this.formattedCompareAtPrice,
    required this.convertedPrice,
    required this.convertedCompareAtPrice,
    required this.isOnSale,
    required this.isFeatured,
    required this.isNewArrival,
    required this.isBestSeller,
    required this.isInStock,
    required this.totalStock,
    required this.averageRating,
    required this.reviewCount,
    required this.colors,
  });

  final int id;
  final String name;
  final String nameEn;
  final String? nameKm;
  final String slug;
  final String skuPrefix;
  final String? tagline;
  final String? taglineEn;
  final String? taglineKm;
  final CategorySummaryDto? category;
  final String primaryImageUrl;
  final int basePriceCents;
  final int? compareAtPriceCents;
  final String formattedPrice;
  final String? formattedCompareAtPrice;
  final double convertedPrice;
  final double? convertedCompareAtPrice;
  final bool isOnSale;
  final bool isFeatured;
  final bool isNewArrival;
  final bool isBestSeller;
  final bool isInStock;
  final int totalStock;
  final double averageRating;
  final int reviewCount;
  final List<ProductColorSwatchDto> colors;

  factory ProductCardDto.fromJson(Map<String, dynamic> json) {
    final categoryRaw = json['category'];
    return ProductCardDto(
      id: asInt(json['id']),
      name: asString(json['name']),
      nameEn: asString(json['name_en'], fallback: asString(json['name'])),
      nameKm: asNullableString(json['name_km']),
      slug: asString(json['slug']),
      skuPrefix: asString(json['sku_prefix']),
      tagline: asNullableString(json['tagline']),
      taglineEn: asNullableString(json['tagline_en']),
      taglineKm: asNullableString(json['tagline_km']),
      category: categoryRaw == null
          ? null
          : CategorySummaryDto.fromJson(asMap(categoryRaw)),
      primaryImageUrl: asString(json['primary_image_url']),
      basePriceCents: asInt(json['base_price_cents']),
      compareAtPriceCents: asNullableInt(json['compare_at_price_cents']),
      formattedPrice: asString(json['formatted_price']),
      formattedCompareAtPrice: asNullableString(
        json['formatted_compare_at_price'],
      ),
      convertedPrice: asDouble(json['converted_price']),
      convertedCompareAtPrice: asNullableDouble(
        json['converted_compare_at_price'],
      ),
      isOnSale: asBool(json['is_on_sale']),
      isFeatured: asBool(json['is_featured']),
      isNewArrival: asBool(json['is_new_arrival']),
      isBestSeller: asBool(json['is_best_seller']),
      isInStock: asBool(json['is_in_stock'], fallback: true),
      totalStock: asInt(json['total_stock']),
      averageRating: asDouble(json['average_rating']),
      reviewCount: asInt(json['review_count']),
      colors: asList(json['colors'])
          .map((e) => ProductColorSwatchDto.fromJson(asMap(e)))
          .toList(),
    );
  }
}

class ProductDetailDto extends ProductCardDto {
  const ProductDetailDto({
    required super.id,
    required super.name,
    required super.nameEn,
    required super.nameKm,
    required super.slug,
    required super.skuPrefix,
    required super.tagline,
    required super.taglineEn,
    required super.taglineKm,
    required super.category,
    required super.primaryImageUrl,
    required super.basePriceCents,
    required super.compareAtPriceCents,
    required super.formattedPrice,
    required super.formattedCompareAtPrice,
    required super.convertedPrice,
    required super.convertedCompareAtPrice,
    required super.isOnSale,
    required super.isFeatured,
    required super.isNewArrival,
    required super.isBestSeller,
    required super.isInStock,
    required super.totalStock,
    required super.averageRating,
    required super.reviewCount,
    required super.colors,
    required this.description,
    required this.descriptionEn,
    required this.descriptionKm,
    required this.images,
    required this.variants,
    required this.availableSizes,
    required this.availableColors,
    required this.details,
    required this.detailTabs,
    required this.reviews,
  });

  final String description;
  final String descriptionEn;
  final String? descriptionKm;
  final List<ProductImageDto> images;
  final List<ProductVariantDto> variants;
  final List<String> availableSizes;
  final List<ProductColorSwatchDto> availableColors;
  final ProductDetailsRawDto details;
  final List<ProductDetailTabDto> detailTabs;
  final List<ReviewDto> reviews;

  factory ProductDetailDto.fromJson(Map<String, dynamic> json) {
    final card = ProductCardDto.fromJson(json);
    return ProductDetailDto(
      id: card.id,
      name: card.name,
      nameEn: card.nameEn,
      nameKm: card.nameKm,
      slug: card.slug,
      skuPrefix: card.skuPrefix,
      tagline: card.tagline,
      taglineEn: card.taglineEn,
      taglineKm: card.taglineKm,
      category: card.category,
      primaryImageUrl: card.primaryImageUrl,
      basePriceCents: card.basePriceCents,
      compareAtPriceCents: card.compareAtPriceCents,
      formattedPrice: card.formattedPrice,
      formattedCompareAtPrice: card.formattedCompareAtPrice,
      convertedPrice: card.convertedPrice,
      convertedCompareAtPrice: card.convertedCompareAtPrice,
      isOnSale: card.isOnSale,
      isFeatured: card.isFeatured,
      isNewArrival: card.isNewArrival,
      isBestSeller: card.isBestSeller,
      isInStock: card.isInStock,
      totalStock: card.totalStock,
      averageRating: card.averageRating,
      reviewCount: card.reviewCount,
      colors: card.colors,
      description: asString(json['description']),
      descriptionEn: asString(
        json['description_en'],
        fallback: asString(json['description']),
      ),
      descriptionKm: asNullableString(json['description_km']),
      images: asList(json['images'])
          .map((e) => ProductImageDto.fromJson(asMap(e)))
          .toList(),
      variants: asList(json['variants'])
          .map((e) => ProductVariantDto.fromJson(asMap(e)))
          .toList(),
      availableSizes: asStringList(json['available_sizes']),
      availableColors: asList(json['available_colors'])
          .map((e) => ProductColorSwatchDto.fromJson(asMap(e)))
          .toList(),
      details: ProductDetailsRawDto.fromJson(asMap(json['details'])),
      detailTabs: asList(json['detail_tabs'])
          .map((e) => ProductDetailTabDto.fromJson(asMap(e)))
          .toList(),
      reviews: asList(json['reviews'])
          .map((e) => ReviewDto.fromJson(asMap(e)))
          .toList(),
    );
  }
}

class HomeResponse {
  const HomeResponse({
    required this.categories,
    required this.featuredProducts,
    required this.newArrivals,
    required this.bestSellers,
  });

  final List<CategoryDto> categories;
  final List<ProductCardDto> featuredProducts;
  final List<ProductCardDto> newArrivals;
  final List<ProductCardDto> bestSellers;

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    return HomeResponse(
      categories: asList(json['categories'])
          .map((e) => CategoryDto.fromJson(asMap(e)))
          .toList(),
      featuredProducts: asList(json['featured_products'])
          .map((e) => ProductCardDto.fromJson(asMap(e)))
          .toList(),
      newArrivals: asList(json['new_arrivals'])
          .map((e) => ProductCardDto.fromJson(asMap(e)))
          .toList(),
      bestSellers: asList(json['best_sellers'])
          .map((e) => ProductCardDto.fromJson(asMap(e)))
          .toList(),
    );
  }
}

class ProductsQuery {
  const ProductsQuery({
    this.q,
    this.category,
    this.sizes = const <String>[],
    this.color,
    this.minPrice,
    this.maxPrice,
    this.inStock = false,
    this.sort = 'featured',
    this.page = 1,
    this.perPage = 12,
  });

  final String? q;
  final String? category;
  final List<String> sizes;
  final String? color;
  final double? minPrice;
  final double? maxPrice;
  final bool inStock;
  final String sort;
  final int page;
  final int perPage;

  ProductsQuery copyWith({
    String? q,
    bool clearQ = false,
    String? category,
    bool clearCategory = false,
    List<String>? sizes,
    String? color,
    bool clearColor = false,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    bool? inStock,
    String? sort,
    int? page,
    int? perPage,
  }) {
    return ProductsQuery(
      q: clearQ ? null : (q ?? this.q),
      category: clearCategory ? null : (category ?? this.category),
      sizes: sizes ?? this.sizes,
      color: clearColor ? null : (color ?? this.color),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      inStock: inStock ?? this.inStock,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'sort': sort,
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (q != null && q!.trim().isNotEmpty) {
      params['q'] = q!.trim();
    }
    if (category != null && category!.trim().isNotEmpty) {
      params['category'] = category!.trim();
    }
    if (sizes.isNotEmpty) {
      params['size[]'] = sizes;
    }
    if (color != null && color!.trim().isNotEmpty) {
      params['color'] = color!.trim();
    }
    if (minPrice != null) {
      params['min_price'] =
          minPrice! == minPrice!.roundToDouble() ? '${minPrice!.round()}' : '$minPrice';
    }
    if (maxPrice != null) {
      params['max_price'] =
          maxPrice! == maxPrice!.roundToDouble() ? '${maxPrice!.round()}' : '$maxPrice';
    }
    if (inStock) {
      params['in_stock'] = '1';
    }
    return params;
  }
}

class ShopCategoryFacetDto {
  const ShopCategoryFacetDto({
    required this.id,
    required this.name,
    required this.slug,
    required this.productsCount,
  });

  final int id;
  final String name;
  final String slug;
  final int productsCount;

  factory ShopCategoryFacetDto.fromJson(Map<String, dynamic> json) {
    return ShopCategoryFacetDto(
      id: asInt(json['id']),
      name: asString(json['name']),
      slug: asString(json['slug']),
      productsCount: asInt(json['products_count']),
    );
  }
}

class ShopColorFacetDto {
  const ShopColorFacetDto({
    required this.color,
    required this.colorCode,
  });

  final String color;
  final String colorCode;

  factory ShopColorFacetDto.fromJson(Map<String, dynamic> json) {
    return ShopColorFacetDto(
      color: asString(json['color']),
      colorCode: asString(json['color_code'], fallback: '#111111'),
    );
  }
}

class ShopFacetsDto {
  const ShopFacetsDto({
    required this.allProductsCount,
    required this.categories,
    required this.availableSizes,
    required this.availableColors,
    required this.activeFilterCount,
    required this.currency,
    required this.exchangeRate,
  });

  final int allProductsCount;
  final List<ShopCategoryFacetDto> categories;
  final List<String> availableSizes;
  final List<ShopColorFacetDto> availableColors;
  final int activeFilterCount;
  final String currency;
  final int exchangeRate;

  factory ShopFacetsDto.fromJson(Map<String, dynamic> json) {
    return ShopFacetsDto(
      allProductsCount: asInt(json['all_products_count']),
      categories: asList(json['categories'])
          .map((e) => ShopCategoryFacetDto.fromJson(asMap(e)))
          .toList(),
      availableSizes: asStringList(json['available_sizes']),
      availableColors: asList(json['available_colors'])
          .map((e) => ShopColorFacetDto.fromJson(asMap(e)))
          .toList(),
      activeFilterCount: asInt(json['active_filter_count']),
      currency: asString(json['currency'], fallback: 'KHR'),
      exchangeRate: asInt(json['exchange_rate'], fallback: 4100),
    );
  }
}

class ProductsResponse extends PaginatedResponse<ProductCardDto> {
  const ProductsResponse({
    required super.data,
    required super.meta,
    required this.facets,
  });

  final ShopFacetsDto facets;

  factory ProductsResponse.fromJson(Map<String, dynamic> json) {
    return ProductsResponse(
      data: asList(json['data'])
          .map((e) => ProductCardDto.fromJson(asMap(e)))
          .toList(),
      meta: PaginationMeta.fromJson(asMap(json['meta'])),
      facets: ShopFacetsDto.fromJson(asMap(json['facets'])),
    );
  }
}

class SearchCategorySuggestionDto {
  const SearchCategorySuggestionDto({
    required this.name,
    required this.slug,
  });

  final String name;
  final String slug;

  factory SearchCategorySuggestionDto.fromJson(Map<String, dynamic> json) {
    return SearchCategorySuggestionDto(
      name: asString(json['name']),
      slug: asString(json['slug']),
    );
  }
}

class SearchProductSuggestionDto {
  const SearchProductSuggestionDto({
    required this.id,
    required this.name,
    required this.slug,
    required this.imageUrl,
    required this.price,
    required this.compareAtPrice,
    required this.priceCents,
    required this.compareAtPriceCents,
    required this.category,
    required this.isInStock,
  });

  final int id;
  final String name;
  final String slug;
  final String imageUrl;
  final String price;
  final String? compareAtPrice;
  final int priceCents;
  final int? compareAtPriceCents;
  final String? category;
  final bool isInStock;

  factory SearchProductSuggestionDto.fromJson(Map<String, dynamic> json) {
    return SearchProductSuggestionDto(
      id: asInt(json['id']),
      name: asString(json['name']),
      slug: asString(json['slug']),
      imageUrl: asString(json['image_url']),
      price: asString(json['price']),
      compareAtPrice: asNullableString(json['compare_at_price']),
      priceCents: asInt(json['price_cents']),
      compareAtPriceCents: asNullableInt(json['compare_at_price_cents']),
      category: asNullableString(json['category']),
      isInStock: asBool(json['is_in_stock'], fallback: true),
    );
  }
}

class SearchSuggestResponse {
  const SearchSuggestResponse({
    required this.query,
    required this.popularSearches,
    required this.categories,
    required this.products,
    required this.total,
  });

  final String query;
  final List<String> popularSearches;
  final List<SearchCategorySuggestionDto> categories;
  final List<SearchProductSuggestionDto> products;
  final int total;

  factory SearchSuggestResponse.fromJson(Map<String, dynamic> json) {
    return SearchSuggestResponse(
      query: asString(json['query']),
      popularSearches: asStringList(json['popular_searches']),
      categories: asList(json['categories'])
          .map((e) => SearchCategorySuggestionDto.fromJson(asMap(e)))
          .toList(),
      products: asList(json['products'])
          .map((e) => SearchProductSuggestionDto.fromJson(asMap(e)))
          .toList(),
      total: asInt(json['total']),
    );
  }
}

class ProductDetailResponse {
  const ProductDetailResponse({
    required this.product,
    required this.hasPurchased,
    required this.inWishlist,
    required this.relatedProducts,
  });

  final ProductDetailDto product;
  final bool hasPurchased;
  final bool inWishlist;
  final List<ProductCardDto> relatedProducts;

  factory ProductDetailResponse.fromJson(Map<String, dynamic> json) {
    return ProductDetailResponse(
      product: ProductDetailDto.fromJson(asMap(json['product'])),
      hasPurchased: asBool(json['has_purchased']),
      inWishlist: asBool(json['in_wishlist']),
      relatedProducts: asList(json['related_products'])
          .map((e) => ProductCardDto.fromJson(asMap(e)))
          .toList(),
    );
  }
}

class CreateReviewRequest {
  const CreateReviewRequest({
    required this.rating,
    this.title,
    required this.body,
  });

  final int rating;
  final String? title;
  final String body;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'rating': rating,
        if (title != null && title!.trim().isNotEmpty) 'title': title!.trim(),
        'body': body.trim(),
      };
}

class CreateReviewResponse {
  const CreateReviewResponse({
    required this.message,
    required this.review,
    required this.averageRating,
    required this.reviewCount,
  });

  final String message;
  final ReviewDto review;
  final double averageRating;
  final int reviewCount;

  factory CreateReviewResponse.fromJson(Map<String, dynamic> json) {
    return CreateReviewResponse(
      message: asString(json['message']),
      review: ReviewDto.fromJson(asMap(json['review'])),
      averageRating: asDouble(json['average_rating']),
      reviewCount: asInt(json['review_count']),
    );
  }
}

class WishlistResponse {
  const WishlistResponse({
    required this.items,
    required this.total,
  });

  final List<ProductCardDto> items;
  final int total;

  factory WishlistResponse.fromJson(Map<String, dynamic> json) {
    return WishlistResponse(
      items: asList(json['items'])
          .map((e) => ProductCardDto.fromJson(asMap(e)))
          .toList(),
      total: asInt(json['total']),
    );
  }
}

class ToggleWishlistResponse {
  const ToggleWishlistResponse({
    required this.added,
    required this.productId,
    required this.message,
    required this.totalWishlists,
  });

  final bool added;
  final int productId;
  final String message;
  final int totalWishlists;

  factory ToggleWishlistResponse.fromJson(Map<String, dynamic> json) {
    return ToggleWishlistResponse(
      added: asBool(json['added']),
      productId: asInt(json['product_id']),
      message: asString(json['message']),
      totalWishlists: asInt(json['total_wishlists']),
    );
  }
}
