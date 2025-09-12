import React from 'react'

export default function ProfileAvatar({ src, size = 48 }: { src?: string; size?: number }) {
  return (
    <div style={{ width: size, height: size }} className="rounded-full overflow-hidden bg-gray-200">
      {src ? <img src={src} alt="avatar" className="w-full h-full object-cover" /> : <div className="w-full h-full flex items-center justify-center text-gray-400">No</div>}
    </div>
  )
}


