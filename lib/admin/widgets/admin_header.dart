import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const CustomHeader({super.key, required this.title, this.showBackButton = false});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.green,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                context.pop(); // Go back to the previous route
              },
            )
          : Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
      title: Text(
        title,
        style: TextStyle(fontSize: MediaQuery.of(context).size.width > 600 ? 22 : 18, color: Colors.white),
      ),
      centerTitle: false,
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {},
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                height: 8,
                width: 8,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            context.go('/admin/dashboard'); // Navigate to the dashboard route
          },
          child: const CircleAvatar(
            backgroundColor: Colors.white,
            radius: 15,
            child: Icon(Icons.account_circle, color: Colors.green),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}