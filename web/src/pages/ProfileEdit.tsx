import React, { useEffect, useState, useRef } from 'react'
import { useAuth } from '../context/AuthContext'
import api from '../services/api'
import { supabase } from '../supabaseClient'
import { User, Camera, MapPin, Heart, Save, Upload, X, Navigation, Loader2 } from 'lucide-react'

const INTERESTS = [
  'Music', 'Travel', 'Sports', 'Movies', 'Food', 'Photography', 
  'Reading', 'Gaming', 'Dancing', 'Art', 'Fitness', 'Cooking',
  'Writing', 'Technology', 'Nature', 'Fashion', 'Pets', 'Adventure'
]

export default function ProfileEdit() {
  const { user } = useAuth()
  const [name, setName] = useState('')
  const [age, setAge] = useState<number | ''>('')
  const [description, setDescription] = useState('')
  const [location, setLocation] = useState('')
  
  // Debug log when location changes
  useEffect(() => {
    console.log('📍 [DEBUG] Location state changed to:', location)
  }, [location])
  const [hobbies, setHobbies] = useState<string[]>([])
  const [imageUrls, setImageUrls] = useState<string[]>([])
  const [newFiles, setNewFiles] = useState<File[]>([])
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [detectingLocation, setDetectingLocation] = useState(false)
  const [locationPermission, setLocationPermission] = useState<'granted' | 'denied' | 'prompt' | 'unknown'>('unknown')
  const [hasInitiallyLoaded, setHasInitiallyLoaded] = useState(false)
  const locationRef = useRef('')

  useEffect(() => {
    const load = async () => {
      if (!user) return
      setLoading(true)
      console.log('🔍 [DEBUG] Starting profile load for user:', user.id)
      try {
        const { data, error } = await supabase.from('profiles').select('*').eq('id', user.id).maybeSingle()
        console.log('🔍 [DEBUG] Profile query result:', { data, error })
        
        if (error) {
          console.error('❌ [DEBUG] Profile query error:', error)
          return
        }
        
        if (data) {
          console.log('🔍 [DEBUG] Raw profile data from DB:', data)
          console.log('🔍 [DEBUG] Location from DB:', data.location)
          console.log('🔍 [DEBUG] Description from DB:', data.description)
          console.log('🔍 [DEBUG] Hobbies from DB:', data.hobbies)
          console.log('🔍 [DEBUG] Image URLs from DB:', data.image_urls)
          
          setName(data.name || '')
          setAge(data.age || '')
          setDescription(data.description || '') // Use description field (actual DB field)
          
          // Only set location on initial load to prevent overwriting detected location
          if (!hasInitiallyLoaded) {
            const dbLocation = data.location || ''
            setLocation(dbLocation)
            locationRef.current = dbLocation
            console.log('🔍 [DEBUG] Initial load - Location set from DB:', dbLocation)
            setHasInitiallyLoaded(true)
          } else {
            console.log('🔍 [DEBUG] Subsequent load - keeping current location:', locationRef.current)
          }
          
          setHobbies(data.hobbies || []) // Use hobbies field (actual DB field)
          setImageUrls(data.image_urls || []) // Use image_urls field (actual DB field)
          
          console.log('🔍 [DEBUG] State set - Location:', location)
        } else {
          console.log('🔍 [DEBUG] No profile data found for user')
        }
      } catch (error) {
        console.error('❌ [DEBUG] Error loading profile:', error)
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [user])

  const handleInterestToggle = (interest: string) => {
    setHobbies(prev => 
      prev.includes(interest) 
        ? prev.filter(h => h !== interest)
        : [...prev, interest]
    )
  }

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || [])
    setNewFiles(prev => [...prev, ...files])
  }

  const removeImage = (index: number) => {
    setImageUrls(prev => prev.filter((_, i) => i !== index))
  }

  const removeNewFile = (index: number) => {
    setNewFiles(prev => prev.filter((_, i) => i !== index))
  }

  const moveImage = (fromIndex: number, toIndex: number) => {
    setImageUrls(prev => {
      const newImages = [...prev]
      const [movedImage] = newImages.splice(fromIndex, 1)
      newImages.splice(toIndex, 0, movedImage)
      return newImages
    })
  }

  // Check location permission on component mount
  useEffect(() => {
    if ('geolocation' in navigator) {
      navigator.permissions?.query({ name: 'geolocation' as PermissionName }).then((result) => {
        setLocationPermission(result.state as 'granted' | 'denied' | 'prompt')
      }).catch(() => {
        setLocationPermission('unknown')
      })
    }
  }, [])

  const detectLocation = async () => {
    console.log('📍 [DEBUG] Starting location detection')
    
    if (!navigator.geolocation) {
      console.log('❌ [DEBUG] Geolocation not supported')
      alert('Geolocation is not supported by this browser.')
      return
    }

    setDetectingLocation(true)
    console.log('📍 [DEBUG] Requesting geolocation...')
    
    try {
      const position = await new Promise<GeolocationPosition>((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(resolve, reject, {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 300000 // 5 minutes
        })
      })

      const { latitude, longitude } = position.coords
      console.log('📍 [DEBUG] Got coordinates:', { latitude, longitude })
      
      // Reverse geocoding to get city and country
      try {
        console.log('📍 [DEBUG] Starting reverse geocoding...')
        const response = await fetch(
          `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${latitude}&longitude=${longitude}&localityLanguage=en`
        )
        const data = await response.json()
        console.log('📍 [DEBUG] Reverse geocoding response:', data)
        
        if (data.city && data.countryName) {
          const detectedLocation = `${data.city}, ${data.countryName}`
          console.log('📍 [DEBUG] Setting location to:', detectedLocation)
          setLocation(detectedLocation)
          locationRef.current = detectedLocation
          setLocationPermission('granted')
        } else {
          const coordinateLocation = `${latitude.toFixed(4)}, ${longitude.toFixed(4)}`
          console.log('📍 [DEBUG] Setting location to coordinates:', coordinateLocation)
          setLocation(coordinateLocation)
          locationRef.current = coordinateLocation
        }
      } catch (error) {
        // Fallback to coordinates if reverse geocoding fails
        const coordinateLocation = `${latitude.toFixed(4)}, ${longitude.toFixed(4)}`
        console.log('📍 [DEBUG] Reverse geocoding failed, using coordinates:', coordinateLocation)
        setLocation(coordinateLocation)
        locationRef.current = coordinateLocation
      }
      
    } catch (error: any) {
      console.error('❌ [DEBUG] Location detection failed:', error)
      
      if (error.code === 1) {
        console.log('❌ [DEBUG] Permission denied')
        alert('Location access denied. Please enable location permissions in your browser settings.')
        setLocationPermission('denied')
      } else if (error.code === 2) {
        console.log('❌ [DEBUG] Location unavailable')
        alert('Location unavailable. Please check your internet connection and try again.')
      } else if (error.code === 3) {
        console.log('❌ [DEBUG] Location timeout')
        alert('Location request timed out. Please try again.')
      } else {
        console.log('❌ [DEBUG] Unknown location error')
        alert('Failed to detect location. Please enter your location manually.')
      }
    } finally {
      setDetectingLocation(false)
      console.log('📍 [DEBUG] Location detection completed')
    }
  }

  const save = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!user) return alert('Sign in first')
    setSaving(true)
    
    console.log('💾 [DEBUG] Starting save process')
    console.log('💾 [DEBUG] Current state values:')
    console.log('  - Name:', name)
    console.log('  - Age:', age)
    console.log('  - Description:', description)
    console.log('  - Location (state):', location)
    console.log('  - Location (ref):', locationRef.current)
    console.log('  - Hobbies:', hobbies)
    console.log('  - ImageUrls:', imageUrls)
    console.log('  - NewFiles:', newFiles.length)
    
    try {
      // Upload new files
      const uploadedUrls: string[] = []
      for (const file of newFiles) {
        console.log('💾 [DEBUG] Uploading file:', file.name)
        const url = await api.uploadProfileImage(file, user.id)
        if (url) {
          uploadedUrls.push(url)
          console.log('💾 [DEBUG] File uploaded successfully:', url)
        }
      }

      // Combine existing and new images
      const allImageUrls = [...imageUrls, ...uploadedUrls]
      console.log('💾 [DEBUG] All image URLs:', allImageUrls)

      const payload = { 
        id: user.id, 
        name, 
        age: age || 0, 
        description: description, // Use description field (actual DB field)
        location: locationRef.current || location, // Use ref value if available
        hobbies: hobbies, // Use hobbies field (actual DB field)
        image_urls: allImageUrls // Use image_urls field (actual DB field)
      }
      
      console.log('💾 [DEBUG] Payload to save:', payload)
      console.log('💾 [DEBUG] Location in payload:', payload.location)
      
      const { data, error } = await supabase.from('profiles').upsert(payload)
      
      console.log('💾 [DEBUG] Supabase response:', { data, error })
      
      if (error) {
        console.error('❌ [DEBUG] Database error:', error)
        alert(`Save failed: ${error.message}`)
        return
      }
      
      console.log('✅ [DEBUG] Profile saved successfully:', data)
      alert('Profile saved successfully!')
    } catch (e) {
      console.error('❌ [DEBUG] Save error:', e)
      alert('Save failed. Please try again.')
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-pink border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-white/70 text-lg">Loading profile...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen">
      {/* Main Content */}
      <div className="max-w-4xl mx-auto px-6 py-8">
        <form onSubmit={save} className="space-y-8">
          {/* Profile Photo Section */}
          <div className="relative rounded-3xl p-1 bg-gradient-card-pink border border-pink-30 backdrop-blur-md shadow-card-soft">
            <div className="rounded-[22px] overflow-hidden bg-black/40 p-8">
              <div className="text-center space-y-4 sm:space-y-6">
                <div className="relative inline-block">
                  <div className="w-24 h-24 sm:w-32 sm:h-32 rounded-full overflow-hidden border-4 border-pink/30 mx-auto shadow-lg">
                    {imageUrls[0] ? (
                      <img src={imageUrls[0]} alt="Profile" className="w-full h-full object-cover" />
                    ) : (
                      <div className="w-full h-full bg-white/10 flex items-center justify-center">
                        <User className="w-8 h-8 sm:w-12 sm:h-12 text-white/50" />
                      </div>
                    )}
                  </div>
                  <label className="absolute -bottom-1 -right-1 sm:-bottom-2 sm:-right-2 w-8 h-8 sm:w-10 sm:h-10 bg-gradient-cta rounded-full flex items-center justify-center cursor-pointer hover:scale-110 transition-transform shadow-lg">
                    <Camera className="w-4 h-4 sm:w-5 sm:h-5 text-white" />
                    <input 
                      type="file" 
                      accept="image/*" 
                      onChange={handleFileUpload}
                      className="hidden"
                      multiple
                    />
                  </label>
                </div>
                
                <div>
                  <h2 className="text-xl sm:text-2xl font-bold text-white mb-1 sm:mb-2">Profile Photos</h2>
                  <p className="text-white/70 text-sm sm:text-base">Upload photos to showcase yourself</p>
                </div>

                {/* Photo Gallery - Mobile Responsive */}
                <div className="space-y-4">
                  {/* Photo Count Indicator */}
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <p className="text-white/70 text-sm">
                        {imageUrls.length + newFiles.length} photo{imageUrls.length + newFiles.length !== 1 ? 's' : ''}
                      </p>
                      {newFiles.length > 0 && (
                        <div className="flex items-center gap-1 text-pink-300 text-xs">
                          <div className="w-2 h-2 bg-pink-400 rounded-full animate-pulse"></div>
                          <span>Uploading...</span>
                        </div>
                      )}
                    </div>
                    <p className="text-pink-300 text-xs hidden sm:block">Drag to reorder</p>
                    <p className="text-pink-300 text-xs sm:hidden">Tap & hold to reorder</p>
                  </div>
                  
                  {/* Unified Responsive Photo Gallery */}
                  <div className="space-y-3">
                    {/* Mobile: 2x2 Grid, Desktop: Horizontal Scroll */}
                    <div className="grid grid-cols-2 gap-3 sm:hidden">
                      {/* Mobile Grid Layout */}
                      {imageUrls.slice(0, 4).map((url, index) => (
                        <div key={index} className="relative aspect-square rounded-xl overflow-hidden border border-white/20 group">
                          <img src={url} alt={`Photo ${index + 1}`} className="w-full h-full object-cover" />
                          <button
                            type="button"
                            onClick={() => removeImage(index)}
                            className="absolute top-2 right-2 w-8 h-8 bg-red-500 rounded-full flex items-center justify-center hover:scale-110 transition-transform shadow-lg opacity-0 group-hover:opacity-100"
                          >
                            <X className="w-4 h-4 text-white" />
                          </button>
                          {/* Photo Quality Indicator */}
                          <div className="absolute bottom-2 left-2 flex items-center gap-1">
                            <div className="w-2 h-2 bg-green-400 rounded-full"></div>
                            <span className="text-white text-xs font-medium">HD</span>
                          </div>
                          {/* Photo Number */}
                          <div className="absolute top-2 left-2 w-6 h-6 bg-black/50 rounded-full flex items-center justify-center">
                            <span className="text-white text-xs font-medium">{index + 1}</span>
                          </div>
                        </div>
                      ))}
                      {imageUrls.length < 4 && (
                        <label className="aspect-square rounded-xl border-2 border-dashed border-white/30 flex items-center justify-center cursor-pointer hover:border-pink/50 hover:bg-pink/5 transition-all duration-200 group">
                          <div className="text-center">
                            <Upload className="w-8 h-8 text-white/50 group-hover:text-pink/70 mx-auto mb-2 transition-colors" />
                            <span className="text-white/50 group-hover:text-pink/70 text-sm font-medium transition-colors">Add Photo</span>
                          </div>
                          <input 
                            type="file" 
                            accept="image/*" 
                            onChange={handleFileUpload}
                            className="hidden"
                            multiple
                          />
                        </label>
                      )}
                    </div>

                    {/* Desktop: Horizontal Scroll Layout */}
                    <div className="hidden sm:block">
                      <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-hide">
                        {/* Existing Photos */}
                        {imageUrls.map((url, index) => (
                          <div 
                            key={index} 
                            className="relative flex-shrink-0 w-24 h-24 rounded-xl overflow-hidden border-2 border-white/20 shadow-lg cursor-move hover:scale-105 transition-transform duration-200 group"
                            draggable
                            onDragStart={(e) => {
                              e.dataTransfer.setData('text/plain', index.toString())
                              e.currentTarget.style.opacity = '0.5'
                            }}
                            onDragEnd={(e) => {
                              e.currentTarget.style.opacity = '1'
                            }}
                            onDragOver={(e) => e.preventDefault()}
                            onDrop={(e) => {
                              e.preventDefault()
                              const fromIndex = parseInt(e.dataTransfer.getData('text/plain'))
                              if (fromIndex !== index) {
                                moveImage(fromIndex, index)
                              }
                            }}
                          >
                            <img 
                              src={url} 
                              alt={`Photo ${index + 1}`} 
                              className="w-full h-full object-cover pointer-events-none" 
                            />
                            <button
                              type="button"
                              onClick={() => removeImage(index)}
                              className="absolute -top-1 -right-1 w-8 h-8 bg-red-500 rounded-full flex items-center justify-center hover:scale-110 transition-transform shadow-lg border-2 border-white opacity-0 group-hover:opacity-100"
                            >
                              <X className="w-4 h-4 text-white" />
                            </button>
                            {/* Photo Number Badge */}
                            <div className="absolute bottom-1 left-1 w-5 h-5 bg-black/50 rounded-full flex items-center justify-center">
                              <span className="text-white text-xs font-medium">{index + 1}</span>
                            </div>
                            {/* Drag Handle */}
                            <div className="absolute top-1 left-1 w-5 h-5 bg-black/50 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                              <svg className="w-3 h-3 text-white" fill="currentColor" viewBox="0 0 20 20">
                                <path d="M7 2a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM7 8a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM7 14a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM13 2a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM13 8a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM13 14a2 2 0 1 0 0 4 2 2 0 0 0 0-4z"/>
                              </svg>
                            </div>
                          </div>
                        ))}
                        
                        {/* New Photos (Pending Upload) */}
                        {newFiles.map((file, index) => (
                          <div key={`new-${index}`} className="relative flex-shrink-0 w-24 h-24 rounded-xl overflow-hidden border-2 border-pink/50 shadow-lg">
                            <img 
                              src={URL.createObjectURL(file)} 
                              alt={`New photo ${index + 1}`} 
                              className="w-full h-full object-cover cursor-pointer hover:scale-105 transition-transform duration-200" 
                            />
                            <button
                              type="button"
                              onClick={() => removeNewFile(index)}
                              className="absolute -top-1 -right-1 w-8 h-8 bg-red-500 rounded-full flex items-center justify-center hover:scale-110 transition-transform shadow-lg border-2 border-white"
                            >
                              <X className="w-4 h-4 text-white" />
                            </button>
                            {/* Uploading Indicator */}
                            <div className="absolute inset-0 bg-black/50 flex items-center justify-center">
                              <div className="w-6 h-6 border-2 border-pink border-t-transparent rounded-full animate-spin"></div>
                            </div>
                          </div>
                        ))}
                        
                        {/* Add Photo Button */}
                        <label className="flex-shrink-0 w-24 h-24 rounded-xl border-2 border-dashed border-white/30 flex items-center justify-center cursor-pointer hover:border-pink/50 hover:bg-pink/5 transition-all duration-200 group">
                          <div className="text-center">
                            <Upload className="w-7 h-7 text-white/50 group-hover:text-pink/70 mx-auto mb-1 transition-colors" />
                            <span className="text-white/50 group-hover:text-pink/70 text-xs font-medium transition-colors">Add</span>
                          </div>
                          <input 
                            type="file" 
                            accept="image/*" 
                            onChange={handleFileUpload}
                            className="hidden"
                            multiple
                          />
                        </label>
                      </div>
                      
                      {/* Scroll Indicators */}
                      <div className="flex justify-center mt-2 space-x-1">
                        {Array.from({ length: Math.ceil((imageUrls.length + newFiles.length + 1) / 4) }).map((_, i) => (
                          <div key={i} className="w-1.5 h-1.5 bg-white/30 rounded-full"></div>
                        ))}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Basic Information */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <div className="space-y-6">
              <div className="bg-white/5 backdrop-blur-sm rounded-2xl p-6 border border-white/10">
                <h3 className="text-xl font-bold text-white mb-4">Basic Information</h3>
                <div className="space-y-4">
                  <div>
                    <label className="block text-white/80 text-sm font-medium mb-2">Name</label>
                    <input 
                      className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-xl text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-pink/50 focus:border-transparent transition-all"
                      placeholder="Your name"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      required
                    />
                  </div>
                  
                      <div>
                        <label className="block text-white/80 text-sm font-medium mb-2">Age</label>
                        <input 
                          type="number"
                          min="18"
                          max="100"
                          className="w-full px-4 py-3 bg-white/5 border border-white/10 rounded-xl text-white/70 placeholder-white/30 focus:outline-none transition-all cursor-not-allowed"
                          placeholder="Your age"
                          value={age}
                          readOnly
                          disabled
                        />
                        <p className="text-xs text-white/50 mt-1">Age cannot be changed after registration</p>
                      </div>
                  
                  <div>
                    <label className="block text-white/80 text-sm font-medium mb-2">Location</label>
                    <div className="space-y-3">
                      <div className="relative">
                        <MapPin className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-white/50" />
                        <input 
                          className="w-full pl-10 pr-4 py-3 bg-white/10 border border-white/20 rounded-xl text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-pink/50 focus:border-transparent transition-all"
                          placeholder="City, Country"
                          value={location}
                          onChange={(e) => setLocation(e.target.value)}
                        />
                      </div>
                      
                      <div className="flex items-center gap-3">
                        <button
                          type="button"
                          onClick={detectLocation}
                          disabled={detectingLocation || locationPermission === 'denied'}
                          className="flex items-center gap-2 px-4 py-2 bg-gradient-cta text-white text-sm font-medium rounded-lg hover:scale-105 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
                        >
                          {detectingLocation ? (
                            <>
                              <Loader2 className="w-4 h-4 animate-spin" />
                              Detecting...
                            </>
                          ) : (
                            <>
                              <Navigation className="w-4 h-4" />
                              Use Current Location
                            </>
                          )}
                        </button>
                        
                        {locationPermission === 'denied' && (
                          <span className="text-xs text-red-400">
                            Location access denied. Please enable in browser settings.
                          </span>
                        )}
                        
                        {locationPermission === 'granted' && location && (
                          <span className="text-xs text-green-400 flex items-center gap-1">
                            <MapPin className="w-3 h-3" />
                            Location detected
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="space-y-6">
              <div className="bg-white/5 backdrop-blur-sm rounded-2xl p-6 border border-white/10">
                <h3 className="text-xl font-bold text-white mb-4">About You</h3>
                <div>
                  <label className="block text-white/80 text-sm font-medium mb-2">Bio</label>
                  <textarea 
                    className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-xl text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-pink/50 focus:border-transparent transition-all resize-none"
                    placeholder="Tell us about yourself..."
                    rows={6}
                    value={description}
                    onChange={(e) => setDescription(e.target.value)}
                  />
                </div>
              </div>
            </div>
          </div>

          {/* Interests Section */}
          <div className="bg-white/5 backdrop-blur-sm rounded-2xl p-6 border border-white/10">
            <h3 className="text-xl font-bold text-white mb-4">Interests</h3>
            <p className="text-white/70 mb-6">Select your interests to help others find you</p>
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
              {INTERESTS.map((interest) => (
                <button
                  key={interest}
                  type="button"
                  onClick={() => handleInterestToggle(interest)}
                  className={`px-4 py-3 rounded-xl text-sm font-medium transition-all duration-300 hover:scale-105 ${
                    hobbies.includes(interest)
                      ? 'bg-gradient-cta text-white border border-pink/30'
                      : 'bg-white/10 text-white/70 border border-white/20 hover:bg-white/20'
                  }`}
                >
                  {interest}
                </button>
              ))}
            </div>
          </div>

          {/* Save Button */}
          <div className="flex justify-center">
            <button
              type="submit"
              disabled={saving}
              className="px-12 py-4 bg-gradient-cta text-white font-semibold rounded-2xl hover:scale-105 transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-3"
            >
              {saving ? (
                <>
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                  Saving...
                </>
              ) : (
                <>
                  <Save className="w-5 h-5" />
                  Save Profile
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}


