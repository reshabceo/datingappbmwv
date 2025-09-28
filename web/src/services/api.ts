import { supabase } from '../supabaseClient'

async function getPublicUrl(path: string | null | undefined) {
  if (!path) return null
  if (path.startsWith('http')) return path
  // Try common buckets
  const buckets = ['profile-photos', 'profiles', 'stories', 'public']
  for (const b of buckets) {
    try {
      const { data } = await supabase.storage.from(b).getPublicUrl(path)
      // data may be null if not found
      // @ts-ignore
      if (data && data.publicUrl) return data.publicUrl
    } catch (_) {
      // ignore and continue
    }
  }
  return null
}

export async function fetchProfiles(limit = 60) {
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .limit(limit)

    if (error) {
      console.error('fetchProfiles error:', error)
      return []
    }
    const profiles = (data || []) as any[]
    console.info('Loaded profiles:', profiles.length)
    const resolved = await Promise.all(
      profiles.map(async (p) => {
        const avatar = p.avatar_url || (p.image_urls && p.image_urls[0]) || (p.photos && p.photos[0])
        const publicUrl = await getPublicUrl(avatar)
        return { ...p, avatar_url: publicUrl }
      })
    )
    return resolved
  } catch (e) {
    console.error('fetchProfiles exception:', e)
    return []
  }
}

export async function fetchProfileById(id: string) {
  const { data } = await supabase.from('profiles').select('*').eq('id', id).maybeSingle()
  const profile = data as any
  if (!profile) return null
  const avatar = profile.avatar_url || (profile.image_urls && profile.image_urls[0]) || (profile.photos && profile.photos[0])
  profile.avatar_url = await getPublicUrl(avatar)
  // Resolve gallery
  const gallery = (profile.image_urls || profile.photos || []) as string[]
  profile.gallery = await Promise.all(gallery.map(async (g) => await getPublicUrl(g)))
  return profile
}

export async function fetchStories() {
  const { data } = await supabase.from('stories').select('id,media_url,content,created_at,user_id,profiles(name,avatar_url)')
  const stories = (data || []) as any[]
  return await Promise.all(stories.map(async (s) => ({
    ...s,
    media_url: await getPublicUrl(s.media_url),
    profiles: { ...s.profiles, avatar_url: await getPublicUrl(s.profiles?.avatar_url) }
  })))
}

export async function findMatchIdBetween(userA: string, userB: string) {
  if (!userA || !userB) return null
  const [u1, u2] = [userA, userB].sort()
  const { data } = await supabase.from('matches').select('id').eq('user_id_1', u1).eq('user_id_2', u2).maybeSingle()
  return data?.id ?? null
}

export async function sendMessage(matchId: string, senderId: string, content: string, storyId?: string, storyUserName?: string) {
  if (!matchId) throw new Error('matchId required')
  const payload: any = { match_id: matchId, sender_id: senderId, content, created_at: new Date().toISOString() }
  if (storyId) payload.story_id = storyId
  if (storyUserName) payload.story_user_name = storyUserName
  const { error } = await supabase.from('messages').insert(payload)
  if (error) throw error
  return true
}

export async function uploadProfileImage(file: File, userId: string) {
  console.log('📤 [UPLOAD] Starting upload for user:', userId, 'file:', file.name, 'size:', file.size)
  
  const bucket = 'profile-photos'
  const safeName = `${Date.now()}_` + file.name
    .toLowerCase()
    .replace(/\s+/g, '_')
    .replace(/[^a-z0-9._-]/g, '')
  const path = `${userId}/${safeName}`
  
  console.log('📤 [UPLOAD] Upload path:', path)
  
  try {
    // Check if user is authenticated
    const { data: { user: authUser } } = await supabase.auth.getUser()
    if (!authUser) {
      throw new Error('User not authenticated')
    }
    console.log('📤 [UPLOAD] User authenticated:', authUser.id)
    
    // Upload the file
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from(bucket)
      .upload(path, file, {
        cacheControl: '3600',
        upsert: false
      })
    
    if (uploadError) {
      console.error('📤 [UPLOAD] Upload error:', uploadError)
      throw new Error(`Upload failed: ${uploadError.message}`)
    }
    
    console.log('📤 [UPLOAD] Upload successful:', uploadData)
    
    // Get public URL
    const { data: urlData } = supabase.storage.from(bucket).getPublicUrl(path)
    const publicUrl = urlData?.publicUrl
    
    if (!publicUrl) {
      throw new Error('Failed to get public URL')
    }
    
    console.log('📤 [UPLOAD] Public URL generated:', publicUrl)
    return publicUrl
    
  } catch (error: any) {
    console.error('📤 [UPLOAD] Upload failed:', error)
    throw new Error(`Upload failed: ${error.message || 'Unknown error'}`)
  }
}

export async function isUserAdmin(userId: string) {
  if (!userId) return false
  try {
    const { data } = await supabase.from('profiles').select('is_admin').eq('id', userId).maybeSingle()
    return Boolean(data?.is_admin)
  } catch (_) {
    return false
  }
}

export default { getPublicUrl, fetchProfiles, fetchProfileById, fetchStories, uploadProfileImage }


