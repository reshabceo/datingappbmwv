import React, { useState, useEffect } from 'react'
import { useAuth } from '../context/AuthContext'
import { getVerificationStatus, getRandomChallenge, submitVerificationPhoto, uploadVerificationPhoto } from '../services/verification'
import { useNavigate } from 'react-router-dom'

interface VerificationStatus {
  status: 'unverified' | 'pending' | 'verified' | 'rejected'
  photo_url?: string
  challenge?: string
  rejection_reason?: string
  submitted_at?: string
  reviewed_at?: string
  confidence?: number
  ai_reason?: string
}

export default function VerificationScreen() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const [verificationStatus, setVerificationStatus] = useState<VerificationStatus | null>(null)
  const [challenge, setChallenge] = useState<string>('')
  const [loading, setLoading] = useState(false)
  const [uploading, setUploading] = useState(false)
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const [previewUrl, setPreviewUrl] = useState<string>('')

  useEffect(() => {
    if (user) {
      loadVerificationStatus()
    }
  }, [user])

  const loadVerificationStatus = async () => {
    if (!user) return
    
    try {
      setLoading(true)
      const status = await getVerificationStatus(user.id)
      setVerificationStatus(status)
      
      if (status?.challenge) {
        setChallenge(status.challenge)
      }
    } catch (error) {
      console.error('Error loading verification status:', error)
    } finally {
      setLoading(false)
    }
  }

  const getNewChallenge = async () => {
    try {
      setLoading(true)
      const newChallenge = await getRandomChallenge()
      if (newChallenge) {
        setChallenge(newChallenge)
        setSelectedFile(null)
        setPreviewUrl('')
      }
    } catch (error) {
      console.error('Error getting challenge:', error)
      alert('Failed to get new challenge')
    } finally {
      setLoading(false)
    }
  }

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) {
      setSelectedFile(file)
      const url = URL.createObjectURL(file)
      setPreviewUrl(url)
    }
  }

  const submitVerification = async () => {
    if (!user || !selectedFile || !challenge) return

    try {
      setUploading(true)
      
      // Upload photo
      const photoUrl = await uploadVerificationPhoto(selectedFile, user.id)
      if (!photoUrl) {
        throw new Error('Failed to upload photo')
      }

      // Submit for AI verification
      const result = await submitVerificationPhoto(user.id, photoUrl, challenge)
      if (result) {
        if (result.verified) {
          alert(`🎉 Verification Successful! Confidence: ${result.confidence}%`)
        } else {
          alert(`❌ Verification Failed: ${result.reason}`)
        }
        
        // Reload status
        await loadVerificationStatus()
      } else {
        alert('Verification failed. Please try again.')
      }
    } catch (error) {
      console.error('Error submitting verification:', error)
      alert('Failed to submit verification')
    } finally {
      setUploading(false)
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'verified': return 'text-green-400'
      case 'pending': return 'text-orange-400'
      case 'rejected': return 'text-red-400'
      default: return 'text-gray-400'
    }
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'verified': return '✓'
      case 'pending': return '⏳'
      case 'rejected': return '✗'
      default: return '👤'
    }
  }

  if (loading && !verificationStatus) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-white text-xl">Loading verification status...</div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-900 text-white p-6">
      <div className="max-w-2xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <button 
            onClick={() => navigate(-1)}
            className="mb-4 text-gray-400 hover:text-white"
          >
            ← Back
          </button>
          <h1 className="text-3xl font-bold mb-2">Profile Verification</h1>
          <p className="text-gray-400">
            Get your profile verified with AI-powered photo verification
          </p>
        </div>

        {/* Status Card */}
        {verificationStatus && (
          <div className="mb-8 p-6 bg-gray-800 rounded-lg border border-gray-700">
            <div className="flex items-center space-x-3 mb-4">
              <span className="text-2xl">{getStatusIcon(verificationStatus.status)}</span>
              <div>
                <h3 className={`text-xl font-semibold ${getStatusColor(verificationStatus.status)}`}>
                  {verificationStatus.status === 'unverified' ? 'Not Verified' :
                   verificationStatus.status === 'pending' ? 'Under Review' :
                   verificationStatus.status === 'verified' ? 'Verified' : 'Rejected'}
                </h3>
                {verificationStatus.confidence && (
                  <p className="text-sm text-gray-400">
                    Confidence: {verificationStatus.confidence}%
                  </p>
                )}
              </div>
            </div>
            
            {verificationStatus.rejection_reason && (
              <p className="text-red-400 text-sm mb-4">
                {verificationStatus.rejection_reason}
              </p>
            )}
            
            {verificationStatus.ai_reason && (
              <p className="text-gray-400 text-sm">
                AI Analysis: {verificationStatus.ai_reason}
              </p>
            )}
          </div>
        )}

        {/* Verification Flow */}
        {(!verificationStatus || verificationStatus.status === 'unverified' || verificationStatus.status === 'rejected') && (
          <div className="space-y-6">
            {/* Challenge Section */}
            <div className="p-6 bg-gray-800 rounded-lg border border-gray-700">
              <h3 className="text-xl font-semibold mb-4">Your Challenge</h3>
              
              {challenge ? (
                <div className="space-y-4">
                  <div className="p-4 bg-purple-900/30 rounded-lg border border-purple-500/30">
                    <p className="text-lg font-medium text-purple-200 text-center">
                      {challenge}
                    </p>
                  </div>
                  
                  <button
                    onClick={getNewChallenge}
                    disabled={loading}
                    className="text-sm text-gray-400 hover:text-white underline"
                  >
                    Get Different Challenge
                  </button>
                </div>
              ) : (
                <div className="text-center py-8">
                  <button
                    onClick={getNewChallenge}
                    disabled={loading}
                    className="px-6 py-3 bg-purple-600 hover:bg-purple-700 rounded-lg font-medium"
                  >
                    {loading ? 'Getting Challenge...' : 'Get Verification Challenge'}
                  </button>
                </div>
              )}
            </div>

            {/* Photo Upload Section */}
            {challenge && (
              <div className="p-6 bg-gray-800 rounded-lg border border-gray-700">
                <h3 className="text-xl font-semibold mb-4">Take Your Photo</h3>
                
                <div className="space-y-4">
                  <div className="border-2 border-dashed border-gray-600 rounded-lg p-6 text-center">
                    {previewUrl ? (
                      <div className="space-y-4">
                        <img
                          src={previewUrl}
                          alt="Verification photo preview"
                          className="mx-auto max-h-64 rounded-lg"
                        />
                        <p className="text-sm text-gray-400">Verification Photo</p>
                      </div>
                    ) : (
                      <div className="space-y-4">
                        <div className="text-4xl">📸</div>
                        <p className="text-gray-400">Take a photo following the challenge</p>
                        <input
                          type="file"
                          accept="image/*"
                          capture="camera"
                          onChange={handleFileSelect}
                          className="hidden"
                          id="verification-photo"
                        />
                        <label
                          htmlFor="verification-photo"
                          className="inline-block px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg cursor-pointer"
                        >
                          Choose Photo
                        </label>
                      </div>
                    )}
                  </div>
                  
                  {selectedFile && (
                    <div className="space-y-4">
                      <div className="bg-blue-900/30 p-4 rounded-lg border border-blue-500/30">
                        <p className="text-sm text-blue-200">
                          <strong>Challenge:</strong> {challenge}
                        </p>
                        <p className="text-sm text-gray-400 mt-1">
                          Make sure your photo clearly shows you following this instruction
                        </p>
                      </div>
                      
                      <button
                        onClick={submitVerification}
                        disabled={uploading}
                        className="w-full px-6 py-3 bg-green-600 hover:bg-green-700 disabled:bg-gray-600 rounded-lg font-medium"
                      >
                        {uploading ? 'Verifying...' : 'Submit for Verification'}
                      </button>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        )}

        {/* Benefits Section */}
        <div className="mt-8 p-6 bg-green-900/20 rounded-lg border border-green-500/30">
          <h3 className="text-lg font-semibold text-green-400 mb-4">Benefits of Verification</h3>
          <ul className="space-y-2 text-sm text-gray-300">
            <li>✓ More profile views and matches</li>
            <li>✓ Higher trust from other users</li>
            <li>✓ Priority in search results</li>
            <li>✓ Verified badge on your profile</li>
          </ul>
        </div>
      </div>
    </div>
  )
}
