-- ================================================
-- GUINÉMALI - POLITIQUES DE SÉCURITÉ ET RLS
-- Row Level Security pour protéger les données
-- ================================================

-- Activer RLS sur toutes les tables
ALTER TABLE public.utilisateurs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alertes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.preuves ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contacts_urgence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages_forum ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reponses_forum ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ressources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications_alertes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.aidants_disponibles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_actions ENABLE ROW LEVEL SECURITY;

-- ================================================
-- POLITIQUES POUR LA TABLE UTILISATEURS
-- ================================================

-- Les utilisateurs peuvent voir et modifier leur propre profil
CREATE POLICY "Utilisateurs peuvent voir leur profil" ON public.utilisateurs
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Utilisateurs peuvent modifier leur profil" ON public.utilisateurs
    FOR UPDATE USING (auth.uid() = id);

-- Les utilisateurs peuvent s'inscrire
CREATE POLICY "Inscription publique" ON public.utilisateurs
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Les admins peuvent voir tous les utilisateurs
CREATE POLICY "Admins voient tous les utilisateurs" ON public.utilisateurs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.utilisateurs 
            WHERE id = auth.uid() AND type_utilisateur = 'admin'
        )
    );

-- ================================================
-- POLITIQUES POUR LA TABLE ALERTES
-- ================================================

-- Les victimes peuvent créer et voir leurs alertes
CREATE POLICY "Victimes gèrent leurs alertes" ON public.alertes
    FOR ALL USING (auth.uid() = utilisateur_id);

-- Les aidants et ONG peuvent voir les alertes actives dans leur zone
CREATE POLICY "Aidants voient alertes actives" ON public.alertes
    FOR SELECT USING (
        statut = 'active' AND (
            EXISTS (
                SELECT 1 FROM public.utilisateurs 
                WHERE id = auth.uid() 
                AND type_utilisateur IN ('aidant', 'ong', 'admin')
            )
        )
    );

-- Les aidants peuvent mettre à jour le statut des alertes
CREATE POLICY "Aidants peuvent résoudre alertes" ON public.alertes
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.utilisateurs 
            WHERE id = auth.uid() 
            AND type_utilisateur IN ('aidant', 'ong', 'admin')
        )
    );

-- ================================================
-- POLITIQUES POUR LA TABLE PREUVES
-- ================================================

-- Seule la victime peut voir ses preuves
CREATE POLICY "Victimes voient leurs preuves" ON public.preuves
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.alertes 
            WHERE id = alerte_id AND utilisateur_id = auth.uid()
        )
    );

-- Les victimes peuvent ajouter des preuves à leurs alertes
CREATE POLICY "Victimes ajoutent preuves" ON public.preuves
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.alertes 
            WHERE id = alerte_id AND utilisateur_id = auth.uid()
        )
    );

-- Les admins peuvent voir toutes les preuves (pour modération)
CREATE POLICY "Admins voient toutes preuves" ON public.preuves
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.utilisateurs 
            WHERE id = auth.uid() AND type_utilisateur = 'admin'
        )
    );

-- ================================================
-- POLITIQUES POUR LA TABLE CONTACTS_URGENCE
-- ================================================

-- Les utilisateurs gèrent leurs propres contacts
CREATE POLICY "Gestion contacts personnels" ON public.contacts_urgence
    FOR ALL USING (auth.uid() = utilisateur_id);

-- Autoriser explicitement l'insertion des contacts par leur propriétaire
CREATE POLICY "Contacts personnels - insertion" ON public.contacts_urgence
    FOR INSERT WITH CHECK (auth.uid() = utilisateur_id);

-- ================================================
-- POLITIQUES POUR LE FORUM
-- ================================================

-- Tous les utilisateurs connectés peuvent lire les messages validés
CREATE POLICY "Lecture messages validés" ON public.messages_forum
    FOR SELECT USING (valide = true AND auth.uid() IS NOT NULL);

-- Les utilisateurs peuvent créer des messages
CREATE POLICY "Création messages" ON public.messages_forum
    FOR INSERT WITH CHECK (auth.uid() = utilisateur_id);

-- Les utilisateurs peuvent modifier leurs propres messages
CREATE POLICY "Modification messages personnels" ON public.messages_forum
    FOR UPDATE USING (auth.uid() = utilisateur_id);

-- Les modérateurs peuvent tout voir et modifier
CREATE POLICY "Modération messages" ON public.messages_forum
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.utilisateurs 
            WHERE id = auth.uid() 
            AND type_utilisateur IN ('admin', 'ong')
        )
    );

-- Politiques similaires pour les réponses
CREATE POLICY "Lecture réponses validées" ON public.reponses_forum
    FOR SELECT USING (valide = true AND auth.uid() IS NOT NULL);

CREATE POLICY "Création réponses" ON public.reponses_forum
    FOR INSERT WITH CHECK (auth.uid() = utilisateur_id);

CREATE POLICY "Modification réponses personnelles" ON public.reponses_forum
    FOR UPDATE USING (auth.uid() = utilisateur_id);

-- ================================================
-- POLITIQUES POUR LES RESSOURCES
-- ================================================

-- Tous les utilisateurs peuvent lire les ressources actives
CREATE POLICY "Lecture ressources publiques" ON public.ressources
    FOR SELECT USING (actif = true AND auth.uid() IS NOT NULL);

-- Les ONG et admins peuvent créer et modifier des ressources
CREATE POLICY "Gestion ressources" ON public.ressources
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.utilisateurs 
            WHERE id = auth.uid() 
            AND type_utilisateur IN ('ong', 'admin')
        )
    );

-- ================================================
-- POLITIQUES POUR LES NOTIFICATIONS
-- ================================================

-- Les utilisateurs voient leurs notifications
CREATE POLICY "Notifications personnelles" ON public.notifications_alertes
    FOR SELECT USING (auth.uid() = destinataire_id);

-- Le système peut créer des notifications
CREATE POLICY "Création notifications système" ON public.notifications_alertes
    FOR INSERT WITH CHECK (true);

-- ================================================
-- POLITIQUES POUR LES AIDANTS
-- ================================================

-- Les aidants gèrent leur profil d'aide
CREATE POLICY "Gestion profil aidant" ON public.aidants_disponibles
    FOR ALL USING (auth.uid() = utilisateur_id);

-- Les autres peuvent voir les aidants disponibles
CREATE POLICY "Voir aidants disponibles" ON public.aidants_disponibles
    FOR SELECT USING (disponible = true AND auth.uid() IS NOT NULL);

-- ================================================
-- POLITIQUES POUR LE JOURNAL D'ACTIONS
-- ================================================

-- Seuls les admins peuvent lire le journal
CREATE POLICY "Journal admin seulement" ON public.journal_actions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.utilisateurs 
            WHERE id = auth.uid() AND type_utilisateur = 'admin'
        )
    );

-- Le système peut écrire dans le journal
CREATE POLICY "Écriture journal système" ON public.journal_actions
    FOR INSERT WITH CHECK (true);
