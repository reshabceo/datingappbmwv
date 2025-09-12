import React, { useState } from 'react'
import WizardShell from './WizardShell'
import { useAuth } from '../../context/AuthContext'
import { upsertMyProfile, ensureProfileInitialized, getMyProfile } from '../../services/profiles'
import { useNavigate } from 'react-router-dom'

export default function Step4Bio() {
  const { user } = useAuth()
  const nav = useNavigate()
  const [bio, setBio] = useState('')
  const next = async () => {
    if (!user) return
    try {
      await ensureProfileInitialized(user.id)
      const existing = await getMyProfile(user.id)
      await upsertMyProfile({ id: user.id, description: bio, name: existing?.name ?? 'EMPTY', age: existing?.age ?? 18 })
      nav('/profile/setup/5')
    } catch (e: any) {
      console.error('[Step4Bio] save error', e)
      alert(e?.message || 'Failed to save bio')
    }
  }
  return (
    <WizardShell step={4}>
      <div className="space-y-4">
        <div className="text-white text-xl font-semibold">Tell us about yourself</div>
        <textarea className="w-full h-40 px-4 py-3 bg-white/90 border border-border-black-10 rounded-xl" placeholder="Write a short bio..." value={bio} onChange={(e)=>setBio(e.target.value)} />
        <div className="flex justify-between pt-4">
          <button onClick={()=>nav('/profile/setup/3')} className="px-6 py-3 rounded-full border border-border-white-10 text-white">Back</button>
          <button onClick={next} className="bg-gradient-cta text-white px-6 py-3 rounded-full font-semibold">Next</button>
        </div>
      </div>
    </WizardShell>
  )
}


