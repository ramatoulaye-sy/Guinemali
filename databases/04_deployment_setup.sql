-- ================================================
-- GUINÉMALI - CONFIGURATION DE DÉPLOIEMENT
-- Scripts pour la configuration initiale en production
-- ================================================

-- ===== CONFIGURATION DES BUCKETS STORAGE =====

-- Bucket pour les preuves (audio, vidéo, photos)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('evidence', 'evidence', false) 
ON CONFLICT (id) DO NOTHING;

-- Bucket pour les avatars des utilisateurs
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true) 
ON CONFLICT (id) DO NOTHING;

-- Bucket pour les ressources publiques (guides, logos ONG)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('public-resources', 'public-resources', true) 
ON CONFLICT (id) DO NOTHING;

-- ===== POLITIQUES STORAGE =====

-- Politiques pour le bucket evidence
CREATE POLICY "Utilisateurs peuvent uploader leurs preuves" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'evidence' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Utilisateurs peuvent voir leurs preuves" 
ON storage.objects FOR SELECT 
USING (
  bucket_id = 'evidence' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Utilisateurs peuvent supprimer leurs preuves" 
ON storage.objects FOR DELETE 
USING (
  bucket_id = 'evidence' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Politiques pour les avatars
CREATE POLICY "Gestion avatars utilisateurs" 
ON storage.objects FOR ALL 
USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1])
WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Politiques pour les ressources publiques
CREATE POLICY "Lecture publique ressources" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'public-resources');

CREATE POLICY "ONG peuvent gérer ressources" 
ON storage.objects FOR ALL 
USING (
  bucket_id = 'public-resources' 
  AND EXISTS (
    SELECT 1 FROM public.utilisateurs 
    WHERE id = auth.uid() 
    AND type_utilisateur IN ('ong', 'admin')
  )
);

-- ===== DONNÉES INITIALES =====

-- Insérer les régions de Guinée
INSERT INTO public.ressources (titre, type, langue, region, contenu_texte, actif) VALUES
('Numéros d''urgence Conakry', 'numero_urgence', 'fr', 'Conakry', 
 'Police: 117, Sapeurs-Pompiers: 118, SAMU: 124, Gendarmerie: 122', true),
('Numéros d''urgence Kindia', 'numero_urgence', 'fr', 'Kindia', 
 'Police: 117, Sapeurs-Pompiers: 118, SAMU: 124, Gendarmerie: 122', true),
('Numéros d''urgence Boké', 'numero_urgence', 'fr', 'Boké', 
 'Police: 117, Sapeurs-Pompiers: 118, SAMU: 124, Gendarmerie: 122', true),
('Numéros d''urgence Mamou', 'numero_urgence', 'fr', 'Mamou', 
 'Police: 117, Sapeurs-Pompiers: 118, SAMU: 124, Gendarmerie: 122', true),
('Numéros d''urgence Labé', 'numero_urgence', 'fr', 'Labé', 
 'Police: 117, Sapeurs-Pompiers: 118, SAMU: 124, Gendarmerie: 122', true),
('Numéros d''urgence Faranah', 'numero_urgence', 'fr', 'Faranah', 
 'Police: 117, Sapeurs-Pompiers: 118, SAMU: 124, Gendarmerie: 122', true),
('Numéros d''urgence Kankan', 'numero_urgence', 'fr', 'Kankan', 
 'Police: 117, Sapeurs-Pompiers: 118, SAMU: 124, Gendarmerie: 122', true),
('Numéros d''urgence Nzérékoré', 'numero_urgence', 'fr', 'Nzérékoré', 
 'Police: 117, Sapeurs-Pompiers: 118, SAMU: 124, Gendarmerie: 122', true);

-- Guides de sécurité de base
INSERT INTO public.ressources (titre, type, langue, contenu_texte, actif) VALUES
('Guide de sécurité personnelle', 'guide', 'fr', 
 'Conseils pour éviter les situations dangereuses:\n\n' ||
 '• Restez vigilante dans les espaces publics\n' ||
 '• Évitez les endroits isolés, surtout la nuit\n' ||
 '• Gardez votre téléphone chargé en permanence\n' ||
 '• Informez vos proches de vos déplacements\n' ||
 '• Faites confiance à votre instinct\n' ||
 '• Utilisez Guinèmali pour rester connectée au réseau de soutien', true),

('Que faire en cas d''agression', 'guide', 'fr',
 'En cas d''agression imminente:\n\n' ||
 '1. Activez immédiatement l''alerte Guinèmali\n' ||
 '2. Criez fort pour attirer l''attention\n' ||
 '3. Fuyez vers un endroit sûr si possible\n' ||
 '4. Ne résistez pas si votre vie est en danger\n' ||
 '5. Mémorisez le maximum de détails sur l''agresseur\n' ||
 '6. Contactez immédiatement les autorités après\n' ||
 '7. Cherchez un soutien psychologique', true),

('Utilisation de Guinèmali', 'guide', 'fr',
 'Comment utiliser efficacement l''application:\n\n' ||
 '• Configurez vos contacts d''urgence (maximum 3)\n' ||
 '• Activez toujours la géolocalisation\n' ||
 '• Testez régulièrement l''alerte en mode sécurisé\n' ||
 '• Participez au forum pour partager vos expériences\n' ||
 '• Signalez tout problème technique immédiatement\n' ||
 '• Gardez l''application à jour', true);

