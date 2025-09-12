import React from 'react'
import { useParams } from 'react-router-dom'
import StoryViewer from '../components/StoryViewer'

export default function StoryDetail() {
  const { id } = useParams()
  if (!id) return null
  return <StoryViewer storyId={id} />
}


