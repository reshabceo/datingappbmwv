import React, { useEffect, useState } from 'react'
import api from '../services/api'
import StoryCard from '../components/StoryCard'
import StoryViewer from '../components/StoryViewer'
import { Routes, Route, useParams } from 'react-router-dom'

export default function Stories() {
  const [stories, setStories] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const load = async () => {
      try {
        setLoading(true)
        setError(null)
        const rows = await api.fetchStories()
        setStories(rows || [])
        console.log('Loaded stories:', rows?.length || 0)
      } catch (err: any) {
        console.error('Error loading stories:', err)
        setError(err.message || 'Failed to load stories')
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [])

  if (loading) {
    return (
      <div className="min-h-screen bg-light-bg flex items-center justify-center">
        <div className="text-center">
          <div className="w-8 h-8 border-4 border-secondary border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-gray-600">Loading stories...</p>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen bg-light-bg flex items-center justify-center">
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
    <div className="min-h-screen bg-light-bg">
      <div className="max-w-4xl mx-auto p-4">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-3xl font-bold text-gray-800">Stories</h1>
          <button className="bg-gradient-to-r from-secondary to-primary text-white px-6 py-3 rounded-xl font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200">
            + Add Story
          </button>
        </div>
        
        {stories.length === 0 ? (
          <div className="text-center py-12">
            <div className="text-gray-400 text-6xl mb-4">📸</div>
            <h3 className="text-xl font-semibold text-gray-600 mb-2">No stories yet</h3>
            <p className="text-gray-500">Be the first to share a story!</p>
          </div>
        ) : (
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
            {stories.map((s) => (
              <StoryCard key={s.id} story={s} />
            ))}
          </div>
        )}

        <Routes>
          <Route path="/story/:id" element={<StoryRoute />} />
        </Routes>
      </div>
    </div>
  )
}

function StoryRoute() {
  const { id } = useParams()
  if (!id) return null
  return <StoryViewer storyId={id} />
}


