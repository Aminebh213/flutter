// lib/pages/gestion_contact.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
        _contacts = [
          Contact(prenom: 'Ahmed', nom: 'Ben Ali', telephone: '+216 20 123 456', email: 'ahmed@email.com'),
          Contact(prenom: 'Fatma', nom: 'Trabelsi', telephone: '+216 22 234 567', email: 'fatma@email.com'),
        ];
        _filteredContacts = List.from(_contacts);
        _fabAnimationController.forward();
        return;
      }

      final list = await _db.getAllContacts();

      if (list.isEmpty) {
        _contacts = [
          Contact(prenom: 'Ahmed', nom: 'Ben Ali', telephone: '+216 20 123 456', email: 'ahmed@email.com'),
          Contact(prenom: 'Fatma', nom: 'Trabelsi', telephone: '+216 22 234 567', email: 'fatma@email.com'),
        ];
      } else {
        _contacts = list;
      }

      _filteredContacts = List.from(_contacts);
      _fabAnimationController.forward();

    } catch (e) {
      _contacts = [];
      _filteredContacts = [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredContacts = List.from(_contacts);
      } else {
        final s = query.toLowerCase();
        _filteredContacts = _contacts.where((c) {
          final nomComplet = '${c.prenom} ${c.nom}'.toLowerCase();
          return nomComplet.contains(s) ||
                 c.telephone.toLowerCase().contains(s) ||
                 c.email.toLowerCase().contains(s);
        }).toList();
      }
    });
  }

  // ---------- Méthodes implémentées (add / edit / delete / details) ----------

  // Ajouter un contact
  void _addContact() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 12,
          ),
          child: _ContactDialog(
            onSave: (Contact newContact) async {
              try {
                if (kIsWeb) {
                  // Générer un id temporaire pour la web demo
                  newContact.id = DateTime.now().millisecondsSinceEpoch;
                  setState(() {
                    _contacts.insert(0, newContact);
                    _filterContacts(_searchController.text);
                  });
                  _showSnackBar("Contact ajouté", Colors.green);
                  return;
                }

                final id = await _db.insertContact(newContact);
                newContact.id = id;
                setState(() {
                  _contacts.insert(0, newContact);
                  _filterContacts(_searchController.text);
                });
                _showSnackBar("Contact ajouté", Colors.green);
              } catch (e) {
                _showSnackBar("Erreur lors de l'ajout", Colors.red);
              }
            },
          ),
        ),
      ),
    );
  }

  // Modifier un contact (index correspond à _filteredContacts index)
  void _editContact(int index) {
    final contact = _filteredContacts[index];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 12,
          ),
          child: _ContactDialog(
            contact: contact,
            onSave: (Contact updated) async {
              try {
                if (kIsWeb) {
                  // mettre à jour en mémoire (web demo)
                  final masterIndex = _contacts.indexWhere((c) => c.id == updated.id);
                  if (masterIndex != -1) {
                    setState(() {
                      _contacts[masterIndex] = updated;
                      _filterContacts(_searchController.text);
                    });
                  } else {
                    // fallback : remplacer par matching name/email/phone
                    final fallback = _contacts.indexWhere((c) =>
                        c.email == updated.email || c.telephone == updated.telephone);
                    if (fallback != -1) {
                      setState(() {
                        _contacts[fallback] = updated;
                        _filterContacts(_searchController.text);
                      });
                    }
                  }
                  _showSnackBar("Contact modifié", Colors.green);
                  return;
                }

                await _db.updateContact(updated);

                final masterIndex = _contacts.indexWhere((c) => c.id == updated.id);
                if (masterIndex != -1) {
                  setState(() {
                    _contacts[masterIndex] = updated;
                    _filterContacts(_searchController.text);
                  });
                } else {
                  // si pas trouvé par id, essayer par email/telephone
                  final fallback = _contacts.indexWhere((c) =>
                      c.email == updated.email || c.telephone == updated.telephone);
                  if (fallback != -1) {
                    setState(() {
                      _contacts[fallback] = updated;
                      _filterContacts(_searchController.text);
                    });
                  }
                }
                _showSnackBar("Contact modifié", Colors.green);
              } catch (e) {
                _showSnackBar("Erreur lors de la modification", Colors.red);
              }
            },
          ),
        ),
      ),
    );
  }

  // Supprimer un contact (index correspond à _filteredContacts index)
  void _deleteContact(int index) {
    final contact = _filteredContacts[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: Text("Voulez-vous supprimer ${contact.fullName} ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context); // fermer le dialog
              try {
                if (!kIsWeb && contact.id != null) {
                  await _db.deleteContact(contact.id!);
                }
                // Supprimer localement des deux listes
                setState(() {
                  _contacts.removeWhere((c) => c.id == contact.id && contact.id != null);
                  // Si id null (rare), supprimer par matching téléphone/email
                  _contacts.removeWhere((c) =>
                      contact.id == null &&
                      (c.email == contact.email || c.telephone == contact.telephone));
                  _filterContacts(_searchController.text);
                });
                _showSnackBar("Contact supprimé", Colors.green);
              } catch (e) {
                _showSnackBar("Erreur lors de la suppression", Colors.red);
              }
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }

  // Afficher les détails d'un contact
  void _showContactDetails(Contact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: bottomInset + bottomPadding + 12,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                CircleAvatar(
                  radius: 36,
                  backgroundColor: _getAvatarColor(contact.prenom),
                  child: Text(_getInitials(contact.prenom, contact.nom), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Text(contact.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(contact.email, style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 16),

                _buildModernDetailRow(Icons.phone_rounded, "Téléphone", contact.telephone, onTap: () {
                  Navigator.pop(context);
                  _openWhatsApp(contact.telephone);
                }),

                const SizedBox(height: 12),

                _buildModernDetailRow(Icons.email_rounded, "Email", contact.email),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // trouver l'index filtré et ouvrir edit
                          final idx = _filteredContacts.indexWhere((c) => c.id == contact.id);
                          if (idx != -1) {
                            _editContact(idx);
                          } else {
                            // try find by phone/email fallback
                            final fallbackIdx = _filteredContacts.indexWhere((c) =>
                                c.email == contact.email || c.telephone == contact.telephone);
                            if (fallbackIdx != -1) _editContact(fallbackIdx);
                          }
                        },
                        child: const Text("Modifier"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          Navigator.pop(context);
                          final idx = _filteredContacts.indexWhere((c) => c.id == contact.id);
                          if (idx != -1) {
                            _deleteContact(idx);
                          } else {
                            final fallbackIdx = _filteredContacts.indexWhere((c) =>
                                c.email == contact.email || c.telephone == contact.telephone);
                            if (fallbackIdx != -1) _deleteContact(fallbackIdx);
                          }
                        },
                        child: const Text("Supprimer"),
                      ),
                    ),
                  ],
                ),

                // espace final pour éviter recouvrement par la barre gestuelle
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // ⬇️ Version 2 : icône chat modernisée (verte, alignée, propre)
  Widget _buildModernDetailRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    final row = Container(
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
                Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: onTap != null ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),

          if (onTap != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.chat, color: Colors.green),
                onPressed: onTap,
                tooltip: "Contacter sur WhatsApp",
              ),
            ),
        ],
      ),
    );

    return onTap != null
        ? InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: row)
        : row;
  }
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text("Déconnexion"),
          ],
        ),
        content: const Text("Voulez-vous vraiment vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.goNamed('signin');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Déconnexion"),
          )
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
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Rechercher un contact...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                style: const TextStyle(fontSize: 16),
              )
            : const Text(
                "Mes Contacts",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
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
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.black87),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == "logout") _logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "profile",
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
                value: "logout",
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red),
                    SizedBox(width: 12),
                    Text("Déconnexion", style: TextStyle(color: Colors.red)),
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
          icon: const Icon(Icons.add_rounded),
          label: const Text("Nouveau"),
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE5E7EB),
            ),
            child: Icon(
              _searchController.text.isEmpty ? Icons.contacts_rounded : Icons.search_off_rounded,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isEmpty ? "Aucun contact" : "Aucun résultat",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? "Commencez par ajouter votre premier contact"
                : "Essayez une autre recherche",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
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

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                offset: const Offset(0, 3),
                blurRadius: 8,
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

            leading: CircleAvatar(
              radius: 26,
              backgroundColor: _getAvatarColor(contact.prenom),
              child: Text(
                _getInitials(contact.prenom, contact.nom),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),

            title: Text(
              contact.fullName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(Icons.phone_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),

                    // NUMÉRO + ICÔNE WHATSAPP MODERNE
                    Expanded(
                      child: Row(
                        children: [
                          // texte du numéro cliquable
                          InkWell(
                            onTap: () => _openWhatsApp(contact.telephone),
                            child: Text(
                              contact.telephone,
                              style: const TextStyle(
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // bouton moderne
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.chat, size: 16, color: Colors.green),
                              onPressed: () => _openWhatsApp(contact.telephone),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(Icons.email_rounded, size: 14, color: Colors.grey),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey[700]),
              onSelected: (value) {
                if (value == "details") _showContactDetails(contact);
                if (value == "edit") _editContact(index);
                if (value == "delete") _deleteContact(index);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: "details",
                  child: Row(
                    children: [
                      Icon(Icons.info, size: 20),
                      SizedBox(width: 10),
                      Text("Détails"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: "edit",
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 10),
                      Text("Modifier"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: "delete",
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 10),
                      Text("Supprimer", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
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

  // ---------- OUVERTURE WHATSAPP ----------
  Future<void> _openWhatsApp(String rawNumber) async {
    if (rawNumber.trim().isEmpty) {
      _showSnackBar("Numéro vide", Colors.red);
      return;
    }

    // Nettoyage du numéro
    String digits = rawNumber.replaceAll(RegExp(r'[^0-9+]'), '');

    if (digits.startsWith('+')) digits = digits.substring(1);
    if (digits.startsWith('00')) digits = digits.replaceFirst('00', '');

    // Si numéro tunisien local → ajouter +216
    if (digits.startsWith('0')) {
      digits = digits.replaceFirst(RegExp(r'^0+'), '');
      digits = '216$digits';
    }

    if (digits.length < 6) {
      _showSnackBar("Numéro invalide", Colors.red);
      return;
    }

    final uri = Uri.parse("https://wa.me/$digits");

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _showSnackBar("Impossible d'ouvrir WhatsApp", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Erreur lors de l'ouverture", Colors.red);
    }
  }
}

// ---------- DIALOG POUR AJOUTER / MODIFIER UN CONTACT ----------
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

    _prenomController = TextEditingController(text: widget.contact?.prenom ?? "");
    _nomController = TextEditingController(text: widget.contact?.nom ?? "");
    _telephoneController = TextEditingController(text: widget.contact?.telephone ?? "");
    _emailController = TextEditingController(text: widget.contact?.email ?? "");
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.only(bottom: bottomInset + bottomPadding + 12),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),

            child: Form(
              key: _formKey,

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

                  const SizedBox(height: 20),

                  Text(
                    widget.contact == null ? "Nouveau contact" : "Modifier le contact",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 24),

                  _buildField(
                    controller: _prenomController,
                    label: "Prénom",
                    icon: Icons.person_outline_rounded,
                    validator: (v) => v!.isEmpty ? "Prénom requis" : null,
                  ),

                  const SizedBox(height: 16),

                  _buildField(
                    controller: _nomController,
                    label: "Nom",
                    icon: Icons.person_rounded,
                    validator: (v) => v!.isEmpty ? "Nom requis" : null,
                  ),

                  const SizedBox(height: 16),

                  _buildField(
                    controller: _telephoneController,
                    label: "Téléphone",
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? "Téléphone requis" : null,
                  ),

                  const SizedBox(height: 16),

                  _buildField(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v!.isEmpty) return "Email requis";
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                        return "Email invalide";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Annuler"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          child: const Text("Enregistrer"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  // espace final pour la barre système
                  SizedBox(height: bottomPadding + 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
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
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}