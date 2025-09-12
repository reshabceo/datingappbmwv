import React from 'react'

export default function Button({ children, onClick, className = '', type = 'button' }: { children: React.ReactNode; onClick?: () => void; className?: string; type?: 'button' | 'submit' }) {
  return (
    <button type={type} onClick={onClick} className={`px-4 py-2 rounded bg-accent text-white hover:opacity-95 ${className}`}>
      {children}
    </button>
  )
}


