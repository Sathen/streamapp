// stream_selector_modal.dart
import 'package:flutter/material.dart';
import '../models/video_streams.dart';

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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.itemTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (selectedSource == null) ..._buildSourceSelection(),
          if (selectedSource != null && selectedTranslator == null)
            ..._buildTranslatorSelection(),
          if (selectedTranslator != null) ..._buildQualitySelection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _buildSourceSelection() {
    return [
      const Text(
        "📡 Оберіть джерело",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      if (widget.streams.data.isEmpty) const Text("Джерел не знайдено."),
      ...widget.streams.data.map(
        (source) => ListTile(
          title: Text(source.sourceName),
          onTap: () => setState(() => selectedSource = source.sourceName),
        ),
      ),
    ];
  }

  List<Widget> _buildTranslatorSelection() {
    final translators = widget.streams.data
        .firstWhere((d) => d.sourceName == selectedSource).sources;

    return [
      Text(
        "🗣 Перекладач (Джерело: $selectedSource)",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      if (translators.isEmpty) const Text("Перекладачів не знайдено."),
      ...translators.map(
        (translator) => ListTile(
          title: Text(translator.name),
          onTap: () => setState(() => selectedTranslator = translator),
        ),
      ),
      const SizedBox(height: 8),
      TextButton.icon(
        icon: const Icon(Icons.arrow_back),
        label: const Text("Назад до джерел"),
        onPressed: () => setState(() => selectedSource = null),
      ),
    ];
  }

  List<Widget> _buildQualitySelection() {
    final links = selectedTranslator!.links;
    return [
      Text(
        "🎞 Якість (Переклад: ${selectedTranslator!.name})",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      if (links.isEmpty) const Text("Варіантів якості не знайдено."),
      ...links.map(
        (link) => ListTile(
          title: Text(link.quality),
          onTap: () {
            Navigator.of(context).pop();
            widget.onStreamSelected(
              link.url,
              "${selectedTranslator!.name} - ${link.quality}",
            );
          },
        ),
      ),
      const SizedBox(height: 8),
      TextButton.icon(
        icon: const Icon(Icons.arrow_back),
        label: const Text("Назад до перекладачів"),
        onPressed: () => setState(() => selectedTranslator = null),
      ),
    ];
  }
}
