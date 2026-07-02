import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('RLS Test', (WidgetTester tester) async {
    await Supabase.initialize(
      url: 'https://xowudhicrbgjcplvkqnb.supabase.co',
      anonKey: 'sb_publishable__vbOvduayzWwqbeCY7a87Q_bzVVlXXo',
    );
    final client = Supabase.instance.client;
    await client.auth.signOut();
    try {
      final res = await client.from('users').select().limit(1);
      print('SUCCESS: $res');
    } catch (e) {
      print('ERROR: $e');
    }
  });
}
