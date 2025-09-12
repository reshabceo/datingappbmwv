import React from 'react'

type Props = {
  id: string
  name?: string
  age?: number
  avatar_url?: string
}

import { Link } from 'react-router-dom'

export default function ProfileCard({ id, name, age, avatar_url }: Props) {
  return (
    <Link to={`/profile/${id}`} className="block">
      <div className="bg-light-card shadow-lg rounded-xl overflow-hidden hover:shadow-xl transition-all duration-300 transform hover:scale-105 border border-border-black-10">
        <div className="aspect-[3/4] bg-gradient-to-br from-secondary to-primary flex items-center justify-center relative">
          {avatar_url ? (
            <img 
              src={avatar_url} 
              alt={name} 
              className="h-full w-full object-cover" 
            />
          ) : (
            <div className="text-white text-center">
              <div className="w-16 h-16 bg-white bg-opacity-20 rounded-full flex items-center justify-center mb-2 mx-auto">
                <span className="text-2xl">👤</span>
              </div>
              <div className="text-sm">No image</div>
            </div>
          )}
          <div className="absolute top-2 right-2 bg-black bg-opacity-50 text-white text-xs px-2 py-1 rounded-full">
            {age ? `${age}` : '?'}
          </div>
        </div>
        <div className="p-4 bg-white">
          <div className="font-semibold text-gray-800 text-lg capitalize">{name || 'Unknown'}</div>
          <div className="text-sm text-gray-500 mt-1">
            {age ? `${age} years old` : 'Age not specified'}
          </div>
        </div>
      </div>
    </Link>
  )
}


