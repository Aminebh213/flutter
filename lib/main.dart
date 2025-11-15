import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      home: LoginPage(onThemeToggle: toggleTheme),
    );
  }
}

// ==================== PAGE DE CONNEXION ====================
class LoginPage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  
  const LoginPage({super.key, required this.onThemeToggle});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = '';

  void _login() {
    String email = _emailController.text;
    String password = _passwordController.text;

    if (email == 'farahbahri25@gmail.com' && password == 'farah1234') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ContactsPage(onThemeToggle: widget.onThemeToggle),
        ),
      );
    } else {
      setState(() {
        _message = 'Email ou mot de passe incorrect !';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: widget.onThemeToggle,
            tooltip: 'Changer le thème',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Se connecter'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterPage(onThemeToggle: widget.onThemeToggle),
                  ),
                );
              },
              child: const Text("S'inscrire"),
            ),
            const SizedBox(height: 20),
            Text(
              _message,
              style: TextStyle(
                color: _message.contains('réussie') ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== PAGE D'INSCRIPTION ====================
class RegisterPage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  
  const RegisterPage({super.key, required this.onThemeToggle});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _message = '';

  void _register() {
    String nom = _nomController.text.trim();
    String prenom = _prenomController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (nom.isEmpty || prenom.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _message = 'Veuillez remplir tous les champs.');
    } else if (!email.contains('@')) {
      setState(() => _message = 'Veuillez entrer un email valide.');
    } else if (password.length < 6) {
      setState(() => _message = 'Le mot de passe doit contenir au moins 6 caractères.');
    } else {
      setState(() => _message = 'Inscription réussie 🎉');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("S'inscrire"),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: widget.onThemeToggle,
            tooltip: 'Changer le thème',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _register,
                child: const Text("Créer un compte"),
              ),
              const SizedBox(height: 20),
              Text(
                _message,
                style: TextStyle(
                  color: _message.contains('réussie') ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Retour à la connexion"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== MODÈLE DE CONTACT ====================
class Contact {
  String nom;
  String prenom;
  String email;
  String telephone;
  bool isFavorite;

  Contact({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    this.isFavorite = false,
  });
}

// ==================== ENUM POUR LE TRI ====================
enum SortOrder { aToZ, zToA, none }

// ==================== PAGE DE GESTION DES CONTACTS ====================
class ContactsPage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  
  const ContactsPage({super.key, required this.onThemeToggle});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> with TickerProviderStateMixin {
  final List<Contact> _contacts = [];
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  SortOrder _currentSortOrder = SortOrder.none;
  String _searchQuery = '';
  bool _showFavoritesOnly = false;

  // Liste filtrée et triée des contacts
  List<Contact> get _filteredContacts {
    List<Contact> filtered = _contacts.where((contact) {
      if (_showFavoritesOnly && !contact.isFavorite) return false;
      
      if (_searchQuery.isEmpty) return true;
      
      String query = _searchQuery.toLowerCase();
      return contact.nom.toLowerCase().contains(query) ||
          contact.prenom.toLowerCase().contains(query) ||
          contact.email.toLowerCase().contains(query) ||
          contact.telephone.toLowerCase().contains(query);
    }).toList();

    // Trier les contacts
    if (_currentSortOrder == SortOrder.aToZ) {
      filtered.sort((a, b) => '${a.prenom} ${a.nom}'.toLowerCase().compareTo('${b.prenom} ${b.nom}'.toLowerCase()));
    } else if (_currentSortOrder == SortOrder.zToA) {
      filtered.sort((a, b) => '${b.prenom} ${b.nom}'.toLowerCase().compareTo('${a.prenom} ${a.nom}'.toLowerCase()));
    }

    return filtered;
  }

  void _ajouterContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _viderChamps();
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nomController.text.trim().isNotEmpty &&
                  _prenomController.text.trim().isNotEmpty) {
                setState(() {
                  _contacts.add(Contact(
                    nom: _nomController.text.trim(),
                    prenom: _prenomController.text.trim(),
                    email: _emailController.text.trim(),
                    telephone: _telephoneController.text.trim(),
                  ));
                });
                _viderChamps();
                Navigator.pop(context);
                _afficherMessage('Contact ajouté avec succès !', Colors.green);
              } else {
                _afficherMessage('Le nom et le prénom sont obligatoires', Colors.red);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _modifierContact(int originalIndex) {
    int index = _contacts.indexOf(_filteredContacts[originalIndex]);
    
    _nomController.text = _contacts[index].nom;
    _prenomController.text = _contacts[index].prenom;
    _emailController.text = _contacts[index].email;
    _telephoneController.text = _contacts[index].telephone;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _viderChamps();
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nomController.text.trim().isNotEmpty &&
                  _prenomController.text.trim().isNotEmpty) {
                setState(() {
                  _contacts[index] = Contact(
                    nom: _nomController.text.trim(),
                    prenom: _prenomController.text.trim(),
                    email: _emailController.text.trim(),
                    telephone: _telephoneController.text.trim(),
                    isFavorite: _contacts[index].isFavorite,
                  );
                });
                _viderChamps();
                Navigator.pop(context);
                _afficherMessage('Contact modifié avec succès !', Colors.blue);
              } else {
                _afficherMessage('Le nom et le prénom sont obligatoires', Colors.red);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _supprimerContact(int originalIndex) {
    int index = _contacts.indexOf(_filteredContacts[originalIndex]);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer ${_contacts[index].prenom} ${_contacts[index].nom} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _contacts.removeAt(index);
              });
              Navigator.pop(context);
              _afficherMessage('Contact supprimé !', Colors.red);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _toggleFavorite(int originalIndex) {
    int index = _contacts.indexOf(_filteredContacts[originalIndex]);
    setState(() {
      _contacts[index].isFavorite = !_contacts[index].isFavorite;
    });
    _afficherMessage(
      _contacts[index].isFavorite ? 'Ajouté aux favoris ⭐' : 'Retiré des favoris',
      _contacts[index].isFavorite ? Colors.amber : Colors.grey,
    );
  }

  void _afficherDetails(int originalIndex) {
    int index = _contacts.indexOf(_filteredContacts[originalIndex]);
    final contact = _contacts[index];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                '${contact.prenom[0]}${contact.nom[0]}'.toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${contact.prenom} ${contact.nom}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            if (contact.isFavorite)
              const Icon(Icons.star, color: Colors.amber, size: 24),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.email.isNotEmpty) ...[
              const Row(
                children: [
                  Icon(Icons.email, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 5),
              Text(contact.email),
              const SizedBox(height: 15),
            ],
            if (contact.telephone.isNotEmpty) ...[
              const Row(
                children: [
                  Icon(Icons.phone, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text('Téléphone', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 5),
              Text(contact.telephone),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _viderChamps() {
    _nomController.clear();
    _prenomController.clear();
    _emailController.clear();
    _telephoneController.clear();
  }

  void _afficherMessage(String message, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: couleur,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deconnexion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(onThemeToggle: widget.onThemeToggle),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Trier par',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('A → Z'),
              trailing: _currentSortOrder == SortOrder.aToZ
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                setState(() => _currentSortOrder = SortOrder.aToZ);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Z → A'),
              trailing: _currentSortOrder == SortOrder.zToA
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                setState(() => _currentSortOrder = SortOrder.zToA);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Par défaut'),
              trailing: _currentSortOrder == SortOrder.none
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                setState(() => _currentSortOrder = SortOrder.none);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredContacts;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Contacts'),
        actions: [
          // Compteur de contacts
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Chip(
                label: Text(
                  '${_contacts.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.blue[700],
              ),
            ),
          ),
          // Bouton de tri
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            tooltip: 'Trier',
          ),
          // Bouton favoris
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.star : Icons.star_border,
              color: _showFavoritesOnly ? Colors.amber : null,
            ),
            onPressed: () {
              setState(() => _showFavoritesOnly = !_showFavoritesOnly);
            },
            tooltip: 'Favoris',
          ),
          // Bouton thème
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: widget.onThemeToggle,
            tooltip: 'Changer le thème',
          ),
          // Bouton de déconnexion
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _deconnexion,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un contact...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Liste des contacts
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showFavoritesOnly ? Icons.star_border : Icons.contacts_outlined,
                          size: 100,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _showFavoritesOnly
                              ? 'Aucun favori'
                              : _searchQuery.isNotEmpty
                                  ? 'Aucun résultat'
                                  : 'Aucun contact',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _showFavoritesOnly
                              ? 'Marquez des contacts comme favoris ⭐'
                              : _searchQuery.isNotEmpty
                                  ? 'Essayez avec d\'autres mots-clés'
                                  : 'Appuyez sur + pour ajouter votre premier contact',
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : AnimatedList(
                    key: GlobalKey<AnimatedListState>(),
                    padding: const EdgeInsets.all(8),
                    initialItemCount: filteredList.length,
                    itemBuilder: (context, index, animation) {
                      final contact = filteredList[index];
                      return SizeTransition(
                        sizeFactor: animation,
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          elevation: 3,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: contact.isFavorite ? Colors.amber : Colors.blue,
                              child: Text(
                                '${contact.prenom[0]}${contact.nom[0]}'.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${contact.prenom} ${contact.nom}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (contact.isFavorite)
                                  const Icon(Icons.star, color: Colors.amber, size: 18),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (contact.email.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.email, size: 14, color: Colors.grey),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            contact.email,
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (contact.telephone.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                                        const SizedBox(width: 5),
                                        Text(
                                          contact.telephone,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            trailing: SizedBox(
                              width: 140,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      contact.isFavorite ? Icons.star : Icons.star_border,
                                      color: contact.isFavorite ? Colors.amber : Colors.grey,
                                      size: 20,
                                    ),
                                    onPressed: () => _toggleFavorite(index),
                                    tooltip: 'Favori',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                    onPressed: () => _modifierContact(index),
                                    tooltip: 'Modifier',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () => _supprimerContact(index),
                                    tooltip: 'Supprimer',
                                  ),
                                ],
                              ),
                            ),
                            onTap: () => _afficherDetails(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterContact,
        tooltip: 'Ajouter un contact',
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}