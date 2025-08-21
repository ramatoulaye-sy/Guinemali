-- ================================================
-- GUINÉMALI - INDEX ET FONCTIONS
-- Optimisations et fonctions utilitaires
-- ================================================

-- ================================================
-- EXTENSIONS REQUISES
-- ================================================

-- Activer l'extension earthdistance pour les calculs géographiques
CREATE EXTENSION IF NOT EXISTS cube;
CREATE EXTENSION IF NOT EXISTS earthdistance;

-- ================================================
-- INDEX POUR OPTIMISER LES PERFORMANCES
-- ================================================

-- Index pour les alertes actives par localisation
CREATE INDEX IF NOT EXISTS idx_alertes_actives_geo ON public.alertes 
    USING GIST (
        ll_to_earth(latitude, longitude)
    ) WHERE statut = 'active';

-- Index pour les alertes par utilisateur et statut
CREATE INDEX IF NOT EXISTS idx_alertes_utilisateur_statut ON public.alertes 
    (utilisateur_id, statut, timestamp DESC);

-- Index pour les preuves par alerte
CREATE INDEX IF NOT EXISTS idx_preuves_alerte ON public.preuves 
    (alerte_id, timestamp DESC);

-- Index pour les messages du forum
CREATE INDEX IF NOT EXISTS idx_messages_forum_valides ON public.messages_forum 
    (valide, date_post DESC) WHERE valide = true;

-- Index pour les aidants disponibles par localisation
CREATE INDEX IF NOT EXISTS idx_aidants_geo ON public.aidants_disponibles 
    USING GIST (
        ll_to_earth(latitude, longitude)
    ) WHERE disponible = true;

-- Index pour les contacts d'urgence
CREATE INDEX IF NOT EXISTS idx_contacts_urgence_utilisateur ON public.contacts_urgence 
    (utilisateur_id, priorite) WHERE actif = true;

-- Index pour les notifications
CREATE INDEX IF NOT EXISTS idx_notifications_destinataire ON public.notifications_alertes 
    (destinataire_id, date_envoi DESC);

-- Index pour le journal d'actions
CREATE INDEX IF NOT EXISTS idx_journal_utilisateur_timestamp ON public.journal_actions 
    (utilisateur_id, timestamp DESC);

-- ================================================
-- FONCTIONS UTILITAIRES
-- ================================================

-- Fonction pour calculer la distance entre deux points
CREATE OR REPLACE FUNCTION distance_entre_points(
    lat1 DECIMAL,
    lon1 DECIMAL,
    lat2 DECIMAL,
    lon2 DECIMAL
) RETURNS DECIMAL AS $$
BEGIN
    RETURN earth_distance(
        ll_to_earth(lat1, lon1),
        ll_to_earth(lat2, lon2)
    );
END;
$$ LANGUAGE plpgsql;

