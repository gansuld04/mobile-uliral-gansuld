import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'widgets/product_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Худалдааны Апп'),
        actions: [
          Consumer<ApplicationState>(
            builder: (context, appState, _) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => context.push('/cart'),
                ),
                if (appState.cartItemIds.isNotEmpty)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${appState.cartItemIds.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => context.push('/favorites'),
          ),
          Consumer<ApplicationState>(
            builder: (context, appState, _) => IconButton(
              icon: Icon(appState.loggedIn ? Icons.logout : Icons.login),
              onPressed: () {
                if (appState.loggedIn) {
                  context.push('/profile');
                } else {
                  context.push('/sign-in');
                }
              },
            ),
          ),
        ],
      ),
      body: Consumer<ApplicationState>(
        builder: (context, appState, _) {
          if (appState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appState.products.isEmpty) {
            return const Center(child: Text('Бүтээгдэхүүн олдсонгүй'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: appState.products.length,
            itemBuilder: (context, index) {
              return ProductCard(product: appState.products[index]);
            },
          );
        },
      ),
    );
  }
}
