import React, { useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import api from '../services/api'
import ProfileAvatar from '../components/ProfileAvatar'

export default function ProfileDetail() {
  const { id } = useParams()
  const [profile, setProfile] = useState<any | null>(null)

  useEffect(() => {
    const load = async () => {
      if (!id) return
      const p = await api.fetchProfileById(id)
      setProfile(p)
    }
    load()
  }, [id])

  if (!profile) return <div className="mt-8">Profile not found</div>

  return (
    <div className="max-w-2xl mx-auto bg-white shadow rounded p-4 mt-6">
      <div className="flex items-center space-x-4">
        <ProfileAvatar src={profile.avatar_url} size={96} />
        <div>
          <div className="text-xl font-semibold">{profile.name}</div>
          <div className="text-sm text-gray-500">{profile.age ? `${profile.age} yrs` : ''}</div>
        </div>
      </div>

      <div className="mt-4">
        <h3 className="font-semibold">About</h3>
        <p className="text-sm text-gray-700 mt-2">{profile.bio ?? 'No bio provided'}</p>
      </div>

      {profile.gallery && profile.gallery.length > 0 && (
        <div className="mt-4">
          <h3 className="font-semibold mb-2">Photos</h3>
          <div className="grid grid-cols-3 gap-2">
            {profile.gallery.map((g: string, idx: number) => (
              <img key={idx} src={g} className="w-full h-24 object-cover rounded" />
            ))}
          </div>
        </div>
      )}
    </div>
  )
}


