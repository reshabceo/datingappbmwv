import React, { useState, useEffect } from 'react'
import { supabase } from '../services/supabase'

interface VerificationItem {
  id: string
  user_id: string
  challenge_text: string
  verification_photo_url: string
  submitted_at: string
  user_name: string
  user_age: number
  user_photos: string[]
}

export default function AdminVerification() {
  const [verifications, setVerifications] = useState<VerificationItem[]>([])
  const [loading, setLoading] = useState(true)
  const [reviewing, setReviewing] = useState<string | null>(null)

  useEffect(() => {
    loadVerifications()
  }, [])

  const loadVerifications = async () => {
    try {
      setLoading(true)
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

      const formattedData = data?.map(item => ({
        id: item.id,
        user_id: item.user_id,
        challenge_text: item.challenge_text,
        verification_photo_url: item.verification_photo_url,
        submitted_at: item.submitted_at,
        user_name: item.profiles?.name || 'Unknown',
        user_age: item.profiles?.age || 0,
        user_photos: item.profiles?.photos || []
      })) || []

      setVerifications(formattedData)
    } catch (error) {
      console.error('Error loading verifications:', error)
    } finally {
      setLoading(false)
    }
  }

  const reviewVerification = async (queueId: string, approved: boolean, rejectionReason?: string) => {
    try {
      setReviewing(queueId)
      
      const { error } = await supabase.rpc('review_verification', {
        p_queue_id: queueId,
        p_reviewer_id: (await supabase.auth.getUser()).data.user?.id,
        p_approved: approved,
        p_rejection_reason: rejectionReason || null
      })

      if (error) throw error

      // Reload the list
      await loadVerifications()
      
      alert(approved ? 'Verification approved!' : 'Verification rejected!')
    } catch (error) {
      console.error('Error reviewing verification:', error)
      alert('Error reviewing verification')
    } finally {
      setReviewing(null)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-white text-xl">Loading verifications...</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-900 text-white p-6">
      <div className="max-w-6xl mx-auto">
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-2">Profile Verification Review</h1>
          <p className="text-gray-400">
            Review and approve user verification photos
          </p>
        </div>

        {verifications.length === 0 ? (
          <div className="text-center py-12">
            <div className="text-gray-400 text-xl">No pending verifications</div>
          </div>
        ) : (
          <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
            {verifications.map((verification) => (
              <div key={verification.id} className="bg-gray-800 rounded-lg p-6 border border-gray-700">
                {/* User Info */}
                <div className="mb-4">
                  <div className="flex items-center space-x-3 mb-2">
                    {verification.user_photos[0] && (
                      <img
                        src={verification.user_photos[0]}
                        alt="Profile"
                        className="w-12 h-12 rounded-full object-cover"
                      />
                    )}
                    <div>
                      <div className="font-semibold">{verification.user_name}</div>
                      <div className="text-gray-400 text-sm">Age {verification.user_age}</div>
                    </div>
                  </div>
                  <div className="text-sm text-gray-400">
                    Submitted: {new Date(verification.submitted_at).toLocaleString()}
                  </div>
                </div>

                {/* Challenge */}
                <div className="mb-4">
                  <div className="text-sm text-gray-400 mb-1">Challenge:</div>
                  <div className="bg-purple-900/30 text-purple-200 px-3 py-2 rounded text-sm">
                    {verification.challenge_text}
                  </div>
                </div>

                {/* Verification Photo */}
                <div className="mb-4">
                  <div className="text-sm text-gray-400 mb-2">Verification Photo:</div>
                  <div className="relative">
                    <img
                      src={verification.verification_photo_url}
                      alt="Verification photo"
                      className="w-full h-48 object-cover rounded-lg border border-gray-600"
                    />
                    <div className="absolute top-2 right-2 bg-black/60 text-white text-xs px-2 py-1 rounded">
                      Verification
                    </div>
                  </div>
                </div>

                {/* Action Buttons */}
                <div className="flex space-x-2">
                  <button
                    onClick={() => reviewVerification(verification.id, true)}
                    disabled={reviewing === verification.id}
                    className="flex-1 bg-green-600 hover:bg-green-700 disabled:bg-green-800 text-white px-4 py-2 rounded text-sm font-medium transition-colors"
                  >
                    {reviewing === verification.id ? 'Processing...' : '✓ Approve'}
                  </button>
                  <button
                    onClick={() => {
                      const reason = prompt('Rejection reason (optional):')
                      if (reason !== null) {
                        reviewVerification(verification.id, false, reason)
                      }
                    }}
                    disabled={reviewing === verification.id}
                    className="flex-1 bg-red-600 hover:bg-red-700 disabled:bg-red-800 text-white px-4 py-2 rounded text-sm font-medium transition-colors"
                  >
                    ✗ Reject
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Stats */}
        <div className="mt-8 bg-gray-800 rounded-lg p-6">
          <h3 className="text-lg font-semibold mb-4">Verification Stats</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-orange-400">{verifications.length}</div>
              <div className="text-gray-400">Pending Review</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-green-400">0</div>
              <div className="text-gray-400">Approved Today</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-red-400">0</div>
              <div className="text-gray-400">Rejected Today</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
