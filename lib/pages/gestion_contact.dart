// lib/pages/gestion_contact.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart'; // <<-- AJOUTE CETTE LIGNE
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

class _GestionContactPageState extends State<GestionContactPage> {
  final DbHelper _db = DbHelper();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Écoute pour la recherche
    _searchController.addListener(() {
      _filterContacts(_searchController.text);
    });

    // Chargement initial des contacts (sécurisé)
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Chargement sécurisé des contacts depuis la DB
  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);

    try {
      // Si exécution sur le Web, sqflite n'est pas disponible -> fallback
      if (kIsWeb) {
        debugPrint('[DB] Platform = Web -> sqflite non supporté. Chargement de données de demo.');
        _contacts = [
          Contact(prenom: 'Ahmed', nom: 'Ben Ali', telephone: '+216 20 123 456', email: 'ahmed.benali@email.com'),
          Contact(prenom: 'Fatma', nom: 'Trabelsi', telephone: '+216 22 234 567', email: 'fatma.trabelsi@email.com'),
        ];
        _filteredContacts = List.from(_contacts);
        return;
      }

      final list = await _db.getAllContacts();

      if (list.isEmpty) {
        // Optionnel : insérer des exemples si la DB est vide (asynchrone)
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

  // Ajout d'un contact
  void _addContact() {
    showDialog(
      context: context,
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

            // Annonce pour lecteurs d'écran
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

  // Édition
  void _editContact(int filteredIndex) {
    final contact = _filteredContacts[filteredIndex];
    showDialog(
      context: context,
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

            // annonce modification
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

  // Suppression
  void _deleteContact(int filteredIndex) {
    final contact = _filteredContacts[filteredIndex];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        semanticLabel: 'Confirmer la suppression',
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${contact.fullName} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
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

                // annonce suppression
                SemanticsService.announce('Contact ${contact.prenom} ${contact.nom} supprimé', TextDirection.ltr);
              } catch (e, st) {
                debugPrint('[DB] Erreur deleteContact: $e\n$st');
                _showSnackBar('Erreur lors de la suppression', Colors.red);
                SemanticsService.announce('Erreur lors de la suppression du contact', TextDirection.ltr);
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showContactDetails(Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        semanticLabel: 'Détails du contact',
        title: Text(contact.fullName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.phone, 'Téléphone', contact.telephone),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.email, 'Email', contact.email),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ]),
        ),
      ],
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)));
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        semanticLabel: 'Déconnexion',
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.goNamed('signin');
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Déconnecté avec succès'), backgroundColor: Colors.orange, duration: Duration(seconds: 2)));
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(hintText: 'Rechercher un contact...', border: InputBorder.none),
              )
            : const Text('Gestion des Contacts'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
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
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'profile', child: Row(children: [const Icon(Icons.person), const SizedBox(width: 8), Expanded(child: Text(widget.userEmail, overflow: TextOverflow.ellipsis))])),
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Colors.red), SizedBox(width: 8), Text('Déconnexion', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredContacts.isEmpty
              ? _buildEmptyState()
              : _buildContactsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        tooltip: 'Ajouter un contact',
        child: Semantics(label: 'Ajouter un contact', button: true, child: const Icon(Icons.add)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(_searchController.text.isEmpty ? Icons.contacts_outlined : Icons.search_off, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(_searchController.text.isEmpty ? 'Aucun contact' : 'Aucun résultat', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text(_searchController.text.isEmpty ? 'Appuyez sur + pour ajouter votre premier contact' : 'Essayez une autre recherche', style: TextStyle(fontSize: 16, color: Colors.grey[500]), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildContactsList() {
    return ListView.builder(
      itemCount: _filteredContacts.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Semantics(
              label: 'Avatar ${contact.prenom} ${contact.nom}',
              child: CircleAvatar(backgroundColor: Theme.of(context).primaryColor, child: Text(_getInitials(contact.prenom, contact.nom), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ),
            title: Text(contact.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 4),
              Row(children: [const Icon(Icons.phone, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(contact.telephone)]),
              const SizedBox(height: 2),
              Row(children: [const Icon(Icons.email, size: 14, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text(contact.email, overflow: TextOverflow.ellipsis))]),
            ]),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'details') _showContactDetails(contact);
                else if (value == 'edit') _editContact(index);
                else if (value == 'delete') _deleteContact(index);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'details',
                  child: Semantics(
                    button: true,
                    label: 'Voir les détails de ${contact.prenom} ${contact.nom}',
                    child: Row(children: [Icon(Icons.info, size: 20), const SizedBox(width: 8), const Text('Détails')]),
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Semantics(
                    button: true,
                    label: 'Modifier ${contact.prenom} ${contact.nom}',
                    child: Row(children: [Icon(Icons.edit, size: 20), const SizedBox(width: 8), const Text('Modifier')]),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Semantics(
                    button: true,
                    label: 'Supprimer ${contact.prenom} ${contact.nom}',
                    child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), const SizedBox(width: 8), const Text('Supprimer', style: TextStyle(color: Colors.red))]),
                  ),
                ),
              ],
            ),
            onTap: () => _showContactDetails(contact),
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

// Dialog pour ajouter/modifier un contact
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
    return AlertDialog(
      semanticLabel: widget.contact == null ? 'Nouveau contact' : 'Modifier contact',
      title: Text(widget.contact == null ? 'Nouveau contact' : 'Modifier'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: _prenomController, decoration: const InputDecoration(labelText: 'Prénom *', prefixIcon: Icon(Icons.person_outline)), validator: (v) => v?.trim().isEmpty ?? true ? 'Requis' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _nomController, decoration: const InputDecoration(labelText: 'Nom *', prefixIcon: Icon(Icons.person)), validator: (v) => v?.trim().isEmpty ?? true ? 'Requis' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _telephoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Téléphone *', prefixIcon: Icon(Icons.phone)), validator: (v) => v?.trim().isEmpty ?? true ? 'Requis' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email)), validator: (value) {
              if (value?.trim().isEmpty ?? true) return 'Requis';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!.trim())) return 'Email invalide';
              return null;
            }),
          ]),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')), ElevatedButton(onPressed: _save, child: const Text('Enregistrer'))],
    );
  }
}
