import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:signals/signals_flutter.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';
import 'package:sistem_cormex/Src/Models/logisticsModels.dart';
import 'package:sistem_cormex/Src/Pages/Logistics/Components/logisticsCommon.dart';
import 'package:sistem_cormex/Src/Pages/Logistics/Controller/logisticsController.dart';

Future<bool?> showRouteEditorSheet(
  BuildContext context, {
  required LogisticsController controller,
}) {
  controller.resetRouteDraft();
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180, maxHeight: 850),
        child: _RouteEditor(controller: controller),
      ),
    ),
  );
}

class _RouteEditor extends StatefulWidget {
  const _RouteEditor({required this.controller});

  final LogisticsController controller;

  @override
  State<_RouteEditor> createState() => _RouteEditorState();
}

class _RouteEditorState extends State<_RouteEditor> {
  late final TextEditingController nameController;
  late final TextEditingController candidateSearchController;
  late final TextEditingController customOriginController;
  Timer? searchDebounce;

  DateTime routeDate = DateTime.now();
  String kind = 'all';
  String originMode = 'company';
  String? driverId;
  String? vehicleId;
  bool returnToOrigin = false;
  final selectedCities = <String>{};
  double? currentLatitude;
  double? currentLongitude;
  bool locating = false;

  LogisticsController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: 'Rota ${logisticsDate(routeDate)}',
    );
    candidateSearchController = TextEditingController();
    customOriginController = TextEditingController();
    final options = controller.bootstrap.value;
    driverId = options.drivers.isEmpty ? null : options.drivers.first.id;
    vehicleId = options.vehicles.isEmpty ? null : options.vehicles.first.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCandidates());
  }

  @override
  void dispose() {
    searchDebounce?.cancel();
    nameController.dispose();
    candidateSearchController.dispose();
    customOriginController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Criar rota inteligente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            Text(
              'Selecione as paradas e deixe o sistema definir a melhor ordem.',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Fechar',
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.close_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 850;
          final setup = _SetupPanel(
            child: _buildSetup(context),
          );
          final candidates = _CandidatesPanel(
            child: _buildCandidates(context),
          );
          if (compact) {
            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const Material(
                    color: Colors.white,
                    child: TabBar(
                      tabs: [
                        Tab(text: 'Configuração'),
                        Tab(text: 'Paradas'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(children: [setup, candidates]),
                  ),
                ],
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 370, child: setup),
              const VerticalDivider(width: 1),
              Expanded(child: candidates),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildActions(),
    );
  }

  Widget _buildSetup(BuildContext context) {
    final options = controller.bootstrap.value;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const _EditorTitle(
          icon: Icons.tune_rounded,
          title: 'Configuração',
          description: 'Defina origem, região e responsável.',
        ),
        const SizedBox(height: 18),
        TextField(
          controller: nameController,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'Nome da rota *',
            hintText: 'Ex.: Entregas Navegantes — manhã',
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Data da rota',
              suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
            ),
            child: Text(logisticsDate(routeDate)),
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: originMode,
          decoration: const InputDecoration(labelText: 'Ponto de partida'),
          items: const [
            DropdownMenuItem(
              value: 'company',
              child: Text('Endereço da empresa'),
            ),
            DropdownMenuItem(
              value: 'current',
              child: Text('Minha localização atual'),
            ),
            DropdownMenuItem(
              value: 'custom',
              child: Text('Outro endereço'),
            ),
          ],
          onChanged: (value) async {
            if (value == null) return;
            setState(() => originMode = value);
            if (value == 'current') await _captureCurrentLocation();
          },
        ),
        if (originMode == 'custom') ...[
          const SizedBox(height: 12),
          TextField(
            controller: customOriginController,
            decoration: const InputDecoration(
              labelText: 'Endereço de partida *',
              hintText: 'Rua, número, cidade e estado',
            ),
          ),
        ],
        if (originMode == 'current') ...[
          const SizedBox(height: 9),
          Row(
            children: [
              Icon(
                currentLatitude == null
                    ? Icons.location_searching_rounded
                    : Icons.my_location_rounded,
                size: 16,
                color: currentLatitude == null
                    ? AppColors.muted
                    : const Color(0xFF14734E),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  locating
                      ? 'Obtendo localização...'
                      : currentLatitude == null
                          ? 'Localização ainda não autorizada'
                          : 'Localização capturada',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ),
              TextButton(
                onPressed: locating ? null : _captureCurrentLocation,
                child: const Text('Atualizar'),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: kind,
          decoration: const InputDecoration(labelText: 'Tipo de parada'),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Visitas e entregas')),
            DropdownMenuItem(value: 'delivery', child: Text('Somente entregas')),
            DropdownMenuItem(value: 'visit', child: Text('Somente visitas')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => kind = value);
            _loadCandidates();
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Cidades',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (options.cities.isEmpty)
          const Text(
            'Nenhuma cidade retornada pela API. A busca considerará todas.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          )
        else
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: options.cities.map((city) {
              final selected = selectedCities.contains(city.id);
              return FilterChip(
                selected: selected,
                label: Text(city.label),
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      selectedCities.add(city.id);
                    } else {
                      selectedCities.remove(city.id);
                    }
                  });
                  _loadCandidates();
                },
              );
            }).toList(),
          ),
        const SizedBox(height: 16),
        if (options.drivers.isNotEmpty)
          DropdownButtonFormField<String>(
            value: driverId,
            decoration: const InputDecoration(labelText: 'Motorista/vendedor'),
            items: options.drivers
                .map(
                  (driver) => DropdownMenuItem(
                    value: driver.id,
                    child: Text(driver.label),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => driverId = value),
          ),
        if (options.vehicles.isNotEmpty) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: vehicleId,
            decoration: const InputDecoration(labelText: 'Veículo'),
            items: options.vehicles
                .map(
                  (vehicle) => DropdownMenuItem(
                    value: vehicle.id,
                    child: Text(vehicle.label),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => vehicleId = value),
          ),
        ],
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Retornar ao ponto de partida',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          subtitle: const Text(
            'Inclui o retorno no cálculo de distância e tempo.',
            style: TextStyle(fontSize: 10.5),
          ),
          value: returnToOrigin,
          onChanged: (value) => setState(() => returnToOrigin = value),
        ),
      ],
    );
  }

  Widget _buildCandidates(BuildContext context) {
    return Watch((context) {
      final candidates = controller.routeCandidates.value;
      final selected = controller.selectedCandidateIds.value;
      final preview = controller.optimizedPreview.value;
      final loading = controller.candidatesLoading.value;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Expanded(
                  child: _EditorTitle(
                    icon: Icons.pin_drop_outlined,
                    title: 'Paradas disponíveis',
                    description: 'Pedidos e visitas encontrados na região.',
                  ),
                ),
                Text(
                  '${selected.length} selecionadas',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: candidateSearchController,
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar cliente, pedido ou endereço',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: (value) {
                      searchDebounce?.cancel();
                      searchDebounce = Timer(
                        const Duration(milliseconds: 400),
                        _loadCandidates,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Atualizar clientes',
                  onPressed: loading ? null : _loadCandidates,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Checkbox(
                  value: candidates.isNotEmpty &&
                      selected.length ==
                          candidates.where((item) => item.hasValidAddress).length,
                  onChanged: candidates.isEmpty
                      ? null
                      : (value) => controller.selectAllCandidates(value == true),
                ),
                const Text(
                  'Selecionar todos com endereço válido',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: preview != null
                ? _RoutePreview(
                    route: preview,
                    onBack: () => controller.optimizedPreview.value = null,
                  )
                : candidates.isEmpty && !loading
                    ? const _EmptyCandidates()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
                        itemCount: candidates.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final candidate = candidates[index];
                          return _CandidateTile(
                            candidate: candidate,
                            selected: selected.contains(candidate.id),
                            onChanged: candidate.hasValidAddress
                                ? (value) => controller.toggleCandidate(
                                      candidate.id,
                                      value,
                                    )
                                : null,
                          );
                        },
                      ),
          ),
        ],
      );
    });
  }

  Widget _buildActions() {
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Watch((context) {
            final saving = controller.savingRoute.value;
            final optimizing = controller.optimizing.value;
            final preview = controller.optimizedPreview.value;
            return Row(
              children: [
                if (controller.error.value != null)
                  Expanded(
                    child: Text(
                      controller.error.value!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: saving || optimizing ? null : _optimize,
                  icon: optimizing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(preview == null ? 'Otimizar rota' : 'Recalcular'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: saving || optimizing || preview == null ? null : _save,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Salvar rota'),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: routeDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => routeDate = picked);
    await _loadCandidates();
  }

  Future<void> _loadCandidates() {
    return controller.loadRouteCandidates(
      routeDate: routeDate,
      cities: selectedCities.toList(),
      kind: kind,
      query: candidateSearchController.text,
    );
  }

  Future<void> _captureCurrentLocation() async {
    setState(() => locating = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw const FormatException('Ative a localização do aparelho.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const FormatException('Autorize o acesso à localização.');
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        currentLatitude = position.latitude;
        currentLongitude = position.longitude;
      });
    } catch (exception) {
      controller.error.value = exception is FormatException
          ? exception.message.toString()
          : 'Não foi possível obter sua localização.';
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Map<String, dynamic> _request() {
    return {
      'name': nameController.text.trim(),
      'routeDate': routeDate.toUtc().toIso8601String(),
      'originMode': originMode,
      'originAddress': originMode == 'custom'
          ? {'label': customOriginController.text.trim()}
          : null,
      'originCoordinates': originMode == 'current'
          ? {
              'latitude': currentLatitude,
              'longitude': currentLongitude,
            }
          : null,
      'cities': selectedCities.toList(),
      'kind': kind,
      'driverId': driverId,
      'vehicleId': vehicleId,
      'returnToOrigin': returnToOrigin,
      'provider': 'google_routes',
    };
  }

  Future<bool> _ensureOrigin() async {
    if (originMode == 'custom' && customOriginController.text.trim().isEmpty) {
      controller.error.value = 'Informe o endereço de partida.';
      return false;
    }
    if (originMode == 'current' && currentLatitude == null) {
      await _captureCurrentLocation();
      return currentLatitude != null;
    }
    return true;
  }

  Future<void> _optimize() async {
    if (!await _ensureOrigin()) return;
    await controller.optimizeRoute(_request());
  }

  Future<void> _save() async {
    if (!await _ensureOrigin()) return;
    final saved = await controller.saveRoute(_request());
    if (!mounted || saved == null) return;
    Navigator.pop(context, true);
  }
}

class _SetupPanel extends StatelessWidget {
  const _SetupPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: Colors.white, child: child);
  }
}

class _CandidatesPanel extends StatelessWidget {
  const _CandidatesPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: AppColors.canvas, child: child);
  }
}

class _EditorTitle extends StatelessWidget {
  const _EditorTitle({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.cyan.withOpacity(.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.cyan, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                description,
                style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.candidate,
    required this.selected,
    required this.onChanged,
  });

  final RouteCandidate candidate;
  final bool selected;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.cyan.withOpacity(.07) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(
          color: selected ? AppColors.cyan : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!selected),
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: onChanged == null
                    ? null
                    : (value) => onChanged!(value == true),
              ),
              const SizedBox(width: 4),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: candidate.kind == 'delivery'
                      ? AppColors.navy.withOpacity(.08)
                      : AppColors.cyan.withOpacity(.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  candidate.kind == 'delivery'
                      ? Icons.local_shipping_outlined
                      : Icons.handshake_outlined,
                  color: candidate.kind == 'delivery'
                      ? AppColors.navy
                      : AppColors.cyan,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            candidate.clientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        LogisticsStatusBadge(
                          status: 'ready',
                          label: candidate.kindLabel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      candidate.address.formatted.isEmpty
                          ? 'Endereço incompleto — revise o cadastro do cliente'
                          : candidate.address.formatted,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: candidate.hasValidAddress
                            ? AppColors.muted
                            : AppColors.danger,
                        fontSize: 10.5,
                      ),
                    ),
                    if (candidate.referenceLabel.isNotEmpty)
                      Text(
                        candidate.referenceLabel,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutePreview extends StatelessWidget {
  const _RoutePreview({required this.route, required this.onBack});

  final RoutePlan route;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 17),
              label: const Text('Editar seleção'),
            ),
            const Spacer(),
            Text(
              '${route.distanceKm.toStringAsFixed(1)} km • ${logisticsDuration(route.durationSeconds)}',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(height: 260, child: LogisticsRouteMap(route: route)),
        const SizedBox(height: 14),
        ...route.stops.map(
          (stop) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.lime,
              child: Text(
                '${stop.sequence}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
              ),
            ),
            title: Text(
              stop.clientName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              '${stop.kindLabel} • ${stop.address.formatted}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5),
            ),
            trailing: Text(
              logisticsDateTime(stop.estimatedArrival).split(' às ').last,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCandidates extends StatelessWidget {
  const _EmptyCandidates();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined, size: 44, color: AppColors.muted),
            SizedBox(height: 10),
            Text(
              'Nenhuma parada encontrada',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Altere a cidade, o tipo ou a data para localizar clientes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
