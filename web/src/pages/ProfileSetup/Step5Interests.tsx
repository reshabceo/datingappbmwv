import React, { useState } from 'react'
import WizardShell from './WizardShell'
import { useAuth } from '../../context/AuthContext'
import { upsertMyProfile, ensureProfileInitialized, getMyProfile } from '../../services/profiles'
import { useNavigate } from 'react-router-dom'

const INTERESTS = ['Music','Travel','Sports','Movies','Food','Photography','Reading','Gaming','Dancing','Art']

export default function Step5Interests() {
  const { user } = useAuth()
  const nav = useNavigate()
  const [selected, setSelected] = useState<string[]>([])
  const toggle = (i: string) => setSelected((s) => (s.includes(i) ? s.filter(x=>x!==i) : [...s, i]))
  const next = async () => {
    if (!user) return
    try {
      await ensureProfileInitialized(user.id)
      const existing = await getMyProfile(user.id)
      await upsertMyProfile({ id: user.id, hobbies: selected, name: existing?.name ?? 'EMPTY', age: existing?.age ?? 18 })
      nav('/profile/setup/6')
    } catch (e: any) {
      console.error('[Step5Interests] save error', e)
      alert(e?.message || 'Failed to save interests')
    }
  }
  return (
    <WizardShell step={5}>
      <div className="space-y-4">
        <div className="text-white text-xl font-semibold">Your interests</div>
        <div className="grid grid-cols-2 gap-3">
          {INTERESTS.map((i)=> (
            <button key={i} onClick={()=>toggle(i)} className={`px-4 py-3 rounded-xl border ${selected.includes(i)?'border-light-pink bg-white/20 text-white':'border-border-white-10 bg-white/10 text-white'}`}>{i}</button>
          ))}
        </div>
        <div className="text-light-white">Selected: {selected.length} (Minimum 2 required)</div>
        <div className="flex justify-between pt-4">
          <button onClick={()=>nav('/profile/setup/4')} className="px-6 py-3 rounded-full border border-border-white-10 text-white">Back</button>
          <button onClick={next} className="bg-gradient-cta text-white px-6 py-3 rounded-full font-semibold disabled:opacity-50" disabled={selected.length<2}>Next</button>
        </div>
      </div>
    </WizardShell>
  )
}


