import 'package:intl/intl.dart';

class Helpers {
  // Formatar timestamp para exibição
  static String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Hoje - mostra apenas a hora
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      // Ontem
      return 'Ontem';
    } else if (difference.inDays < 7) {
      // Última semana - mostra o dia da semana
      return DateFormat('EEEE', 'pt_BR').format(dateTime);
    } else {
      // Mais antigo - mostra a data
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  // Formatar timestamp detalhado
  static String formatDetailedTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Hoje às ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Ontem às ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('dd/MM/yyyy às HH:mm').format(dateTime);
    }
  }

  // Formatar tamanho de arquivo
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Obter iniciais do nome
  static String getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    } else {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
  }

  // Validar email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Truncar texto
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Gerar cor a partir do ID do usuário (para avatares)
  static int generateColorFromId(String id) {
    int hash = 0;
    for (int i = 0; i < id.length; i++) {
      hash = id.codeUnitAt(i) + ((hash << 5) - hash);
    }

    final colors = [
      0xFF1976D2, // Azul
      0xFFD32F2F, // Vermelho
      0xFF388E3C, // Verde
      0xFFF57C00, // Laranja
      0xFF7B1FA2, // Roxo
      0xFF0097A7, // Ciano
      0xFFC2185B, // Rosa
      0xFF5D4037, // Marrom
    ];

    return colors[hash.abs() % colors.length];
  }
}
