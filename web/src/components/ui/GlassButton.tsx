import React from 'react'

export default function GlassButton({ children, onClick, className = '' }: { children: React.ReactNode; onClick?: () => void; className?: string }) {
  return (
    <button onClick={onClick} className={`px-3 py-2 rounded bg-white/10 backdrop-blur-sm text-white border border-white/10 ${className}`}>
      {children}
    </button>
  )
}


