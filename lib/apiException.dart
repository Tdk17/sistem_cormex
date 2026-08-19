import 'package:flutter/material.dart';
import 'package:sistem_cormex/Src/Config/appColors.dart';

class CommerceShowcase extends StatelessWidget {
  const CommerceShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy,
      child: Stack(
        children: [
          const Positioned(
            right: -90,
            top: -70,
            child: _GlowCircle(size: 290, color: AppColors.cyan),
          ),
          const Positioned(
            left: -130,
            bottom: -150,
            child: _GlowCircle(size: 420, color: AppColors.lime),
          ),
          Padding(
            padding: const EdgeInsets.all(56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                const Text(
                  'Venda com clareza.\nCresça com controle.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Uma visão simples da sua operação B2B, do primeiro contato ao pedido aprovado.',
                  style: TextStyle(
                    color: Color(0xFFB9C8D0),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 38),
                const _SalesCard(),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        icon: Icons.shopping_bag_outlined,
                        value: '128',
                        label: 'pedidos no mês',
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: _MiniStat(
                        icon: Icons.trending_up_rounded,
                        value: '+24%',
                        label: 'em conversão',
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.lime,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Text(
                      'Feito para distribuidoras e representantes',
                      style: TextStyle(color: Color(0xFFB9C8D0), fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(.18), color.withOpacity(0)],
        ),
      ),
    );
  }
}

class _SalesCard extends StatelessWidget {
  const _SalesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        border: Border.all(color: Colors.white.withOpacity(.12)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: AppColors.lime),
              SizedBox(width: 10),
              Text(
                'Vendas da semana',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Text(
                'R\$ 48.720',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ChartBar(height: 32),
                _ChartBar(height: 48),
                _ChartBar(height: 42),
                _ChartBar(height: 67),
                _ChartBar(height: 58),
                _ChartBar(height: 82, active: true),
                _ChartBar(height: 74),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  const _ChartBar({required this.height, this.active = false});
  final double height;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: height,
          decoration: BoxDecoration(
            color: active ? AppColors.lime : AppColors.cyan.withOpacity(.48),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.navySoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.cyan, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9DB0BB),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
