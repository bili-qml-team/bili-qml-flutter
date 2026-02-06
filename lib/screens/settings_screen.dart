import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/providers.dart';
import '../theme/colors.dart';
import '../widgets/widgets.dart';

/// 设置页面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final sections = <Widget>[
            _buildSection(
              context,
              title: '用户设置',
              children: [
                _buildUserIdTile(context, settings),
                const SizedBox(height: 8),
                _buildVoteTokenTile(context, settings),
              ],
            ),
            _buildSection(
              context,
              title: '第一名显示设置',
              description: '自定义排行榜第一名的显示文本',
              children: [
                RadioGroup<String>(
                  groupValue: settings.rank1Setting,
                  onChanged: (v) => settings.setRank1Setting(v!),
                  child: Column(
                    children: [
                      _buildRadioTile<String>(
                        context,
                        title: '正常 (1)',
                        value: 'default',
                      ),
                      _buildRadioTile<String>(
                        context,
                        title: '抽象 (何一位)',
                        value: 'custom',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _buildSection(
              context,
              title: '主题色设置',
              children: [
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return RadioGroup<ThemeMode>(
                      groupValue: themeProvider.themeMode,
                      onChanged: (v) => themeProvider.setThemeMode(v!),
                      child: Column(
                        children: [
                          _buildRadioTile<ThemeMode>(
                            context,
                            title: '跟随系统',
                            value: ThemeMode.system,
                          ),
                          _buildRadioTile<ThemeMode>(
                            context,
                            title: '浅色模式',
                            value: ThemeMode.light,
                          ),
                          _buildRadioTile<ThemeMode>(
                            context,
                            title: '深色模式',
                            value: ThemeMode.dark,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            _buildAdvancedSection(context, settings),
          ];

          return ResponsivePageContainer(
            maxWidth: 1480,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = constraints.maxWidth;
                final useGrid = contentWidth >= ResponsiveBreakpoints.desktop;

                if (!useGrid) {
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: sections.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => sections[index],
                  );
                }

                final spacing = 16.0;
                final columns = 2;
                final cardWidth =
                    (contentWidth - spacing * (columns - 1)) / columns;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: sections
                        .map((section) => SizedBox(width: cardWidth, child: section))
                        .toList(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    String? description,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(description, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile<T>(
    BuildContext context, {
    required String title,
    required T value,
  }) {
    return RadioListTile<T>(
      title: Text(title),
      value: value,
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeColor: AppColors.biliBlue,
    );
  }

  Widget _buildUserIdTile(BuildContext context, SettingsProvider settings) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('B站 UID'),
      subtitle: Text(
        settings.userId ?? '未设置',
        style: TextStyle(
          color: settings.userId != null ? AppColors.biliBlue : null,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showUserIdDialog(context, settings),
    );
  }

  Widget _buildVoteTokenTile(BuildContext context, SettingsProvider settings) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('投票 Token'),
      subtitle: Text(
        settings.voteToken == null ? '未设置' : '已设置',
        style: TextStyle(
          color: settings.voteToken != null ? AppColors.biliBlue : null,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showVoteTokenDialog(context, settings),
    );
  }

  void _showUserIdDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.userId ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('设置 B站 UID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '请输入您的 B站 UID（数字），用于投票功能。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'UID',
                hintText: '例如: 12345678',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          if (settings.userId != null)
            TextButton(
              onPressed: () async {
                await settings.setUserId(null);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('清除', style: TextStyle(color: AppColors.error)),
            ),
          ElevatedButton(
            onPressed: () async {
              final userId = controller.text.trim();
              if (userId.isEmpty || RegExp(r'^\d+$').hasMatch(userId)) {
                await settings.setUserId(userId.isEmpty ? null : userId);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              } else {
                StatusFeedback.warning(dialogContext, 'UID 格式无效，请输入纯数字');
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showVoteTokenDialog(
    BuildContext context,
    SettingsProvider settings,
  ) {
    final controller = TextEditingController(text: settings.voteToken ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('设置投票 Token'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '请输入从插件端获取的 Token，用于投票鉴权。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Token',
                hintText: '粘贴 Token',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          if (settings.voteToken != null)
            TextButton(
              onPressed: () async {
                await settings.setVoteToken(null);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('清除', style: TextStyle(color: AppColors.error)),
            ),
          ElevatedButton(
            onPressed: () async {
              final token = controller.text.trim();
              await settings.setVoteToken(token.isEmpty ? null : token);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection(
    BuildContext context,
    SettingsProvider settings,
  ) {
    return _AdvancedOptionsSection(settings: settings);
  }
}

class _AdvancedOptionsSection extends StatefulWidget {
  final SettingsProvider settings;

  const _AdvancedOptionsSection({required this.settings});

  @override
  State<_AdvancedOptionsSection> createState() => _AdvancedOptionsSectionState();
}

class _AdvancedOptionsSectionState extends State<_AdvancedOptionsSection> {
  late final TextEditingController _apiController;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _apiController = TextEditingController(text: widget.settings.apiEndpoint);
    _apiController.addListener(_onApiInputChanged);
  }

  @override
  void didUpdateWidget(covariant _AdvancedOptionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isSaving || _hasChanges) return;

    final latestEndpoint = widget.settings.apiEndpoint;
    if (_apiController.text != latestEndpoint) {
      _apiController.text = latestEndpoint;
    }
  }

  @override
  void dispose() {
    _apiController.removeListener(_onApiInputChanged);
    _apiController.dispose();
    super.dispose();
  }

  void _onApiInputChanged() {
    final input = _apiController.text.trim();
    final normalized = input.isEmpty ? ApiConfig.defaultApiBase : input;
    final changed = normalized != widget.settings.apiEndpoint;

    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  Future<void> _saveAdvancedSettings() async {
    if (_isSaving || !_hasChanges) return;

    setState(() => _isSaving = true);
    try {
      await widget.settings.setApiEndpoint(_apiController.text.trim());
      if (!mounted) return;
      _apiController.removeListener(_onApiInputChanged);
      _apiController.text = widget.settings.apiEndpoint;
      _apiController.addListener(_onApiInputChanged);
      setState(() {
        _isSaving = false;
        _hasChanges = false;
      });
      StatusFeedback.success(context, '高级设置已保存');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      StatusFeedback.error(context, '保存失败，请稍后重试');
    }
  }

  void _resetToDefault() {
    _apiController.text = ApiConfig.defaultApiBase;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ExpansionTile(
        title: Text(
          '高级选项',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('API 服务器设置', style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text('修改后请点击「保存设置」生效', style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _apiController,
                        decoration: InputDecoration(
                          hintText: ApiConfig.defaultApiBase,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _saveAdvancedSettings(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _isSaving ? null : _resetToDefault,
                      tooltip: '填入默认地址',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: (_isSaving || !_hasChanges)
                        ? null
                        : _saveAdvancedSettings,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? '保存中...' : '保存设置'),
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
