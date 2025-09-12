import React, { useEffect, useState } from 'react'
import { supabase } from '../supabaseClient'
import { useAuth } from '../context/AuthContext'
import api from '../services/api'

export default function StoryViewer({ storyId }: { storyId: string }) {
  const [stories, setStories] = useState<any[]>([])
  const [index, setIndex] = useState<number | null>(null)
  const [reply, setReply] = useState('')
  const [sending, setSending] = useState(false)
  const { user } = useAuth()
  const [progress, setProgress] = useState(0)

  useEffect(() => {
    let mounted = true
    const load = async () => {
      const rows = await api.fetchStories()
      if (!mounted) return
      setStories(rows || [])
      const idx = rows.findIndex((r: any) => r.id === storyId)
      setIndex(idx >= 0 ? idx : 0)
    }
    load()
    return () => { mounted = false }
  }, [storyId])

  useEffect(() => {
    if (index === null) return
    setProgress(0)
    const interval = setInterval(() => {
      setProgress((p) => {
        if (p >= 100) return 100
        return p + 2
      })
    }, 100)
    return () => clearInterval(interval)
  }, [index])

  useEffect(() => {
    if (progress >= 100 && index !== null) {
      // advance
      const next = index + 1
      if (next < stories.length) {
        const id = stories[next].id
        window.history.pushState({}, '', `/story/${id}`)
        setIndex(next)
        setProgress(0)
      } else {
        // close viewer
        window.history.back()
      }
    }
  }, [progress, index, stories])

  if (index === null || stories.length === 0) return <div>Loading story...</div>
  const story = stories[index]

  const close = () => window.history.back()

  const prev = () => {
    if (index > 0) {
      const id = stories[index - 1].id
      window.history.pushState({}, '', `/story/${id}`)
      setIndex(index - 1)
      setProgress(0)
    }
  }

  const next = () => {
    if (index + 1 < stories.length) {
      const id = stories[index + 1].id
      window.history.pushState({}, '', `/story/${id}`)
      setIndex(index + 1)
      setProgress(0)
    } else {
      close()
    }
  }

  const sendReply = async () => {
    if (!user) return alert('Sign in to reply')
    if (!reply.trim()) return
    setSending(true)
    try {
      const matchId = await api.findMatchIdBetween(user.id, story.user_id)
      if (!matchId) return alert('No match exists between you and this user')
      await api.sendMessage(matchId, user.id, reply.trim(), story.id, story.profiles?.name)
      setReply('')
      alert('Reply sent')
    } catch (e: any) {
      console.error(e)
      alert('Failed to send reply')
    } finally {
      setSending(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-4">
      <div className="bg-black rounded max-w-3xl w-full overflow-hidden relative">
        <button onClick={close} className="absolute top-2 right-2 z-20 bg-white/10 text-white px-3 py-1 rounded">Close</button>
        <div className="relative" style={{ height: 384 }}>
          <img src={story.media_url} alt="story" className="w-full h-full object-contain bg-black" />
          <div className="absolute top-2 left-2 right-2 flex gap-2">
            {stories.map((s, i) => (
              <div key={s.id} className="h-2 bg-gray-600 rounded" style={{ flex: 1, width: 0 }}>
                <div className="h-2 bg-accent rounded" style={{ width: `${i < index ? 100 : i === index ? progress : 0}%`, height: '100%' }} />
              </div>
            ))}
          </div>
          <div className="absolute inset-0 flex">
            <div className="flex-1" onClick={prev} />
            <div className="flex-1" onClick={next} />
          </div>
        </div>
        <div className="p-3 bg-black">
          <div className="text-white font-semibold">{story.profiles?.name}</div>
          <div className="text-sm text-gray-300 mt-2">{story.content}</div>

          <div className="mt-3 flex gap-2">
            <input value={reply} onChange={(e) => setReply(e.target.value)} className="flex-1 px-3 py-2 rounded bg-white/5 text-white" placeholder="Reply to story..." />
            <button onClick={sendReply} disabled={sending} className="px-4 py-2 bg-accent rounded text-white">Send</button>
          </div>
        </div>
      </div>
    </div>
  )
}


