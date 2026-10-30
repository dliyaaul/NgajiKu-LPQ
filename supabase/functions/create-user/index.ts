import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Tangani preflight request (CORS)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 1. Inisialisasi Supabase Client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!
    const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    // Client bawaan Auth User (menggunakan JWT Token pengirim)
    const authHeader = req.headers.get('Authorization')!
    const supabaseUserClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    })

    // 2. Verifikasi user yang sedang memanggil function
    const { data: { user: currentUser }, error: authError } = await supabaseUserClient.auth.getUser()
    if (authError || !currentUser) {
      return new Response(
        JSON.stringify({ success: false, message: 'User tidak terautentikasi / belum login.' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 3. Cek Role Pengirim (Harus Admin)
    const { data: currentProfile, error: profileError } = await supabaseUserClient
      .from('profiles')
      .select('role')
      .eq('id', currentUser.id)
      .single()

    if (profileError || currentProfile?.role !== 'admin') {
      return new Response(
        JSON.stringify({ success: false, message: 'Hanya admin yang dapat membuat pengguna baru.' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 4. Baca Body Request
    const { email, password, username, alamat, no_hp, role } = await req.json()

    if (!email || !password || !username || !role) {
      return new Response(
        JSON.stringify({ success: false, message: 'Email, password, username, dan role wajib diisi.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 5. Inisialisasi Admin Client (Service Role) untuk pembuatan User
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey)

    // 6. Buat User di auth.users
    const { data: newUser, error: createUserError } = await supabaseAdmin.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true,
    })

    if (createUserError || !newUser.user) {
      return new Response(
        JSON.stringify({ success: false, message: createUserError?.message ?? 'Gagal membuat user auth.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 7. Insert Data Profile ke public.profiles
    const { error: insertProfileError } = await supabaseAdmin
      .from('profiles')
      .insert({
        id: newUser.user.id,
        username: username,
        alamat: alamat,
        no_hp: no_hp,
        role: role,
      })

    // Rollback jika insert profile gagal
    if (insertProfileError) {
      await supabaseAdmin.auth.admin.deleteUser(newUser.user.id)
      return new Response(
        JSON.stringify({ success: false, message: insertProfileError.message }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 8. Berhasil
    return new Response(
      JSON.stringify({
        success: true,
        message: 'Pengguna berhasil dibuat.',
        user: {
          id: newUser.user.id,
          email: newUser.user.email,
          username: username,
          role: role,
        },
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({
        success: false,
        message: error instanceof Error ? error.message : 'Terjadi kesalahan pada server.',
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})