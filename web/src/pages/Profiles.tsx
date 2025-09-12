import React, { useEffect, useState } from 'react'
import api from '../services/api'
import DiscoverProfileCard from '../components/DiscoverProfileCard'

export default function Profiles() {
  const [profiles, setProfiles] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const load = async () => {
      try {
        setLoading(true)
        setError(null)
        const rows = await api.fetchProfiles(50)
        setProfiles(rows || [])
        console.log('Loaded profiles:', rows?.length || 0)
      } catch (err: any) {
        console.error('Error loading profiles:', err)
        setError(err.message || 'Failed to load profiles')
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="w-8 h-8 border-4 border-secondary border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-gray-600">Loading profiles...</p>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="text-red-500 text-xl mb-4">⚠️</div>
          <p className="text-red-600 mb-4">{error}</p>
          <button 
            onClick={() => window.location.reload()} 
            className="bg-secondary text-white px-4 py-2 rounded-lg hover:bg-primary transition-colors"
          >
            Retry
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen">
      <div className="max-w-[1400px] mx-auto p-4">
        <div className="mb-8 text-white">
          <h1 className="text-3xl font-bold mb-2">Discover</h1>
          <p className="text-light-white">Find amazing people in your area</p>
        </div>
        
        {profiles.length === 0 ? (
          <div className="text-center py-12 text-white/80">
            <div className="text-6xl mb-4">👥</div>
            <h3 className="text-xl font-semibold mb-2">No profiles found</h3>
            <p className="text-light-white">Check back later for new profiles!</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-3 gap-6">
            {profiles.map((p) => (
              <DiscoverProfileCard key={p.id} profile={p} />
            ))}
          </div>
        )}
      </div>
    </div>
  )
}


