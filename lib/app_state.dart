import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'
    hide EmailAuthProvider, PhoneAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'firebase_options.dart';
import 'models/product.dart';
import 'models/review.dart';

// Background мэдэгдэл хүлээн авах функц
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📬 Background мэдэгдэл: ${message.notification?.title}');
}

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  List<Product> _products = [];
  List<Product> get products => _products;

  List<String> _cartItemIds = [];
  List<String> get cartItemIds => _cartItemIds;

  List<String> _favoriteIds = [];
  List<String> get favoriteIds => _favoriteIds;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseUIAuth.configureProviders([EmailAuthProvider()]);

    //  Firebase Messaging эхлүүлэх
    await _setupFirebaseMessaging();

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loggedIn = true;
        _loadUserData();
        _saveFCMToken();
      } else {
        _loggedIn = false;
        _cartItemIds = [];
        _favoriteIds = [];
      }
      notifyListeners();
    });

    await fetchProducts();
  }

  // Firebase Messaging тохируулах
  Future<void> _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // FCM Token авах
    _fcmToken = await messaging.getToken();
    print(' FCM Token: $_fcmToken');

    // Token шинэчлэгдэх үед
    messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _saveFCMToken();
    });

    // Foreground мэдэгдэл (апп нээлттэй үед)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(' Мэдэгдэл ирлээ!');
      print('Гарчиг: ${message.notification?.title}');
      print('Агуулга: ${message.notification?.body}');
    });

    // Background мэдэгдэл handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Мэдэгдэл дээр дарахад
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(' Мэдэгдэл дээр дарлаа');
    });
  }

  //FCM Token-г Firebase-д хадгалах
  Future<void> _saveFCMToken() async {
    if (_fcmToken == null || !_loggedIn) return;

    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': _fcmToken,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Token хадгалах алдаа: $e');
    }
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://fakestoreapi.com/products'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _products = data.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching products: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Product?> fetchProductById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('https://fakestoreapi.com/products/$id'),
      );

      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      }
    } catch (e) {
      print('Error fetching product: $e');
    }
    return null;
  }

  Future<void> _loadUserData() async {
    if (!_loggedIn) return;

    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Load cart
    final cartDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .get();

    _cartItemIds = cartDoc.docs.map((doc) => doc.id).toList();

    // Load favorites
    final favDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .get();

    _favoriteIds = favDoc.docs.map((doc) => doc.id).toList();

    notifyListeners();
  }

  Future<void> addToCart(String productId) async {
    if (!_loggedIn) {
      throw Exception('Нэвтэрсэн байх шаардлагатай');
    }

    final userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId)
        .set({'addedAt': FieldValue.serverTimestamp()});

    _cartItemIds.add(productId);
    notifyListeners();
  }

  Future<void> removeFromCart(String productId) async {
    if (!_loggedIn) return;

    final userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId)
        .delete();

    _cartItemIds.remove(productId);
    notifyListeners();
  }

  Future<void> toggleFavorite(String productId) async {
    if (!_loggedIn) {
      throw Exception('Нэвтэрсэн байх шаардлагатай');
    }

    final userId = FirebaseAuth.instance.currentUser!.uid;

    if (_favoriteIds.contains(productId)) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(productId)
          .delete();

      _favoriteIds.remove(productId);
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(productId)
          .set({'addedAt': FieldValue.serverTimestamp()});

      _favoriteIds.add(productId);
    }

    notifyListeners();
  }

  bool isInCart(String productId) => _cartItemIds.contains(productId);
  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  List<Product> getCartProducts() {
    return _products
        .where((p) => _cartItemIds.contains(p.id.toString()))
        .toList();
  }

  List<Product> getFavoriteProducts() {
    return _products
        .where((p) => _favoriteIds.contains(p.id.toString()))
        .toList();
  }

  Future<void> addReview(
    String productId,
    String comment,
    double rating,
  ) async {
    if (!_loggedIn) {
      throw Exception('Нэвтэрсэн байх шаардлагатай');
    }

    final user = FirebaseAuth.instance.currentUser!;

    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .add({
          'userId': user.uid,
          'userName': user.displayName ?? 'Anonymous',
          'comment': comment,
          'rating': rating,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Stream<List<Review>> getReviews(String productId) {
    return FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Review(
              userName: data['userName'] ?? 'Anonymous',
              comment: data['comment'] ?? '',
              rating: (data['rating'] ?? 0.0).toDouble(),
              timestamp: data['timestamp'] != null
                  ? (data['timestamp'] as Timestamp).toDate()
                  : DateTime.now(),
            );
          }).toList();
        });
  }
}
