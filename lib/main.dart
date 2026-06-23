import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:pethome_app/src/core/router/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "assets/env");

  if (!kIsWeb) {
    await _initializeNativeServices();
  }

  runApp(const PetHomeApp());
}

Future<void> _initializeNativeServices() async {
  try {
    final stripePublishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
    if (stripePublishableKey != null && stripePublishableKey.trim().isNotEmpty) {
      Stripe.publishableKey = stripePublishableKey.trim();
      await Stripe.instance
          .applySettings()
          .timeout(const Duration(seconds: 8));
    }
  } catch (error) {
    if (kDebugMode) {
      debugPrint('stripe_init_error=$error');
    }
  }

  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 8));
  } catch (error) {
    if (kDebugMode) {
      debugPrint('firebase_init_error=$error');
    }
  }
}
