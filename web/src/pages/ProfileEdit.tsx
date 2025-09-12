import React, { useEffect, useState } from 'react'
import { useAuth } from '../context/AuthContext'
import api from '../services/api'
import { supabase } from '../supabaseClient'

export default function ProfileEdit() {
  const { user } = useAuth()
  const [name, setName] = useState('')
  const [age, setAge] = useState<number | ''>('')
  const [bio, setBio] = useState('')
  const [file, setFile] = useState<File | null>(null)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    const load = async () => {
      if (!user) return
      const { data } = await supabase.from('profiles').select('*').eq('id', user.id).maybeSingle()
      if (data) {
        setName(data.name || '')
        setAge(data.age || '')
        setBio(data.bio || '')
      }
    }
    load()
  }, [user])

  const save = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!user) return alert('Sign in first')
    setLoading(true)
    try {
      let avatar_url = undefined
      if (file) {
        avatar_url = await api.uploadProfileImage(file, user.id)
      }
      const payload: any = { id: user.id, name, age: age || 0, bio }
      if (avatar_url) payload.avatar_url = avatar_url
      await supabase.from('profiles').upsert(payload)
      alert('Saved')
    } catch (e) {
      console.error(e)
      alert('Save failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-md mx-auto mt-8">
      <h2 className="text-2xl font-semibold mb-4">Edit profile</h2>
      <form onSubmit={save} className="space-y-3">
        <input className="w-full px-3 py-2 border rounded" placeholder="Name" value={name} onChange={(e) => setName(e.target.value)} />
        <input className="w-full px-3 py-2 border rounded" placeholder="Age" value={age as any} onChange={(e) => setAge(e.target.value ? Number(e.target.value) : '')} />
        <textarea className="w-full px-3 py-2 border rounded" placeholder="Bio" value={bio} onChange={(e) => setBio(e.target.value)} />
        <div>
          <label className="block text-sm mb-1">Avatar</label>
          <input type="file" accept="image/*" onChange={(e) => setFile(e.target.files?.[0] ?? null)} />
        </div>
        <button className="w-full bg-accent text-white px-4 py-2 rounded" disabled={loading}>Save</button>
      </form>
    </div>
  )
}


