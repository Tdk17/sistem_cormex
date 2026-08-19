import 'package:sistem_cormex/Src/Connection/endpoints.dart';
import 'package:sistem_cormex/Src/Connection/httpManager.dart';
import 'package:sistem_cormex/Src/Models/productModels.dart';

abstract interface class ProductsRepository {
  Future<ProductListResult> listProducts({
    required String sessionToken,
    required int page,
    required int pageSize,
    required String query,
    required String visibility,
    String? categoryId,
  });

  Future<ProductFormOptions> getFormOptions({required String sessionToken});

  Future<ProductDetail> getProduct({
    required String sessionToken,
    required String productId,
  });

  Future<ProductDetail> saveProduct({
    required String sessionToken,
    required Map<String, dynamic> product,
  });

  Future<ProductDetail> uploadImage({
    required String sessionToken,
    required String productId,
    required String fileName,
    required String mimeType,
    required String base64,
  });

  Future<void> deleteProduct({
    required String sessionToken,
    required String productId,
  });

  Future<ProductImportResult> importProducts({
    required String sessionToken,
    required String fileName,
    required String base64,
  });

  Future<ProductExport> exportProducts({
    required String sessionToken,
    required String format,
    required String scope,
  });

  Future<void> deleteAllImages({required String sessionToken});
}

class ParseProductsRepository implements ProductsRepository {
  const ParseProductsRepository(this._httpManager);

  final HttpManager _httpManager;

  @override
  Future<ProductListResult> listProducts({
    required String sessionToken,
    required int page,
    required int pageSize,
    required String query,
    required String visibility,
    String? categoryId,
  }) async {
    final result = await _post(
      Endpoints.productsList,
      sessionToken,
      {
        'page': page,
        'pageSize': pageSize,
        'query': query.trim(),
        'visibility': visibility,
        'categoryId': categoryId,
      },
    );
    return ProductListResult.fromMap(result);
  }

  @override
  Future<ProductFormOptions> getFormOptions({required String sessionToken}) async {
    final result = await _post(
      Endpoints.productsFormOptions,
      sessionToken,
      const {},
    );
    return ProductFormOptions.fromMap(result);
  }

  @override
  Future<ProductDetail> getProduct({
    required String sessionToken,
    required String productId,
  }) async {
    final result = await _post(
      Endpoints.productsGet,
      sessionToken,
      {'productId': productId},
    );
    return ProductDetail.fromMap(_productMap(result));
  }

  @override
  Future<ProductDetail> saveProduct({
    required String sessionToken,
    required Map<String, dynamic> product,
  }) async {
    final result = await _post(Endpoints.productsSave, sessionToken, product);
    return ProductDetail.fromMap(_productMap(result));
  }

  @override
  Future<ProductDetail> uploadImage({
    required String sessionToken,
    required String productId,
    required String fileName,
    required String mimeType,
    required String base64,
  }) async {
    final result = await _post(
      Endpoints.productImageUpload,
      sessionToken,
      {
        'productId': productId,
        'fileName': fileName,
        'mimeType': mimeType,
        'base64': base64,
      },
    );
    return ProductDetail.fromMap(_productMap(result));
  }

  @override
  Future<void> deleteProduct({
    required String sessionToken,
    required String productId,
  }) async {
    await _post(
      Endpoints.productsDelete,
      sessionToken,
      {'productId': productId},
    );
  }

  @override
  Future<ProductImportResult> importProducts({
    required String sessionToken,
    required String fileName,
    required String base64,
  }) async {
    final result = await _post(
      Endpoints.productsImport,
      sessionToken,
      {'fileName': fileName, 'base64': base64},
    );
    return ProductImportResult.fromMap(result);
  }

  @override
  Future<ProductExport> exportProducts({
    required String sessionToken,
    required String format,
    required String scope,
  }) async {
    final result = await _post(
      Endpoints.productsExport,
      sessionToken,
      {'format': format, 'scope': scope},
    );
    return ProductExport.fromMap(result);
  }

  @override
  Future<void> deleteAllImages({required String sessionToken}) async {
    await _post(
      Endpoints.productImagesDeleteAll,
      sessionToken,
      const {'confirmation': 'DELETE_ALL_PRODUCT_IMAGES'},
    );
  }

  Future<Map<String, dynamic>> _post(
    String endpoint,
    String sessionToken,
    Map<String, dynamic> body,
  ) async {
    final response = await _httpManager.restRequest(
      url: endpoint,
      method: HttpMethod.post,
      sessionToken: sessionToken,
      body: body,
    );
    final result = response['result'];
    if (result is Map) return Map<String, dynamic>.from(result);
    throw const FormatException(
      'O servidor retornou uma resposta inválida para Produtos.',
    );
  }

  Map<String, dynamic> _productMap(Map<String, dynamic> result) {
    final product = result['product'];
    return product is Map ? Map<String, dynamic>.from(product) : result;
  }
}
