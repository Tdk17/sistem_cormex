import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Dependencies/dependencies.dart';
import 'package:sistem_cormex/Src/Models/productModels.dart';
import 'package:sistem_cormex/Src/Pages/Orders/Components/orderCommon.dart';
import 'package:sistem_cormex/Src/Pages/Products/Controller/productsController.dart';
import 'package:sistem_cormex/Src/Routes/appRouter.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late final ProductsController controller;
  late final TextEditingController searchController;
  Timer? debounce;

  @override
  void initState() {
    super.initState();
    controller = getIt<ProductsController>();
    searchController = TextEditingController(text: controller.query.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.initializeList();
    });
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrdersScaffold(
      floatingActionButton: MediaQuery.sizeOf(context).width < 650
          ? Watch((context) => FloatingActionButton.extended(
                onPressed: controller.permissions.value.canCreate
                    ? () => context.go(AppRoutes.productNew)
                    : null,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Cadastrar'),
              ))
          : null,
      child: Scrollbar(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 42),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrdersPageHeader(
                    title: 'Produtos',
                    description: 'Organize o catálogo, preços, imagens, estoque e variações.',
                    actions: [
                      OutlinedButton.icon(
                        onPressed: controller.loadProducts,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Atualizar'),
                      ),
                      if (MediaQuery.sizeOf(context).width >= 650)
                        Watch((context) => FilledButton.icon(
                              onPressed: controller.permissions.value.canCreate
                                  ? () => context.go(AppRoutes.productNew)
                                  : null,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Cadastrar produto'),
                              style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                            )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ProductSections(),
                  const SizedBox(height: 12),
                  Watch((context) => _ProductToolbar(
                        controller: controller,
                        searchController: searchController,
                        onSearchChanged: _scheduleSearch,
                        onImport: controller.permissions.value.canImport
                            ? () => _importFile(context)
                            : null,
                        onMore: controller.permissions.value.canExport
                            ? (value) => _handleMore(context, value)
                            : null,
                      )),
                  const SizedBox(height: 14),
                  _ProductsContent(controller: controller, onDelete: _delete),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _scheduleSearch(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 450), () {
      controller.applySearch(value);
    });
  }

  Future<void> _delete(BuildContext context, ProductSummary product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir produto?'),
        content: Text('Deseja excluir “${product.name}”? Produtos usados em pedidos deverão ser apenas desativados.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await controller.deleteProduct(product);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Produto excluído.' : controller.listError.value ?? 'Não foi possível excluir.')),
    );
  }

  Future<void> _importFile(BuildContext context) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx'],
    );
    if (picked.isEmpty) return;
    final file = picked.single;
    final bytes = await file.readAsBytes();
    if (bytes.length > 8 * 1024 * 1024) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O arquivo deve ter no máximo 8 MB.')),
        );
      }
      return;
    }
    final result = await controller.importProducts(
      fileName: file.name,
      base64: base64Encode(bytes),
    );
    if (!context.mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.listError.value ?? 'Não foi possível importar os produtos.')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Importação concluída'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${result.created} produtos criados'),
            Text('${result.updated} produtos atualizados'),
            Text('${result.skipped} linhas ignoradas'),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Ocorrências:', style: TextStyle(fontWeight: FontWeight.w800)),
              ...result.errors.take(5).map((message) => Text(message)),
            ],
          ],
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Concluir'))],
      ),
    );
  }

  Future<void> _handleMore(BuildContext context, String value) async {
    if (value == 'delete_images') {
      await _deleteAllImages(context);
      return;
    }
    final parts = value.split(':');
    final result = await controller.exportProducts(
      format: parts.first,
      scope: parts.length > 1 ? parts.last : 'all',
    );
    if (!context.mounted) return;
    final url = result?.downloadUrl;
    if (url == null || !await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.listError.value ?? 'O arquivo ainda não está disponível.')),
        );
      }
    }
  }

  Future<void> _deleteAllImages(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir todas as imagens?'),
        content: const Text('Esta ação remove as imagens de todos os produtos da empresa e não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Excluir imagens'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await controller.deleteAllImages();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Imagens removidas.' : controller.listError.value ?? 'Não foi possível remover as imagens.')),
    );
  }
}

class _ProductSections extends StatelessWidget {
  const _ProductSections();

  @override
  Widget build(BuildContext context) {
    return OrderSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          const _SectionChip(icon: Icons.inventory_2_outlined, label: 'Produtos e tabelas', selected: true),
          _SectionChip(icon: Icons.warehouse_outlined, label: 'Gerenciar estoque', onTap: () => _comingSoon(context, 'Estoque')),
          _SectionChip(icon: Icons.add_photo_alternate_outlined, label: 'Importar fotos', onTap: () => _comingSoon(context, 'Importação de fotos')),
          _SectionChip(icon: Icons.sell_outlined, label: 'Promoções', onTap: () => _comingSoon(context, 'Promoções')),
          _SectionChip(icon: Icons.star_outline_rounded, label: 'Destaques', onTap: () => _comingSoon(context, 'Destaques')),
          _SectionChip(icon: Icons.settings_outlined, label: 'Configurações', onTap: () => _comingSoon(context, 'Configurações de produtos')),
        ],
      ),
    );
  }

  static void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label será conectado na próxima etapa.')));
  }
}

