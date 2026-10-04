import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

const firebaseProjectId = 'datedawn';
const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

bool get hasWebFirebaseConfig =>
    DefaultFirebaseOptions.web.apiKey.isNotEmpty &&
    DefaultFirebaseOptions.web.appId.isNotEmpty;

FirebaseOptions get firebaseOptions => DefaultFirebaseOptions.currentPlatform;
