import React, { useEffect, useState } from 'react'
import { useAuth } from '../context/AuthContext'
import { createClient } from '@supabase/supabase-js'
import GlassCardPink from '../components/ui/GlassCardPink'
import { ArrowLeft, Download, CheckCircle, XCircle, Clock } from 'lucide-react'
import { useNavigate } from 'react-router-dom'

const supabaseUrl = 'https://dkcitxzvojvecuvacwsp.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw'
const supabase = createClient(supabaseUrl, supabaseAnonKey)

interface PaymentOrder {
  id: string
  order_id: string
  plan_type: string
  amount: number
  status: string
  payment_id?: string
  user_id: string
  user_email: string
  created_at: string
  updated_at: string
}

interface UserSubscription {
  id: string
  user_id: string
  plan_type: string
  start_date: string
  end_date: string
  status: string
  created_at: string
  updated_at: string
}

export default function OrderHistory() {
  const { user } = useAuth()
  const navigate = useNavigate()
  const [orders, setOrders] = useState<PaymentOrder[]>([])
  const [subscriptions, setSubscriptions] = useState<UserSubscription[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (user) {
      fetchOrderHistory()
    }
  }, [user])

  const fetchOrderHistory = async () => {
    try {
      setLoading(true)
      
      // Fetch payment orders
      const { data: ordersData, error: ordersError } = await supabase
        .from('payment_orders')
        .select('*')
        .eq('user_id', user?.id)
        .order('created_at', { ascending: false })

      if (ordersError) {
        console.error('Error fetching orders:', ordersError)
      } else {
        setOrders(ordersData || [])
      }

      // Fetch user subscriptions
      const { data: subscriptionsData, error: subscriptionsError } = await supabase
        .from('user_subscriptions')
        .select('*')
        .eq('user_id', user?.id)
        .order('created_at', { ascending: false })

      if (subscriptionsError) {
        console.error('Error fetching subscriptions:', subscriptionsError)
      } else {
        setSubscriptions(subscriptionsData || [])
      }
    } catch (error) {
      console.error('Error fetching order history:', error)
    } finally {
      setLoading(false)
    }
  }

  const formatPrice = (amount: number) => {
    return `₹${(amount / 100).toFixed(2)}`
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-IN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'success':
        return <CheckCircle className="w-5 h-5 text-green-500" />
      case 'failed':
        return <XCircle className="w-5 h-5 text-red-500" />
      case 'pending':
        return <Clock className="w-5 h-5 text-yellow-500" />
      default:
        return <Clock className="w-5 h-5 text-gray-500" />
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'success':
        return 'text-green-500'
      case 'failed':
        return 'text-red-500'
      case 'pending':
        return 'text-yellow-500'
      default:
        return 'text-gray-500'
    }
  }

  const downloadInvoice = async (order: PaymentOrder) => {
    try {
      console.log('📄 Generating PDF invoice for order:', order.order_id)
      
      // Get user profile data
      const { data: profileData } = await supabase
        .from('profiles')
        .select('name')
        .eq('id', user?.id)
        .single()
      
      const userName = profileData?.name || 'User'
      
      // Get subscription data for expiry date
      const { data: subscriptionData } = await supabase
        .from('user_subscriptions')
        .select('end_date')
        .eq('order_id', order.order_id)
        .single()
      
      // Call Edge Function to generate PDF
      const { data, error } = await supabase.functions.invoke('genreate-invoice-html', {
        body: {
          orderId: order.order_id,
          paymentId: order.payment_id || 'N/A',
          amount: order.amount,
          planType: order.plan_type,
          userEmail: order.user_email,
          userName: userName,
          paymentDate: order.created_at,
          expiryDate: subscriptionData?.end_date || new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
        }
      })
      
      if (error) {
        console.error('❌ PDF generation error:', error)
        alert('Failed to generate PDF invoice. Please try again.')
        return
      }
      
      if (data?.success && data?.htmlBase64) {
        // Convert base64 to HTML and download (handle UTF-8 encoding)
        const htmlData = decodeURIComponent(escape(atob(data.htmlBase64)))
        
        const blob = new Blob([htmlData], { type: 'text/html' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = data.filename || `invoice-${order.order_id}.html`
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
        
        console.log('✅ HTML invoice downloaded successfully')
        alert('Invoice downloaded! You can open it in your browser and print to PDF.')
      } else {
        console.error('❌ Invalid response from invoice generation')
        alert('Failed to generate invoice. Please try again.')
      }
      
    } catch (error) {
      console.error('❌ Error downloading invoice:', error)
      alert('Failed to download invoice. Please try again.')
    }
  }


  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-pink border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-white/70 text-lg">Loading order history...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen">
      {/* Header */}
      <section className="w-full">
        <div className="max-w-[1600px] mx-auto px-4 sm:px-6 md:px-8 xl:px-12 py-12 sm:py-16 md:py-20">
          <button 
            onClick={() => navigate('/profile/edit')}
            className="text-pink-300 hover:text-pink-200 text-sm mb-6 flex items-center gap-2"
          >
            <ArrowLeft className="w-4 h-4" />
            Back to Profile
          </button>
          
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl sm:text-4xl md:text-5xl font-bold text-white">Order History</h1>
              <p className="text-light-white mt-3 max-w-2xl text-sm sm:text-base">View your payment history and subscription details.</p>
            </div>
            <button
              onClick={fetchOrderHistory}
              className="px-4 py-2 bg-pink-600 hover:bg-pink-700 text-white rounded-lg transition-colors"
            >
              Refresh
            </button>
          </div>
        </div>
        <div className="w-full border-t border-border-white-10" />
      </section>

      {/* Current Subscription Status */}
      <section className="w-full">
        <div className="max-w-[1600px] mx-auto px-4 sm:px-6 md:px-8 xl:px-12 py-8 sm:py-12">
          <h2 className="text-2xl font-bold text-white mb-6">Current Subscription</h2>
          
          {subscriptions.length > 0 ? (
            <div className="grid gap-4">
              {subscriptions.map((subscription) => (
                <GlassCardPink key={subscription.id} className="p-6">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="text-xl font-bold text-white">
                        {subscription.plan_type.replace('_', ' ').toUpperCase()} Plan
                      </h3>
                      <p className="text-light-white">
                        {subscription.status === 'active' ? 'Active' : 'Inactive'} • 
                        Valid until {formatDate(subscription.end_date)}
                      </p>
                    </div>
                    <div className="text-right">
                      <div className={`text-lg font-semibold ${subscription.status === 'active' ? 'text-green-500' : 'text-red-500'}`}>
                        {subscription.status === 'active' ? '✓ Active' : '✗ Inactive'}
                      </div>
                    </div>
                  </div>
                </GlassCardPink>
              ))}
            </div>
          ) : (
            <GlassCardPink className="p-6 text-center">
              <p className="text-light-white">No active subscriptions found.</p>
            </GlassCardPink>
          )}
        </div>
        <div className="w-full border-t border-border-white-10" />
      </section>

      {/* Payment History */}
      <section className="w-full">
        <div className="max-w-[1600px] mx-auto px-4 sm:px-6 md:px-8 xl:px-12 py-8 sm:py-12">
          <h2 className="text-2xl font-bold text-white mb-6">Payment History</h2>
          
          {orders.length > 0 ? (
            <div className="grid gap-4">
              {orders.map((order) => (
                <GlassCardPink key={order.id} className="p-6">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                      {getStatusIcon(order.status)}
                      <div>
                        <h3 className="text-lg font-bold text-white">
                          {order.plan_type.replace('_', ' ').toUpperCase()} Plan
                        </h3>
                        <p className="text-light-white">
                          Order ID: {order.order_id} • {formatDate(order.created_at)}
                        </p>
                        {order.payment_id && (
                          <p className="text-sm text-light-white">
                            Payment ID: {order.payment_id}
                          </p>
                        )}
                      </div>
                    </div>
                    <div className="flex items-center gap-4">
                      <div className="text-right">
                        <div className="text-xl font-bold text-white">
                          {formatPrice(order.amount)}
                        </div>
                        <div className={`text-sm font-semibold ${getStatusColor(order.status)}`}>
                          {order.status.toUpperCase()}
                        </div>
                      </div>
                      <button
                        onClick={() => downloadInvoice(order)}
                        className="p-2 text-pink-300 hover:text-pink-200 transition-colors"
                        title="Download Invoice"
                      >
                        <Download className="w-5 h-5" />
                      </button>
                    </div>
                  </div>
                </GlassCardPink>
              ))}
            </div>
          ) : (
            <GlassCardPink className="p-6 text-center">
              <p className="text-light-white">No payment history found.</p>
            </GlassCardPink>
          )}
        </div>
      </section>
    </div>
  )
}
