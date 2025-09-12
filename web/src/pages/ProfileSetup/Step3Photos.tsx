import React, { useState } from 'react'
import WizardShell from './WizardShell'
import { useAuth } from '../../context/AuthContext'
import { upsertMyProfile, ensureProfileInitialized, getMyProfile } from '../../services/profiles'
import { uploadProfileImage } from '../../services/api'
import { useNavigate } from 'react-router-dom'

export default function Step3Photos() {
  const { user } = useAuth()
  const nav = useNavigate()
  const [photos, setPhotos] = useState<string[]>([])
  const [uploadingIndex, setUploadingIndex] = useState<number | null>(null)
  const addPhoto = async (index: number, file: File) => {
    if (!user || !file) return
    try {
      setUploadingIndex(index)
      console.log('[Step3Photos] uploading file', index, file.name)
      const url = await uploadProfileImage(file, user.id)
      if (!url) throw new Error('Upload failed')
      setPhotos((s) => [...s, url])
      console.log('[Step3Photos] uploaded url', url)
    } catch (e: any) {
      console.error('[Step3Photos] upload error', e)
      alert(e?.message || 'Image upload failed')
    } finally {
      setUploadingIndex(null)
    }
  }
  const remove = (i: number) => setPhotos((s) => s.filter((_, idx) => idx !== i))
  const next = async () => {
    if (!user) return
    try {
      await ensureProfileInitialized(user.id)
      const existing = await getMyProfile(user.id)
      const payload: any = {
        id: user.id,
        photos,
        image_urls: photos as any,
        name: existing?.name ?? 'EMPTY',
        age: existing?.age ?? 18,
      }
      console.log('[Step3Photos] upserting payload', payload)
      await upsertMyProfile(payload)
    } catch (e: any) {
      console.error('[Step3Photos] save error', e)
      alert(e?.message || 'Failed to save photos')
      return
    }
    nav('/profile/setup/4')
  }
  return (
    <WizardShell step={3}>
      <div className="space-y-4">
        <div className="text-white text-xl font-semibold">Add your photos</div>
        <div className="grid grid-cols-2 gap-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="aspect-[1/1] rounded-xl border border-border-white-10 bg-white/10 flex items-center justify-center overflow-hidden">
              {photos[i] ? (
                <div className="relative w-full h-full">
                  <img src={photos[i]} alt="photo" className="object-cover w-full h-full" />
                  <button onClick={() => remove(i)} className="absolute top-2 right-2 bg-black/60 text-white text-xs px-2 py-1 rounded">Remove</button>
                </div>
              ) : (
                <>
                  <label htmlFor={`file-${i}`} className="cursor-pointer w-full h-full flex items-center justify-center text-white/80 text-sm">
                    {uploadingIndex === i ? 'Uploading…' : 'Add Photo'}
                  </label>
                  <input id={`file-${i}`} type="file" className="hidden" accept="image/*" onChange={(e) => e.target.files && addPhoto(i, e.target.files[0])} />
                </>
              )}
            </div>
          ))}
        </div>
        <div className="flex justify-between pt-4">
          <button onClick={()=>nav('/profile/setup/2')} className="px-6 py-3 rounded-full border border-border-white-10 text-white">Back</button>
          <button onClick={next} className="bg-gradient-cta text-white px-6 py-3 rounded-full font-semibold disabled:opacity-50" disabled={photos.length<1 || uploadingIndex!==null}>{uploadingIndex!==null ? 'Uploading…' : 'Next'}</button>
        </div>
      </div>
    </WizardShell>
  )
}


