import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Dependencies/dependencies.dart';
import 'package:sistem_cormex/Src/Models/productModels.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Components/orderCommon.dart';
import 'package:sistem_cormex/Src/Pages/Products/Controller/productsController.dart';
import 'package:sistem_cormex/Src/Routes/appRouter.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.productId});

  final String? productId;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  late final ProductsController controller;

  @override
  void initState() {
    super.initState();
    controller = getIt<ProductsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeForm(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return OrdersScaffold(
      child: Watch((context) {
        final loading = controller.formLoading.value;
        final error = controller.formError.value;
        final options = controller.formOptions.value;
        final product = controller.editingProduct.value;
        if (loading || (product == null && error == null)) {
          return const Center(child: CircularProgressIndicator());
        }
        if (product == null || options == null) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: OrderSurface(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.danger),
                  const SizedBox(height: 12),
                  Text(error ?? 'Não foi possível abrir o produto.'),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => controller.initializeForm(widget.productId),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tentar novamente'),
                  ),
                ]),
              ),
            ),
          );
        }
        return _ProductEditor(
          key: ValueKey('${product.id}-${identityHashCode(product)}'),
          controller: controller,
          options: options,
          initial: product,
        );
      }),
    );
  }
}

class _ProductEditor extends StatefulWidget {
  const _ProductEditor({
    super.key,
    required this.controller,
    required this.options,
    required this.initial,
  });

  final ProductsController controller;
  final ProductFormOptions options;
  final ProductDetail initial;

  @override
  State<_ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<_ProductEditor> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController code;
  late final TextEditingController minimumQuantity;
  late final TextEditingController listPrice;
  late final TextEditingController commissionPercent;
  late final TextEditingController ipiPercent;
  late final TextEditingController description;
  late final TextEditingController barcode;
  late final TextEditingController brand;
  late final TextEditingController notes;
  late final TextEditingController availableStock;
  late final TextEditingController netWeight;
  late final TextEditingController grossWeight;
  late final TextEditingController width;
  late final TextEditingController height;
  late final TextEditingController length;
  late String unit;
  late String currency;
  late String? categoryId;
  late bool active;
  late bool trackStock;
  late List<ProductVariant> variants;
  int selectedTab = 0;
  Uint8List? selectedImage;
  String? imageFileName;
  String? imageMimeType;