class _SectionChip extends StatelessWidget {
  const _SectionChip({required this.icon, required this.label, this.selected = false, this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: selected ? AppColors.lime : AppColors.muted),
            const SizedBox(width: 7),
            Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.muted, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ProductToolbar extends StatelessWidget {
  const _ProductToolbar({
    required this.controller,
    required this.searchController,
    required this.onSearchChanged,
    required this.onImport,
    required this.onMore,
  });

  final ProductsController controller;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onImport;
  final ValueChanged<String>? onMore;

  @override
  Widget build(BuildContext context) {
    return OrderSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(onPressed: onImport, icon: const Icon(Icons.upload_file_outlined), label: const Text('Importar produtos')),
              PopupMenuButton<String>(
                enabled: onMore != null,
                onSelected: onMore,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'pdf:price_table', child: _MenuLabel(Icons.picture_as_pdf_outlined, 'Baixar tabela de preços em PDF')),
                  PopupMenuItem(value: 'xlsx:active', child: _MenuLabel(Icons.table_view_outlined, 'Exportar produtos ativos')),
                  PopupMenuItem(value: 'xlsx:all', child: _MenuLabel(Icons.table_view_outlined, 'Exportar todos os produtos')),
                  PopupMenuItem(value: 'zip:images', child: _MenuLabel(Icons.photo_library_outlined, 'Exportar todas as imagens')),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'delete_images', child: _MenuLabel(Icons.delete_outline_rounded, 'Excluir todas as imagens', danger: true)),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.more_horiz_rounded, color: onMore == null ? AppColors.muted : AppColors.navy),
                      const SizedBox(width: 8),
                      Text(
                        'Mais opções',
                        style: TextStyle(
                          color: onMore == null ? AppColors.muted : AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final search = ValueListenableBuilder<TextEditingValue>(
              valueListenable: searchController,
              builder: (context, value, _) => TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                onSubmitted: controller.applySearch,
                decoration: InputDecoration(
                  hintText: 'Pesquise por código ou nome',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            searchController.clear();
                            controller.applySearch('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            );
            final visibility = DropdownButtonFormField<String>(
              value: controller.visibility.value,
              decoration: const InputDecoration(labelText: 'Exibir produtos'),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Ativos')),
                DropdownMenuItem(value: 'inactive', child: Text('Inativos')),
                DropdownMenuItem(value: 'all', child: Text('Todos')),
              ],
              onChanged: controller.listLoading.value ? null : (value) { if (value != null) controller.changeVisibility(value); },
            );
            final category = DropdownButtonFormField<String>(
              value: controller.categoryId.value ?? '',
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Todas as categorias')),
                ...controller.categories.value.map((item) => DropdownMenuItem(value: item.id, child: Text(item.label))),
              ],
              onChanged: controller.listLoading.value ? null : controller.changeCategory,
            );
            if (constraints.maxWidth < 850) {
              return Column(children: [search, const SizedBox(height: 10), category, const SizedBox(height: 10), visibility]);
            }
            return Row(children: [Expanded(flex: 4, child: search), const SizedBox(width: 10), Expanded(flex: 2, child: category), const SizedBox(width: 10), Expanded(flex: 2, child: visibility)]);
          }),
        ],
      ),
    );
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel(this.icon, this.label, {this.danger = false});
  final IconData icon;
  final String label;
  final bool danger;
  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, size: 18, color: danger ? AppColors.danger : AppColors.navy), const SizedBox(width: 9), Text(label, style: TextStyle(color: danger ? AppColors.danger : null))]);
}

class _ProductsContent extends StatelessWidget {
  const _ProductsContent({required this.controller, required this.onDelete});
  final ProductsController controller;
  final void Function(BuildContext, ProductSummary) onDelete;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final loading = controller.listLoading.value;
      final error = controller.listError.value;
      final products = controller.products.value;
      final page = controller.pagination.value;
      final permissions = controller.permissions.value;
      return OrderSurface(
        padding: EdgeInsets.zero,
        child: Column(children: [
          if (loading) const LinearProgressIndicator(minHeight: 2),
          if (error != null) Padding(padding: const EdgeInsets.all(14), child: OrderInlineError(message: error, onRetry: controller.loadProducts)),
          if (!loading && products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(34),
              child: Column(children: [Icon(Icons.inventory_2_outlined, size: 46, color: AppColors.muted), SizedBox(height: 10), Text('Nenhum produto encontrado', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), SizedBox(height: 4), Text('Ajuste os filtros ou cadastre o primeiro produto.', style: TextStyle(color: AppColors.muted))]),
            )
          else
            LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return Column(children: products.map((product) => _ProductMobileCard(product: product, canEdit: permissions.canEdit, canDelete: permissions.canDelete, onDelete: () => onDelete(context, product))).toList());
              }
              return _ProductTable(products: products, canEdit: permissions.canEdit, canDelete: permissions.canDelete, onDelete: (product) => onDelete(context, product));
            }),
          if (page != null)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${page.totalItems} produtos', style: const TextStyle(color: AppColors.muted)),
                if (page.totalPages > 1)
                  Row(children: [
                    IconButton.outlined(onPressed: loading || page.page <= 1 ? null : () => controller.loadProducts(page: page.page - 1), icon: const Icon(Icons.chevron_left_rounded)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('${page.page} de ${page.totalPages}', style: const TextStyle(fontWeight: FontWeight.w800))),
                    IconButton.outlined(onPressed: loading || !page.hasNextPage ? null : () => controller.loadProducts(page: page.page + 1), icon: const Icon(Icons.chevron_right_rounded)),
                  ]),
              ]),
            ),
        ]),
      );
    });
  }
}

