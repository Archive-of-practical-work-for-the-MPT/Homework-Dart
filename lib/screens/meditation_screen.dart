import 'package:flutter/material.dart';

class MeditationScreen extends StatelessWidget {
  const MeditationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                // Изображение
                Center(
                  child: Container(
                    width: 343,
                    height: 231,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/lake_music.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Автор
                const Text(
                  'Peter Mach',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 22 / 12,
                  ),
                ),
                const SizedBox(height: 8),
                // Заголовок
                const Text(
                  'Mind Deep Relax',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 22 / 20,
                  ),
                ),
                const SizedBox(height: 12),
                // Описание
                const Text(
                  'Join the Community as we prepare over 33 days to relax and feel joy with the mind and happnies session across the World.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF555555),
                    height: 22 / 15,
                  ),
                ),
                const SizedBox(height: 24),
                // Кнопка Play Next Session
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF039EA2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/play.png',
                          width: 10.5,
                          height: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Play Next Session',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Список элементов
                _buildListItem(
                  color: const Color(0xFF2F80ED),
                  title: 'Sweet Memories',
                  subtitle: 'December 29 Pre-Launch',
                ),
                _buildListItem(
                  color: const Color(0xFF039EA2),
                  title: 'A Day Dream',
                  subtitle: 'December 29 Pre-Launch',
                ),
                _buildListItem(
                  color: const Color(0xFFF09235),
                  title: 'Mind Explore',
                  subtitle: 'December 29 Pre-Launch',
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListItem({
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      height: 73,
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/play.png',
                      width: 10.5,
                      height: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E1E1E),
                          height: 22 / 17,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          height: 20 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text(
              '...',
              style: TextStyle(fontSize: 24, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
