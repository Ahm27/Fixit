import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/chat_models.dart';
import '../../models/request_job.dart';
import '../../services/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_badge.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.thread, required this.isWorkerView});

  final MessageThread thread;
  final bool isWorkerView;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppController>().openThread(widget.thread.id);
    });
  }

  @override
  void dispose() {
    context.read<AppController>().closeThread(widget.thread.id);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final text = app.strings;
    final messages = app.messagesFor(widget.thread.id);
    final isSending = app.isSendingMessage(widget.thread.id);
    final selfId = widget.isWorkerView
        ? app.workerProfile?.id ?? ''
        : app.customerProfile?.id ?? '';
    final request = app.requestById(widget.thread.requestId);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            AvatarBadge(
              initials: widget.thread.initialsFor(widget.isWorkerView),
              size: 40,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.thread.counterpartFor(widget.isWorkerView),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  request?.title ?? text.serviceChat,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (request != null) _RequestContextBanner(request: request),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMine = message.senderId == selfId;
                return Align(
                  alignment: isMine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    decoration: BoxDecoration(
                      color: isMine ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomLeft: Radius.circular(isMine ? 20 : 8),
                        bottomRight: Radius.circular(isMine ? 8 : 20),
                      ),
                      border: isMine
                          ? null
                          : Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.body,
                          style: TextStyle(
                            color: isMine ? Colors.white : AppColors.text,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat.jm().format(message.createdAt),
                          style: TextStyle(
                            color: isMine
                                ? Colors.white.withValues(alpha: 0.72)
                                : AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemCount: messages.length,
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(hintText: text.typeMessage),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      minimumSize: const Size(56, 56),
                    ),
                    onPressed: isSending ? null : _send,
                    child: isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final app = context.read<AppController>();
    if (text.isEmpty || app.isSendingMessage(widget.thread.id)) {
      return;
    }
    await app.sendMessage(thread: widget.thread, body: text);
    _controller.clear();
  }
}

class _RequestContextBanner extends StatelessWidget {
  const _RequestContextBanner({required this.request});

  final RequestJob request;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.build_circle_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  request.customerAddress,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
