import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/presence_service.dart';
import '../../services/reaction_service.dart';
import '../../models/message.dart';
import '../../widgests/message_bubble.dart';
import '../../widgests/chat_input.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String conversationName;
  final String? avatarUrl;
  final bool? isOnline;
  final bool isGroup;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.conversationName,
    this.avatarUrl,
    this.isOnline,
    this.isGroup = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  late ConversationProvider _conversationProvider;
  final _presenceService = PresenceService(); // Adicionar serviço de presença
  final _reactionService = ReactionService(); // Adicionar serviço de reações
  Timer? _typingTimer;
  List<Map<String, dynamic>> _typingUsers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Observar ciclo de vida

    _conversationProvider = ConversationProvider();
    _conversationProvider.loadMessages(widget.conversationId);

    _presenceService.setOnlineStatus(true);

    _presenceService.watchTypingUsers(widget.conversationId).listen((users) {
      if (mounted) {
        setState(() {
          _typingUsers = users;
        });
      }
    });

    // Carregar mais mensagens ao chegar no topo
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _conversationProvider.loadMoreMessages();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _conversationProvider.dispose();
    _typingTimer?.cancel();
    _presenceService
        .stopTyping(widget.conversationId); // Parar digitação ao sair
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _presenceService.setOnlineStatus(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _presenceService.setOnlineStatus(false);
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _handleTyping() {
    _presenceService.startTyping(widget.conversationId);

    // Cancelar timer anterior
    _typingTimer?.cancel();

    // Parar digitação após 3 segundos de inatividade
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _presenceService.stopTyping(widget.conversationId);
    });
  }

  Future<void> _handleSendMedia(File file, String messageType) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Enviando arquivo...'),
        duration: Duration(seconds: 2),
      ),
    );

    final success =
        await _conversationProvider.sendMediaMessage(file, messageType);

    if (!success && mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
              _conversationProvider.errorMessage ?? 'Erro ao enviar arquivo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleReaction(String messageId, String emoji) async {
    try {
      await _reactionService.addReaction(messageId: messageId, emoji: emoji);
      // Recarregar mensagens para atualizar reações
      _conversationProvider.loadMessages(widget.conversationId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar reação: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().currentUser?.id;

    return ChangeNotifierProvider.value(
      value: _conversationProvider,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: widget.avatarUrl != null
                    ? NetworkImage(widget.avatarUrl!)
                    : null,
                child: widget.avatarUrl == null
                    ? Text(widget.conversationName[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.conversationName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_typingUsers.isNotEmpty)
                      Text(
                        'digitando...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[300],
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else if (!widget.isGroup && widget.isOnline != null)
                      Text(
                        widget.isOnline! ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isOnline!
                              ? Colors.green[300]
                              : Colors.grey[400],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                // TODO: Implementar ações
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'info',
                  child: Text('Informações'),
                ),
                const PopupMenuItem(
                  value: 'mute',
                  child: Text('Silenciar'),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Text('Limpar conversa'),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Consumer<ConversationProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoadingMessages) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(provider.errorMessage!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                provider.loadMessages(widget.conversationId),
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('Nenhuma mensagem ainda'),
                          const SizedBox(height: 8),
                          Text(
                            'Envie uma mensagem para iniciar a conversa',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.messages.length,
                    itemBuilder: (context, index) {
                      final message = provider.messages[index];
                      final isMe = message.senderId == currentUserId;
                      final showAvatar = widget.isGroup && !isMe;

                      return MessageBubble(
                        message: message,
                        isMe: isMe,
                        showAvatar: showAvatar,
                        onEdit: message.canEdit() && isMe
                            ? () => _showEditDialog(message)
                            : null,
                        onDelete:
                            isMe ? () => _confirmDelete(message.id) : null,
                        onReact: (emoji) => _handleReaction(
                            message.id, emoji), // Adicionar callback
                      );
                    },
                  );
                },
              ),
            ),
            ChatInput(
              onSendMessage: (content) {
                _conversationProvider.sendTextMessage(content);
                _presenceService.stopTyping(
                    widget.conversationId); // Parar digitação ao enviar
              },
              onSendMedia: _handleSendMedia,
              onTyping: _handleTyping, // Adicionar callback de digitação
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Message message) {
    final controller = TextEditingController(text: message.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar mensagem'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Digite sua mensagem',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _conversationProvider.editMessage(
                  message.id,
                  controller.text.trim(),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String messageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar mensagem'),
        content: const Text('Tem certeza que deseja deletar esta mensagem?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _conversationProvider.deleteMessage(messageId);
    }
  }
}
