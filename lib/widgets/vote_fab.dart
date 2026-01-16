import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// 投票悬浮按钮组件
class VoteFab extends StatelessWidget {
  final int count;
  final bool isVoted;
  final bool isLoading;
  final VoidCallback? onPressed;

  const VoteFab({
    super.key,
    required this.count,
    required this.isVoted,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: isLoading ? null : onPressed,
      backgroundColor: isVoted ? AppColors.biliBlue : Colors.grey[600],
      foregroundColor: Colors.white,
      icon: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Text(
              '❓',
              style: TextStyle(
                fontSize: 20,
                color: isVoted ? Colors.white : Colors.white70,
              ),
            ),
      label: Text(
        _formatCount(count),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      elevation: 4,
      highlightElevation: 8,
    );
  }

  String _formatCount(int count) {
    if (count >= 10000) {
      final v = count / 10000;
      return '${v >= 10 ? v.round() : v.toStringAsFixed(1)}万';
    }
    return count.toString();
  }
}

/// 扩展版投票悬浮按钮（带动画效果）
class AnimatedVoteFab extends StatefulWidget {
  final int count;
  final bool isVoted;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AnimatedVoteFab({
    super.key,
    required this.count,
    required this.isVoted,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  State<AnimatedVoteFab> createState() => _AnimatedVoteFabState();
}

class _AnimatedVoteFabState extends State<AnimatedVoteFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: VoteFab(
              count: widget.count,
              isVoted: widget.isVoted,
              isLoading: widget.isLoading,
              onPressed: widget.onPressed,
            ),
          );
        },
      ),
    );
  }
}
