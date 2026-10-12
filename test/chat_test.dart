import 'package:flutter_test/flutter_test.dart';
import 'package:sahmi/features/chat/chat_room.dart';

void main() {
  test('room parses with null creator (system room)', () {
    final r = ChatRoom.fromMap({
      'id': 'r1', 'name': 'عام', 'description': null,
      'created_by': null, 'created_at': '2026-10-12T10:00:00Z',
    });
    expect(r.name, 'عام');
    expect(r.createdBy, isNull);
    expect(r.description, isNull);
  });

  test('message parses with and without username', () {
    final base = {
      'id': 'm1', 'room_id': 'r1', 'user_id': 'u1',
      'content': 'مرحبا', 'created_at': '2026-10-12T10:00:00Z',
    };
    expect(ChatMessage.fromMap({...base, 'username': 'ali'}).username, 'ali');
    expect(ChatMessage.fromMap(base).username, isNull);
  });

  test('send error mapping', () {
    expect(chatErrorMessage('rate limit'), contains('كثيرة'));
    expect(chatErrorMessage('new row violates row-level security policy'), contains('غير مسموح'));
    expect(chatErrorMessage('boom'), 'تعذر إرسال الرسالة');
  });
}
