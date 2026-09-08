import 'package:flutter/material.dart';

import 'package:track_me/core/theme.dart';
import 'package:track_me/data/app_repository.dart';
import 'package:track_me/screens/assistant/assistant_chat_view.dart';
import 'package:track_me/services/assistant_service.dart';

class AssistantScreen extends StatefulWidget {
  static const String routeName = '/assistant';

  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _chatKey = GlobalKey<AssistantChatViewState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrackMe Assistant'),
        actions: [
          IconButton(
            tooltip: 'Help',
            icon: const Icon(Icons.help_outline),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('What can I do?'),
                content: const SingleChildScrollView(
                    child: Text(AssistantService.helpText)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Got it')),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Clear chat',
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () async {
              await AppRepository.instance.clearChat();
              _chatKey.currentState?.reload();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.primary.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: AppColors.brandGradient),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.forum_outlined,
                      color: Colors.white, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TrackMe CSR',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13.5)),
                      Text('Online · replies instantly & logs expenses',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .color)),
                    ],
                  ),
                ),
                const Text('●',
                    style: TextStyle(color: AppColors.income, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: AssistantChatView(key: _chatKey),
          ),
        ],
      ),
    );
  }
}
