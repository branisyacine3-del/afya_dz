import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // سنستخدم نفس الإعدادات للأندرويد لنتجاوز تعقيدات الملفات
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('DefaultFirebaseOptions have not been configured for ios.');
      case TargetPlatform.macOS:
        throw UnsupportedError('DefaultFirebaseOptions have not been configured for macos.');
      case TargetPlatform.windows:
        throw UnsupportedError('DefaultFirebaseOptions have not been configured for windows.');
      case TargetPlatform.linux:
        throw UnsupportedError('DefaultFirebaseOptions have not been configured for linux.');
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // إعداداتك التي أرسلتها
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDlQHl2B8d_8nw8-N6_51MEH4j_KYqz7NA',
    appId: '1:311376524644:web:a3d9c77a53c0570a0eb671',
    messagingSenderId: '311376524644',
    projectId: 'afya-dz',
    authDomain: 'afya-dz.firebaseapp.com',
    storageBucket: 'afya-dz.firebasestorage.app',
  );

  // سنستخدم نفس البيانات للأندرويد كحل بديل
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDlQHl2B8d_8nw8-N6_51MEH4j_KYqz7NA',
    appId: '1:311376524644:web:a3d9c77a53c0570a0eb671',
    messagingSenderId: '311376524644',
    projectId: 'afya-dz',
    storageBucket: 'afya-dz.firebasestorage.app',
  );
}
