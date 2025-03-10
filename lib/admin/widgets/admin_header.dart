import 'package:flutter/material.dart';

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

      // ✅ Leading Section (Back Button OR Drawer Button)
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          : Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer(); // Open drawer
                },
              ),
            ),

      // ✅ Title Section (With Search Icon on the Left)
      title: Row(
        
        children: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 22, color: Colors.white),
          ),
        ],
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
        const CircleAvatar(
          backgroundColor: Colors.white,
          radius: 15,
          child: Icon(Icons.account_circle, color: Colors.green),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
