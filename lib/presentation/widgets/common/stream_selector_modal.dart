import 'package:flutter/material.dart';

import '../../../data/models/models/video_streams.dart';

class StreamSelectorModal extends StatefulWidget {
  final String itemTitle;
  final VideoStreams streams;
  final void Function(String streamUrl, String streamName) onStreamSelected;

  const StreamSelectorModal({
    super.key,
    required this.itemTitle,
    required this.streams,
    required this.onStreamSelected,
  });

  @override
  State<StreamSelectorModal> createState() => _StreamSelectorModalState();
}

class _StreamSelectorModalState extends State<StreamSelectorModal> {
  String? selectedSource;
  VideoStream? selectedTranslator;

  @override
  Widget build(BuildContext context) {
    // The modal is now wrapped in a simple container.
    // The default `showModalBottomSheet` animation handles the initial appearance.
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildProgressIndicator(),
            const SizedBox(height: 32),
            Flexible(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Drag handle
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        // Title with icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.play_circle_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Вибір стріму',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    widget.itemTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    int currentStep = 0;
    if (selectedSource != null) currentStep = 1;
    if (selectedTranslator != null) currentStep = 2;

    return Row(
      children: [
        _buildStepIndicator(0, currentStep, '📡', 'Джерело'),
        Expanded(child: _buildStepConnector(currentStep >= 1)),
        _buildStepIndicator(1, currentStep, '🗣', 'Переклад'),
        Expanded(child: _buildStepConnector(currentStep >= 2)),
        _buildStepIndicator(2, currentStep, '🎞', 'Якість'),
      ],
    );
  }

  Widget _buildStepIndicator(
    int step,
    int currentStep,
    String emoji,
    String label,
  ) {
    final isActive = step <= currentStep;
    final isCurrent = step == currentStep;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border:
                isCurrent
                    ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                    : null,
          ),
          child: Center(
            child: Text(
              emoji,
              style: TextStyle(
                fontSize: 16,
                color:
                    isActive
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color:
                isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color:
            isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildContent() {
    Widget page;
    String pageKey;

    if (selectedSource == null) {
      pageKey = "source";
      page = _buildSourceSelection();
    } else if (selectedTranslator == null) {
      pageKey = "translator";
      page = _buildTranslatorSelection();
    } else {
      pageKey = "quality";
      page = _buildQualitySelection();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Don't slide the initial page; just fade it in.
        if ((child.key as ValueKey).value == 'source') {
          return FadeTransition(opacity: animation, child: child);
        }

        // For subsequent pages, slide them in from the right.
        // The old page will fade out by default, which is a clean look.
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
      child: Container(
        // The key is essential for AnimatedSwitcher to detect a change.
        key: ValueKey(pageKey),
        child: page,
      ),
    );
  }

  Widget _buildSourceSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Оберіть джерело стріму",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        if (widget.streams.data.isEmpty)
          _buildEmptyState('Джерел не знайдено', Icons.signal_wifi_off)
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.streams.data.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final source = widget.streams.data[index];
                return _buildOptionCard(
                  title: source.sourceName,
                  subtitle: '${source.sources.length} перекладачів',
                  icon: Icons.router,
                  onTap: () {
                    // Just update the state; AnimatedSwitcher handles the rest.
                    setState(() => selectedSource = source.sourceName);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTranslatorSelection() {
    final translators =
        widget.streams.data
            .firstWhere((d) => d.sourceName == selectedSource)
            .sources;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              // Just update the state to go back.
              onPressed: () => setState(() => selectedSource = null),
              icon: const Icon(Icons.arrow_back),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Оберіть перекладача",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Джерело: $selectedSource",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (translators.isEmpty)
          _buildEmptyState('Перекладачів не знайдено', Icons.translate)
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: translators.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final translator = translators[index];
                return _buildOptionCard(
                  title: translator.name,
                  subtitle: '${translator.links.length} варіантів якості',
                  icon: Icons.record_voice_over,
                  onTap: () {
                    // Just update the state.
                    setState(() => selectedTranslator = translator);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildQualitySelection() {
    final links = selectedTranslator!.links;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              // Just update the state to go back.
              onPressed: () => setState(() => selectedTranslator = null),
              icon: const Icon(Icons.arrow_back),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Оберіть якість",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Переклад: ${selectedTranslator!.name}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (links.isEmpty)
          _buildEmptyState('Варіантів якості не знайдено', Icons.hd)
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: links.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final link = links[index];
                return _buildOptionCard(
                  title: link.quality,
                  subtitle: 'Натисніть для перегляду',
                  icon: _getQualityIcon(link.quality),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onStreamSelected(
                      link.url,
                      "${selectedTranslator!.name} - ${link.quality}",
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getQualityIcon(String quality) {
    final q = quality.toLowerCase();
    if (q.contains('1080')) return Icons.hd;
    if (q.contains('720')) return Icons.hd_outlined;
    if (q.contains('480')) return Icons.sd;
    return Icons.video_settings;
  }
}
