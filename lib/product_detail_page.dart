import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'app_state.dart';
import 'models/review.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _commentController = TextEditingController();
  double _rating = 5.0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Дэлгэрэнгүй'),
        actions: [
          Consumer<ApplicationState>(
            builder: (context, appState, _) {
              final isFavorite = appState.isFavorite(widget.productId);
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : null,
                ),
                onPressed: () async {
                  if (!appState.loggedIn) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Нэвтэрсэн байх шаардлагатай'),
                      ),
                    );
                    context.push('/sign-in');
                    return;
                  }
                  await appState.toggleFavorite(widget.productId);
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<ApplicationState>(
        builder: (context, appState, _) {
          final product = appState.products.firstWhere(
            (p) => p.id.toString() == widget.productId,
            orElse: () => appState.products.first,
          );

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.network(
                    product.image,
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          Text(
                            ' ${product.rating.rate.toStringAsFixed(1)} (${product.rating.count} үнэлгээ)',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        product.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Chip(label: Text(product.category)),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (!appState.loggedIn) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Нэвтэрсэн байх шаардлагатай'),
                                ),
                              );
                              context.push('/sign-in');
                              return;
                            }

                            if (appState.isInCart(widget.productId)) {
                              await appState.removeFromCart(widget.productId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Сагснаас хасагдлаа'),
                                ),
                              );
                            } else {
                              await appState.addToCart(widget.productId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Сагсанд нэмэгдлээ'),
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            appState.isInCart(widget.productId)
                                ? Icons.remove_shopping_cart
                                : Icons.add_shopping_cart,
                          ),
                          label: Text(
                            appState.isInCart(widget.productId)
                                ? 'Сагснаас хасах'
                                : 'Сагсанд нэмэх',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Сэтгэгдэл нэмэх',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (appState.loggedIn) ...[
                        TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Сэтгэгдлээ бичнэ үү...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Үнэлгээ: '),
                            Expanded(
                              child: Slider(
                                value: _rating,
                                min: 1,
                                max: 5,
                                divisions: 4,
                                label: _rating.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _rating = value;
                                  });
                                },
                              ),
                            ),
                            Text(_rating.toStringAsFixed(1)),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (_commentController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Сэтгэгдэл бичнэ үү'),
                                ),
                              );
                              return;
                            }

                            await appState.addReview(
                              widget.productId,
                              _commentController.text,
                              _rating,
                            );

                            _commentController.clear();
                            setState(() {
                              _rating = 5.0;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Сэтгэгдэл нэмэгдлээ'),
                              ),
                            );
                          },
                          child: const Text('Илгээх'),
                        ),
                      ] else
                        Center(
                          child: TextButton(
                            onPressed: () => context.push('/sign-in'),
                            child: const Text(
                              'Сэтгэгдэл бичихийн тулд нэвтэрнэ үү',
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      const Text(
                        'Бусад сэтгэгдлүүд',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<List<Review>>(
                        stream: appState.getReviews(widget.productId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Одоогоор сэтгэгдэл байхгүй байна'),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final review = snapshot.data![index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            review.userName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                size: 16,
                                                color: Colors.amber,
                                              ),
                                              Text(
                                                ' ${review.rating.toStringAsFixed(1)}',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(review.comment),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${review.timestamp.year}/${review.timestamp.month}/${review.timestamp.day}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
