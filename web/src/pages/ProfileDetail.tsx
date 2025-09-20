import React, { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import api from '../services/api'
import { Heart, MapPin, Calendar, Camera, Star, ArrowLeft, User } from 'lucide-react'

type Profile = {
  id: string
  name?: string | null
  age?: number | null
  image_urls?: string[] | null
  photos?: string[] | null
  location?: string | null
  is_active?: boolean | null
  last_seen?: string | null
  description?: string | null
  hobbies?: string[] | null
  created_at?: string | null
}

export default function ProfileDetail() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [profile, setProfile] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)
  const [selectedPhotoIndex, setSelectedPhotoIndex] = useState(0)

  useEffect(() => {
    const load = async () => {
      if (!id) return
      try {
        setLoading(true)
        const p = await api.fetchProfileById(id)
        setProfile(p)
      } catch (error) {
        console.error('Error loading profile:', error)
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [id])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        {/* Back Button */}
        <div className="fixed top-20 left-4 z-50">
          <button
            onClick={() => navigate(-1)}
            className="w-12 h-12 bg-black/60 backdrop-blur-sm border border-white/20 rounded-full flex items-center justify-center text-white hover:bg-black/80 hover:scale-105 transition-all duration-200 shadow-lg"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
        </div>
        
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-pink border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-white/70">Loading profile...</p>
        </div>
      </div>
    )
  }

  if (!profile) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="text-6xl mb-4">😔</div>
          <h2 className="text-2xl font-bold text-white mb-2">Profile not found</h2>
          <p className="text-white/70 mb-6">This profile might have been removed or doesn't exist.</p>
          <button 
            onClick={() => navigate('/browse')}
            className="bg-gradient-cta text-white px-6 py-3 rounded-full font-semibold hover:scale-105 transition-transform"
          >
            Back to Discover
          </button>
        </div>
      </div>
    )
  }

  const gallery: string[] = (profile.image_urls && profile.image_urls.length ? profile.image_urls : (profile.photos || [])) as string[]
  const mainPhoto = gallery?.[0]
  const isVerified = Boolean(profile.is_active)
  const activeNow = (() => {
    if (!profile.last_seen) return false
    const last = new Date(profile.last_seen).getTime()
    return Date.now() - last < 5 * 60 * 1000
  })()
  const hobbies = Array.isArray(profile.hobbies) ? profile.hobbies : []
  const joinDate = profile.created_at ? new Date(profile.created_at).toLocaleDateString('en-US', { 
    year: 'numeric', 
    month: 'long' 
  }) : null

  return (
    <div className="min-h-screen">
      {/* Back Button */}
      <div className="fixed top-20 left-4 z-50">
        <button
          onClick={() => navigate(-1)}
          className="w-12 h-12 bg-black/60 backdrop-blur-sm border border-white/20 rounded-full flex items-center justify-center text-white hover:bg-black/80 hover:scale-105 transition-all duration-200 shadow-lg"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-6 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
          {/* Left Side - Photo Section */}
          <div className="space-y-6">
            {/* Main Profile Photo */}
            <div className="relative">
              <div className="aspect-[4/5] rounded-3xl overflow-hidden bg-white/5 border border-white/10">
                {mainPhoto ? (
                  <img 
                    src={mainPhoto} 
                    alt={profile.name || 'profile'} 
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-white/50">
                    <div className="text-center">
                      <Camera className="w-16 h-16 mx-auto mb-4 opacity-50" />
                      <p className="text-lg">No photos available</p>
                    </div>
                  </div>
                )}
              </div>
              
              {/* Status Badges */}
              <div className="absolute top-4 right-4 flex flex-col gap-2">
                {isVerified && (
                  <div className="px-3 py-1.5 rounded-full bg-pink/20 border border-pink-30 backdrop-blur-sm">
                    <div className="flex items-center gap-1.5 text-pink text-sm font-medium">
                      <Star className="w-4 h-4" />
                      <span>Verified</span>
                    </div>
                  </div>
                )}
                {activeNow && (
                  <div className="px-3 py-1.5 rounded-full bg-green-500/20 border border-green-400/30 backdrop-blur-sm">
                    <div className="flex items-center gap-1.5 text-green-400 text-sm font-medium">
                      <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                      <span>Active Now</span>
                    </div>
                  </div>
                )}
              </div>

              {/* Photo Count */}
              {gallery.length > 1 && (
                <div className="absolute top-4 left-4 px-3 py-1.5 rounded-full bg-black/60 backdrop-blur-sm border border-pink-30">
                  <div className="flex items-center gap-1.5 text-white text-sm">
                    <Camera className="w-4 h-4" />
                    <span>{gallery.length} photos</span>
                  </div>
                </div>
              )}
            </div>

            {/* Photo Gallery */}
            {gallery.length > 1 && (
              <div>
                <h3 className="text-xl font-bold text-white mb-4">Photo Gallery</h3>
                <div className="grid grid-cols-2 gap-4">
                  {gallery.slice(1).map((photo, index) => (
                    <div 
                      key={index}
                      className={`relative aspect-square rounded-2xl overflow-hidden cursor-pointer transition-all duration-300 hover:scale-105 group ${
                        selectedPhotoIndex === index + 1 ? 'ring-2 ring-pink shadow-lg shadow-pink/20' : ''
                      }`}
                      onClick={() => setSelectedPhotoIndex(index + 1)}
                    >
                      <img 
                        src={photo} 
                        alt={`Photo ${index + 2}`}
                        className="w-full h-full object-cover"
                      />
                      <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors" />
                      <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                        <div className="w-8 h-8 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center">
                          <Camera className="w-4 h-4 text-white" />
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Right Side - Profile Details */}
          <div className="space-y-8">
            {/* Basic Info */}
            <div className="space-y-4">
              <div className="flex items-center gap-4">
                <div className="w-20 h-20 rounded-full overflow-hidden border-2 border-pink/30">
                  {mainPhoto ? (
                    <img src={mainPhoto} alt="avatar" className="w-full h-full object-cover" />
                  ) : (
                    <div className="w-full h-full bg-white/10 flex items-center justify-center">
                      <User className="w-8 h-8 text-white/50" />
                    </div>
                  )}
                </div>
                <div>
                  <h1 className="text-4xl font-bold text-white mb-1">{profile.name || 'Anonymous'}</h1>
                  <div className="flex items-center gap-4 text-white/70">
                    {profile.age && (
                      <div className="flex items-center gap-1">
                        <Calendar className="w-4 h-4" />
                        <span>{profile.age} years old</span>
                      </div>
                    )}
                    {profile.location && (
                      <div className="flex items-center gap-1">
                        <MapPin className="w-4 h-4" />
                        <span>{profile.location}</span>
                      </div>
                    )}
                  </div>
                  {joinDate && (
                    <div className="flex items-center gap-1 text-white/60 text-sm mt-1">
                      <Calendar className="w-4 h-4" />
                      <span>Joined {joinDate}</span>
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* About Section */}
            <div className="space-y-3">
              <h2 className="text-2xl font-bold text-white">About</h2>
              <div className="bg-white/5 backdrop-blur-sm rounded-2xl p-6 border border-white/10">
                <p className="text-white/80 text-lg leading-relaxed">
                  {profile.description || profile.bio || 'No bio provided yet.'}
                </p>
              </div>
            </div>

            {/* Interests */}
            {hobbies.length > 0 && (
              <div className="space-y-4">
                <h2 className="text-2xl font-bold text-white">Interests</h2>
                <div className="flex flex-wrap gap-3">
                  {hobbies.map((hobby, idx) => (
                    <span 
                      key={idx}
                      className="px-4 py-2 bg-gradient-cta text-white rounded-full text-sm font-medium hover:scale-105 transition-transform cursor-default"
                    >
                      {hobby}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {/* Stats */}
            <div className="grid grid-cols-2 gap-4">
              <div className="bg-white/5 backdrop-blur-sm rounded-2xl p-6 border border-white/10 text-center">
                <div className="text-2xl font-bold text-pink mb-1">{gallery.length}</div>
                <div className="text-white/70 text-sm">Photos</div>
              </div>
              <div className="bg-white/5 backdrop-blur-sm rounded-2xl p-6 border border-white/10 text-center">
                <div className="text-2xl font-bold text-pink mb-1">{hobbies.length}</div>
                <div className="text-white/70 text-sm">Interests</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}


