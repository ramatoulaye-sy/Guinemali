import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/contact_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/storage_service.dart';
import 'package:uuid/uuid.dart';
import '../widgets/contact_card.dart';
import '../widgets/add_contact_dialog.dart';

/// Écran de gestion des contacts d'urgence (maximum 3)
class VictimContactsScreen extends StatefulWidget {
  const VictimContactsScreen({super.key});

  @override
  State<VictimContactsScreen> createState() => _VictimContactsScreenState();
}

class _VictimContactsScreenState extends State<VictimContactsScreen> {
  List<ContactModel> _contacts = [];
  bool _isLoading = true;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      setState(() => _isLoading = true);
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      
      if (userId == null) return;

      final response = await SupabaseService.instance.select(
        'contacts_urgence',
        filters: {'utilisateur_id': userId, 'actif': true},
        orderBy: 'priorite',
      );

      final contacts = (response as List?)
              ?.map((json) => ContactModel.fromJson(json as Map<String, dynamic>))
              .toList() 
          ?? [];

      // Fallback: lire depuis le cache si serveur renvoie vide
      if (contacts.isEmpty) {
        final cached = await StorageService.instance.getCachedContacts(userId);
        if (cached.isNotEmpty) {
          setState(() {
            _contacts = cached.map((c) => ContactModel(
              id: c['id'] as String,
              utilisateurId: c['user_id'] as String,
              nom: c['name'] as String,
              numeroTelephone: c['phone_number'] as String,
              relation: c['relation'] as String?,
              priorite: c['priority'] as int? ?? 3,
              actif: (c['active'] as int? ?? 1) == 1,
              dateAjout: DateTime.parse(c['date_added'] as String),
            )).toList();
            _isLoading = false;
          });
          return;
        }
      }
      
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _addContact() async {
    if (_contacts.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 3 contacts d\'urgence autorisés'),
          backgroundColor: AppConstants.warningColor,
        ),
      );
      return;
    }

    final result = await showDialog<ContactModel>(
      context: context,
      builder: (context) => AddContactDialog(
        priority: _contacts.length + 1,
      ),
    );

    if (result != null) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.currentUser?.id;
        
        if (userId == null) return;

        final insertResp = await SupabaseService.instance.insert(
          'contacts_urgence',
          {
            'utilisateur_id': userId,
            'nom': result.nom,
            'numero_telephone': result.numeroTelephone,
            'relation': result.relation,
            'priorite': result.priorite,
            'actif': true,
          },
        );

        // Sauvegarder dans le cache local
        final created = (insertResp as List).first as Map<String, dynamic>;
        await StorageService.instance.saveCachedContact(
          id: created['id'] as String,
          userId: userId,
          name: created['nom'] as String,
          phoneNumber: created['numero_telephone'] as String,
          relation: created['relation'] as String?,
          priority: created['priorite'] as int? ?? 3,
          active: created['actif'] as bool? ?? true,
          dateAdded: DateTime.parse(created['date_ajout'] as String),
        );

        _loadContacts();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact ajouté avec succès'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        }
      } catch (e) {
        // Fallback hors-ligne / RLS: sauvegarder en cache local pour utilisation immédiate
        try {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final userId = authProvider.currentUser?.id;
          if (userId != null) {
            final localId = _uuid.v4();
            await StorageService.instance.saveCachedContact(
              id: localId,
              userId: userId,
              name: result.nom,
              phoneNumber: result.numeroTelephone,
              relation: result.relation,
              priority: result.priorite,
              active: true,
              dateAdded: DateTime.now(),
            );
            // Recharger depuis le cache si le serveur a échoué
            final cached = await StorageService.instance.getCachedContacts(userId);
            setState(() {
              _contacts = cached.map((c) => ContactModel(
                id: c['id'] as String,
                utilisateurId: c['user_id'] as String,
                nom: c['name'] as String,
                numeroTelephone: c['phone_number'] as String,
                relation: c['relation'] as String?,
                priorite: c['priority'] as int? ?? 3,
                actif: (c['active'] as int? ?? 1) == 1,
                dateAjout: DateTime.parse(c['date_added'] as String),
              )).toList();
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact enregistré localement (hors-ligne)'),
                  backgroundColor: AppConstants.warningColor,
                ),
              );
            }
          }
        } catch (cacheErr) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de l\'ajout: $e\nCache: $cacheErr'),
                backgroundColor: AppConstants.errorColor,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _deleteContact(ContactModel contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le contact'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${contact.nom} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance.update(
          'contacts_urgence',
          {'actif': false},
          idColumn: 'id',
          idValue: contact.id,
        );

        _loadContacts();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact supprimé'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Mes Contacts d\'Urgence'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.whiteColor,
        elevation: 0,
        actions: [
          if (_contacts.length < 3)
            IconButton(
              onPressed: _addContact,
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: Column(
        children: [
          // Informations sur les contacts d'urgence
          Container(
            margin: const EdgeInsets.all(AppConstants.paddingMedium),
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryColor.withValues(alpha: 0.1),
                  AppConstants.secondaryColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppConstants.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emergency,
                        color: AppConstants.whiteColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Contacts d\'Urgence',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                          Text(
                            '${_contacts.length}/3 contacts configurés',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_contacts.length == 3)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.successColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'COMPLET',
                          style: TextStyle(
                            color: AppConstants.whiteColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingMedium),
                const Text(
                  'Ces contacts recevront automatiquement vos alertes d\'urgence avec votre position GPS.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // Liste des contacts
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryColor,
                    ),
                  )
                : _contacts.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: _buildEmptyState(),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadContacts,
                        color: AppConstants.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                          ),
                          itemCount: _contacts.length,
                          itemBuilder: (context, index) {
                            final contact = _contacts[index];
                            return ContactCard(
                              contact: contact,
                              onDelete: () => _deleteContact(contact),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _contacts.length < 3
          ? FloatingActionButton(
              onPressed: _addContact,
              backgroundColor: AppConstants.primaryColor,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contacts_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppConstants.spacingMedium),
          const Text(
            'Aucun contact d\'urgence',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: AppConstants.spacingSmall),
          const Text(
            'Ajoutez jusqu\'à 3 contacts qui recevront\nvos alertes d\'urgence',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLarge),
          ElevatedButton.icon(
            onPressed: _addContact,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un contact'),
          ),
        ],
      ),
    );
  }
}