  bool get canEdit => widget.initial.isPersisted
      ? widget.options.permissions.canEdit
      : widget.options.permissions.canCreate;

  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    name = TextEditingController(text: value.name);
    code = TextEditingController(text: value.code);
    minimumQuantity = TextEditingController(text: _editableNumber(value.minimumQuantity));
    listPrice = TextEditingController(text: _editableNumber(value.listPrice));
    commissionPercent = TextEditingController(text: _editableNumber(value.commissionPercent));
    ipiPercent = TextEditingController(text: _editableNumber(value.ipiPercent));
    description = TextEditingController(text: value.description);
    barcode = TextEditingController(text: value.barcode);
    brand = TextEditingController(text: value.brand);
    notes = TextEditingController(text: value.notes);
    availableStock = TextEditingController(text: value.availableStock == null ? '' : _editableNumber(value.availableStock!));
    netWeight = TextEditingController(text: value.netWeight == null ? '' : _editableNumber(value.netWeight!));
    grossWeight = TextEditingController(text: value.grossWeight == null ? '' : _editableNumber(value.grossWeight!));
    width = TextEditingController(text: value.width == null ? '' : _editableNumber(value.width!));
    height = TextEditingController(text: value.height == null ? '' : _editableNumber(value.height!));
    length = TextEditingController(text: value.length == null ? '' : _editableNumber(value.length!));
    unit = value.unit;
    currency = value.currency;
    categoryId = value.categoryId;
    active = value.active;
    trackStock = value.trackStock;
    variants = List<ProductVariant>.from(value.variants);
  }

  @override
  void dispose() {
    for (final controller in [
      name,
      code,
      minimumQuantity,
      listPrice,
      commissionPercent,
      ipiPercent,
      description,
      barcode,
      brand,
      notes,
      availableStock,
      netWeight,
      grossWeight,
      width,
      height,
      length,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 112),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1450),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OrdersPageHeader(
                          title: widget.initial.isPersisted ? 'Alterar produto' : 'Novo produto',
                          description: 'Cadastre informações comerciais, preços, estoque, variações e dimensões.',
                          leading: IconButton.outlined(onPressed: () => context.go(AppRoutes.products), icon: const Icon(Icons.arrow_back_rounded)),
                          actions: widget.initial.isPersisted
                              ? [Chip(label: Text(active ? 'Produto ativo' : 'Produto inativo'), avatar: Icon(active ? Icons.check_circle_outline_rounded : Icons.block_rounded, size: 17))]
                              : const [],
                        ),
                        const SizedBox(height: 18),
                        if (!canEdit) ...[
                          const OrderInlineError(message: 'Você pode visualizar este produto, mas não possui permissão para alterá-lo.'),
                          const SizedBox(height: 14),
                        ],
                        _buildIdentity(),
                        const SizedBox(height: 16),
                        _buildTabs(),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: KeyedSubtree(key: ValueKey(selectedTab), child: _tabContent()),
                        ),
                        Watch((context) {
                          final error = widget.controller.formError.value;
                          return error == null
                              ? const SizedBox.shrink()
                              : Padding(padding: const EdgeInsets.only(top: 16), child: OrderInlineError(message: error));
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Align(alignment: Alignment.bottomCenter, child: _bottomBar()),
      ],
    );
  }

  Widget _buildIdentity() {
    return OrderSurface(
      child: LayoutBuilder(builder: (context, constraints) {
        final image = _ProductImagePicker(
          imageUrl: widget.initial.imageUrl,
          bytes: selectedImage,
          enabled: canEdit,
          onPick: _pickImage,
        );
        final fields = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const OrderSectionTitle(icon: Icons.inventory_2_outlined, title: 'Identificação', description: 'Dados principais usados no catálogo e nos pedidos.'),
          const SizedBox(height: 18),
          _FieldGrid(children: [
            TextFormField(controller: name, enabled: canEdit, validator: _required, decoration: const InputDecoration(labelText: 'Nome *', hintText: 'Nome comercial do produto')),
            TextFormField(controller: code, enabled: canEdit, validator: _required, decoration: const InputDecoration(labelText: 'Código / SKU *', hintText: 'SKU ou referência')),
            _optionField('Unidade de medida *', unit, _units, (value) => setState(() => unit = value ?? 'UN')),
            TextFormField(controller: minimumQuantity, enabled: canEdit, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _positive, decoration: const InputDecoration(labelText: 'Venda em múltiplos de *')),
            _optionField('Categoria', categoryId, widget.options.categories, (value) => setState(() => categoryId = value)),
          ]),
        ]);
        if (constraints.maxWidth < 760) {
          return Column(children: [image, const SizedBox(height: 18), fields]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [image, const SizedBox(width: 22), Expanded(child: fields)]);
      }),
    );
  }

  Widget _buildTabs() {
    const tabs = [
      (Icons.price_change_outlined, 'Tabelas de preço'),
      (Icons.info_outline_rounded, 'Informações gerais'),
      (Icons.account_tree_outlined, 'Variações'),
      (Icons.straighten_rounded, 'Peso e dimensões'),
    ];
    return OrderSurface(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: tabs.asMap().entries.map((entry) {
          final selected = selectedTab == entry.key;
          return InkWell(
            onTap: () => setState(() => selectedTab = entry.key),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(color: selected ? AppColors.navy : Colors.transparent, borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(entry.value.$1, size: 18, color: selected ? AppColors.lime : AppColors.muted), const SizedBox(width: 8), Text(entry.value.$2, style: TextStyle(color: selected ? Colors.white : AppColors.muted, fontWeight: FontWeight.w800))]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _tabContent() {
    switch (selectedTab) {
      case 1:
        return _buildGeneralInfo();
      case 2:
        return _buildVariations();
      case 3:
        return _buildDimensions();
      default:
        return _buildPrices();
    }
  }

  Widget _buildPrices() {
    return OrderSurface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const OrderSectionTitle(icon: Icons.payments_outlined, title: 'Tabela de preço', description: 'Preço padrão usado como base para orçamentos e pedidos.'),
        const SizedBox(height: 20),
        _FieldGrid(children: [
          _optionField('Moeda', currency, _currencies, (value) => setState(() => currency = value ?? 'BRL')),
          TextFormField(controller: listPrice, enabled: canEdit, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _nonNegative, decoration: InputDecoration(labelText: 'Preço de tabela *', prefixText: currency == 'BRL' ? 'R\$ ' : null)),
          TextFormField(controller: commissionPercent, enabled: canEdit, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _percent, decoration: const InputDecoration(labelText: 'Comissão', suffixText: '%')),
          TextFormField(controller: ipiPercent, enabled: canEdit, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _percent, decoration: const InputDecoration(labelText: 'IPI', suffixText: '%')),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.cyan.withOpacity(.08), borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.cyan.withOpacity(.22))),
          child: const Row(children: [Icon(Icons.info_outline_rounded, color: AppColors.cyan), SizedBox(width: 9), Expanded(child: Text('A API pode aplicar tabelas específicas por cliente. O preço definitivo do pedido sempre será recalculado no servidor.'))]),
        ),
      ]),
    );
  }

  Widget _buildGeneralInfo() {
    return OrderSurface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const OrderSectionTitle(icon: Icons.description_outlined, title: 'Informações gerais', description: 'Descrição, código de barras, marca, impostos e controle de estoque.'),
        const SizedBox(height: 20),
        _FieldGrid(children: [
          TextFormField(controller: barcode, enabled: canEdit, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Código de barras / EAN')),
          TextFormField(controller: brand, enabled: canEdit, decoration: const InputDecoration(labelText: 'Marca')),
          SwitchListTile.adaptive(contentPadding: const EdgeInsets.symmetric(horizontal: 10), title: const Text('Produto ativo', style: TextStyle(fontWeight: FontWeight.w800)), value: active, onChanged: canEdit ? (value) => setState(() => active = value) : null),
          SwitchListTile.adaptive(contentPadding: const EdgeInsets.symmetric(horizontal: 10), title: const Text('Controlar estoque', style: TextStyle(fontWeight: FontWeight.w800)), value: trackStock, onChanged: canEdit ? (value) => setState(() => trackStock = value) : null),
          if (trackStock)
            TextFormField(controller: availableStock, enabled: canEdit && widget.options.permissions.canManageStock, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _nonNegative, decoration: const InputDecoration(labelText: 'Estoque disponível')),
        ]),
        const SizedBox(height: 16),
        TextFormField(controller: description, enabled: canEdit, minLines: 3, maxLines: 7, decoration: const InputDecoration(labelText: 'Descrição comercial', hintText: 'Descrição que poderá aparecer no catálogo e no pedido.')),
        const SizedBox(height: 14),
        TextFormField(controller: notes, enabled: canEdit, minLines: 2, maxLines: 5, decoration: const InputDecoration(labelText: 'Observações internas')),
      ]),
    );
  }

  Widget _buildVariations() {
    return OrderSurface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        OrderSectionTitle(
          icon: Icons.account_tree_outlined,
          title: 'Variações',
          description: 'Cores, tamanhos, embalagens ou outras opções do produto.',
          trailing: canEdit ? OutlinedButton.icon(onPressed: () => _editVariant(), icon: const Icon(Icons.add_rounded), label: const Text('Adicionar variação')) : null,
        ),
        if (variants.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Center(child: Text('Nenhuma variação cadastrada.', style: TextStyle(color: AppColors.muted))))
        else ...[
          const SizedBox(height: 16),
          ...variants.asMap().entries.map((entry) {
            final variant = entry.value;
            final attributes = variant.attributes.entries.map((item) => '${item.key}: ${item.value}').join(' • ');
            return Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                const Icon(Icons.tune_rounded, color: AppColors.cyan),
                const SizedBox(width: 11),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(variant.name, style: const TextStyle(fontWeight: FontWeight.w900)), Text([variant.code, attributes, variant.priceAdjustment == 0 ? '' : 'Ajuste: ${variant.priceAdjustment}'].where((item) => item.isNotEmpty).join(' — '), style: const TextStyle(color: AppColors.muted, fontSize: 12))])),
                if (canEdit) IconButton(onPressed: () => _editVariant(index: entry.key), icon: const Icon(Icons.edit_outlined)),
                if (canEdit) IconButton(onPressed: () => setState(() => variants.removeAt(entry.key)), color: AppColors.danger, icon: const Icon(Icons.delete_outline_rounded)),
              ]),
            );
          }),
        ],
      ]),
    );
  }

  Widget _buildDimensions() {
    return OrderSurface(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const OrderSectionTitle(icon: Icons.straighten_rounded, title: 'Peso e dimensões', description: 'Informações usadas no cálculo logístico e de frete.'),
        const SizedBox(height: 20),
        _FieldGrid(children: [
          TextFormField(controller: netWeight, enabled: canEdit, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _optionalNonNegative, decoration: const InputDecoration(labelText: 'Peso líquido', suffixText: 'kg')),
          TextFormField(controller: grossWeight, enabled: canEdit, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _optionalNonNegative, decoration: const InputDecoration(labelText: 'Peso bruto', suffixText: 'kg')),
          TextFormField(controller: length, enabled: canEdit, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _optionalNonNegative, decoration: const InputDecoration(labelText: 'Comprimento', suffixText: 'cm')),
          TextFormField(controller: width, enabled: canEdit, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _optionalNonNegative, decoration: const InputDecoration(labelText: 'Largura', suffixText: 'cm')),
          TextFormField(controller: height, enabled: canEdit, keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: _optionalNonNegative, decoration: const InputDecoration(labelText: 'Altura', suffixText: 'cm')),
        ]),
      ]),
    );
  }

  Widget _bottomBar() {
    return Material(
      elevation: 12,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
          child: Watch((context) {
            final saving = widget.controller.saving.value;
            return Wrap(spacing: 9, runSpacing: 9, children: [
              FilledButton(
                onPressed: !canEdit || saving ? null : () => _save(false),
                style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Salvar'),
              ),
              if (!widget.initial.isPersisted)
                FilledButton.tonal(onPressed: !canEdit || saving ? null : () => _save(true), child: const Text('Salvar e cadastrar outro')),
              OutlinedButton(onPressed: saving ? null : () => context.go(AppRoutes.products), child: const Text('Cancelar')),
            ]);
          }),
        ),
      ),
    );
  }

  List<ProductOption> get _units => widget.options.units.isEmpty ? _defaultUnits : widget.options.units;
  List<ProductOption> get _currencies => widget.options.currencies.isEmpty ? _defaultCurrencies : widget.options.currencies;

  Widget _optionField(String label, String? value, List<ProductOption> options, ValueChanged<String?> onChanged) {
    final validValue = options.any((item) => item.id == value) ? value : null;
    return DropdownButtonFormField<String>(
      value: validValue,
      decoration: InputDecoration(labelText: label),
      items: [
        if (!label.contains('*')) const DropdownMenuItem(value: '', child: Text('Não informado')),
        ...options.map((item) => DropdownMenuItem(value: item.id, child: Text(item.label))),
      ],
      onChanged: canEdit ? (next) => onChanged(next == null || next.isEmpty ? null : next) : null,
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;
  String? _positive(String? value) => (_parse(value) ?? 0) <= 0 ? 'Informe um valor maior que zero' : null;
  String? _nonNegative(String? value) => (_parse(value) ?? -1) < 0 ? 'Informe um valor válido' : null;
  String? _optionalNonNegative(String? value) => value == null || value.trim().isEmpty ? null : (_parse(value) ?? -1) < 0 ? 'Informe um valor válido' : null;
  String? _percent(String? value) { final number = _parse(value); return number == null || number < 0 || number > 100 ? 'Use um valor entre 0 e 100' : null; }

  double? _parse(String? value) {
    final raw = (value ?? '').trim();
    final normalized = raw.contains(',')
        ? raw.replaceAll('.', '').replaceAll(',', '.')
        : raw;
    return normalized.isEmpty ? null : double.tryParse(normalized);
  }

  ProductDetail _value() {
    return ProductDetail(
      id: widget.initial.id,
      name: name.text,
      code: code.text,
      unit: unit,
      minimumQuantity: _parse(minimumQuantity.text) ?? 1,
      categoryId: categoryId,
      currency: currency,
      listPrice: _parse(listPrice.text) ?? 0,
      commissionPercent: _parse(commissionPercent.text) ?? 0,
      ipiPercent: _parse(ipiPercent.text) ?? 0,
      description: description.text,
      barcode: barcode.text,
      brand: brand.text,
      notes: notes.text,
      active: active,
      trackStock: trackStock,
      availableStock: trackStock ? _parse(availableStock.text) ?? 0 : null,
      netWeight: _parse(netWeight.text),
      grossWeight: _parse(grossWeight.text),
      width: _parse(width.text),
      height: _parse(height.text),
      length: _parse(length.text),
      imageUrl: widget.initial.imageUrl,
      variants: variants,
    );
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 88);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A imagem deve ter no máximo 2 MB.')));
      return;
    }
    final lower = file.name.toLowerCase();
    setState(() {
      selectedImage = bytes;
      imageFileName = file.name;
      imageMimeType = file.mimeType ?? (lower.endsWith('.png') ? 'image/png' : lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg');
    });
  }

  Future<void> _save(bool another) async {
    widget.controller.clearFormError();
    if (!(formKey.currentState?.validate() ?? false)) return;
    final saved = await widget.controller.saveProduct(
      _value(),
      imageFileName: imageFileName,
      imageMimeType: imageMimeType,
      imageBase64: selectedImage == null ? null : base64Encode(selectedImage!),
    );
    if (!mounted || saved == null) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produto salvo com sucesso.')));
    if (another) {
      widget.controller.prepareAnotherProduct();
    } else {
      context.go(AppRoutes.products);
    }
  }

  Future<void> _editVariant({int? index}) async {
    final result = await showDialog<ProductVariant>(
      context: context,
      builder: (_) => _VariantDialog(initial: index == null ? null : variants[index]),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (index == null) {
        variants.add(result);
      } else {
        variants[index] = result;
      }
    });
  }
}

