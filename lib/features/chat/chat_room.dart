// chat_room.dart
// غرف الدردشة: قائمة الغرف، فتح غرفة، إرسال واستقبال رسائل فورية عبر Supabase Realtime.
// Chat rooms: room list, chat sheet, realtime messages via Supabase Realtime.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat; // لا تستورد كل intl: فيها TextDirection يتعارض مع Flutter
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../auth/auth_repository.dart';

// ═══════════════════════════════════════════
// Models
// ═══════════════════════════════════════════

class ChatRoom {
  final String id;
  final String name;
  final String? description;
  final String? createdBy; // null للغرف النظامية
  final DateTime createdAt;

  const ChatRoom({
    required this.id,
    required this.name,
    this.description,
    this.createdBy,
    required this.createdAt,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map) => ChatRoom(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        createdBy: map['created_by'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class ChatMessage {
  final String id;
  final String roomId;
  final String userId;
  final String? username; // يملأه الخادم تلقائياً
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.userId,
    this.username,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'] as String,
        roomId: map['room_id'] as String,
        userId: map['user_id'] as String,
        username: map['username'] as String?,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

/// رسالة خطأ مناسبة للمستخدم / user-facing send error
String chatErrorMessage(String m) {
  final s = m.toLowerCase();
  if (s.contains('rate limit')) return 'أرسلت رسائل كثيرة، انتظر قليلاً';
  if (s.contains('row-level security')) return 'غير مسموح لك بالإرسال (هل الحساب محظور؟)';
  if (s.contains('empty')) return 'الرسالة فارغة';
  return 'تعذر إرسال الرسالة';
}

// ═══════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════

final chatRoomsProvider = FutureProvider.autoDispose<List<ChatRoom>>((ref) async {
  final db = ref.watch(supabaseProvider);
  final rows = await db.from('rooms').select().order('created_at', ascending: true);
  return [for (final r in rows) ChatRoom.fromMap(r)];
});

/// آخر 100 رسالة بالترتيب الزمني (الأقدم أولاً) مع تحديث فوري
final roomMessagesProvider =
    StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, roomId) {
  final db = ref.watch(supabaseProvider);
  return db
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('room_id', roomId)
      .order('created_at', ascending: false)
      .limit(100)
      .map((rows) => rows.reversed.map(ChatMessage.fromMap).toList());
});

// ═══════════════════════════════════════════
// Public entry point: showRoomsDialog
// ═══════════════════════════════════════════

Future<void> showRoomsDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _RoomsDialog());

class _RoomsDialog extends ConsumerWidget {
  const _RoomsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(chatRoomsProvider);
    return Dialog(
      backgroundColor: C.navy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480, maxWidth: 360),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('غرف الدردشة',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: rooms.when<Widget>(
              loading: () => const Center(child: CircularProgressIndicator(color: C.gold)),
              error: (_, __) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('تعذر تحميل الغرف', style: TextStyle(color: C.red)),
                  TextButton(
                    onPressed: () => ref.invalidate(chatRoomsProvider),
                    child: const Text('إعادة المحاولة'),
                  ),
                ]),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(
                    child: Text('لا توجد غرف حالياً', style: TextStyle(color: Colors.white54)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (context, i) {
                    final room = list[i];
                    return ListTile(
                      title: Text(room.name, style: const TextStyle(color: Colors.white)),
                      subtitle: room.description == null
                          ? null
                          : Text(room.description!,
                              style: const TextStyle(color: Colors.white54),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.chevron_left, color: Colors.white38),
                      onTap: () {
                        Navigator.of(context).pop();
                        openChatRoom(context, room);
                      },
                    );
                  },
                );
              },
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق', style: TextStyle(color: Colors.white70)),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Chat bottom sheet
// ═══════════════════════════════════════════

void openChatRoom(BuildContext context, ChatRoom room) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ChatRoomSheet(room: room),
  );
}

class _ChatRoomSheet extends ConsumerStatefulWidget {
  final ChatRoom room;
  const _ChatRoomSheet({required this.room});

  @override
  ConsumerState<_ChatRoomSheet> createState() => _ChatRoomSheetState();
}

class _ChatRoomSheetState extends ConsumerState<_ChatRoomSheet> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final db = ref.read(supabaseProvider);
    final user = db.auth.currentUser;
    if (user == null) return;

    setState(() { _sending = true; _error = null; });
    try {
      await db.from('messages').insert({
        'room_id': widget.room.id,
        'user_id': user.id,
        'content': text,
      });
      _controller.clear();
    } on PostgrestException catch (e) {
      if (mounted) setState(() => _error = chatErrorMessage(e.message));
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر إرسال الرسالة');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(roomMessagesProvider(widget.room.id));
    final myId = ref.watch(supabaseProvider).auth.currentUser?.id;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.75,
      decoration: const BoxDecoration(
        color: C.navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.room.name,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: messages.when<Widget>(
              loading: () => const Center(child: CircularProgressIndicator(color: C.gold)),
              error: (_, __) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('تعذر تحميل الرسائل', style: TextStyle(color: C.red)),
                  TextButton(
                    onPressed: () => ref.invalidate(roomMessagesProvider(widget.room.id)),
                    child: const Text('إعادة المحاولة'),
                  ),
                ]),
              ),
              data: (list) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
                });
                if (list.isEmpty) {
                  return const Center(
                    child: Text('لا توجد رسائل بعد، ابدأ المحادثة',
                        style: TextStyle(color: Colors.white54)),
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _MessageBubble(message: list[i], isMine: list[i].userId == myId),
                );
              },
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(_error!, style: const TextStyle(color: C.red, fontSize: 12)),
              ),
            ),
          _MessageInputBar(controller: _controller, sending: _sending, onSend: _send),
        ]),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.createdAt.toLocal());
    final name = message.username;
    return Align(
      alignment: isMine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.7),
        decoration: BoxDecoration(
          color: isMine ? C.green.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          if (!isMine && name != null && name.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('@$name',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(color: C.gold, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          Text(message.content, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ]),
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _MessageInputBar({required this.controller, required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white24))),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.send,
              inputFormatters: [LengthLimitingTextInputFormatter(500)],
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          IconButton(
            icon: sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: C.gold),
                  )
                : const Icon(Icons.send, color: C.gold),
            onPressed: sending ? null : onSend,
          ),
        ]),
      );
}
