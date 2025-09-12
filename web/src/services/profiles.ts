import { supabase } from '../supabaseClient'

export type Profile = {
  id: string
  name: string | null
  gender: 'Male' | 'Female' | 'Non-binary' | null
  date_of_birth: string | null
  age?: number | null
  description?: string | null
  hobbies?: string[] | null
  photos: string[] | null
  location_lat: number | null
  location_lon: number | null
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
  const payload = { id: userId, name: '', age: 18, photos: [], hobbies: [] as string[] }
  const { data, error } = await supabase.from('profiles').upsert(payload, { onConflict: 'id' }).select('*').single()
  if (error) throw error
  return data as Profile
}

export function isProfileComplete(p: Profile | null): boolean {
  if (!p) return false
  const hasBasics = Boolean((p as any).name && (p as any).gender && (((p as any).age ?? null) !== null || (p as any).date_of_birth))
  const photosArr = (p as any).photos ?? (p as any).image_urls
  const hasPhotos = Array.isArray(photosArr) && photosArr.length >= 1
  const interestsArr = (p as any).hobbies ?? (p as any).interests
  const hasInterests = Array.isArray(interestsArr) && interestsArr.length >= 1
  return hasBasics && hasInterests && hasPhotos
}


