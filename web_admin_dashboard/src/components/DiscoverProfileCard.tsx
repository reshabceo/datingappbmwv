import React from 'react'
import { Link } from 'react-router-dom'

type Profile = {
  id: string
  name?: string | null
  age?: number | null
  image_urls?: string[] | null
  photos?: string[] | null
  location?: string | null
  is_active?: boolean | null
  last_seen?: string | null
  description?: string | null
  hobbies?: string[] | null
}

export default function DiscoverProfileCard({ profile }: { profile: Profile }) {
  const {
    id,
    name,
    age,
    image_urls,
    photos,
    location,
    is_active,
    last_seen,
    description,
    hobbies,
  } = profile

  const gallery: string[] = (image_urls && image_urls.length ? image_urls : (photos || [])) as string[]
  const mainPhoto = gallery?.[0]
  const avatarUrl = mainPhoto
  const count = gallery?.length || 0
  const isVerified = Boolean(is_active)
  const activeNow = (() => {
    if (!last_seen) return false
    const last = new Date(last_seen).getTime()
    return Date.now() - last < 5 * 60 * 1000
  })()
  const chips = Array.isArray(hobbies) ? hobbies.slice(0, 6) : []
  const visibleChips = chips.slice(0, 3)
  const extraCount = Math.max(0, chips.length - visibleChips.length)

  return (
    <Link to={`/profile/${id}`} className="block">
      <div className="relative rounded-[20px] p-1 bg-gradient-card-pink border border-pink-30 backdrop-blur-md shadow-card-soft">
        <div className="rounded-[18px] overflow-hidden bg-black/40">
          <div className="relative aspect-[3/4]">
            {mainPhoto ? (
              <img src={mainPhoto} alt={name || 'profile'} className="absolute inset-0 w-full h-full object-cover" />
            ) : (
              <div className="absolute inset-0 w-full h-full flex items-center justify-center text-white/70">No image</div>
            )}

            {/* Top-left avatar (compact) */}
            <div className="absolute top-3 left-3">
              <div className="p-0.5 rounded-full bg-gradient-cta">
                <div className="w-12 h-12 rounded-full overflow-hidden border border-white/70">
                  {avatarUrl ? (
                    <img src={avatarUrl} alt="avatar" className="w-full h-full object-cover" />
                  ) : (
                    <div className="w-full h-full bg-white/20" />
                  )}
                </div>
              </div>
            </div>

            {/* Top-right photo count (compact) */}
            {count > 0 && (
              <div className="absolute top-3 right-3 px-2.5 py-0.5 rounded-full bg-black/60 text-white text-[11px] flex items-center gap-1 border border-pink-30">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-white"><rect x="3" y="3" width="18" height="14" rx="2"/><circle cx="9" cy="10" r="2"/></svg>
                <span>{count}</span>
              </div>
            )}

            {/* Bottom glass overlay - exactly bottom quarter height like app */}
            <div className="absolute inset-x-0 bottom-0 h-[25%]">
              <div className="absolute inset-0 bg-gradient-to-b from-transparent via-white/50 to-white/95 backdrop-blur-[2px]" />
              <div className="relative h-full px-4 pb-4 flex flex-col justify-end text-black/85">
                  {/* Location */}
                  {location && (
                    <div className="flex items-center gap-2 mb-2">
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-black/70"><path d="M21 10c0 7-9 12-9 12s-9-5-9-12a9 9 0 1 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>
                      <span className="text-sm leading-none">{location}</span>
                    </div>
                  )}

                  {/* Status chips */}
                  <div className="flex items-center gap-2 mb-2">
                    {isVerified && (
                      <span className="px-2.5 py-1 rounded-full text-[11px] border border-pink-30 text-pink bg-pink/20">
                        <span className="inline-flex items-center gap-1">
                          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-pink"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="M9 12l2 2 4-4"/></svg>
                          Verified
                        </span>
                      </span>
                    )}
                    {activeNow && (
                      <span className="px-2.5 py-1 rounded-full text-[11px] border border-pink-30 text-pink bg-pink/20">
                        <span className="inline-flex items-center gap-1">
                          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="text-pink"><path d="M13 3a9 9 0 1 0 8 8c0-4.97-8-8-8-8z"/></svg>
                          Active Now
                        </span>
                      </span>
                    )}
                  </div>

                  {/* Description */}
                  {description && (
                    <div className="mb-2">
                      <div className="px-3 py-2 rounded-[10px] border border-pink-30 bg-white/70 text-black/85 text-sm line-clamp-2">{description}</div>
                    </div>
                  )}

                  {/* Hobbies one-line with +N */}
                  {visibleChips.length > 0 && (
                    <div className="flex items-center gap-2 overflow-hidden">
                      {visibleChips.map((c) => (
                        <span key={c} className="px-2.5 py-1 rounded-full border border-pink-30 bg-white/60 text-[11px] text-black/85 whitespace-nowrap">{c}</span>
                      ))}
                      {extraCount > 0 && (
                        <span className="px-2.5 py-1 rounded-full border border-pink-30 bg-white/60 text-[11px] text-black/85">+{extraCount}</span>
                      )}
                    </div>
                  )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </Link>
  )
}


