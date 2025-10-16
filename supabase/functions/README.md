# 🔔 Supabase Edge Functions - Guinemali

Ce dossier contient les **Edge Functions** pour l'application Guinemali.

## 📁 Fonctions Disponibles

### 1. `send-proximity-notifications`

**Description** : Envoie automatiquement des notifications push aux utilisateurs à proximité quand une alerte SOS est déclenchée.

**Déclenchement** : Automatique via trigger PostgreSQL quand une nouvelle alerte est insérée dans la table `alertes`.

**Paramètres** :
- `alert_id` (string) : ID de l'alerte
- `utilisateur_id` (UUID) : ID de l'utilisateur qui déclenche l'alerte
- `latitude` (number) : Latitude GPS de l'alerte
- `longitude` (number) : Longitude GPS de l'alerte
- `type_alerte` (string) : Type d'alerte
- `niveau_danger` (number) : Niveau de danger (1-5)
- `description` (string) : Description de l'alerte

**Retour** :
```json
{
  "message": "Notifications sent successfully",
  "stats": {
    "total_users": 15,
    "tokens_sent": 12,
    "success": 10,
    "failure": 2
  }
}
```

**Secrets requis** :
- `FCM_SERVER_KEY` : Clé serveur Firebase Cloud Messaging

---

## 🚀 Déploiement

### Méthode 1 : Script automatique
```bash
chmod +x ../../deploy_supabase.sh
../../deploy_supabase.sh
```

### Méthode 2 : Commandes manuelles
```bash
# Déployer toutes les fonctions
supabase functions deploy

# Déployer une fonction spécifique
supabase functions deploy send-proximity-notifications

# Voir les logs en temps réel
supabase functions logs send-proximity-notifications --tail
```

---

## 🔐 Configuration des Secrets

```bash
# Ajouter la clé FCM
supabase secrets set FCM_SERVER_KEY="VOTRE_CLE_SERVEUR_FCM"

# Lister les secrets configurés
supabase secrets list

# Supprimer un secret
supabase secrets unset FCM_SERVER_KEY
```

---

## 🧪 Test Manuel

### Depuis le Dashboard Supabase
1. Aller dans Edge Functions
2. Cliquer sur `send-proximity-notifications`
3. Onglet "Invoke"
4. Envoyer un payload de test :
```json
{
  "alert_id": "123e4567-e89b-12d3-a456-426614174000",
  "utilisateur_id": "456e7890-e89b-12d3-a456-426614174111",
  "latitude": 9.6412,
  "longitude": -13.5784,
  "type_alerte": "agression",
  "niveau_danger": 5,
  "description": "Test notification"
}
```

### Depuis la ligne de commande
```bash
supabase functions invoke send-proximity-notifications \
  --body '{
    "alert_id": "test-123",
    "utilisateur_id": "user-456",
    "latitude": 9.6412,
    "longitude": -13.5784,
    "type_alerte": "test",
    "niveau_danger": 3,
    "description": "Test"
  }'
```

---

## 📊 Monitoring

### Logs en temps réel
```bash
supabase functions logs send-proximity-notifications --tail
```

### Voir les logs récents
```bash
supabase functions logs send-proximity-notifications --limit 50
```

### Voir les métriques
1. Aller dans Supabase Dashboard
2. Edge Functions → `send-proximity-notifications`
3. Onglet "Metrics"

---

## 🐛 Dépannage

### Erreur : "FCM_SERVER_KEY not found"
**Solution** : Configurer le secret :
```bash
supabase secrets set FCM_SERVER_KEY="VOTRE_CLE"
```

### Erreur : "Failed to send notifications"
**Vérifier** :
1. La clé FCM est correcte
2. Les tokens FCM sont valides dans la table `utilisateurs`
3. Les utilisateurs ont activé les notifications

### Erreur : "No nearby users found"
**Vérifier** :
1. Les utilisateurs ont sauvegardé leur position GPS
2. La distance entre les utilisateurs < 5 km
3. La requête SQL `find_nearby_users` fonctionne

---

## 📝 Structure du Code

```
supabase/functions/
├── send-proximity-notifications/
│   └── index.ts                 # Code principal
└── README.md                    # Ce fichier
```

---

## 🔄 Workflow

```
1. Utilisateur déclenche alerte SOS
         ↓
2. Trigger PostgreSQL détecte l'insertion
         ↓
3. Trigger appelle la Edge Function
         ↓
4. Edge Function exécute find_nearby_users()
         ↓
5. Edge Function récupère les tokens FCM
         ↓
6. Edge Function envoie les notifications via Firebase API
         ↓
7. Firebase transmet aux appareils
         ↓
8. Stats sauvegardées dans la table alertes
```

---

## 📚 Documentation

- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Deno Standard Library](https://deno.land/std)

---

**🎉 Edge Functions déployées et opérationnelles !**
