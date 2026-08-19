class ProductListResult {
  const ProductListResult({
    required this.products,
    required this.pagination,
    required this.categories,
    required this.permissions,
  });

  final List<ProductSummary> products;
  final ProductPagination pagination;
  final List<ProductOption> categories;
  final ProductPermissions permissions;

  factory ProductListResult.fromMap(Map<String, dynamic> map) {
    return ProductListResult(
      products: _mapList(map['products']).map(ProductSummary.fromMap).toList(),
      pagination: ProductPagination.fromMap(_mapValue(map['pagination'])),
      categories: _mapList(map['categories']).map(ProductOption.fromMap).toList(),
      permissions: ProductPermissions.fromMap(_mapValue(map['permissions'])),
    );
  }
}

class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.code,
    required this.name,
    required this.imageUrl,
    required this.categoryId,
    required this.categoryName,
    required this.variationCount,
    required this.ipiPercent,
    required this.unit,
    required this.commissionPercent,
    required this.listPrice,
    required this.availableStock,
    required this.active,
  });

  final String id;
  final String code;
  final String name;
  final String? imageUrl;
  final String? categoryId;
  final String categoryName;
  final int variationCount;
  final double ipiPercent;
  final String unit;
  final double commissionPercent;
  final double listPrice;
  final double? availableStock;
  final bool active;

  factory ProductSummary.fromMap(Map<String, dynamic> map) {
    return ProductSummary(
      id: _string(map['id'], fallback: _string(map['objectId'])),
      code: _string(map['code']),
      name: _string(map['name']),
      imageUrl: _nullableString(map['imageUrl']),
      categoryId: _nullableString(map['categoryId']),
      categoryName: _string(map['categoryName']),
      variationCount: _integer(map['variationCount']),
      ipiPercent: _double(map['ipiPercent']),
      unit: _string(map['unit'], fallback: 'UN'),
      commissionPercent: _double(map['commissionPercent']),
      listPrice: _double(map['listPrice']),
      availableStock: map['availableStock'] == null
          ? null
          : _double(map['availableStock']),
      active: _boolean(map['active'], fallback: true),
    );
  }
}

class ProductPagination {
  const ProductPagination({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
  });

  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;

  factory ProductPagination.fromMap(Map<String, dynamic> map) {
    return ProductPagination(
      page: _integer(map['page'], fallback: 1),
      pageSize: _integer(map['pageSize'], fallback: 25),
      totalItems: _integer(map['totalItems']),
      totalPages: _integer(map['totalPages']),
      hasNextPage: _boolean(map['hasNextPage']),
    );
  }
}

class ProductPermissions {
  const ProductPermissions({
    required this.canCreate,
    required this.canEdit,
    required this.canDelete,
    required this.canImport,
    required this.canExport,
    required this.canManageStock,
  });

  final bool canCreate;
  final bool canEdit;
  final bool canDelete;
  final bool canImport;
  final bool canExport;
  final bool canManageStock;

  factory ProductPermissions.fromMap(Map<String, dynamic> map) {
    return ProductPermissions(
      canCreate: _boolean(map['canCreate'], fallback: true),
      canEdit: _boolean(map['canEdit'], fallback: true),
      canDelete: _boolean(map['canDelete'], fallback: true),
      canImport: _boolean(map['canImport']),
      canExport: _boolean(map['canExport']),
      canManageStock: _boolean(map['canManageStock']),
    );
  }

  static const initial = ProductPermissions(
    canCreate: true,
    canEdit: true,
    canDelete: true,
    canImport: false,
    canExport: false,
    canManageStock: false,
  );
}

class ProductFormOptions {
  const ProductFormOptions({
    required this.categories,
    required this.units,
    required this.currencies,
    required this.permissions,
  });

  final List<ProductOption> categories;
  final List<ProductOption> units;
  final List<ProductOption> currencies;
  final ProductPermissions permissions;

  factory ProductFormOptions.fromMap(Map<String, dynamic> map) {
    return ProductFormOptions(
      categories: _mapList(map['categories']).map(ProductOption.fromMap).toList(),
      units: _mapList(map['units']).map(ProductOption.fromMap).toList(),
      currencies: _mapList(map['currencies']).map(ProductOption.fromMap).toList(),
      permissions: ProductPermissions.fromMap(_mapValue(map['permissions'])),
    );
  }
}

class ProductOption {
  const ProductOption({required this.id, required this.label});

  final String id;
  final String label;

  factory ProductOption.fromMap(Map<String, dynamic> map) {
    return ProductOption(
      id: _string(
        map['id'],
        fallback: _string(map['objectId'], fallback: _string(map['value'])),
      ),
      label: _string(map['label'], fallback: _string(map['name'])),
    );
  }
}

