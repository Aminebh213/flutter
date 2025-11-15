// lib/pages/signin_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _buttonFocusNode = FocusNode();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _buttonFocusNode.dispose();
    super.dispose();
  }

  void _announceMessage(String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  Future<void> _handleSignIn() async {
    // Réinitialiser le message d'erreur
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      _announceMessage('Veuillez corriger les erreurs dans le formulaire');
      HapticFeedback.lightImpact();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _announceMessage('Connexion en cours');
    HapticFeedback.mediumImpact();

    try {
      // Simulation d'une requête réseau
      await Future.delayed(const Duration(seconds: 2));

      // Simulation de validation
      if (_emailController.text.contains('@') && _passwordController.text.length >= 6) {
        _announceMessage('Connexion réussie, bienvenue');
        HapticFeedback.heavyImpact();
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connexion réussie !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Identifiants incorrects');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Email ou mot de passe incorrect';
        });
        _announceMessage('Erreur: Email ou mot de passe incorrect');
        HapticFeedback.vibrate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Retour',
        ),
        title: const Text('Connexion'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                
                // Logo
                Semantics(
                  label: 'Application de gestion des contacts',
                  image: true,
                  child: Icon(
                    Icons.contact_phone,
                    size: 80,
                    color: theme.primaryColor,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Titre
                Semantics(
                  header: true,
                  child: Text(
                    'Gestion des Contacts',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Connectez-vous pour accéder à vos contacts',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Message d'erreur global
                if (_errorMessage != null)
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Champ Email
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'exemple@email.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    _passwordFocusNode.requestFocus();
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Champ Mot de passe
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    hintText: 'Entrez votre mot de passe',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: Semantics(
                      label: _obscurePassword 
                          ? 'Afficher le mot de passe' 
                          : 'Masquer le mot de passe',
                      hint: 'Appuyez pour ${_obscurePassword ? "afficher" : "masquer"} le mot de passe',
                      button: true,
                      child: ExcludeSemantics(
                        child: IconButton(
                          icon: Icon(
                            _obscurePassword 
                                ? Icons.visibility_outlined 
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                            _announceMessage(_obscurePassword 
                                ? 'Mot de passe masqué' 
                                : 'Mot de passe visible');
                            HapticFeedback.selectionClick();
                          },
                        ),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) {
                    _handleSignIn();
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Lien mot de passe oublié
                Align(
                  alignment: Alignment.centerRight,
                  child: Semantics(
                    label: 'Mot de passe oublié',
                    hint: 'Appuyez pour réinitialiser votre mot de passe',
                    button: true,
                    child: TextButton(
                      onPressed: () {
                        _announceMessage('Ouverture de la page de réinitialisation du mot de passe');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fonction de réinitialisation du mot de passe'),
                          ),
                        );
                      },
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Bouton de connexion
                Semantics(
                  label: _isLoading ? 'Connexion en cours' : 'Se connecter',
                  hint: _isLoading 
                      ? 'Veuillez patienter' 
                      : 'Appuyez pour vous connecter',
                  button: true,
                  enabled: !_isLoading,
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      focusNode: _buttonFocusNode,
                      onPressed: _isLoading ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: _isLoading
                          ? Semantics(
                              label: 'Chargement en cours',
                              liveRegion: true,
                              child: const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : const Text('Se connecter'),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Lien inscription
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pas encore de compte ? ',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    Semantics(
                      label: "S'inscrire",
                      hint: 'Appuyez pour créer un nouveau compte',
                      button: true,
                      child: TextButton(
                        onPressed: () {
                          _announceMessage("Ouverture de la page d'inscription");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Page d'inscription"),
                            ),
                          );
                        },
                        child: const Text(
                          "S'inscrire",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}