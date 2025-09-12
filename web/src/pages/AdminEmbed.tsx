import React from 'react'

export default function AdminEmbed() {
  const src = '/admin/index.html#/admin'
  return (
    <div className="min-h-screen -mx-8 -mt-4">
      <iframe title="Admin Dashboard" src={src} className="w-[100vw] h-[calc(100vh-64px)] border-0" />
    </div>
  )
}


