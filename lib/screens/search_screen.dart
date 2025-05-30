import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_flutter/models/search_result.dart';
import 'package:stream_flutter/screens/search_result_section.dart';
import '../providers/search_provider.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SearchProvider>(context);
    final textTheme = Theme
        .of(context)
        .textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Search API', style: textTheme.titleLarge),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
              ),
              style: textTheme.bodyLarge,
              onSubmitted: provider.search,
            ),
            const SizedBox(height: 16),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              if (provider.error != null)
                Text("Error: ${provider.error}",
                    style: textTheme.bodyMedium?.copyWith(color: Colors.red))
              else
                if (provider.results.items.isEmpty)
                  Text("No results",
                      style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white60))
                else
                  Expanded(
                      child: _buildBody(provider.results)
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(SearchResult result) {
    return SearchResultSection(
        searchResult: result
    );
  }
}
