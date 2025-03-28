import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to handle authentication state
final authProvider = StateProvider<bool>((ref) => false);

// Provider to store user type - 'admin' or 'employee'
final userTypeProvider = StateProvider<String>((ref) => '');