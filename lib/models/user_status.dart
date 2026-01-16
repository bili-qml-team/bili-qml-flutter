/// 用户投票状态模型
class UserStatus {
  /// 是否已对该视频投过票
  final bool active;

  /// 该视频收到的总"问号"数
  final int count;

  UserStatus({required this.active, required this.count});

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    return UserStatus(
      active: json['active'] as bool? ?? false,
      count: json['count'] as int? ?? 0,
    );
  }
}
