import React from 'react'
import { useNavigate } from 'react-router-dom'

export default function StoryCard({ story }: { story: any }) {
  const navigate = useNavigate()

  return (
    <div 
      className="bg-light-card rounded-2xl shadow-lg overflow-hidden cursor-pointer hover:shadow-xl transform hover:scale-105 transition-all duration-300 border border-border-black-10" 
      onClick={() => navigate(`/story/${story.id}`)}
    >
      <div className="h-40 bg-gradient-to-br from-secondary to-primary flex items-center justify-center relative">
        {story.media_url ? (
          <img 
            src={story.media_url} 
            alt="story" 
            className="w-full h-full object-cover" 
          />
        ) : (
          <div className="text-white text-center">
            <div className="w-12 h-12 bg-white bg-opacity-20 rounded-full flex items-center justify-center mb-2 mx-auto">
              <span className="text-xl">📸</span>
            </div>
            <div className="text-sm">No media</div>
          </div>
        )}
        <div className="absolute top-2 left-2 bg-black bg-opacity-50 text-white text-xs px-2 py-1 rounded-full">
          {story.profiles?.name ? story.profiles.name.charAt(0).toUpperCase() : 'U'}
        </div>
      </div>
      <div className="p-3 bg-white">
        <div className="text-sm font-semibold text-gray-800 capitalize truncate">
          {story.profiles?.name ?? 'User'}
        </div>
        <div className="text-xs text-gray-500 truncate mt-1">
          {story.content ?? 'No caption'}
        </div>
      </div>
    </div>
  )
}


