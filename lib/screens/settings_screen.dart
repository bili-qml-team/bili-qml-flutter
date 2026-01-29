import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/providers.dart';
import '../theme/colors.dart';

/// 设置页面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 用户设置
              _buildSection(
                context,
                title: '用户设置',
                children: [
                  _buildUserIdTile(context, settings),
                  const SizedBox(height: 8),
                  _buildVoteTokenTile(context, settings),
                ],
              ),
              const SizedBox(height: 16),

              // 第一名显示设置
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
              const SizedBox(height: 16),

              // 主题设置
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
              const SizedBox(height: 16),

              // 高级设置
              _buildAdvancedSection(context, settings),
            ],
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
                ScaffoldMessenger.of(
                  dialogContext,
                ).showSnackBar(const SnackBar(content: Text('请输入有效的数字 UID')));
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
                Text('自定义问号榜服务器地址', style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(
                          text: settings.apiEndpoint,
                        ),
                        decoration: InputDecoration(
                          hintText: ApiConfig.defaultApiBase,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (value) => settings.setApiEndpoint(value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => settings.resetApiEndpoint(),
                      tooltip: '重置为默认',
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
