import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
}
