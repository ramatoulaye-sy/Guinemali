// Supabase Edge Function: Envoyer des notifications push aux utilisateurs à proximité
// Déclenchée automatiquement quand une alerte est créée

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')! // À configurer dans Supabase

interface AlertPayload {
  alert_id: string
  utilisateur_id: string
  latitude: number | null
  longitude: number | null
  type_alerte: string
  niveau_danger: number
  description: string
}

serve(async (req) => {
  try {
    // Vérifier la méthode
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Parser le payload
    const payload: AlertPayload = await req.json()
    console.log('📨 Nouvelle alerte reçue:', payload.alert_id)

    // Vérifier que l'alerte a une position GPS
    if (!payload.latitude || !payload.longitude) {
      console.log('⚠️ Alerte sans position GPS, notifications non envoyées')
      return new Response(
        JSON.stringify({ message: 'Alert has no GPS coordinates, notifications skipped' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Créer le client Supabase
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Récupérer les infos de la victime
    const { data: victim, error: victimError } = await supabase
      .from('utilisateurs')
      .select('pseudo, prenom')
      .eq('id', payload.utilisateur_id)
      .single()

    if (victimError) {
      console.error('❌ Erreur récupération victime:', victimError)
      throw victimError
    }

    // Trouver les utilisateurs à proximité (rayon de 5 km)
    const { data: nearbyUsers, error: nearbyError } = await supabase
      .rpc('find_nearby_users', {
        p_latitude: payload.latitude,
        p_longitude: payload.longitude,
        p_radius_km: 5.0,
        p_exclude_user_id: payload.utilisateur_id,
      })

    if (nearbyError) {
      console.error('❌ Erreur recherche utilisateurs proches:', nearbyError)
      throw nearbyError
    }

    if (!nearbyUsers || nearbyUsers.length === 0) {
      console.log('ℹ️ Aucun utilisateur à proximité trouvé')
      return new Response(
        JSON.stringify({ message: 'No nearby users found' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log(`👥 ${nearbyUsers.length} utilisateurs trouvés à proximité`)

    // Préparer les tokens FCM
    const fcmTokens = nearbyUsers
      .filter((user: any) => user.fcm_token)
      .map((user: any) => user.fcm_token)

    if (fcmTokens.length === 0) {
      console.log('⚠️ Aucun token FCM valide trouvé')
      return new Response(
        JSON.stringify({ message: 'No valid FCM tokens found' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Construire le message de notification
    const victimName = victim.prenom || victim.pseudo || 'Une personne'
    const distanceText = nearbyUsers[0]?.distance_km 
      ? `à ${nearbyUsers[0].distance_km.toFixed(1)} km` 
      : 'à proximité'

    const notificationTitle = '🚨 ALERTE URGENCE À PROXIMITÉ'
    const notificationBody = `${victimName} a besoin d'aide ${distanceText} de vous`

    // Envoyer les notifications via FCM (par batch de 500)
    const batchSize = 500
    let successCount = 0
    let failureCount = 0

    for (let i = 0; i < fcmTokens.length; i += batchSize) {
      const batch = fcmTokens.slice(i, i + batchSize)

      const fcmMessage = {
        registration_ids: batch,
        priority: 'high',
        notification: {
          title: notificationTitle,
          body: notificationBody,
          sound: 'emergency_alert',
          android_channel_id: 'emergency_alerts',
          icon: 'launcher_icon',
          color: '#DC3545',
        },
        data: {
          alert_id: payload.alert_id,
          latitude: payload.latitude.toString(),
          longitude: payload.longitude.toString(),
          victim_name: victimName,
          type: 'proximity_alert',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            channel_id: 'emergency_alerts',
            priority: 'high',
            sound: 'emergency_alert',
            visibility: 'public',
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: notificationTitle,
                body: notificationBody,
              },
              sound: 'emergency_alert.wav',
              'interruption-level': 'critical',
            },
          },
        },
      }

      try {
        const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `key=${FCM_SERVER_KEY}`,
          },
          body: JSON.stringify(fcmMessage),
        })

        const fcmResult = await fcmResponse.json()
        successCount += fcmResult.success || 0
        failureCount += fcmResult.failure || 0

        console.log(`✅ Batch ${Math.floor(i / batchSize) + 1}: ${fcmResult.success} succès, ${fcmResult.failure} échecs`)
      } catch (error) {
        console.error(`❌ Erreur envoi batch ${Math.floor(i / batchSize) + 1}:`, error)
        failureCount += batch.length
      }
    }

    // Enregistrer les stats de notification dans l'alerte
    await supabase
      .from('alertes')
      .update({
        nombre_notifications_envoyees: successCount,
        derniere_notification_at: new Date().toISOString(),
      })
      .eq('id', payload.alert_id)

    console.log(`🎉 Notifications envoyées: ${successCount} succès, ${failureCount} échecs`)

    return new Response(
      JSON.stringify({
        message: 'Notifications sent successfully',
        stats: {
          total_users: nearbyUsers.length,
          tokens_sent: fcmTokens.length,
          success: successCount,
          failure: failureCount,
        },
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    console.error('❌ Erreur:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      }
    )
  }
})
