-- Migration: Ajouter les colonnes pour les tokens FCM et géolocalisation
-- Date: 2025-10-16
-- Description: Permet de stocker les tokens FCM pour les push notifications et la localisation des utilisateurs

-- Ajouter les colonnes FCM dans la table utilisateurs
ALTER TABLE public.utilisateurs
ADD COLUMN IF NOT EXISTS fcm_token TEXT,
ADD COLUMN IF NOT EXISTS fcm_token_updated_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS last_known_latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS last_known_longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS last_location_updated_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS notification_enabled BOOLEAN DEFAULT true;

-- Créer un index pour rechercher rapidement les utilisateurs avec tokens FCM
CREATE INDEX IF NOT EXISTS idx_utilisateurs_fcm_token 
ON public.utilisateurs(fcm_token) 
WHERE fcm_token IS NOT NULL;

-- Créer un index géospatial pour les recherches de proximité
CREATE INDEX IF NOT EXISTS idx_utilisateurs_location 
ON public.utilisateurs(last_known_latitude, last_known_longitude) 
WHERE last_known_latitude IS NOT NULL AND last_known_longitude IS NOT NULL;

-- Fonction pour calculer la distance entre deux points (formule de Haversine)
CREATE OR REPLACE FUNCTION public.calculate_distance(
  lat1 DOUBLE PRECISION,
  lon1 DOUBLE PRECISION,
  lat2 DOUBLE PRECISION,
  lon2 DOUBLE PRECISION
) RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  earth_radius CONSTANT DOUBLE PRECISION := 6371; -- Rayon de la Terre en km
  dlat DOUBLE PRECISION;
  dlon DOUBLE PRECISION;
  a DOUBLE PRECISION;
  c DOUBLE PRECISION;
BEGIN
  -- Formule de Haversine
  dlat := radians(lat2 - lat1);
  dlon := radians(lon2 - lon1);
  
  a := sin(dlat / 2) * sin(dlat / 2) +
       cos(radians(lat1)) * cos(radians(lat2)) *
       sin(dlon / 2) * sin(dlon / 2);
  
  c := 2 * atan2(sqrt(a), sqrt(1 - a));
  
  RETURN earth_radius * c;
END;
$$;

-- Fonction pour trouver les utilisateurs proches d'une alerte
CREATE OR REPLACE FUNCTION public.find_nearby_users(
  p_latitude DOUBLE PRECISION,
  p_longitude DOUBLE PRECISION,
  p_radius_km DOUBLE PRECISION DEFAULT 5.0,
  p_exclude_user_id UUID DEFAULT NULL
) RETURNS TABLE (
  user_id UUID,
  fcm_token TEXT,
  pseudo TEXT,
  prenom TEXT,
  distance_km DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.fcm_token,
    u.pseudo,
    u.prenom,
    public.calculate_distance(
      p_latitude,
      p_longitude,
      u.last_known_latitude,
      u.last_known_longitude
    ) AS distance_km
  FROM public.utilisateurs u
  WHERE 
    u.fcm_token IS NOT NULL
    AND u.notification_enabled = true
    AND u.actif = true
    AND u.last_known_latitude IS NOT NULL
    AND u.last_known_longitude IS NOT NULL
    AND (p_exclude_user_id IS NULL OR u.id != p_exclude_user_id)
    AND public.calculate_distance(
      p_latitude,
      p_longitude,
      u.last_known_latitude,
      u.last_known_longitude
    ) <= p_radius_km
  ORDER BY distance_km ASC
  LIMIT 100; -- Limiter à 100 utilisateurs max par notification
END;
$$;

-- Fonction pour mettre à jour la localisation d'un utilisateur
CREATE OR REPLACE FUNCTION public.update_user_location(
  p_user_id UUID,
  p_latitude DOUBLE PRECISION,
  p_longitude DOUBLE PRECISION
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.utilisateurs
  SET 
    last_known_latitude = p_latitude,
    last_known_longitude = p_longitude,
    last_location_updated_at = NOW()
  WHERE id = p_user_id;
END;
$$;

-- Commenter les fonctions
COMMENT ON FUNCTION public.calculate_distance IS 'Calcule la distance en km entre deux points géographiques';
COMMENT ON FUNCTION public.find_nearby_users IS 'Trouve les utilisateurs à proximité d''une position donnée';
COMMENT ON FUNCTION public.update_user_location IS 'Met à jour la localisation d''un utilisateur';

-- Ajouter des commentaires sur les colonnes
COMMENT ON COLUMN public.utilisateurs.fcm_token IS 'Token Firebase Cloud Messaging pour les notifications push';
COMMENT ON COLUMN public.utilisateurs.fcm_token_updated_at IS 'Date de dernière mise à jour du token FCM';
COMMENT ON COLUMN public.utilisateurs.last_known_latitude IS 'Dernière latitude connue de l''utilisateur';
COMMENT ON COLUMN public.utilisateurs.last_known_longitude IS 'Dernière longitude connue de l''utilisateur';
COMMENT ON COLUMN public.utilisateurs.last_location_updated_at IS 'Date de dernière mise à jour de la localisation';
COMMENT ON COLUMN public.utilisateurs.notification_enabled IS 'Indique si l''utilisateur accepte de recevoir des notifications';
