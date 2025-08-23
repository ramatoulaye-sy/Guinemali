# 🔧 Configuration Supabase pour Guinemali

## Problème de connexion résolu !

Votre application Guinemali a été configurée pour utiliser Supabase, mais vous devez encore configurer vos vraies clés d'API.

## 📋 Étapes de configuration

### 1. Créer un projet Supabase
- Allez sur [https://supabase.com](https://supabase.com)
- Créez un compte ou connectez-vous
- Cliquez sur "New Project"
- Donnez un nom à votre projet (ex: "guinemali")
- Créez un mot de passe pour la base de données
- Sélectionnez une région proche de la Guinée
- Cliquez sur "Create new project"

### 2. Attendre l'initialisation
- Le projet prend 2-5 minutes à s'initialiser
- Vous recevrez un email de confirmation

### 3. Récupérer les clés API
- Dans votre projet Supabase, allez dans **Settings > API**
- Copiez l'**URL du projet** (Project URL)
- Copiez la **clé anon/public** (anon/public key)

### 4. Configurer l'application
- Ouvrez le fichier `lib/core/config/supabase_config.dart`
- Remplacez les valeurs par défaut par vos vraies clés :

```dart
class SupabaseConfig {
  // REMPLACEZ cette valeur par votre vraie URL Supabase
  static const String url = 'https://votre-projet.supabase.co';
  
  // REMPLACEZ cette valeur par votre vraie clé anon
  static const String anonKey = 'votre-vraie-cle-ici';
}
```

### 5. Redémarrer l'application
- Sauvegardez le fichier
- Redémarrez l'application Flutter

## 🗄️ Structure de base de données

Votre projet Supabase doit contenir ces tables principales :

### Table `utilisateurs`
```sql
CREATE TABLE utilisateurs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  pseudo TEXT UNIQUE NOT NULL,
  type_utilisateur TEXT NOT NULL DEFAULT 'victime',
  prenom TEXT,
  nom TEXT,
  telephone TEXT,
  region TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Table `alertes`
```sql
CREATE TABLE alertes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id UUID REFERENCES utilisateurs(id),
  statut TEXT NOT NULL DEFAULT 'active',
  position_lat DOUBLE PRECISION,
  position_lng DOUBLE PRECISION,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Table `contacts_urgence`
```sql
CREATE TABLE contacts_urgence (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  utilisateur_id UUID REFERENCES utilisateurs(id),
  nom TEXT NOT NULL,
  telephone TEXT NOT NULL,
  relation TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Table `preuves`
```sql
CREATE TABLE preuves (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alerte_id UUID REFERENCES alertes(id),
  type TEXT NOT NULL,
  fichier_url TEXT,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 🔐 Politiques de sécurité (RLS)

Activez Row Level Security et créez ces politiques :

```sql
-- Activer RLS
ALTER TABLE utilisateurs ENABLE ROW LEVEL SECURITY;
ALTER TABLE alertes ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts_urgence ENABLE ROW LEVEL SECURITY;
ALTER TABLE preuves ENABLE ROW LEVEL SECURITY;

-- Politique pour les utilisateurs (chacun voit ses propres données)
CREATE POLICY "Users can view own profile" ON utilisateurs
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON utilisateurs
  FOR UPDATE USING (auth.uid() = id);

-- Politique pour les alertes
CREATE POLICY "Users can view own alerts" ON alertes
  FOR SELECT USING (auth.uid() = utilisateur_id);

CREATE POLICY "Users can insert own alerts" ON alertes
  FOR INSERT WITH CHECK (auth.uid() = utilisateur_id);

-- Politique pour les contacts d'urgence
CREATE POLICY "Users can manage own emergency contacts" ON contacts_urgence
  FOR ALL USING (auth.uid() = utilisateur_id);

-- Politique pour les preuves
CREATE POLICY "Users can manage own evidence" ON preuves
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM alertes 
      WHERE alertes.id = preuves.alerte_id 
      AND alertes.utilisateur_id = auth.uid()
    )
  );
```

## 🧪 Test de connexion

Une fois configuré, vous pouvez tester la connexion :

1. Lancez l'application
2. Allez sur l'écran d'inscription
3. Utilisez le bouton "Test de connexion Supabase"
4. Vérifiez les logs dans la console

## ❌ Problèmes courants

### Erreur "Invalid API key"
- Vérifiez que vous avez copié la bonne clé anon
- Assurez-vous qu'il n'y a pas d'espaces supplémentaires

### Erreur "Invalid URL"
- Vérifiez que l'URL commence par `https://`
- Assurez-vous qu'il n'y a pas de slash final

### Erreur de connexion réseau
- Vérifiez votre connexion internet
- Vérifiez que Supabase n'est pas en maintenance

### Erreur de table inexistante
- Créez d'abord les tables avec les scripts SQL ci-dessus
- Vérifiez que les noms des tables correspondent exactement

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifiez les logs de l'application
2. Consultez la documentation Supabase
3. Vérifiez que votre projet Supabase est actif

## ✅ Vérification finale

Votre configuration est correcte quand :
- ✅ L'application se lance sans erreur
- ✅ Le test de connexion Supabase réussit
- ✅ Vous pouvez créer un compte utilisateur
- ✅ Les données sont sauvegardées dans Supabase

---

**Bon développement avec Guinemali ! 🚀**
