-- Migration: Trigger pour envoyer automatiquement les notifications de proximité
-- Date: 2025-10-16
-- Description: Déclenche automatiquement l'envoi de notifications quand une alerte est créée

-- Ajouter les colonnes de stats de notification dans la table alertes
ALTER TABLE public.alertes
ADD COLUMN IF NOT EXISTS nombre_notifications_envoyees INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS derniere_notification_at TIMESTAMPTZ;

-- Fonction pour appeler la Edge Function d'envoi de notifications
CREATE OR REPLACE FUNCTION public.trigger_proximity_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_payload JSONB;
BEGIN
  -- Ne déclencher que pour les nouvelles alertes actives
  IF (TG_OP = 'INSERT' AND NEW.statut = 'active') THEN
    -- Construire le payload
    v_payload := jsonb_build_object(
      'alert_id', NEW.id,
      'utilisateur_id', NEW.utilisateur_id,
      'latitude', NEW.latitude,
      'longitude', NEW.longitude,
      'type_alerte', NEW.type_alerte,
      'niveau_danger', NEW.niveau_danger,
      'description', NEW.description
    );

    -- Appeler la Edge Function via pg_net (ou http)
    -- Note: pg_net doit être activé dans Supabase
    PERFORM
      net.http_post(
        url := current_setting('app.supabase_url') || '/functions/v1/send-proximity-notifications',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || current_setting('app.supabase_service_role_key')
        ),
        body := v_payload
      );

    RAISE NOTICE 'Notifications de proximité déclenchées pour alerte %', NEW.id;
  END IF;

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Logger l'erreur mais ne pas bloquer l'insertion de l'alerte
    RAISE WARNING 'Erreur déclenchement notifications: %', SQLERRM;
    RETURN NEW;
END;
$$;

-- Créer le trigger
DROP TRIGGER IF EXISTS on_alert_created_notify_nearby ON public.alertes;
CREATE TRIGGER on_alert_created_notify_nearby
  AFTER INSERT ON public.alertes
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_proximity_notifications();

-- Commenter
COMMENT ON FUNCTION public.trigger_proximity_notifications IS 'Déclenche l''envoi de notifications push aux utilisateurs à proximité';
COMMENT ON TRIGGER on_alert_created_notify_nearby ON public.alertes IS 'Envoie des notifications quand une alerte est créée';

-- Alternative: Si pg_net n'est pas disponible, utiliser un webhook Supabase Realtime
-- Créer une publication pour les alertes
CREATE PUBLICATION alertes_publication FOR TABLE public.alertes
  WHERE statut = 'active';
