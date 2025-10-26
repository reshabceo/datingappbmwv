import React from 'react'

type Props = {
  className?: string
  children: React.ReactNode
}

export default function GlassCardPink({ className = '', children }: Props) {
  return (
    <div className={`rounded-2xl p-6 bg-gradient-card-pink border border-pink-30 backdrop-blur-md shadow-card-soft ${className}`}>
      {children}
    </div>
  )
}


