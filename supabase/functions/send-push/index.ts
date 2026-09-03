import { createClient } from 'npm:@supabase/supabase-js@2';
import { JWT } from 'npm:google-auth-library@9';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
};

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    const authorization = request.headers.get('Authorization');
    if (!authorization) throw new Error('Missing authorization');

    const url = Deno.env.get('SUPABASE_URL')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const admin = createClient(url, serviceKey);
    const jwt = authorization.replace(/^Bearer\s+/i, '');
    const { data: authData, error: authError } = await admin.auth.getUser(jwt);
    if (authError || !authData.user) throw new Error('Invalid session');

    const { data: profile } = await admin.from('profiles').select('role,status')
      .eq('id', authData.user.id).single();
    if (profile?.role !== 'admin' || profile?.status !== 'active') {
      return json({ error: 'Only an active admin can send push notifications' }, 403);
    }

    const { notification_id } = await request.json();
    const { data: notification, error: notificationError } = await admin
      .from('notifications').select('id,user_id,title,body,type')
      .eq('id', notification_id).single();
    if (notificationError || !notification) throw notificationError ?? new Error('Notification not found');

    let recipients = admin.from('profiles').select('fcm_token')
      .eq('role', 'user').eq('status', 'active').not('fcm_token', 'is', null);
    if (notification.user_id) recipients = recipients.eq('id', notification.user_id);
    const { data: profiles, error: recipientError } = await recipients;
    if (recipientError) throw recipientError;

    const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON') ?? '');
    const auth = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    });
    const token = await auth.getAccessToken();
    if (!token.token) throw new Error('Could not obtain Firebase access token');

    const endpoint = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;
    const results = await Promise.all((profiles ?? []).map(async (row) => {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token.token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: {
          token: row.fcm_token,
          notification: { title: notification.title, body: notification.body },
          data: { notification_id: notification.id, type: notification.type ?? 'general' },
          android: { priority: 'high', notification: { channel_id: 'savesmart_notifications' } },
          apns: { payload: { aps: { sound: 'default', badge: 1 } } },
        }}),
      });
      return response.ok;
    }));
    return json({ sent: results.filter((ok) => ok).length, failed: results.filter((ok) => !ok).length });
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : String(error) }, 400);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
