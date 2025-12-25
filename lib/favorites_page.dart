import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'widgets/product_card.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Дуртай бүтээгдэхүүн')),
      body: Consumer<ApplicationState>(
        builder: (context, appState, _) {
          if (!appState.loggedIn) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite, size: 100, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Дуртай бүтээгдэхүүнүүдийг үзэхийн тулд нэвтэрнэ үү',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/sign-in'),
                    child: const Text('Нэвтрэх'),
                  ),
                ],
              ),
            );
          }

          final favoriteProducts = appState.getFavoriteProducts();

          if (favoriteProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 100,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('Дуртай бүтээгдэхүүн байхгүй байна'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Бүтээгдэхүүн үзэх'),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: favoriteProducts.length,
            itemBuilder: (context, index) {
              return ProductCard(product: favoriteProducts[index]);
            },
          );
        },
      ),
    );
  }
}
