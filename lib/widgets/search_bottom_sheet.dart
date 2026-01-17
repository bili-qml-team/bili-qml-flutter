import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../theme/colors.dart';

/// 搜索底部抽屉
class SearchBottomSheet extends StatefulWidget {
  const SearchBottomSheet({super.key});

  /// 显示搜索底部抽屉
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const SearchBottomSheet(),
    );
  }

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  late TextEditingController _keywordController;
  late TextEditingController _upNameController;
  late SearchHistoryService _historyService;
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    final provider = context.read<LeaderboardProvider>();
    _keywordController = TextEditingController(text: provider.searchQuery);
    _upNameController = TextEditingController(text: provider.upNameFilter);

    // 初始化搜索历史
    final storageService = context.read<StorageService>();
    _historyService = SearchHistoryService(storageService.prefs);
    _searchHistory = _historyService.getHistory();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _upNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<LeaderboardProvider>();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题栏
                Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.biliBlue),
                    const SizedBox(width: 8),
                    Text(
                      '搜索与筛选',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (provider.hasActiveFilters)
                      TextButton(
                        onPressed: () {
                          provider.clearFilters();
                          _keywordController.clear();
                          _upNameController.clear();
                        },
                        child: const Text('清除'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      iconSize: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 关键词搜索
                TextField(
                  controller: _keywordController,
                  decoration: InputDecoration(
                    labelText: '搜索视频标题',
                    hintText: '输入关键词...',
                    prefixIcon: const Icon(Icons.video_library),
                    border: const OutlineInputBorder(),
                    suffixIcon: _keywordController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _keywordController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() {}),
                  onSubmitted: (value) => _applySearch(),
                ),
                const SizedBox(height: 16),

                // UP主筛选
                TextField(
                  controller: _upNameController,
                  decoration: InputDecoration(
                    labelText: 'UP主名称',
                    hintText: '按UP主筛选...',
                    prefixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(),
                    suffixIcon: _upNameController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _upNameController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() {}),
                  onSubmitted: (value) => _applySearch(),
                ),
                const SizedBox(height: 16),

                // 搜索历史
                if (_searchHistory.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        '搜索历史',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () async {
                          await _historyService.clearHistory();
                          setState(() {
                            _searchHistory = [];
                          });
                        },
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('清空', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _searchHistory.map((query) {
                      return InputChip(
                        label: Text(query),
                        avatar: const Icon(Icons.history, size: 16),
                        onPressed: () {
                          _keywordController.text = query;
                          setState(() {});
                          _applySearch();
                        },
                        onDeleted: () async {
                          await _historyService.removeSearch(query);
                          setState(() {
                            _searchHistory = _historyService.getHistory();
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // 结果统计
                if (provider.hasActiveFilters) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.biliBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_list,
                          color: AppColors.biliBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '找到 ${provider.items.length} 个结果',
                          style: const TextStyle(
                            color: AppColors.biliBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 应用按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applySearch,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.biliBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      '应用筛选',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _applySearch() {
    final keyword = _keywordController.text.trim();
    final upName = _upNameController.text.trim();

    // 保存搜索历史
    if (keyword.isNotEmpty) {
      _historyService.addSearch(keyword);
    }

    // 应用筛选
    final provider = context.read<LeaderboardProvider>();
    provider.applyFilters(keyword: keyword, upName: upName);

    Navigator.of(context).pop();
  }
}
