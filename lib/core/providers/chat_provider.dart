import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

class ChatState {
  final List<ChatThread> threads;
  final bool isLoading;

  ChatState({this.threads = const [], this.isLoading = false});

  ChatState copyWith({List<ChatThread>? threads, bool? isLoading}) {
    return ChatState(
      threads: threads ?? this.threads,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ChatNotifier(apiService);
});

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(ApiService apiService) : super(ChatState()) {
    fetchThreads();
  }

  Future<void> fetchThreads() async {
    state = state.copyWith(isLoading: true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(threads: [], isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void receiveMessage(ChatMessage message, String threadId) {
    // Update local thread state
  }
}