-- ===== FONCTIONS D'ADMINISTRATION =====

-- Fonction pour créer un utilisateur administrateur initial
CREATE OR REPLACE FUNCTION create_admin_user(
    admin_email text,
    admin_password text,
    admin_pseudo text
) RETURNS text AS $$
DECLARE
    new_user_id uuid;
BEGIN
    -- Cette fonction ne doit être utilisée qu'une seule fois lors du déploiement initial
    
    -- Vérifier qu'aucun admin n'existe déjà
    IF EXISTS (SELECT 1 FROM public.utilisateurs WHERE type_utilisateur = 'admin') THEN
        RETURN 'Un administrateur existe déjà';
    END IF;
    
    -- Créer le compte auth
    INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        recovery_sent_at,
        last_sign_in_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
    ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        gen_random_uuid(),
        'authenticated',
        'authenticated',
        admin_email,
        crypt(admin_password, gen_salt('bf')),
        NOW(),
        NOW(),
        NOW(),
        '{"provider":"email","providers":["email"]}',
        '{}',
        NOW(),
        NOW(),
        '',
        '',
        '',
        ''
    ) RETURNING id INTO new_user_id;
    
    -- Créer le profil utilisateur
    INSERT INTO public.utilisateurs (
        id,
        pseudo,
        pin_chiffre,
        langue,
        type_utilisateur,
        actif,
        profil_complete
    ) VALUES (
        new_user_id,
        admin_pseudo,
        -- PIN par défaut: 123456 (À CHANGER IMMÉDIATEMENT)
        encode(digest('123456guinemali_salt', 'sha256'), 'hex'),
        'fr',
        'admin',
        true,
        true
    );
    
    RETURN 'Administrateur créé avec succès. ID: ' || new_user_id::text;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===== OPTIMISATIONS PERFORMANCES =====

-- Analyser les tables pour optimiser les requêtes
ANALYZE public.utilisateurs;
ANALYZE public.alertes;
ANALYZE public.preuves;
ANALYZE public.contacts_urgence;
ANALYZE public.messages_forum;
ANALYZE public.ressources;
ANALYZE public.notifications_alertes;
ANALYZE public.aidants_disponibles;
ANALYZE public.journal_actions;

-- ===== CONFIGURATION TEMPS RÉEL =====

-- Activer les publications temps réel pour les tables importantes
ALTER publication supabase_realtime ADD TABLE public.alertes;
ALTER publication supabase_realtime ADD TABLE public.notifications_alertes;
ALTER publication supabase_realtime ADD TABLE public.messages_forum;

-- ===== SAUVEGARDE ET MAINTENANCE =====

-- Fonction de nettoyage des données anciennes
CREATE OR REPLACE FUNCTION cleanup_old_data() RETURNS void AS $$
BEGIN
    -- Supprimer les alertes résolues de plus de 1 an
    DELETE FROM public.alertes 
    WHERE statut = 'resolue' 
    AND date_resolution < NOW() - INTERVAL '1 year';
    
    -- Supprimer les preuves orphelines (sans alerte associée)
    DELETE FROM public.preuves 
    WHERE alerte_id NOT IN (SELECT id FROM public.alertes);
    
    -- Supprimer les notifications anciennes (plus de 6 mois)
    DELETE FROM public.notifications_alertes 
    WHERE date_envoi < NOW() - INTERVAL '6 months';
    
    -- Supprimer les entrées du journal anciennes (plus de 2 ans)
    DELETE FROM public.journal_actions 
    WHERE timestamp < NOW() - INTERVAL '2 years';
    
    -- Nettoyer les sessions inactives
    DELETE FROM auth.sessions 
    WHERE updated_at < NOW() - INTERVAL '30 days';
    
END;
$$ LANGUAGE plpgsql;

-- Commenter cette ligne après le premier déploiement
-- SELECT create_admin_user('admin@guinemali.org', 'MotDePasseSecurise123!', 'admin_guinemali');

-- ===== VÉRIFICATIONS FINALES =====

-- Vérifier que toutes les tables existent
DO $$
DECLARE
    missing_tables text[];
    current_table text;
BEGIN
    missing_tables := ARRAY[]::text[];
    
    FOR current_table IN VALUES 
        ('utilisateurs'), ('alertes'), ('preuves'), ('contacts_urgence'),
        ('messages_forum'), ('reponses_forum'), ('ressources'), 
        ('notifications_alertes'), ('aidants_disponibles'), ('journal_actions')
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = current_table
        ) THEN
            missing_tables := array_append(missing_tables, current_table);
        END IF;
    END LOOP;
    
    IF array_length(missing_tables, 1) > 0 THEN
        RAISE EXCEPTION 'Tables manquantes: %', array_to_string(missing_tables, ', ');
    ELSE
        RAISE NOTICE '✅ Toutes les tables sont présentes';
    END IF;
END $$;

-- Vérifier que les index existent
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_alertes_actives_geo') THEN
        RAISE WARNING '⚠️  Index géographique manquant pour les alertes';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_alertes_utilisateur_statut') THEN
        RAISE WARNING '⚠️  Index utilisateur/statut manquant pour les alertes';
    END IF;
    
    RAISE NOTICE '✅ Vérification des index terminée';
END $$;

DO $$
BEGIN
    RAISE NOTICE '🎉 Configuration de déploiement terminée avec succès!';
END $$;
