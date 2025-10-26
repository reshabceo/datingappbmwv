import React, { useEffect, useState } from 'react'
import { createClient } from '@supabase/supabase-js'
import { Crown, CheckCircle, Calendar, Download } from 'lucide-react'
import { useNavigate } from 'react-router-dom'

const supabaseUrl = 'https://dkcitxzvojvecuvacwsp.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw'
const supabase = createClient(supabaseUrl, supabaseAnonKey)

interface SubscriptionStatus {
  isActive: boolean
  planType: string
  endDate: string
  daysRemaining: number
}

export default function PremiumStatusWidget() {
  const [subscription, setSubscription] = useState<SubscriptionStatus | null>(null)
  const [loading, setLoading] = useState(true)
  const navigate = useNavigate()

  useEffect(() => {
    checkSubscriptionStatus()
  }, [])

  const checkSubscriptionStatus = async () => {
    try {
      setLoading(true)
      
      // Check if user has premium status
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) return

      const { data: profile } = await supabase
        .from('profiles')
        .select('is_premium, premium_until')
        .eq('id', user.id)
        .single()

      if (profile?.is_premium && profile?.premium_until) {
        const endDate = new Date(profile.premium_until)
        const now = new Date()
        const daysRemaining = Math.ceil((endDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
        
        setSubscription({
          isActive: true,
          planType: 'Premium',
          endDate: profile.premium_until,
          daysRemaining: Math.max(0, daysRemaining)
        })
      }
    } catch (error) {
      console.error('Error checking subscription status:', error)
    } finally {
      setLoading(false)
    }
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-IN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })
  }

  if (loading) {
    return null
  }

  if (!subscription?.isActive) {
    return null
  }

  return (
    <div className="bg-gradient-to-r from-pink-500/20 to-purple-500/20 border border-pink-400/30 rounded-xl p-4 mb-6">
      <div className="flex items-center gap-3 mb-3">
        <div className="w-8 h-8 bg-gradient-to-r from-pink to-purple rounded-full flex items-center justify-center">
          <Crown className="w-4 h-4 text-white" />
        </div>
        <div>
          <h3 className="text-lg font-bold text-white">Premium Active</h3>
          <p className="text-sm text-pink-200">
            {subscription.daysRemaining > 0 
              ? `${subscription.daysRemaining} days remaining`
              : 'Expires today'
            }
          </p>
        </div>
      </div>
      
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2 text-sm text-pink-200">
          <Calendar className="w-4 h-4" />
          <span>Valid until {formatDate(subscription.endDate)}</span>
        </div>
        
        <div className="flex items-center gap-2">
          <button
            onClick={() => navigate('/order-history')}
            className="text-pink-300 hover:text-pink-200 text-sm flex items-center gap-1"
          >
            <Download className="w-4 h-4" />
            View Orders
          </button>
        </div>
      </div>
      
      {/* Premium Features List */}
      <div className="mt-4 grid grid-cols-2 gap-2 text-sm">
        <div className="flex items-center gap-2 text-green-300">
          <CheckCircle className="w-4 h-4" />
          <span>See who liked you</span>
        </div>
        <div className="flex items-center gap-2 text-green-300">
          <CheckCircle className="w-4 h-4" />
          <span>Priority visibility</span>
        </div>
        <div className="flex items-center gap-2 text-green-300">
          <CheckCircle className="w-4 h-4" />
          <span>Advanced filters</span>
        </div>
        <div className="flex items-center gap-2 text-green-300">
          <CheckCircle className="w-4 h-4" />
          <span>Unlimited matches</span>
        </div>
      </div>
    </div>
  )
}
