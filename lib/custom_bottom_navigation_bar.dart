import 'package:flutter/material.dart';
import 'app_colors.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int selectedIndex;
  final String? profileImageUrl;
  final Function(int) onItemTapped;

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.profileImageUrl,
  });

  @override
  _CustomBottomNavigationBarState createState() =>
      _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        BottomNavigationBarItem(
          // Condicionalmente mostra a imagem do perfil ou o ícone padrão
          icon: widget.profileImageUrl != null
              ? CircleAvatar(
                  backgroundImage: NetworkImage(widget.profileImageUrl!),
                  radius: 15,
                )
              : const Icon(Icons.person),
          label: 'Me',
        ),
      ],
      currentIndex: widget.selectedIndex,
      selectedItemColor: AppColors.blue,
      onTap: widget.onItemTapped,
    );
  }
}