class _ProductTable extends StatelessWidget {
  const _ProductTable({required this.products, required this.canEdit, required this.canDelete, required this.onDelete});
  final List<ProductSummary> products;
  final bool canEdit;
  final bool canDelete;
  final ValueChanged<ProductSummary> onDelete;

  @override
  Widget build(BuildContext context) {
    const header = TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w900);
    return Column(children: [
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [SizedBox(width: 62, child: Text('FOTO', style: header)), Expanded(flex: 2, child: Text('CÓDIGO', style: header)), Expanded(flex: 5, child: Text('NOME', style: header)), Expanded(flex: 2, child: Text('VARIAÇÕES', style: header)), Expanded(flex: 2, child: Text('IPI', style: header)), Expanded(flex: 2, child: Text('UNIDADE', style: header)), Expanded(flex: 2, child: Text('COMISSÃO', style: header)), Expanded(flex: 2, child: Text('PREÇO', style: header)), SizedBox(width: 88)]),
      ),
      const Divider(height: 1),
      ...products.map((product) => InkWell(
            onTap: canEdit ? () => context.go(AppRoutes.productById(product.id)) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(children: [
                SizedBox(width: 62, child: _ProductImage(product: product, size: 40)),
                Expanded(flex: 2, child: Text(product.code, style: const TextStyle(fontWeight: FontWeight.w700))),
                Expanded(flex: 5, child: Row(children: [Flexible(child: Text(product.name, style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w900))), if (!product.active) const Padding(padding: EdgeInsets.only(left: 7), child: Chip(label: Text('Inativo'), visualDensity: VisualDensity.compact))])),
                Expanded(flex: 2, child: Text(product.variationCount == 0 ? '—' : '${product.variationCount}')),
                Expanded(flex: 2, child: Text(product.ipiPercent == 0 ? '—' : '${_number(product.ipiPercent)}%')),
                Expanded(flex: 2, child: Text(product.unit)),
                Expanded(flex: 2, child: Text('${_number(product.commissionPercent)}%')),
                Expanded(flex: 2, child: Text(_money(product.listPrice), style: const TextStyle(fontWeight: FontWeight.w900))),
                SizedBox(width: 88, child: Row(children: [IconButton(onPressed: canEdit ? () => context.go(AppRoutes.productById(product.id)) : null, tooltip: 'Editar', icon: const Icon(Icons.edit_outlined, size: 19)), IconButton(onPressed: canDelete ? () => onDelete(product) : null, tooltip: 'Excluir', color: AppColors.danger, icon: const Icon(Icons.delete_outline_rounded, size: 19))])),
              ]),
            ),
          )),
    ]);
  }
}

class _ProductMobileCard extends StatelessWidget {
  const _ProductMobileCard({required this.product, required this.canEdit, required this.canDelete, required this.onDelete});
  final ProductSummary product;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: canEdit ? () => context.go(AppRoutes.productById(product.id)) : null,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ProductImage(product: product, size: 58),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.navy)),
            const SizedBox(height: 3),
            Text('${product.code} • ${product.unit} • ${product.categoryName.isEmpty ? 'Sem categoria' : product.categoryName}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 7),
            Text(_money(product.listPrice), style: const TextStyle(fontWeight: FontWeight.w900)),
          ])),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') context.go(AppRoutes.productById(product.id));
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', enabled: canEdit, child: const Text('Alterar')),
              PopupMenuItem(value: 'delete', enabled: canDelete, child: const Text('Excluir')),
            ],
          ),
        ]),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product, required this.size});
  final ProductSummary product;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(9), border: Border.all(color: AppColors.border)),
      child: product.imageUrl == null
          ? const Icon(Icons.image_outlined, color: AppColors.muted)
          : Image.network(product.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: AppColors.muted)),
    );
    if (product.imageUrl == null) return image;
    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => Dialog(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720), child: Image.network(product.imageUrl!, fit: BoxFit.contain))),
      ),
      child: image,
    );
  }
}

String _money(double value) => 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
String _number(double value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2).replaceAll('.', ',');
