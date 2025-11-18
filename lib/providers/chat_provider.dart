import 'package:flutter/foundation.dart';
import 'dart:io';
import '../services/chat_service.dart';
import '../services/storage_service.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<Conversation> _conversations = [];
  bool _isLoadingConversations = false;
  String? _errorMessage;

  List<Conversation> get conversations => _conversations;
  bool get isLoadingConversations => _isLoadingConversations;
  String? get errorMessage => _errorMessage;

  // Carregar conversas
  Future<void> loadConversations() async {
    _isLoadingConversations = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _conversations = await _chatService.getUserConversations();
    } catch (e) {
      _errorMessage = e.toString();
      print('[v0] Erro ao carregar conversas: $e');
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  // Criar ou buscar conversa individual
  Future<String?> getOrCreateDirectConversation(String otherUserId) async {
    try {
      final conversationId =
          await _chatService.getOrCreateDirectConversation(otherUserId);
      await loadConversations(); // Recarregar lista
      return conversationId;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

class ConversationProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final StorageService _storageService =
      StorageService(); // Adicionar storage service

  List<Message> _messages = [];
  bool _isLoadingMessages = false;
  bool _isSending = false;
  String? _errorMessage;
  String? _conversationId;

  List<Message> get messages => _messages;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  // Carregar mensagens
  Future<void> loadMessages(String conversationId) async {
    _conversationId = conversationId;
    _isLoadingMessages = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _messages =
          await _chatService.getMessages(conversationId: conversationId);

      // Marcar como lidas
      await _chatService.markAsRead(conversationId);
    } catch (e) {
      _errorMessage = e.toString();
      print('[v0] Erro ao carregar mensagens: $e');
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  // Carregar mais mensagens (paginação)
  Future<void> loadMoreMessages() async {
    if (_conversationId == null || _messages.isEmpty) return;

    try {
      final oldestMessage = _messages.last;
      final olderMessages = await _chatService.getMessages(
        conversationId: _conversationId!,
        beforeMessageId: oldestMessage.id,
      );

      _messages.addAll(olderMessages);
      notifyListeners();
    } catch (e) {
      print('[v0] Erro ao carregar mais mensagens: $e');
    }
  }

  // Enviar mensagem de texto
  Future<bool> sendTextMessage(String content, {String? replyToId}) async {
    if (_conversationId == null) return false;

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final message = await _chatService.sendTextMessage(
        conversationId: _conversationId!,
        content: content,
        replyToId: replyToId,
      );

      // Adicionar mensagem localmente
      _messages.insert(0, message);

      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendMediaMessage(File file, String messageType,
      {String? caption}) async {
    if (_conversationId == null) return false;

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Obter ID do usuário
      final userId = _chatService.currentUserId;
      if (userId == null) throw Exception('Usuário não autenticado');

      // Upload do arquivo
      final mediaUrl = await _storageService.uploadChatMedia(
        file: file,
        conversationId: _conversationId!,
        userId: userId,
      );

      // Obter informações do arquivo
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();

      // Enviar mensagem
      final message = await _chatService.sendMediaMessage(
        conversationId: _conversationId!,
        mediaUrl: mediaUrl,
        messageType: messageType,
        mediaName: fileName,
        mediaSize: fileSize,
        caption: caption,
      );

      // Adicionar mensagem localmente
      _messages.insert(0, message);

      _isSending = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  // Editar mensagem
  Future<bool> editMessage(String messageId, String newContent) async {
    try {
      await _chatService.editMessage(messageId, newContent);

      // Atualizar localmente
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final oldMessage = _messages[index];
        _messages[index] = Message(
          id: oldMessage.id,
          conversationId: oldMessage.conversationId,
          senderId: oldMessage.senderId,
          content: newContent,
          messageType: oldMessage.messageType,
          isEdited: true,
          editedAt: DateTime.now(),
          createdAt: oldMessage.createdAt,
          updatedAt: DateTime.now(),
          senderName: oldMessage.senderName,
          senderAvatar: oldMessage.senderAvatar,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Deletar mensagem
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(messageId);

      // Remover localmente
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
