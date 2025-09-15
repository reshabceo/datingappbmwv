import React, { useEffect, useState } from 'react'
import { useAuth } from '../context/AuthContext'
import api from '../services/api'
import { supabase } from '../supabaseClient'
import { User, Camera, MapPin, Heart, Save, Upload, X } from 'lucide-react'

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
  const [hobbies, setHobbies] = useState<string[]>([])
  const [imageUrls, setImageUrls] = useState<string[]>([])
  const [newFiles, setNewFiles] = useState<File[]>([])
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    const load = async () => {
      if (!user) return
      setLoading(true)
      try {
        const { data } = await supabase.from('profiles').select('*').eq('id', user.id).maybeSingle()
        if (data) {
          setName(data.name || '')
          setAge(data.age || '')
          setDescription(data.description || '')
          setLocation(data.location || '')
          setHobbies(data.hobbies || [])
          setImageUrls(data.image_urls || [])
        }
      } catch (error) {
        console.error('Error loading profile:', error)
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

  const save = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!user) return alert('Sign in first')
    setSaving(true)
    try {
      // Upload new files
      const uploadedUrls: string[] = []
      for (const file of newFiles) {
        const url = await api.uploadProfileImage(file, user.id)
        if (url) uploadedUrls.push(url)
      }

      // Combine existing and new images
      const allImageUrls = [...imageUrls, ...uploadedUrls]

      const payload = { 
        id: user.id, 
        name, 
        age: age || 0, 
        description,
        location,
        hobbies,
        image_urls: allImageUrls
      }
      
      await supabase.from('profiles').upsert(payload)
      alert('Profile saved successfully!')
    } catch (e) {
      console.error(e)
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
              <div className="text-center space-y-6">
                <div className="relative inline-block">
                  <div className="w-32 h-32 rounded-full overflow-hidden border-4 border-pink/30 mx-auto">
                    {imageUrls[0] ? (
                      <img src={imageUrls[0]} alt="Profile" className="w-full h-full object-cover" />
                    ) : (
                      <div className="w-full h-full bg-white/10 flex items-center justify-center">
                        <User className="w-12 h-12 text-white/50" />
                      </div>
                    )}
                  </div>
                  <label className="absolute -bottom-2 -right-2 w-10 h-10 bg-gradient-cta rounded-full flex items-center justify-center cursor-pointer hover:scale-110 transition-transform">
                    <Camera className="w-5 h-5 text-white" />
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
                  <h2 className="text-2xl font-bold text-white mb-2">Profile Photos</h2>
                  <p className="text-white/70">Upload photos to showcase yourself</p>
                </div>

                {/* Photo Gallery */}
                <div className="grid grid-cols-4 gap-4">
                  {imageUrls.map((url, index) => (
                    <div key={index} className="relative aspect-square rounded-2xl overflow-hidden border border-white/20">
                      <img src={url} alt={`Photo ${index + 1}`} className="w-full h-full object-cover" />
                      <button
                        type="button"
                        onClick={() => removeImage(index)}
                        className="absolute top-1 right-1 w-6 h-6 bg-red-500 rounded-full flex items-center justify-center hover:scale-110 transition-transform"
                      >
                        <X className="w-3 h-3 text-white" />
                      </button>
                    </div>
                  ))}
                  {newFiles.map((file, index) => (
                    <div key={`new-${index}`} className="relative aspect-square rounded-2xl overflow-hidden border border-pink/50">
                      <img src={URL.createObjectURL(file)} alt={`New photo ${index + 1}`} className="w-full h-full object-cover" />
                      <button
                        type="button"
                        onClick={() => removeNewFile(index)}
                        className="absolute top-1 right-1 w-6 h-6 bg-red-500 rounded-full flex items-center justify-center hover:scale-110 transition-transform"
                      >
                        <X className="w-3 h-3 text-white" />
                      </button>
                    </div>
                  ))}
                  <label className="aspect-square rounded-2xl border-2 border-dashed border-white/30 flex items-center justify-center cursor-pointer hover:border-pink/50 transition-colors">
                    <div className="text-center">
                      <Upload className="w-6 h-6 text-white/50 mx-auto mb-2" />
                      <span className="text-white/50 text-sm">Add Photo</span>
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
                      className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-xl text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-pink/50 focus:border-transparent transition-all"
                      placeholder="Your age"
                      value={age}
                      onChange={(e) => setAge(e.target.value ? Number(e.target.value) : '')}
                      required
                    />
                  </div>
                  
                  <div>
                    <label className="block text-white/80 text-sm font-medium mb-2">Location</label>
                    <div className="relative">
                      <MapPin className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-white/50" />
                      <input 
                        className="w-full pl-10 pr-4 py-3 bg-white/10 border border-white/20 rounded-xl text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-pink/50 focus:border-transparent transition-all"
                        placeholder="City, Country"
                        value={location}
                        onChange={(e) => setLocation(e.target.value)}
                      />
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


