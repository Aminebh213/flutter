// lib/pages/gestion_contact.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';
import '../models/contact.dart';
import '../services/db_helper.dart';

class GestionContactPage extends StatefulWidget {
  final String userEmail;

  const GestionContactPage({
    Key? key,
    required this.userEmail,
  }) : super(key: key);

  @override
  State<GestionContactPage> createState() => _GestionContactPageState();
}

class _GestionContactPageState extends State<GestionContactPage> with SingleTickerProviderStateMixin {
  final DbHelper _db = DbHelper();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = true;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _filterContacts(_searchController.text);
    });

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );

    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        debugPrint('[DB] Platform = Web -> sqflite non supporté. Chargement de données de demo.');
        _contacts = [
          Contact(prenom: 'Ahmed', nom: 'Ben Ali', telephone: '+216 20 123 456', email: 'ahmed.benali@email.com'),
          Contact(prenom: 'Fatma', nom: 'Trabelsi', telephone: '+216 22 234 567', email: 'fatma.trabelsi@email.com'),
        ];
        _filteredContacts = List.from(_contacts);
        _fabAnimationController.forward();
        return;
      }

      final list = await _db.getAllContacts();

      if (list.isEmpty) {
        _contacts = [
          Contact(prenom: 'Ahmed', nom: 'Ben Ali', telephone: '+216 20 123 456', email: 'ahmed.benali@email.com'),
          Contact(prenom: 'Fatma', nom: 'Trabelsi', telephone: '+216 22 234 567', email: 'fatma.trabelsi@email.com'),
          Contact(prenom: 'Mohamed', nom: 'Karim', telephone: '+216 25 345 678', email: 'mohamed.karim@email.com'),
        ];

        Future.wait(_contacts.map((c) => _db.insertContact(c))).then((_) async {
          try {
            final refreshed = await _db.getAllContacts();
            if (mounted) {
              setState(() {
                _contacts = refreshed;
                _filteredContacts = List.from(_contacts);
              });
            }
          } catch (e, st) {
            debugPrint('[DB] Erreur lors du refresh après insert d\'exemples: $e\n$st');
          }
        }).catchError((e, st) {
          debugPrint('[DB] Erreur lors de l\'insertion d\'exemples: $e\n$st');
        });
      } else {
        _contacts = list;
        _filteredContacts = List.from(_contacts);
      }
      _fabAnimationController.forward();
    } catch (e, st) {
      debugPrint('[_loadContacts] Erreur: $e');
      debugPrint(st.toString());
      _contacts = [];
      _filteredContacts = [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredContacts = List.from(_contacts);
      } else {
        final s = query.toLowerCase().trim();
        _filteredContacts = _contacts.where((c) {
          final nomComplet = '${c.prenom} ${c.nom}'.toLowerCase();
          return nomComplet.contains(s) ||
              c.telephone.toLowerCase().contains(s) ||
              c.email.toLowerCase().contains(s);
        }).toList();
      }
    });
  }

  void _addContact() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContactDialog(
        onSave: (contact) async {
          try {
            final id = await _db.insertContact(contact);
            contact.id = id;
            setState(() {
              _contacts.add(contact);
              _filterContacts(_searchController.text);
            });
            HapticFeedback.mediumImpact();
            _showSnackBar('Contact ajouté avec succès', Colors.green);
            SemanticsService.announce('Contact ${contact.prenom} ${contact.nom} ajouté', TextDirection.ltr);
          } catch (e, st) {
            debugPrint('[DB] Erreur insertContact: $e\n$st');
            _showSnackBar('Erreur lors de l\'ajout', Colors.red);
            SemanticsService.announce('Erreur lors de l\'ajout du contact', TextDirection.ltr);
          }
        },
      ),
    );
  }

  void _editContact(int filteredIndex) {
    final contact = _filteredContacts[filteredIndex];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContactDialog(
        contact: contact,
        onSave: (updated) async {
          try {
            updated.id = contact.id;
            await _db.updateContact(updated);
            final origIndex = _contacts.indexWhere((c) => c.id == contact.id);
            if (origIndex != -1) {
              setState(() {
                _contacts[origIndex] = updated;
                _filterContacts(_searchController.text);
              });
            }
            HapticFeedback.mediumImpact();
            _showSnackBar('Contact modifié avec succès', Colors.blue);
            SemanticsService.announce('Contact ${updated.prenom} ${updated.nom} modifié', TextDirection.ltr);
          } catch (e, st) {
            debugPrint('[DB] Erreur updateContact: $e\n$st');
            _showSnackBar('Erreur lors de la modification', Colors.red);
            SemanticsService.announce('Erreur lors de la modification du contact', TextDirection.ltr);
          }
        },
      ),
    );
  }

  void _deleteContact(int filteredIndex) {
    final contact = _filteredContacts[filteredIndex];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        semanticLabel: 'Confirmer la suppression',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Confirmer la suppression'),
          ],
        ),
        content: Text('Voulez-vous vraiment supprimer ${contact.fullName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              try {
                if (contact.id != null) await _db.deleteContact(contact.id!);
                setState(() {
                  _contacts.removeWhere((c) => c.id == contact.id);
                  _filterContacts(_searchController.text);
                });
                Navigator.pop(context);
                HapticFeedback.heavyImpact();
                _showSnackBar('Contact supprimé', Colors.red);
                SemanticsService.announce('Contact ${contact.prenom} ${contact.nom} supprimé', TextDirection.ltr);
              } catch (e, st) {
                debugPrint('[DB] Erreur deleteContact: $e\n$st');
                _showSnackBar('Erreur lors de la suppression', Colors.red);
                SemanticsService.announce('Erreur lors de la suppression du contact', TextDirection.ltr);
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showContactDetails(Contact contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Hero(
              tag: 'avatar_${contact.id}',
              child: CircleAvatar(
                radius: 50,
                backgroundColor: _getAvatarColor(contact.prenom),
                child: Text(
                  _getInitials(contact.prenom, contact.nom),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              contact.fullName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildModernDetailRow(Icons.phone_rounded, 'Téléphone', contact.telephone),
            const SizedBox(height: 16),
            _buildModernDetailRow(Icons.email_rounded, 'Email', contact.email),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDetailRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        semanticLabel: 'Déconnexion',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Déconnexion'),
          ],
        ),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              context.goNamed('signin');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Déconnecté avec succès'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF43F5E),
      const Color(0xFFF97316),
      const Color(0xFF14B8A6),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
    ];
    return colors[name.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Rechercher un contact...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
          ),
        )
            : const Text(
          'Mes Contacts',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: Colors.black87,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filterContacts('');
                }
              });
            },
            tooltip: _isSearching ? 'Fermer la recherche' : 'Rechercher',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.black87),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.userEmail,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red),
                    SizedBox(width: 12),
                    Text(
                      'Déconnexion',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredContacts.isEmpty
          ? _buildEmptyState()
          : _buildContactsList(),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _addContact,
          tooltip: 'Ajouter un contact',
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nouveau'),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchController.text.isEmpty
                  ? Icons.contacts_rounded
                  : Icons.search_off_rounded,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isEmpty ? 'Aucun contact' : 'Aucun résultat',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              _searchController.text.isEmpty
                  ? 'Commencez par ajouter votre premier contact'
                  : 'Essayez une autre recherche',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    return ListView.builder(
      itemCount: _filteredContacts.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Hero(
                tag: 'avatar_${contact.id}',
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: _getAvatarColor(contact.prenom),
                  child: Text(
                    _getInitials(contact.prenom, contact.nom),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              title: Text(
                contact.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        contact.telephone,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email_rounded, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          contact.email,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: Colors.grey[600]),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'details') _showContactDetails(contact);
                  else if (value == 'edit') _editContact(index);
                  else if (value == 'delete') _deleteContact(index);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Détails'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () => _showContactDetails(contact),
            ),
          ),
        );
      },
    );
  }

  String _getInitials(String prenom, String nom) {
    final a = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final b = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$a$b';
  }
}

// Dialog moderne pour ajouter/modifier un contact
class _ContactDialog extends StatefulWidget {
  final Contact? contact;
  final Function(Contact) onSave;

  const _ContactDialog({this.contact, required this.onSave});

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _prenomController;
  late final TextEditingController _nomController;
  late final TextEditingController _telephoneController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _prenomController = TextEditingController(text: widget.contact?.prenom ?? '');
    _nomController = TextEditingController(text: widget.contact?.nom ?? '');
    _telephoneController = TextEditingController(text: widget.contact?.telephone ?? '');
    _emailController = TextEditingController(text: widget.contact?.email ?? '');
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final contact = Contact(
        id: widget.contact?.id,
        prenom: _prenomController.text.trim(),
        nom: _nomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        email: _emailController.text.trim(),
      );
      widget.onSave(contact);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.contact == null ? 'Nouveau contact' : 'Modifier le contact',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildModernTextField(
                  controller: _prenomController,
                  label: 'Prénom',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Prénom requis' : null,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _nomController,
                  label: 'Nom',
                  icon: Icons.person_rounded,
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Nom requis' : null,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _telephoneController,
                  label: 'Téléphone',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Téléphone requis' : null,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) return 'Email requis';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!.trim())) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}