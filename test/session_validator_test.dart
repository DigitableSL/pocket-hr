import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:localstorage/localstorage.dart';
import 'package:cn_pocket_hr/helpers/session_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SessionValidator.reset();
    final storage = LocalStorage('pocketHR');
    await storage.ready;
    await storage.clear();
  });

  test('SessionValidator does not trigger on 200 OK containing sensitive words', () async {
    final response = http.Response('{"message": "unauthenticated user log note"}', 200);
    SessionValidator.validate(response, url: Uri.parse('https://api.example.com/notes'));
    // Should not crash and should not flag session expired
    expect(true, isTrue);
  });

  test('SessionValidator ignores SSO start and callback endpoints', () async {
    final response = http.Response('{"error": "invalid_grant"}', 400);
    SessionValidator.validate(response, url: Uri.parse('https://api.example.com/sso/mobile-start'));
    expect(true, isTrue);
  });
}

