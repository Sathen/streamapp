import 'package:flutter/material.dart';

class ChipList extends StatefulWidget {
  final List<String> items;
  final ThemeData? theme;
  final bool isSelectable;
  final List<String>? selectedItems;
  final Function(String)? onChipTap;
  final Function(List<String>)? onSelectionChanged;
  final EdgeInsets? padding;
  final double spacing;
  final double runSpacing;
  final ChipStyle style;
  final int? maxLines;
  final bool showAnimation;

  const ChipList({
    super.key,
    required this.items,
    this.theme,
    this.isSelectable = false,
    this.selectedItems,
    this.onChipTap,
    this.onSelectionChanged,
    this.padding,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.style = ChipStyle.filled,
    this.maxLines,
    this.showAnimation = true,
  });

  @override
  State<ChipList> createState() => _ChipListState();
}

class _ChipListState extends State<ChipList>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _fadeAnimations;
  Set<String> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _selectedItems = Set.from(widget.selectedItems ?? []);

    if (widget.showAnimation) {
      _initializeAnimations();
    }
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.items.length,
          (index) => AnimationController(
        duration: Duration(milliseconds: 300 + (index * 50)),
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers.map(
          (controller) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      )),
    ).toList();

    _fadeAnimations = _controllers.map(
          (controller) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      )),
    ).toList();

    // Start animations with staggered delay
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.showAnimation) {
      for (var controller in _controllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(ChipList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedItems != oldWidget.selectedItems) {
      setState(() {
        _selectedItems = Set.from(widget.selectedItems ?? []);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? Theme.of(context);

    Widget chipWrap = Wrap(
      spacing: widget.spacing,
      runSpacing: widget.runSpacing,
      children: _buildChips(theme),
    );

    if (widget.padding != null) {
      chipWrap = Padding(
        padding: widget.padding!,
        child: chipWrap,
      );
    }

    if (widget.maxLines != null) {
      return ClipRect(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (widget.maxLines! * 40.0) +
                ((widget.maxLines! - 1) * widget.runSpacing),
          ),
          child: SingleChildScrollView(
            child: chipWrap,
          ),
        ),
      );
    }

    return chipWrap;
  }

  List<Widget> _buildChips(ThemeData theme) {
    return List.generate(widget.items.length, (index) {
      final item = widget.items[index];
      final isSelected = _selectedItems.contains(item);

      Widget chip = _buildChip(theme, item, isSelected, index);

      if (widget.showAnimation && index < _controllers.length) {
        chip = AnimatedBuilder(
          animation: _controllers[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimations[index].value,
              child: FadeTransition(
                opacity: _fadeAnimations[index],
                child: child,
              ),
            );
          },
          child: chip,
        );
      }

      return chip;
    });
  }

  Widget _buildChip(ThemeData theme, String item, bool isSelected, int index) {
    switch (widget.style) {
      case ChipStyle.outlined:
        return _buildOutlinedChip(theme, item, isSelected);
      case ChipStyle.elevated:
        return _buildElevatedChip(theme, item, isSelected);
      case ChipStyle.gradient:
        return _buildGradientChip(theme, item, isSelected);
      case ChipStyle.minimal:
        return _buildMinimalChip(theme, item, isSelected);
      case ChipStyle.filled:
      default:
        return _buildFilledChip(theme, item, isSelected);
    }
  }

  Widget _buildFilledChip(ThemeData theme, String item, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        label: Text(
          item,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        selected: isSelected,
        onSelected: widget.isSelectable ? (selected) => _onChipSelected(item) : null,
        backgroundColor: theme.colorScheme.surfaceVariant,
        selectedColor: theme.colorScheme.primary,
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildOutlinedChip(ThemeData theme, String item, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? theme.colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: InkWell(
        onTap: widget.isSelectable ? () => _onChipSelected(item) :
        widget.onChipTap != null ? () => widget.onChipTap!(item) : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            item,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElevatedChip(ThemeData theme, String item, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        elevation: isSelected ? 8 : 2,
        borderRadius: BorderRadius.circular(20),
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        shadowColor: theme.colorScheme.shadow.withOpacity(0.3),
        child: InkWell(
          onTap: widget.isSelectable ? () => _onChipSelected(item) :
          widget.onChipTap != null ? () => widget.onChipTap!(item) : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              item,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientChip(ThemeData theme, String item, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isSelected
            ? LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        )
            : null,
        color: isSelected ? null : theme.colorScheme.surfaceVariant,
        border: !isSelected ? Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isSelectable ? () => _onChipSelected(item) :
          widget.onChipTap != null ? () => widget.onChipTap!(item) : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              item,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalChip(ThemeData theme, String item, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isSelected
            ? theme.colorScheme.primary.withOpacity(0.2)
            : theme.colorScheme.surfaceVariant.withOpacity(0.5),
      ),
      child: InkWell(
        onTap: widget.isSelectable ? () => _onChipSelected(item) :
        widget.onChipTap != null ? () => widget.onChipTap!(item) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            item,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  void _onChipSelected(String item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });

    widget.onSelectionChanged?.call(_selectedItems.toList());
    widget.onChipTap?.call(item);
  }
}

enum ChipStyle {
  filled,
  outlined,
  elevated,
  gradient,
  minimal,
}