class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.name,
    required this.code,
    required this.unit,
    required this.minimumQuantity,
    required this.categoryId,
    required this.currency,
    required this.listPrice,
    required this.commissionPercent,
    required this.ipiPercent,
    required this.description,
    required this.barcode,
    required this.brand,
    required this.notes,
    required this.active,
    required this.trackStock,
    required this.availableStock,
    required this.netWeight,
    required this.grossWeight,
    required this.width,
    required this.height,
    required this.length,
    required this.imageUrl,
    required this.variants,
  });

  final String? id;
  final String name;
  final String code;
  final String unit;
  final double minimumQuantity;
  final String? categoryId;
  final String currency;
  final double listPrice;
  final double commissionPercent;
  final double ipiPercent;
  final String description;
  final String barcode;
  final String brand;
  final String notes;
  final bool active;
  final bool trackStock;
  final double? availableStock;
  final double? netWeight;
  final double? grossWeight;
  final double? width;
  final double? height;
  final double? length;
  final String? imageUrl;
  final List<ProductVariant> variants;

  bool get isPersisted => id != null && id!.isNotEmpty;

  factory ProductDetail.empty() {
    return const ProductDetail(
      id: null,
      name: '',
      code: '',
      unit: 'UN',
      minimumQuantity: 1,
      categoryId: null,
      currency: 'BRL',
      listPrice: 0,
      commissionPercent: 0,
      ipiPercent: 0,
      description: '',
      barcode: '',
      brand: '',
      notes: '',
      active: true,
      trackStock: false,
      availableStock: null,
      netWeight: null,
      grossWeight: null,
      width: null,
      height: null,
      length: null,
      imageUrl: null,
      variants: [],
    );
  }

  factory ProductDetail.fromMap(Map<String, dynamic> map) {
    return ProductDetail(
      id: _nullableString(map['id']) ?? _nullableString(map['objectId']),
      name: _string(map['name']),
      code: _string(map['code']),
      unit: _string(map['unit'], fallback: 'UN'),
      minimumQuantity: _double(map['minimumQuantity'], fallback: 1),
      categoryId: _nullableString(map['categoryId']),
      currency: _string(map['currency'], fallback: 'BRL'),
      listPrice: _double(map['listPrice']),
      commissionPercent: _double(map['commissionPercent']),
      ipiPercent: _double(map['ipiPercent']),
      description: _string(map['description']),
      barcode: _string(map['barcode']),
      brand: _string(map['brand']),
      notes: _string(map['notes']),
      active: _boolean(map['active'], fallback: true),
      trackStock: _boolean(map['trackStock']),
      availableStock: map['availableStock'] == null
          ? null
          : _double(map['availableStock']),
      netWeight: map['netWeight'] == null ? null : _double(map['netWeight']),
      grossWeight: map['grossWeight'] == null ? null : _double(map['grossWeight']),
      width: map['width'] == null ? null : _double(map['width']),
      height: map['height'] == null ? null : _double(map['height']),
      length: map['length'] == null ? null : _double(map['length']),
      imageUrl: _nullableString(map['imageUrl']),
      variants: _mapList(map['variants']).map(ProductVariant.fromMap).toList(),
    );
  }

  Map<String, dynamic> toRequest() {
    return {
      if (id != null) 'productId': id,
      'name': name.trim(),
      'code': code.trim(),
      'unit': unit,
      'minimumQuantity': minimumQuantity,
      'categoryId': categoryId,
      'currency': currency,
      'listPrice': listPrice,
      'commissionPercent': commissionPercent,
      'ipiPercent': ipiPercent,
      'description': description.trim(),
      'barcode': barcode.trim(),
      'brand': brand.trim(),
      'notes': notes.trim(),
      'active': active,
      'trackStock': trackStock,
      'availableStock': trackStock ? availableStock ?? 0 : null,
      'netWeight': netWeight,
      'grossWeight': grossWeight,
      'width': width,
      'height': height,
      'length': length,
      'variants': variants.map((item) => item.toRequest()).toList(),
    };
  }
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.name,
    required this.code,
    required this.attributes,
    required this.priceAdjustment,
    required this.availableStock,
    required this.active,
  });

  final String? id;
  final String name;
  final String code;
  final Map<String, String> attributes;
  final double priceAdjustment;
  final double? availableStock;
  final bool active;

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    final rawAttributes = map['attributes'];
    return ProductVariant(
      id: _nullableString(map['id']) ?? _nullableString(map['objectId']),
      name: _string(map['name']),
      code: _string(map['code']),
      attributes: rawAttributes is Map
          ? rawAttributes.map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''))
          : <String, String>{},
      priceAdjustment: _double(map['priceAdjustment']),
      availableStock: map['availableStock'] == null
          ? null
          : _double(map['availableStock']),
      active: _boolean(map['active'], fallback: true),
    );
  }

  Map<String, dynamic> toRequest() {
    return {
      if (id != null) 'id': id,
      'name': name.trim(),
      'code': code.trim(),
      'attributes': attributes,
      'priceAdjustment': priceAdjustment,
      'availableStock': availableStock,
      'active': active,
    };
  }
}

class ProductImportResult {
  const ProductImportResult({
    required this.created,
    required this.updated,
    required this.skipped,
    required this.errors,
  });

  final int created;
  final int updated;
  final int skipped;
  final List<String> errors;

  factory ProductImportResult.fromMap(Map<String, dynamic> map) {
    return ProductImportResult(
      created: _integer(map['created']),
      updated: _integer(map['updated']),
      skipped: _integer(map['skipped']),
      errors: _stringList(map['errors']),
    );
  }
}

class ProductExport {
  const ProductExport({
    required this.exportId,
    required this.status,
    required this.downloadUrl,
  });

  final String exportId;
  final String status;
  final String? downloadUrl;

  factory ProductExport.fromMap(Map<String, dynamic> map) {
    return ProductExport(
      exportId: _string(map['exportId']),
      status: _string(map['status'], fallback: 'ready'),
      downloadUrl: _nullableString(map['downloadUrl']),
    );
  }
}

Map<String, dynamic> _mapValue(dynamic value) {
  return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];
  return value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
}

List<String> _stringList(dynamic value) {
  if (value is! List) return <String>[];
  return value.map((item) => item?.toString() ?? '').where((item) => item.isNotEmpty).toList();
}

String _string(dynamic value, {String fallback = ''}) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? fallback : text;
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _integer(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _double(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? fallback;
}

bool _boolean(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value?.toString().toLowerCase() == 'true') return true;
  if (value?.toString().toLowerCase() == 'false') return false;
  return fallback;
}