class _ProductImagePicker extends StatelessWidget {
  const _ProductImagePicker({required this.imageUrl, required this.bytes, required this.enabled, required this.onPick});
  final String? imageUrl;
  final Uint8List? bytes;
  final bool enabled;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(children: [
        Container(
          width: 150,
          height: 150,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
          child: bytes != null
              ? Image.memory(bytes!, fit: BoxFit.cover)
              : imageUrl != null
                  ? Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 45, color: AppColors.muted))
                  : const Icon(Icons.add_photo_alternate_outlined, size: 45, color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: enabled ? onPick : null, icon: const Icon(Icons.upload_outlined, size: 18), label: Text(imageUrl == null && bytes == null ? 'Adicionar foto' : 'Alterar foto')),
        const SizedBox(height: 5),
        const Text('JPG, PNG ou WebP • até 2 MB', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 10.5)),
      ]),
    );
  }
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050 ? 3 : constraints.maxWidth >= 650 ? 2 : 1;
        final itemWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(spacing: 12, runSpacing: 12, children: children.map((child) => SizedBox(width: itemWidth, child: child)).toList());
      });
}

class _VariantDialog extends StatefulWidget {
  const _VariantDialog({this.initial});
  final ProductVariant? initial;
  @override
  State<_VariantDialog> createState() => _VariantDialogState();
}

