import 'package:flutter/material.dart';
import '../../services/group_service.dart';
import '../../services/chat_service.dart';
import '../chat/chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _groupService = GroupService();
  final _chatService = ChatService();

  bool _isPublic = false;
  bool _isCreating = false;
  List<Map<String, dynamic>> _selectedMembers = [];
  List<Map<String, dynamic>> _searchResults = [];
  String _searchQuery = '';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      final results = await _chatService.searchUsers(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('Erro ao buscar usuários: $e');
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final groupId = await _groupService.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        isPublic: _isPublic,
        initialMemberIds:
            _selectedMembers.map((m) => m['id'] as String).toList(),
      );

      if (!mounted) return;

      // Navegar para o chat do grupo
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: groupId,
            conversationName: _nameController.text.trim(),
            isGroup: true,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar grupo: $e')),
        );
      }
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Grupo'),
        actions: [
          if (_isCreating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _createGroup,
              child: const Text('CRIAR'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar do grupo (placeholder)
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: const Icon(Icons.group, size: 50),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.camera_alt,
                          size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nome do grupo
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do grupo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Digite um nome para o grupo';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descrição
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),

            // Grupo público
            SwitchListTile(
              title: const Text('Grupo público'),
              subtitle: const Text('Qualquer pessoa pode encontrar e entrar'),
              value: _isPublic,
              onChanged: (value) {
                setState(() {
                  _isPublic = value;
                });
              },
            ),
            const Divider(),

            // Adicionar membros
            const Text(
              'Adicionar membros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // Campo de busca
            TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar usuários...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchQuery == value) {
                    _searchUsers(value);
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Membros selecionados
            if (_selectedMembers.isNotEmpty) ...[
              const Text(
                'Membros selecionados:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedMembers.map((member) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundImage: member['avatar_url'] != null
                          ? NetworkImage(member['avatar_url'] as String)
                          : null,
                      child: member['avatar_url'] == null
                          ? Text(
                              (member['username'] as String)[0].toUpperCase())
                          : null,
                    ),
                    label: Text(member['username'] as String),
                    onDeleted: () {
                      setState(() {
                        _selectedMembers.remove(member);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Resultados da busca
            if (_searchResults.isNotEmpty)
              ...(_searchResults.map((user) {
                final isSelected =
                    _selectedMembers.any((m) => m['id'] == user['id']);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['avatar_url'] != null
                        ? NetworkImage(user['avatar_url'] as String)
                        : null,
                    child: user['avatar_url'] == null
                        ? Text((user['username'] as String)[0].toUpperCase())
                        : null,
                  ),
                  title: Text(user['full_name'] as String? ??
                      user['username'] as String),
                  subtitle: Text('@${user['username']}'),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.add_circle_outline),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedMembers
                            .removeWhere((m) => m['id'] == user['id']);
                      } else {
                        _selectedMembers.add(user);
                      }
                    });
                  },
                );
              }).toList()),
          ],
        ),
      ),
    );
  }
}
