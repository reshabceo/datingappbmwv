import { supabase } from '../supabaseClient'

export type Profile = {
  id: string
  name: string | null
  age: number | null
  image_urls: string[] | null
  location: string | null
  distance: string | null
  description: string | null
  hobbies: string[] | null
  is_active: boolean | null
  created_at: string | null
}

export async function getMyProfile(userId: string): Promise<Profile | null> {
  const { data, error } = await supabase.from('profiles').select('*').eq('id', userId).maybeSingle()
  if (error) {
    console.error('getMyProfile error', error)
    return null
  }
  return (data as Profile) || null
}

export async function upsertMyProfile(partial: Partial<Profile> & { id: string }) {
  // Do not force defaults here to avoid overwriting user-filled values.
  // Use ensureProfileInitialized() before calling this if row may not exist yet.
  const { data, error } = await supabase.from('profiles').upsert(partial, { onConflict: 'id' }).select('*')
  if (error) {
    console.error('upsertMyProfile error', error)
    throw error
  }
  console.log('upsertMyProfile ok', data)
}

export async function ensureProfileInitialized(userId: string): Promise<Profile> {
  const existing = await getMyProfile(userId)
  if (existing) return existing
  // Create a minimal row satisfying NOT NULL constraints used by your schema
  const payload = { id: userId, name: '', age: 18, image_urls: [], hobbies: [] as string[] }
  const { data, error } = await supabase.from('profiles').upsert(payload, { onConflict: 'id' }).select('*').single()
  if (error) throw error
  return data as Profile
}

export function isProfileComplete(p: Profile | null): boolean {
  if (!p) return false
  
  // Check basic required fields based on actual database schema
  const hasName = Boolean(p.name && p.name.trim().length > 0)
  const hasAge = Boolean(p.age && p.age >= 18)
  
  // Check photos - use image_urls from database schema
  const photosArr = (p as any).image_urls ?? (p as any).photos
  const hasPhotos = Array.isArray(photosArr) && photosArr.length >= 1
  
  // Check interests/hobbies
  const interestsArr = (p as any).hobbies ?? (p as any).interests
  const hasInterests = Array.isArray(interestsArr) && interestsArr.length >= 1
  
  console.log('Profile completion check:', {
    hasName,
    hasAge,
    hasPhotos,
    hasInterests,
    name: p.name,
    age: p.age,
    image_urls: photosArr,
    hobbies: interestsArr
  })
  
  return hasName && hasAge && hasPhotos && hasInterests
}