class _VariantDialogState extends State<_VariantDialog> {
  late final TextEditingController name;
  late final TextEditingController code;
  late final TextEditingController attributes;
  late final TextEditingController price;
  late final TextEditingController stock;
  late bool active;

  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    name = TextEditingController(text: value?.name ?? '');
    code = TextEditingController(text: value?.code ?? '');
    attributes = TextEditingController(text: value?.attributes.entries.map((item) => '${item.key}=${item.value}').join('; ') ?? '');
    price = TextEditingController(text: value == null ? '0' : _editableNumber(value.priceAdjustment));
    stock = TextEditingController(text: value?.availableStock == null ? '' : _editableNumber(value!.availableStock!));
    active = value?.active ?? true;
  }

  @override
  void dispose() {
    name.dispose();
    code.dispose();
    attributes.dispose();
    price.dispose();
    stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Adicionar variação' : 'Editar variação'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome *', hintText: 'Ex.: Azul / Tamanho M')),
            const SizedBox(height: 10),
            TextField(controller: code, decoration: const InputDecoration(labelText: 'Código / SKU *')),
            const SizedBox(height: 10),
            TextField(controller: attributes, decoration: const InputDecoration(labelText: 'Atributos', hintText: 'Cor=Azul; Tamanho=M')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(labelText: 'Ajuste de preço'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: stock, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Estoque'))),
            ]),
            SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Variação ativa'), value: active, onChanged: (value) => setState(() => active = value)),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Salvar variação')),
      ],
    );
  }

  void _save() {
    if (name.text.trim().isEmpty || code.text.trim().isEmpty) return;
    final parsedAttributes = <String, String>{};
    for (final item in attributes.text.split(';')) {
      final parts = item.split('=');
      if (parts.length >= 2 && parts.first.trim().isNotEmpty) {
        parsedAttributes[parts.first.trim()] = parts.sublist(1).join('=').trim();
      }
    }
    Navigator.pop(
      context,
      ProductVariant(
        id: widget.initial?.id,
        name: name.text,
        code: code.text,
        attributes: parsedAttributes,
        priceAdjustment: _dialogParse(price.text) ?? 0,
        availableStock: _dialogParse(stock.text),
        active: active,
      ),
    );
  }
}

double? _dialogParse(String value) {
  final raw = value.trim();
  final normalized = raw.contains(',')
      ? raw.replaceAll('.', '').replaceAll(',', '.')
      : raw;
  return normalized.isEmpty ? null : double.tryParse(normalized);
}

String _editableNumber(double value) {
  final text = value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  return text.replaceAll('.', ',');
}

const _defaultUnits = <ProductOption>[
  ProductOption(id: 'UN', label: 'Unidade (UN)'),
  ProductOption(id: 'CX', label: 'Caixa (CX)'),
  ProductOption(id: 'KG', label: 'Quilograma (KG)'),
  ProductOption(id: 'LT', label: 'Litro (LT)'),
  ProductOption(id: 'PC', label: 'Peça (PC)'),
  ProductOption(id: 'PCT', label: 'Pacote (PCT)'),
];

const _defaultCurrencies = <ProductOption>[
  ProductOption(id: 'BRL', label: 'Real (R\$)'),
  ProductOption(id: 'USD', label: 'Dólar (US\$)'),
  ProductOption(id: 'EUR', label: 'Euro (€)'),
];
