import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import WizardShell from './WizardShell'
import { useAuth } from '../../context/AuthContext'
import { upsertMyProfile } from '../../services/profiles'

export default function Step1Gender() {
  const nav = useNavigate()
  const { user } = useAuth()
  const [gender, setGender] = useState<'Male'|'Female'|'Non-binary'|''>('')
  const [saving, setSaving] = useState(false)
  const save = async () => {
    try {
      if (!user) {
        console.warn('[Step1Gender] No user in context')
        return
      }
      if (!gender) {
        console.warn('[Step1Gender] No gender selected')
        return
      }
      setSaving(true)
      console.log('[Step1Gender] Upserting profile', { id: user.id, name: '', age: 18, hobbies: [], image_urls: [] })
      // Satisfy possible NOT NULL constraints on initial insert
      await upsertMyProfile({ id: user.id, name: '', age: 18, hobbies: [], image_urls: [] })
      console.log('[Step1Gender] Upsert success → navigating to step 2')
      nav('/profile/setup/2')
    } catch (e: any) {
      console.error('[Step1Gender] Save error', e)
      alert(e?.message || 'Failed to save. Please try again.')
    } finally {
      setSaving(false)
    }
  }
  return (
    <WizardShell step={1}>
      <div className="space-y-4">
        <div className="text-white text-xl font-semibold mb-2">I am a</div>
        <div className="grid grid-cols-1 gap-3">
          {(['Male','Female','Non-binary'] as const).map(g => (
            <button key={g} onClick={() => setGender(g)} className={`w-full px-4 py-4 rounded-xl border ${gender===g?'border-light-pink bg-white/20 text-white':'border-border-white-10 bg-white/10 text-white'}`}>{g}</button>
          ))}
        </div>
        <div className="flex justify-end pt-4">
          <button onClick={save} className="bg-gradient-cta text-white px-6 py-3 rounded-full font-semibold disabled:opacity-50" disabled={!gender || saving}>{saving ? 'Saving…' : 'Next'}</button>
        </div>
      </div>
    </WizardShell>
  )
}


