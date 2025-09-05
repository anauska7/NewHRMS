import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ProductivityTimerWidget extends StatefulWidget {
  const ProductivityTimerWidget({Key? key}) : super(key: key);

  @override
  State createState() => _ProductivityTimerWidgetState();
}

class _ProductivityTimerWidgetState extends State<ProductivityTimerWidget> {
  Timer? _timer;
  String _productivityTime = '0h 0m';
  bool _isCheckedIn = false;

  @override
  void initState() {
    super.initState();
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

      if (mounted) {
        setState(() {
          _productivityTime = '${hours}h ${minutes}m';
        });
      }
    } catch (e) {
      debugPrint('Error updating productivity display: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isCheckedIn ? Icons.timer : Icons.timer_off,
                  color: _isCheckedIn ? Colors.green : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Productivity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isCheckedIn ? Colors.green : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _productivityTime,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _getProductivityColor(),
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 14,
                color: _getProductivityColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_isCheckedIn) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Currently Active',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getProductivityColor() {
    final hours = _getHoursFromProductivityString();
    if (hours >= 9.0) {
      return Colors.green;
    } else if (hours >= 4.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getStatusText() {
    final hours = _getHoursFromProductivityString();
    if (hours >= 9.0) {
      return 'Present Status ✓';
    } else if (hours >= 4.5) {
      return 'Half Day Status';
    } else {
      return 'Need ${(9.0 - hours).toStringAsFixed(1)}h for Present';
    }
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
