import 'package:flutter/material.dart';

/// Widget para exibir estados de carregamento com animação de esqueleto
class SkeletonLoader extends StatefulWidget {
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoader({
    super.key,
    this.height,
    this.width,
    this.borderRadius,
    this.margin,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = widget.baseColor ?? theme.colorScheme.surfaceContainerHighest;
    final highlightColor = widget.highlightColor ?? theme.colorScheme.surface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height ?? 20,
          width: widget.width,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                Color.lerp(baseColor, highlightColor, _animation.value)!,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Widget para criar layouts de esqueleto complexos
class SkeletonLoadingList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final double? itemSpacing;

  const SkeletonLoadingList({
    super.key,
    this.itemCount = 3,
    required this.itemBuilder,
    this.padding,
    this.itemSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (context, index) => SizedBox(height: itemSpacing ?? 16),
      itemBuilder: itemBuilder,
    );
  }
}

/// Widget para esqueleto de cartão
class SkeletonCard extends StatelessWidget {
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final List<Widget>? children;

  const SkeletonCard({
    super.key,
    this.height,
    this.margin,
    this.padding,
    this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children ?? [
              const SkeletonLoader(height: 20, width: 150),
              const SizedBox(height: 8),
              const SkeletonLoader(height: 16, width: double.infinity),
              const SizedBox(height: 4),
              const SkeletonLoader(height: 16, width: 200),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget para esqueleto de linha de texto
class SkeletonText extends StatelessWidget {
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? margin;

  const SkeletonText({
    super.key,
    this.height,
    this.width,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      height: height ?? 16,
      width: width,
      margin: margin,
      borderRadius: BorderRadius.circular(2),
    );
  }
}

/// Widget para esqueleto circular (avatar)
class SkeletonCircle extends StatelessWidget {
  final double radius;
  final EdgeInsetsGeometry? margin;

  const SkeletonCircle({
    super.key,
    this.radius = 24,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      height: radius * 2,
      width: radius * 2,
      margin: margin,
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

/// Esqueletos pré-definidos para casos comuns

/// Esqueleto para lista de endereços
class AddressListSkeleton extends StatelessWidget {
  final int itemCount;

  const AddressListSkeleton({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoadingList(
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonCard(
        height: 120,
        children: [
          Row(
            children: [
              SkeletonCircle(radius: 12),
              SizedBox(width: 8),
              SkeletonText(height: 18, width: 100),
            ],
          ),
          SizedBox(height: 12),
          SkeletonText(width: double.infinity),
          SizedBox(height: 4),
          SkeletonText(width: 180),
          SizedBox(height: 4),
          SkeletonText(width: 120),
        ],
      ),
    );
  }
}

/// Esqueleto para lista de documentos
class DocumentListSkeleton extends StatelessWidget {
  final int itemCount;

  const DocumentListSkeleton({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoadingList(
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonCard(
        height: 80,
        children: [
          Row(
            children: [
              SkeletonLoader(height: 40, width: 40, borderRadius: BorderRadius.all(Radius.circular(8))),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonText(height: 16, width: 120),
                    SizedBox(height: 4),
                    SkeletonText(height: 14, width: 80),
                  ],
                ),
              ),
              SkeletonLoader(height: 24, width: 60, borderRadius: BorderRadius.all(Radius.circular(12))),
            ],
          ),
        ],
      ),
    );
  }
}

/// Esqueleto para formulário
class FormSkeleton extends StatelessWidget {
  final int fieldCount;

  const FormSkeleton({
    super.key,
    this.fieldCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(fieldCount, (index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonText(height: 12, width: 80),
            SizedBox(height: 8),
            SkeletonLoader(height: 56, width: double.infinity, borderRadius: BorderRadius.all(Radius.circular(4))),
          ],
        ),
      )),
    );
  }
}