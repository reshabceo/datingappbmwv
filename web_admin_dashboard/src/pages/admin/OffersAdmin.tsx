import React, { useState, useEffect } from 'react'
import { supabase } from '../../supabaseClient'

interface Offer {
  id: string
  name: string
  description: string | null
  offer_type: 'percentage' | 'fixed_amount' | 'free'
  discount_value: number
  reason: string
  target_audience: 'all' | 'women' | 'men' | 'new_users' | 'existing_users'
  applicable_plans: string[]
  applicable_durations: number[]
  start_date: string
  end_date: string | null
  is_active: boolean
  max_uses: number | null
  current_uses: number
  created_at: string
  updated_at: string
}

interface OfferApplication {
  id: string
  offer_id: string
  user_id: string
  plan_id: string
  pricing_option_id: string
  original_price: number
  discounted_price: number
  discount_amount: number
  applied_at: string
}

export default function OffersAdmin() {
  const [offers, setOffers] = useState<Offer[]>([])
  const [applications, setApplications] = useState<OfferApplication[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [editingOffer, setEditingOffer] = useState<Offer | null>(null)
  const [showAddOffer, setShowAddOffer] = useState(false)
  const [activeTab, setActiveTab] = useState<'offers' | 'applications'>('offers')

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    try {
      setLoading(true)
      setError(null)

      // Fetch offers
      const { data: offersData, error: offersError } = await supabase
        .from('offers')
        .select('*')
        .order('created_at', { ascending: false })

      if (offersError) throw offersError

      // Fetch applications
      const { data: applicationsData, error: applicationsError } = await supabase
        .from('offer_applications')
        .select('*')
        .order('applied_at', { ascending: false })

      if (applicationsError) throw applicationsError

      setOffers(offersData || [])
      setApplications(applicationsData || [])
    } catch (err) {
      console.error('Error fetching data:', err)
      setError('Failed to load offers and applications')
    } finally {
      setLoading(false)
    }
  }

  const handleSaveOffer = async (offer: Partial<Offer>) => {
    try {
      if (editingOffer) {
        // Update existing offer
        const { error } = await supabase
          .from('offers')
          .update({
            ...offer,
            updated_at: new Date().toISOString()
          })
          .eq('id', editingOffer.id)

        if (error) throw error
      } else {
        // Create new offer
        const { error } = await supabase
          .from('offers')
          .insert([{
            ...offer,
            id: crypto.randomUUID(),
            current_uses: 0,
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          }])

        if (error) throw error
      }

      setEditingOffer(null)
      setShowAddOffer(false)
      await fetchData()
    } catch (err) {
      console.error('Error saving offer:', err)
      setError('Failed to save offer')
    }
  }

  const handleDeleteOffer = async (offerId: string) => {
    if (!confirm('Are you sure you want to delete this offer? This will also delete all applications.')) return

    try {
      const { error } = await supabase
        .from('offers')
        .delete()
        .eq('id', offerId)

      if (error) throw error

      await fetchData()
    } catch (err) {
      console.error('Error deleting offer:', err)
      setError('Failed to delete offer')
    }
  }

  const toggleOfferStatus = async (offerId: string, isActive: boolean) => {
    try {
      const { error } = await supabase
        .from('offers')
        .update({ 
          is_active: !isActive,
          updated_at: new Date().toISOString()
        })
        .eq('id', offerId)

      if (error) throw error

      await fetchData()
    } catch (err) {
      console.error('Error toggling offer status:', err)
      setError('Failed to update offer status')
    }
  }

  const formatPrice = (price: number) => {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(price)
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-IN', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-appbar-1 to-appbar-2 text-white p-8">
        <div className="max-w-6xl mx-auto">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-white mx-auto"></div>
            <p className="mt-4">Loading offers...</p>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-appbar-1 to-appbar-2 text-white p-8">
      <div className="max-w-6xl mx-auto">
        <div className="mb-8">
          <h1 className="text-4xl font-bold mb-4">Offers & Promotions Management</h1>
          <p className="text-light-white">Manage special offers and track their usage</p>
        </div>

        {error && (
          <div className="bg-red-500/20 border border-red-500 rounded-lg p-4 mb-6">
            <p className="text-red-200">{error}</p>
          </div>
        )}

        {/* Tabs */}
        <div className="flex gap-4 mb-6">
          <button
            onClick={() => setActiveTab('offers')}
            className={`px-6 py-3 rounded-full font-semibold transition-all ${
              activeTab === 'offers'
                ? 'bg-gradient-cta text-white'
                : 'bg-white/10 text-light-white hover:bg-white/20'
            }`}
          >
            Offers ({offers.length})
          </button>
          <button
            onClick={() => setActiveTab('applications')}
            className={`px-6 py-3 rounded-full font-semibold transition-all ${
              activeTab === 'applications'
                ? 'bg-gradient-cta text-white'
                : 'bg-white/10 text-light-white hover:bg-white/20'
            }`}
          >
            Applications ({applications.length})
          </button>
        </div>

        {/* Offers Tab */}
        {activeTab === 'offers' && (
          <div className="bg-white/5 border border-border-white-10 rounded-xl p-6">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-2xl font-bold">Active Offers</h2>
              <button
                onClick={() => setShowAddOffer(true)}
                className="px-6 py-3 bg-gradient-cta text-white font-semibold rounded-full hover:shadow-lg transform hover:scale-105 transition-all duration-200"
              >
                Create New Offer
              </button>
            </div>

            <div className="space-y-4">
              {offers.map((offer) => (
                <div key={offer.id} className="bg-white/5 border border-border-white-10 rounded-lg p-4">
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <h3 className="text-xl font-semibold">{offer.name}</h3>
                        <span className={`px-2 py-1 rounded text-sm ${
                          offer.is_active ? 'bg-green-500/20 text-green-300' : 'bg-red-500/20 text-red-300'
                        }`}>
                          {offer.is_active ? 'Active' : 'Inactive'}
                        </span>
                        <span className="px-2 py-1 rounded text-sm bg-blue-500/20 text-blue-300">
                          {offer.offer_type.replace('_', ' ').toUpperCase()}
                        </span>
                      </div>
                      
                      {offer.description && (
                        <p className="text-light-white mb-2">{offer.description}</p>
                      )}
                      
                      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                        <div>
                          <span className="font-medium">Discount:</span>
                          <br />
                          {offer.offer_type === 'percentage' && `${offer.discount_value}%`}
                          {offer.offer_type === 'fixed_amount' && formatPrice(offer.discount_value)}
                          {offer.offer_type === 'free' && '100% FREE'}
                        </div>
                        <div>
                          <span className="font-medium">Target:</span>
                          <br />
                          {offer.target_audience.replace('_', ' ').toUpperCase()}
                        </div>
                        <div>
                          <span className="font-medium">Reason:</span>
                          <br />
                          {offer.reason}
                        </div>
                        <div>
                          <span className="font-medium">Uses:</span>
                          <br />
                          {offer.current_uses} / {offer.max_uses || '∞'}
                        </div>
                      </div>
                      
                      <div className="mt-2 text-sm text-light-white">
                        <span className="font-medium">Valid:</span> {formatDate(offer.start_date)}
                        {offer.end_date && ` - ${formatDate(offer.end_date)}`}
                      </div>
                    </div>
                    
                    <div className="flex gap-2 ml-4">
                      <button
                        onClick={() => setEditingOffer(offer)}
                        className="px-4 py-2 bg-blue-500/20 text-blue-300 rounded-lg hover:bg-blue-500/30 transition-colors"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => toggleOfferStatus(offer.id, offer.is_active)}
                        className={`px-4 py-2 rounded-lg transition-colors ${
                          offer.is_active
                            ? 'bg-yellow-500/20 text-yellow-300 hover:bg-yellow-500/30'
                            : 'bg-green-500/20 text-green-300 hover:bg-green-500/30'
                        }`}
                      >
                        {offer.is_active ? 'Deactivate' : 'Activate'}
                      </button>
                      <button
                        onClick={() => handleDeleteOffer(offer.id)}
                        className="px-4 py-2 bg-red-500/20 text-red-300 rounded-lg hover:bg-red-500/30 transition-colors"
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Applications Tab */}
        {activeTab === 'applications' && (
          <div className="bg-white/5 border border-border-white-10 rounded-xl p-6">
            <h2 className="text-2xl font-bold mb-6">Offer Applications</h2>
            
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-border-white-10">
                    <th className="text-left py-3 px-4">User ID</th>
                    <th className="text-left py-3 px-4">Offer</th>
                    <th className="text-left py-3 px-4">Original Price</th>
                    <th className="text-left py-3 px-4">Discounted Price</th>
                    <th className="text-left py-3 px-4">Savings</th>
                    <th className="text-left py-3 px-4">Applied At</th>
                  </tr>
                </thead>
                <tbody>
                  {applications.map((app) => {
                    const offer = offers.find(o => o.id === app.offer_id)
                    return (
                      <tr key={app.id} className="border-b border-border-white-10/50">
                        <td className="py-3 px-4 font-mono text-xs">{app.user_id.slice(0, 8)}...</td>
                        <td className="py-3 px-4">{offer?.name || 'Unknown Offer'}</td>
                        <td className="py-3 px-4">{formatPrice(app.original_price)}</td>
                        <td className="py-3 px-4">{formatPrice(app.discounted_price)}</td>
                        <td className="py-3 px-4 text-green-300">{formatPrice(app.discount_amount)}</td>
                        <td className="py-3 px-4">{formatDate(app.applied_at)}</td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* Add/Edit Offer Modal */}
        {(showAddOffer || editingOffer) && (
          <OfferModal
            offer={editingOffer}
            onSave={handleSaveOffer}
            onClose={() => {
              setEditingOffer(null)
              setShowAddOffer(false)
            }}
          />
        )}
      </div>
    </div>
  )
}

// Offer Modal Component
function OfferModal({ offer, onSave, onClose }: {
  offer: Offer | null
  onSave: (offer: Partial<Offer>) => void
  onClose: () => void
}) {
  const [formData, setFormData] = useState({
    name: offer?.name || '',
    description: offer?.description || '',
    offer_type: offer?.offer_type || 'percentage' as const,
    discount_value: offer?.discount_value || 0,
    reason: offer?.reason || '',
    target_audience: offer?.target_audience || 'all' as const,
    applicable_plans: offer?.applicable_plans || [],
    applicable_durations: offer?.applicable_durations || [],
    start_date: offer?.start_date ? offer.start_date.split('T')[0] : '',
    end_date: offer?.end_date ? offer.end_date.split('T')[0] : '',
    is_active: offer?.is_active ?? true,
    max_uses: offer?.max_uses || null
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    
    const submitData = {
      ...formData,
      start_date: new Date(formData.start_date).toISOString(),
      end_date: formData.end_date ? new Date(formData.end_date).toISOString() : null,
      max_uses: formData.max_uses || null
    }
    
    onSave(submitData)
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white/10 backdrop-blur-md border border-border-white-10 rounded-xl p-6 w-full max-w-2xl mx-4 max-h-[90vh] overflow-y-auto">
        <h2 className="text-2xl font-bold mb-6">
          {offer ? 'Edit Offer' : 'Create New Offer'}
        </h2>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Offer Name</label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-pink-500"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Reason</label>
              <input
                type="text"
                value={formData.reason}
                onChange={(e) => setFormData(prev => ({ ...prev, reason: e.target.value }))}
                className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-pink-500"
                placeholder="e.g., Pre-launch, Women's special"
                required
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">Description</label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
              className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-pink-500"
              rows={3}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Offer Type</label>
              <select
                value={formData.offer_type}
                onChange={(e) => setFormData(prev => ({ ...prev, offer_type: e.target.value as any }))}
                className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-pink-500"
              >
                <option value="percentage">Percentage Discount</option>
                <option value="fixed_amount">Fixed Amount Discount</option>
                <option value="free">Free (100% off)</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">
                {formData.offer_type === 'percentage' ? 'Discount %' : 
                 formData.offer_type === 'fixed_amount' ? 'Discount Amount (₹)' : 'Value'}
              </label>
              <input
                type="number"
                value={formData.discount_value}
                onChange={(e) => setFormData(prev => ({ ...prev, discount_value: parseFloat(e.target.value) || 0 }))}
                className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-pink-500"
                max={formData.offer_type === 'percentage' ? 100 : undefined}
                required
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Target Audience</label>
              <select
                value={formData.target_audience}
                onChange={(e) => setFormData(prev => ({ ...prev, target_audience: e.target.value as any }))}
                className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-pink-500"
              >
                <option value="all">All Users</option>
                <option value="women">Women Only</option>
                <option value="men">Men Only</option>
                <option value="new_users">New Users Only</option>
                <option value="existing_users">Existing Users Only</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Max Uses (Optional)</label>
              <input
                type="number"
                value={formData.max_uses || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, max_uses: e.target.value ? parseInt(e.target.value) : null }))}
                className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-pink-500"
                placeholder="Leave empty for unlimited"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Start Date</label>
              <input
                type="date"
                value={formData.start_date}
                onChange={(e) => setFormData(prev => ({ ...prev, start_date: e.target.value }))}
                className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-pink-500"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">End Date (Optional)</label>
              <input
                type="date"
                value={formData.end_date}
                onChange={(e) => setFormData(prev => ({ ...prev, end_date: e.target.value }))}
                className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-pink-500"
              />
            </div>
          </div>

          <div className="flex items-center">
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={formData.is_active}
                onChange={(e) => setFormData(prev => ({ ...prev, is_active: e.target.checked }))}
                className="w-4 h-4 text-pink-500 bg-white/10 border-border-white-10 rounded focus:ring-pink-500"
              />
              <span className="text-sm">Active</span>
            </label>
          </div>

          <div className="flex gap-4 pt-4">
            <button
              type="submit"
              className="px-6 py-3 bg-gradient-cta text-white font-semibold rounded-full hover:shadow-lg transform hover:scale-105 transition-all duration-200"
            >
              {offer ? 'Update Offer' : 'Create Offer'}
            </button>
            <button
              type="button"
              onClick={onClose}
              className="px-6 py-3 bg-white/10 text-white rounded-full hover:bg-white/20 transition-colors"
            >
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
