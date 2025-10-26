import React, { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import WizardShell from './WizardShell'
import { upsertMyProfile } from '../../services/profiles'
import { useAuth } from '../../context/AuthContext'

export default function Step2Basic() {
  const nav = useNavigate()
  const { user } = useAuth()
  const [name, setName] = useState('')
  const [dob, setDob] = useState('') // YYYY-MM-DD
  const age = useMemo(() => {
    if (!dob) return 0
    const d = new Date(dob)
    const diff = Date.now() - d.getTime()
    const a = new Date(diff).getUTCFullYear() - 1970
    return a
  }, [dob])
  const valid = Boolean(name.trim() && age >= 18)

  const save = async () => {
    if (!user || !valid) return
    // Save derived age to match existing schema; DOB kept client-side only
    await upsertMyProfile({ id: user.id, name, age })
    nav('/profile/setup/3')
  }
  return (
    <WizardShell step={2}>
      <div className="space-y-4">
        <div className="text-white text-xl font-semibold">Tell us about yourself</div>
        <input className="w-full px-4 py-3 bg-white/90 border border-border-black-10 rounded-xl" placeholder="Your name" value={name} onChange={(e)=>setName(e.target.value)} />
        <input className="w-full px-4 py-3 bg-white/90 border border-border-black-10 rounded-xl" type="date" value={dob} onChange={(e)=>setDob(e.target.value)} />
        <div className="text-light-white">{dob ? (age>=18?`Age: ${age}`:'You must be at least 18') : 'Enter your date of birth'}</div>
        <div className="flex justify-between pt-4">
          <button onClick={()=>nav('/profile/setup/1')} className="px-6 py-3 rounded-full border border-border-white-10 text-white">Back</button>
          <button onClick={save} className="bg-gradient-cta text-white px-6 py-3 rounded-full font-semibold disabled:opacity-50" disabled={!valid}>Next</button>
        </div>
      </div>
    </WizardShell>
  )
}