-- Fonction pour trouver les aidants dans un rayon
CREATE OR REPLACE FUNCTION trouver_aidants_proximite(
    alerte_lat DECIMAL,
    alerte_lon DECIMAL,
    rayon_metres INTEGER DEFAULT 5000
) RETURNS TABLE (
    aidant_id UUID,
    pseudo VARCHAR,
    distance_metres DECIMAL,
    specialites TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.utilisateur_id,
        u.pseudo,
        distance_entre_points(alerte_lat, alerte_lon, a.latitude, a.longitude) as distance,
        a.specialites
    FROM public.aidants_disponibles a
    JOIN public.utilisateurs u ON a.utilisateur_id = u.id
    WHERE a.disponible = true
    AND distance_entre_points(alerte_lat, alerte_lon, a.latitude, a.longitude) <= rayon_metres
    ORDER BY distance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour créer une alerte avec notification automatique
CREATE OR REPLACE FUNCTION creer_alerte_avec_notifications(
    p_utilisateur_id UUID,
    p_latitude DECIMAL,
    p_longitude DECIMAL,
    p_type_alerte VARCHAR DEFAULT 'urgence',
    p_niveau_danger INTEGER DEFAULT 3
) RETURNS UUID AS $$
DECLARE
    nouvelle_alerte_id UUID;
    aidant RECORD;
BEGIN
    -- Créer l'alerte
    INSERT INTO public.alertes (
        utilisateur_id, latitude, longitude, type_alerte, niveau_danger
    ) VALUES (
        p_utilisateur_id, p_latitude, p_longitude, p_type_alerte, p_niveau_danger
    ) RETURNING id INTO nouvelle_alerte_id;

    -- Note: Les contacts d'urgence seront notifiés via SMS par l'application mobile
    -- Ici nous pourrions logger les contacts à notifier mais pas les insérer directement
    -- car ils ne sont pas des utilisateurs de l'application

    -- Notifier les aidants dans la zone
    FOR aidant IN 
        SELECT * FROM trouver_aidants_proximite(p_latitude, p_longitude, 10000)
        LIMIT 10
    LOOP
        INSERT INTO public.notifications_alertes (
            alerte_id, destinataire_id, type_notification, message
        ) VALUES (
            nouvelle_alerte_id,
            aidant.aidant_id,
            'push',
            'ALERTE DANS VOTRE ZONE: Une personne a besoin d''aide à ' || ROUND(aidant.distance_metres)::TEXT || 'm de votre position.'
        );
    END LOOP;

    -- Journaliser l'action
    INSERT INTO public.journal_actions (
        utilisateur_id, action, details
    ) VALUES (
        p_utilisateur_id,
        'creation_alerte',
        jsonb_build_object(
            'alerte_id', nouvelle_alerte_id,
            'type', p_type_alerte,
            'niveau_danger', p_niveau_danger,
            'latitude', p_latitude,
            'longitude', p_longitude
        )
    );

    RETURN nouvelle_alerte_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- RPC AUTH UTILITAIRES (bypass RLS via SECURITY DEFINER)
-- ================================================

-- Connexion par pseudo + hash PIN
CREATE OR REPLACE FUNCTION public.login_by_pseudo_hash(
    p_pseudo TEXT,
    p_pin_hash TEXT
) RETURNS SETOF public.utilisateurs AS $$
  SELECT *
  FROM public.utilisateurs
  WHERE pseudo = p_pseudo
    AND pin_chiffre = p_pin_hash
    AND actif = TRUE
  LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER;

-- Création du profil utilisateur après création du compte auth
CREATE OR REPLACE FUNCTION public.create_user_profile(
    p_id UUID,
    p_pseudo TEXT,
    p_pin_hash TEXT,
    p_num_tel TEXT,
    p_langue TEXT,
    p_region TEXT,
    p_type_utilisateur TEXT
) RETURNS SETOF public.utilisateurs AS $$
BEGIN
  INSERT INTO public.utilisateurs (
    id, pseudo, pin_chiffre, num_tel, langue, region, type_utilisateur, actif, date_creation, profil_complete
  ) VALUES (
    p_id,
    p_pseudo,
    p_pin_hash,
    NULLIF(p_num_tel, ''),
    COALESCE(p_langue, 'fr'),
    p_region,
    p_type_utilisateur,
    TRUE,
    NOW(),
    FALSE
  ) RETURNING *;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Mise à jour sécurisée de la dernière connexion
CREATE OR REPLACE FUNCTION public.update_last_login_secure(
    p_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.utilisateurs SET derniere_connexion = NOW() WHERE id = p_id;
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Vérifier la disponibilité d'un pseudo
CREATE OR REPLACE FUNCTION public.check_pseudo_available(
    p_pseudo TEXT
) RETURNS BOOLEAN AS $$
  SELECT NOT EXISTS (
    SELECT 1 FROM public.utilisateurs WHERE pseudo = p_pseudo
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Droits d'exécution pour les rôles clients
REVOKE ALL ON FUNCTION public.login_by_pseudo_hash(TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.create_user_profile(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_last_login_secure(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.check_pseudo_available(TEXT) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.login_by_pseudo_hash(TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_user_profile(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.update_last_login_secure(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_pseudo_available(TEXT) TO anon, authenticated;

-- Fonction pour mettre à jour le statut d'une alerte
CREATE OR REPLACE FUNCTION resoudre_alerte(
    p_alerte_id UUID,
    p_nouveau_statut VARCHAR,
    p_notes_resolution TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    alerte_existe BOOLEAN;
BEGIN
    -- Vérifier que l'alerte existe
    SELECT EXISTS(SELECT 1 FROM public.alertes WHERE id = p_alerte_id) INTO alerte_existe;
    
    IF NOT alerte_existe THEN
        RETURN FALSE;
    END IF;

    -- Mettre à jour l'alerte
    UPDATE public.alertes 
    SET 
        statut = p_nouveau_statut,
        date_resolution = CASE WHEN p_nouveau_statut IN ('resolue', 'fausse_alerte') THEN NOW() ELSE NULL END,
        notes_resolution = p_notes_resolution
    WHERE id = p_alerte_id;

    -- Journaliser l'action
    INSERT INTO public.journal_actions (
        utilisateur_id, action, details
    ) VALUES (
        auth.uid(),
        'resolution_alerte',
        jsonb_build_object(
            'alerte_id', p_alerte_id,
            'nouveau_statut', p_nouveau_statut,
            'notes', p_notes_resolution
        )
    );

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour obtenir les statistiques d'un utilisateur
CREATE OR REPLACE FUNCTION statistiques_utilisateur(p_utilisateur_id UUID)
RETURNS TABLE (
    nombre_alertes_total INTEGER,
    nombre_alertes_actives INTEGER,
    nombre_alertes_resolues INTEGER,
    derniere_alerte TIMESTAMP WITH TIME ZONE,
    nombre_preuves INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total,
        COUNT(CASE WHEN statut = 'active' THEN 1 END)::INTEGER as actives,
        COUNT(CASE WHEN statut = 'resolue' THEN 1 END)::INTEGER as resolues,
        MAX(timestamp) as derniere,
        (SELECT COUNT(*)::INTEGER FROM public.preuves p 
         JOIN public.alertes a ON p.alerte_id = a.id 
         WHERE a.utilisateur_id = p_utilisateur_id) as preuves
    FROM public.alertes
    WHERE utilisateur_id = p_utilisateur_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================
-- TRIGGERS
-- ================================================

-- Fonction trigger pour mettre à jour les statistiques
CREATE OR REPLACE FUNCTION update_derniere_connexion()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.utilisateurs 
    SET derniere_connexion = NOW()
    WHERE id = NEW.id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer le trigger (nécessite d'être configuré côté auth)
-- CREATE TRIGGER trigger_derniere_connexion
--     AFTER UPDATE OF last_sign_in_at ON auth.users
--     FOR EACH ROW EXECUTE FUNCTION update_derniere_connexion();

-- Fonction pour incrémenter le compteur de réponses
CREATE OR REPLACE FUNCTION increment_nombre_reponses()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.messages_forum 
    SET nombre_reponses = nombre_reponses + 1
    WHERE id = NEW.message_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour compter les réponses
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE t.tgname = 'trigger_increment_reponses'
      AND n.nspname = 'public'
      AND c.relname = 'reponses_forum'
  ) THEN
    CREATE TRIGGER trigger_increment_reponses
      AFTER INSERT ON public.reponses_forum
      FOR EACH ROW EXECUTE FUNCTION increment_nombre_reponses();
  END IF;
END $$;
