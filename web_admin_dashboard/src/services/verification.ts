import { supabase } from './supabase'

export interface VerificationStatus {
  status: 'unverified' | 'pending' | 'verified' | 'rejected'
  photo_url?: string
  challenge?: string
  rejection_reason?: string
  submitted_at?: string
  reviewed_at?: string
}

export async function getVerificationStatus(userId: string): Promise<VerificationStatus | null> {
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('verification_status, verification_photo_url, verification_challenge, verification_rejection_reason, verification_submitted_at, verification_reviewed_at')
      .eq('id', userId)
      .single()

    if (error) throw error

    return {
      status: data.verification_status,
      photo_url: data.verification_photo_url,
      challenge: data.verification_challenge,
      rejection_reason: data.verification_rejection_reason,
      submitted_at: data.verification_submitted_at,
      reviewed_at: data.verification_reviewed_at
    }
  } catch (error) {
    console.error('Error getting verification status:', error)
    return null
  }
}

export async function getRandomChallenge(): Promise<string | null> {
  try {
    const { data, error } = await supabase.rpc('get_random_verification_challenge')
    if (error) throw error
    return data
  } catch (error) {
    console.error('Error getting challenge:', error)
    return null
  }
}

export async function submitVerificationPhoto(
  userId: string, 
  photoUrl: string, 
  challenge: string
): Promise<{ verified: boolean; confidence: number; reason: string } | null> {
  try {
    // Call AI verification edge function
    const { data, error } = await supabase.functions.invoke('ai-verification', {
      body: {
        userId,
        verificationPhotoUrl: photoUrl,
        challenge
      }
    })

    if (error) throw error
    return data
  } catch (error) {
    console.error('Error submitting verification photo:', error)
    return null
  }
}

export async function uploadVerificationPhoto(file: File, userId: string): Promise<string | null> {
  try {
    const bucket = 'profile-photos'
    const fileName = `verification_${userId}_${Date.now()}.jpg`
    const path = `${userId}/verification/${fileName}`

    const { data: uploadData, error: uploadError } = await supabase.storage
      .from(bucket)
      .upload(path, file, {
        cacheControl: '3600',
        upsert: false
      })

    if (uploadError) throw uploadError

    const { data: urlData } = supabase.storage.from(bucket).getPublicUrl(path)
    return urlData?.publicUrl || null
  } catch (error) {
    console.error('Error uploading verification photo:', error)
    return null
  }
}

export async function getPendingVerifications(): Promise<any[]> {
  try {
    const { data, error } = await supabase
      .from('verification_queue')
      .select(`
        *,
        profiles!verification_queue_user_id_fkey (
          name,
          age,
          photos
        )
      `)
      .eq('status', 'pending')
      .order('submitted_at', { ascending: false })

    if (error) throw error
    return data || []
  } catch (error) {
    console.error('Error getting pending verifications:', error)
    return []
  }
}

export async function reviewVerification(
  queueId: string, 
  approved: boolean, 
  rejectionReason?: string
): Promise<boolean> {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('User not authenticated')

    const { error } = await supabase.rpc('review_verification', {
      p_queue_id: queueId,
      p_reviewer_id: user.id,
      p_approved: approved,
      p_rejection_reason: rejectionReason || null
    })

    if (error) throw error
    return true
  } catch (error) {
    console.error('Error reviewing verification:', error)
    return false
  }
}
