#!/bin/bash

# Script de déploiement Supabase pour Guinemali
# Déploie les migrations SQL et la Edge Function pour les notifications de proximité

set -e  # Arrêter en cas d'erreur

echo "🚀 Déploiement Supabase pour Guinemali"
echo "========================================="

# Vérifier que Supabase CLI est installé
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI n'est pas installé!"
    echo "Installez-le avec: npm install -g supabase"
    exit 1
fi

echo "✅ Supabase CLI détecté"

# Vérifier la connexion
echo ""
echo "📡 Vérification de la connexion..."
supabase projects list > /dev/null 2>&1 || {
    echo "⚠️ Non connecté à Supabase"
    echo "Connexion en cours..."
    supabase login
}

echo "✅ Connecté à Supabase"

# Lister les projets disponibles
echo ""
echo "📋 Projets disponibles:"
supabase projects list

# Demander le project ref
echo ""
read -p "Entrez le Project Ref de Guinemali: " PROJECT_REF

if [ -z "$PROJECT_REF" ]; then
    echo "❌ Project Ref requis!"
    exit 1
fi

# Lier le projet
echo ""
echo "🔗 Liaison au projet $PROJECT_REF..."
supabase link --project-ref "$PROJECT_REF"

# Déployer les migrations SQL
echo ""
echo "📤 Déploiement des migrations SQL..."
supabase db push

echo "✅ Migrations SQL déployées"

# Déployer la Edge Function
echo ""
echo "📤 Déploiement de la Edge Function 'send-proximity-notifications'..."
supabase functions deploy send-proximity-notifications

echo "✅ Edge Function déployée"

# Configurer les secrets
echo ""
echo "🔐 Configuration des secrets..."
echo ""
echo "Entrez la clé serveur FCM (Firebase Server Key):"
echo "📍 Vous pouvez la trouver dans Firebase Console > Paramètres > Cloud Messaging"
read -sp "FCM Server Key: " FCM_KEY
echo ""

if [ -z "$FCM_KEY" ]; then
    echo "⚠️ Clé FCM non fournie, secret non configuré"
else
    supabase secrets set FCM_SERVER_KEY="$FCM_KEY"
    echo "✅ Secret FCM_SERVER_KEY configuré"
fi

# Vérifier les secrets
echo ""
echo "📋 Secrets configurés:"
supabase secrets list

echo ""
echo "🎉 Déploiement terminé avec succès!"
echo ""
echo "📝 Prochaines étapes:"
echo "1. Configurez Firebase dans votre projet (voir FIREBASE_SETUP_INSTRUCTIONS.md)"
echo "2. Téléchargez google-services.json et placez-le dans android/app/"
echo "3. Rebuild l'application: flutter build apk --release"
echo "4. Testez les notifications sur un appareil réel"
echo ""
echo "✅ Félicitations, le système de notifications de proximité est prêt!"
