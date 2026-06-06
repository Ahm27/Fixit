import 'jsr:@supabase/functions-js/edge-runtime.d.ts'
import { createClient } from 'jsr:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return jsonResponse({ error: 'Missing authorization header.' }, 401)
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const anonKey =
      Deno.env.get('SUPABASE_ANON_KEY') ??
      Deno.env.get('SUPABASE_PUBLISHABLE_KEY') ??
      Deno.env.get('SB_PUBLISHABLE_KEY') ??
      ''

    const supabase = createClient(supabaseUrl, anonKey, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    })

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      return jsonResponse({ error: 'Unauthorized.' }, 401)
    }

    const body = await req.json()
    const threadId = String(body.thread_id ?? '').trim()
    const messageBody = String(body.body ?? '').trim()

    if (threadId.length === 0 || messageBody.length === 0) {
      return jsonResponse({ error: 'thread_id and body are required.' }, 400)
    }

    const { data: thread, error: threadError } = await supabase
      .from('message_threads')
      .select('id, request_id')
      .eq('id', threadId)
      .single()

    if (threadError || !thread) {
      return jsonResponse({ error: 'Thread not found.' }, 404)
    }

    const { data: request, error: requestError } = await supabase
      .from('service_requests')
      .select('id, customer_id, worker_id')
      .eq('id', thread.request_id)
      .single()

    if (requestError || !request) {
      return jsonResponse({ error: 'Request not found.' }, 404)
    }

    const receiverId =
      user.id === request.customer_id ? request.worker_id : request.customer_id

    const { data: insertedMessage, error: insertError } = await supabase
      .from('messages')
      .insert({
        thread_id: threadId,
        sender_id: user.id,
        receiver_id: receiverId,
        body: messageBody,
      })
      .select()
      .single()

    if (insertError) {
      return jsonResponse({ error: insertError.message }, 400)
    }

    const { error: threadUpdateError } = await supabase
      .from('message_threads')
      .update({
        last_message: messageBody,
        last_message_at: new Date().toISOString(),
      })
      .eq('id', threadId)

    if (threadUpdateError) {
      return jsonResponse({ error: threadUpdateError.message }, 400)
    }

    if (receiverId) {
      await supabase.from('notifications').insert({
        user_id: receiverId,
        title: 'New message',
        body: messageBody,
        type: 'message',
        request_id: request.id,
        thread_id: threadId,
        is_read: false,
      })
    }

    return jsonResponse({ message: insertedMessage }, 200)
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unexpected error'
    return jsonResponse({ error: message }, 500)
  }
})

function jsonResponse(payload: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  })
}
