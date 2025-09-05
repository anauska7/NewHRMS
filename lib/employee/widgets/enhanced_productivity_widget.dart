import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class EnhancedProductivityWidget extends StatefulWidget {
  const EnhancedProductivityWidget({Key? key}) : super(key: key);

  @override
  State createState() => _EnhancedProductivityWidgetState();
}

class _EnhancedProductivityWidgetState extends State<EnhancedProductivityWidget>
    with TickerProviderStateMixin {
  Timer? _timer;
  String _productivityTime = '0h 0m';
  bool _isCheckedIn = false;
  double _progressValue = 0.0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateProductivityDisplay();
    });
  }

  Future _updateProductivityDisplay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // <-- THIS ENSURES LATEST VALUE FROM DISK
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final storedProductivityDate = prefs.getString('last_productivity_date');
      final lastEntryType = prefs.getString('last_entry_type') ?? 'OUT';
      _isCheckedIn = lastEntryType == 'IN';

      int totalMinutes = 0;
      if (storedProductivityDate == today) {
        totalMinutes = prefs.getInt('daily_productivity_minutes') ?? 0;
      }

      final int hours = totalMinutes ~/ 60;
      final int minutes = totalMinutes % 60;
      final double totalHours = hours + (minutes / 60);
      final double newProgress = (totalHours / 9.0).clamp(0.0, 1.0);

      if (mounted) {
        setState(() {
          _productivityTime = '${hours}h ${minutes}m';
          _progressValue = newProgress;
        });
        _animationController.animateTo(_progressValue);
      }
    } catch (e) {
      debugPrint('Error updating productivity display: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            Text(
              'Daily Productivity Tracker',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CircularProgressIndicator(
                        value: _animationController.value,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(
                          _getProgressColor(_animationController.value),
                        ),
                      );
                    },
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _productivityTime,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          '/ 9h',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusChip(),
            const SizedBox(height: 12),
            _buildProgressStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final hours = _getHoursFromProductivityString();
    String status;
    Color color;
    IconData icon;

    if (hours >= 9.0) {
      status = 'Present';
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (hours >= 4.5) {
      status = 'Half Day';
      color = Colors.orange;
      icon = Icons.schedule;
    } else {
      status = 'Incomplete';
      color = Colors.red;
      icon = Icons.access_time;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_isCheckedIn) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressStats() {
    final hours = _getHoursFromProductivityString();
    final remaining = (9.0 - hours).clamp(0.0, 9.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Completed', '${(hours).toStringAsFixed(1)}h', Colors.blue),
        _buildStatItem('Remaining', '${remaining.toStringAsFixed(1)}h', Colors.grey),
        _buildStatItem('Progress', '${(_progressValue * 100).toInt()}%', Colors.green),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.5) return Colors.orange;
    return Colors.red;
  }

  double _getHoursFromProductivityString() {
    final parts = _productivityTime.split(' ');
    if (parts.length >= 2) {
      final hoursStr = parts[0].replaceAll('h', '');
      final minutesStr = parts[1].replaceAll('m', '');
      final hours = double.tryParse(hoursStr) ?? 0;
      final minutes = double.tryParse(minutesStr) ?? 0;
      return hours + (minutes / 60);
    }
    return 0.0;
  }
}
