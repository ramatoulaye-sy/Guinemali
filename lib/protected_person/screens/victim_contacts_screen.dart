import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/contact_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import 'package:uuid/uuid.dart';
import '../widgets/contact_card.dart';
import '../widgets/add_contact_dialog.dart';

/// Écran de gestion des contacts d'urgence avec design professionnel
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
      await _saveContact(result);
    }
  }

  Future<void> _saveContact(ContactModel contact) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      
      if (userId == null) return;

      final contactData = {
        'id': contact.id,
        'utilisateur_id': userId,
        'nom': contact.nom,
        'numero_telephone': contact.numeroTelephone,
        'relation': contact.relation,
        'priorite': contact.priorite,
        'actif': contact.actif,
        'date_ajout': contact.dateAjout.toIso8601String(),
      };

      await SupabaseService.instance.insert('contacts_urgence', contactData);
      
      // Sauvegarder en cache local
      await StorageService.instance.saveCachedContact(
        id: contactData['id'] as String,
        userId: userId,
        name: contactData['nom'] as String,
        phoneNumber: contactData['numero_telephone'] as String,
        relation: contactData['relation'] as String?,
        priority: contactData['priorite'] as int? ?? 3,
        active: contactData['actif'] as bool? ?? true,
        dateAdded: DateTime.parse(contactData['date_ajout'] as String),
      );
      
      await _loadContacts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Contact ${contact.nom} ajouté avec succès'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteContact(String contactId) async {
    try {
      await SupabaseService.instance.delete(
        'contacts_urgence',
        idColumn: 'id',
        idValue: contactId,
      );
      await _loadContacts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.delete, color: Colors.white),
                const SizedBox(width: 12),
                Text('Contact supprimé avec succès'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildProfessionalAppBar(),
      body: _buildProfessionalBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// AppBar professionnel avec design moderne
  PreferredSizeWidget _buildProfessionalAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.contacts, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Contacts d\'Urgence',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.secondaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${_contacts.length}/3',
            style: TextStyle(
              color: AppTheme.secondaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Corps principal avec organisation professionnelle
  Widget _buildProfessionalBody() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 32),
            _buildContactsSection(),
            const SizedBox(height: 24),
            _buildEmergencyInfoSection(),
          ],
        ),
      ),
    );
  }

  /// Section d'accueil avec design moderne
  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.secondaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.emergency,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contacts d\'Urgence',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configurez jusqu\'à 3 contacts de confiance qui seront notifiés en cas d\'urgence.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section des contacts avec design professionnel
  Widget _buildContactsSection() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_contacts.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'Vos Contacts',
          icon: Icons.people,
          color: Colors.blue,
          subtitle: '${_contacts.length} contact${_contacts.length > 1 ? 's' : ''} configuré${_contacts.length > 1 ? 's' : ''}',
        ),
        const SizedBox(height: 20),
        ..._contacts.map((contact) => _buildContactCard(contact)).toList(),
      ],
    );
  }

  /// Section d'information d'urgence avec design moderne
  Widget _buildEmergencyInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Information Importante',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'En cas d\'urgence, ces contacts seront automatiquement notifiés de votre situation et de votre position géographique.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.red.withValues(alpha: 0.7),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Assurez-vous que vos contacts sont joignables 24h/24',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// En-tête de section avec design professionnel
  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carte de contact avec design moderne
  Widget _buildContactCard(ContactModel contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // En-tête de la carte
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getPriorityColor(contact.priorite).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(contact.priorite),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.nom,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getPriorityColor(contact.priorite),
                        ),
                      ),
                      if (contact.relation != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          contact.relation!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: _getPriorityColor(contact.priorite),
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteContact(contact.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Text('Supprimer'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Contenu de la carte
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.phone,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        contact.numeroTelephone,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(contact.priorite).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Priorité ${contact.priorite}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getPriorityColor(contact.priorite),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ajouté le ${_formatDate(contact.dateAjout)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// État de chargement avec design moderne
  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: 20),
          Text(
            'Chargement des contacts...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// État vide avec design moderne
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun contact configuré',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ajoutez votre premier contact d\'urgence pour commencer',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Bouton flottant avec design moderne
  Widget _buildFloatingActionButton() {
    if (_contacts.length >= 3) {
      return Container();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _addContact,
        backgroundColor: Colors.transparent,
        elevation: 0,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Ajouter Contact',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Obtenir la couleur de priorité
  Color _getPriorityColor(int? priority) {
    switch (priority) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
      default:
        return Colors.green;
    }
  }

  /// Formater la date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
