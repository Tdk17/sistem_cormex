import 'package:signals/signals.dart';
import 'package:sistem_cormex/Src/Connection/apiException.dart';
import 'package:sistem_cormex/Src/Models/productModels.dart';
import 'package:sistem_cormex/Src/Pages/Auth/Controller/authController.dart';
import 'package:sistem_cormex/Src/Pages/Products/Repository/productsRepository.dart';

class ProductsController {
  ProductsController(this._repository, this._authController);

  final ProductsRepository _repository;
  final AuthController _authController;
  String? _dataSessionToken;
  int _listRequestId = 0;

  final listLoading = signal(false);
  final listError = signal<String?>(null);
  final products = signal<List<ProductSummary>>([]);
  final pagination = signal<ProductPagination?>(null);
  final categories = signal<List<ProductOption>>([]);
  final permissions = signal(ProductPermissions.initial);
  final query = signal('');
  final visibility = signal('active');
  final categoryId = signal<String?>(null);

  final formLoading = signal(false);
  final formError = signal<String?>(null);
  final formOptions = signal<ProductFormOptions?>(null);
  final editingProduct = signal<ProductDetail?>(null);
  final saving = signal(false);
  final deleting = signal(false);
  final importing = signal(false);
  final exporting = signal(false);
  final deletingImages = signal(false);

  Future<void> initializeList() async {
    _synchronizeSession();
    if (products.value.isEmpty) await loadProducts();
  }

  Future<void> loadProducts({int page = 1}) async {
    final requestId = ++_listRequestId;
    batch(() {
      listLoading.value = true;
      listError.value = null;
    });
    try {
      final result = await _repository.listProducts(
        sessionToken: _sessionToken,
        page: page,
        pageSize: 25,
        query: query.value,
        visibility: visibility.value,
        categoryId: categoryId.value,
      );
      if (requestId != _listRequestId) return;
      batch(() {
        products.value = result.products;
        pagination.value = result.pagination;
        categories.value = result.categories;
        permissions.value = result.permissions;
      });
    } catch (error) {
      if (requestId == _listRequestId) listError.value = _messageFor(error);
    } finally {
      if (requestId == _listRequestId) listLoading.value = false;
    }
  }

  Future<void> applySearch(String value) async {
    query.value = value.trim();
    await loadProducts();
  }

  Future<void> changeVisibility(String value) async {
    visibility.value = value;
    await loadProducts();
  }

  Future<void> changeCategory(String? value) async {
    categoryId.value = value == null || value.isEmpty ? null : value;
    await loadProducts();
  }

  Future<void> initializeForm(String? productId) async {
    _synchronizeSession();
    batch(() {
      formLoading.value = true;
      formError.value = null;
      editingProduct.value = null;
    });
    try {
      final optionsFuture = _repository.getFormOptions(
        sessionToken: _sessionToken,
      );
      final productFuture = productId == null
          ? Future<ProductDetail?>.value(null)
          : _repository
              .getProduct(sessionToken: _sessionToken, productId: productId)
              .then<ProductDetail?>((value) => value);
      final results = await Future.wait<dynamic>([optionsFuture, productFuture]);
      final options = results[0] as ProductFormOptions;
      final product = results[1] as ProductDetail?;
      batch(() {
        formOptions.value = options;
        permissions.value = options.permissions;
        editingProduct.value = product ?? ProductDetail.empty();
      });
    } catch (error) {
      formError.value = _messageFor(error);
    } finally {
      formLoading.value = false;
    }
  }

  Future<ProductDetail?> saveProduct(
    ProductDetail product, {
    String? imageFileName,
    String? imageMimeType,
    String? imageBase64,
  }) async {
    if (saving.value) return null;
    final validation = _validate(product);
    if (validation != null) {
      formError.value = validation;
      return null;
    }
    batch(() {
      saving.value = true;
      formError.value = null;
    });
    try {
      var saved = await _repository.saveProduct(
        sessionToken: _sessionToken,
        product: product.toRequest(),
      );
      if (imageBase64 != null &&
          imageBase64.isNotEmpty &&
          imageFileName != null &&
          imageMimeType != null &&
          saved.id != null) {
        saved = await _repository.uploadImage(
          sessionToken: _sessionToken,
          productId: saved.id!,
          fileName: imageFileName,
          mimeType: imageMimeType,
          base64: imageBase64,
        );
      }
      await loadProducts();
      return saved;
    } catch (error) {
      formError.value = _messageFor(error);
      return null;
    } finally {
      saving.value = false;
    }
  }

  Future<bool> deleteProduct(ProductSummary product) async {
    if (deleting.value) return false;
    batch(() {
      deleting.value = true;
      listError.value = null;
    });
    try {
      await _repository.deleteProduct(
        sessionToken: _sessionToken,
        productId: product.id,
      );
      await loadProducts();
      return true;
    } catch (error) {
      listError.value = _messageFor(error);
      return false;
    } finally {
      deleting.value = false;
    }
  }

  Future<ProductImportResult?> importProducts({
    required String fileName,
    required String base64,
  }) async {
    if (importing.value) return null;
    batch(() {
      importing.value = true;
      listError.value = null;
    });
    try {
      final result = await _repository.importProducts(
        sessionToken: _sessionToken,
        fileName: fileName,
        base64: base64,
      );
      await loadProducts();
      return result;
    } catch (error) {
      listError.value = _messageFor(error);
      return null;
    } finally {
      importing.value = false;
    }
  }

  Future<ProductExport?> exportProducts({
    required String format,
    required String scope,
  }) async {
    if (exporting.value) return null;
    batch(() {
      exporting.value = true;
      listError.value = null;
    });
    try {
      return await _repository.exportProducts(
        sessionToken: _sessionToken,
        format: format,
        scope: scope,
      );
    } catch (error) {
      listError.value = _messageFor(error);
      return null;
    } finally {
      exporting.value = false;
    }
  }

  Future<bool> deleteAllImages() async {
    if (deletingImages.value) return false;
    batch(() {
      deletingImages.value = true;
      listError.value = null;
    });
    try {
      await _repository.deleteAllImages(sessionToken: _sessionToken);
      await loadProducts();
      return true;
    } catch (error) {
      listError.value = _messageFor(error);
      return false;
    } finally {
      deletingImages.value = false;
    }
  }

  void prepareAnotherProduct() {
    batch(() {
      editingProduct.value = ProductDetail.empty();
      formError.value = null;
    });
  }

  void clearFormError() => formError.value = null;

  String? _validate(ProductDetail product) {
    if (product.name.trim().length < 2) return 'Informe o nome do produto.';
    if (product.code.trim().isEmpty) return 'Informe o código ou SKU.';
    if (product.code.trim().length > 80) return 'O código deve ter no máximo 80 caracteres.';
    if (product.unit.isEmpty) return 'Selecione a unidade de medida.';
    if (product.minimumQuantity <= 0) return 'O múltiplo de venda deve ser maior que zero.';
    if (product.listPrice < 0) return 'O preço de tabela não pode ser negativo.';
    if (product.commissionPercent < 0 || product.commissionPercent > 100) {
      return 'A comissão deve ficar entre 0% e 100%.';
    }
    if (product.ipiPercent < 0 || product.ipiPercent > 100) {
      return 'O IPI deve ficar entre 0% e 100%.';
    }
    final measures = [
      product.netWeight,
      product.grossWeight,
      product.width,
      product.height,
      product.length,
    ];
    if (measures.whereType<double>().any((value) => value < 0)) {
      return 'Peso e dimensões não podem ser negativos.';
    }
    if (product.trackStock && (product.availableStock ?? 0) < 0) {
      return 'O estoque disponível não pode ser negativo.';
    }
    return null;
  }

  void _synchronizeSession() {
    final token = _authController.sessionToken.value;
    if (_dataSessionToken == token) return;
    _dataSessionToken = token;
    _listRequestId++;
    batch(() {
      listLoading.value = false;
      formLoading.value = false;
      products.value = [];
      pagination.value = null;
      categories.value = [];
      permissions.value = ProductPermissions.initial;
      query.value = '';
      visibility.value = 'active';
      categoryId.value = null;
      formOptions.value = null;
      editingProduct.value = null;
      listError.value = null;
      formError.value = null;
    });
  }

  String get _sessionToken {
    final token = _authController.sessionToken.value;
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'Sua sessão expirou. Entre novamente.',
        code: 209,
      );
    }
    return token;
  }

  String _messageFor(Object error) {
    if (error is ApiException) {
      switch (error.code) {
        case 209:
          return 'Sua sessão expirou. Entre novamente.';
        case 9500:
          return 'Você não possui permissão para acessar os produtos.';
        case 9501:
          return 'Produto não localizado.';
        case 9502:
          return 'Já existe um produto com este código na empresa.';
        case 9503:
          return 'Revise os dados informados.';
        case 9504:
          return 'Este produto possui pedidos e não pode ser excluído. Desative-o.';
        case 9505:
          return 'A imagem é inválida. Use JPG, PNG ou WebP com até 2 MB.';
        case 9506:
          return 'A planilha é inválida. Use CSV ou XLSX com até 8 MB.';
        case 9507:
          return 'Não foi possível gerar o arquivo solicitado.';
        case 9508:
          return 'Categoria inválida ou pertencente a outra empresa.';
        default:
          return error.message;
      }
    }
    if (error is FormatException) return error.message.toString();
    return 'Não foi possível concluir a operação de produtos.';
  }
}
