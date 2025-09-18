import React, { useState, useEffect } from 'react'
import { supabase } from '../../supabaseClient'

interface SubscriptionPlan {
  id: string
  name: string
  description: string
  price_monthly: number
  price_yearly: number
  features: string[]
  is_active: boolean
  sort_order: number
  created_at: string
  updated_at: string
}

interface PricingOption {
  id: string
  plan_id: string
  duration_months: number
  price: number
  original_price: number | null
  discount_percentage: number | null
  is_popular: boolean
  created_at: string
  updated_at: string
}

export default function SubscriptionPlansAdmin() {
  const [plans, setPlans] = useState<SubscriptionPlan[]>([])
  const [pricingOptions, setPricingOptions] = useState<PricingOption[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [editingPlan, setEditingPlan] = useState<SubscriptionPlan | null>(null)
  const [editingPricing, setEditingPricing] = useState<PricingOption | null>(null)
  const [showAddPlan, setShowAddPlan] = useState(false)
  const [showAddPricing, setShowAddPricing] = useState(false)

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    try {
      setLoading(true)
      setError(null)

      // Fetch plans
      const { data: plansData, error: plansError } = await supabase
        .from('subscription_plans')
        .select('*')
        .order('sort_order')

      if (plansError) throw plansError

      // Fetch pricing options
      const { data: pricingData, error: pricingError } = await supabase
        .from('pricing_options')
        .select('*')
        .order('plan_id, duration_months')

      if (pricingError) throw pricingError

      setPlans(plansData || [])
      setPricingOptions(pricingData || [])
    } catch (err) {
      console.error('Error fetching data:', err)
      setError('Failed to load subscription plans')
    } finally {
      setLoading(false)
    }
  }

  const handleSavePlan = async (plan: Partial<SubscriptionPlan>) => {
    try {
      if (editingPlan) {
        // Update existing plan
        const { error } = await supabase
          .from('subscription_plans')
          .update({
            ...plan,
            updated_at: new Date().toISOString()
          })
          .eq('id', editingPlan.id)

        if (error) throw error
      } else {
        // Create new plan
        const { error } = await supabase
          .from('subscription_plans')
          .insert([{
            ...plan,
            id: crypto.randomUUID(),
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          }])

        if (error) throw error
      }

      setEditingPlan(null)
      setShowAddPlan(false)
      await fetchData()
    } catch (err) {
      console.error('Error saving plan:', err)
      setError('Failed to save plan')
    }
  }

  const handleSavePricing = async (pricing: Partial<PricingOption>) => {
    try {
      if (editingPricing) {
        // Update existing pricing
        const { error } = await supabase
          .from('pricing_options')
          .update({
            ...pricing,
            updated_at: new Date().toISOString()
          })
          .eq('id', editingPricing.id)

        if (error) throw error
      } else {
        // Create new pricing
        const { error } = await supabase
          .from('pricing_options')
          .insert([{
            ...pricing,
            id: crypto.randomUUID(),
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          }])

        if (error) throw error
      }

      setEditingPricing(null)
      setShowAddPricing(false)
      await fetchData()
    } catch (err) {
      console.error('Error saving pricing:', err)
      setError('Failed to save pricing option')
    }
  }

  const handleDeletePlan = async (planId: string) => {
    if (!confirm('Are you sure you want to delete this plan? This will also delete all pricing options.')) return

    try {
      const { error } = await supabase
        .from('subscription_plans')
        .delete()
        .eq('id', planId)

      if (error) throw error

      await fetchData()
    } catch (err) {
      console.error('Error deleting plan:', err)
      setError('Failed to delete plan')
    }
  }

  const handleDeletePricing = async (pricingId: string) => {
    if (!confirm('Are you sure you want to delete this pricing option?')) return

    try {
      const { error } = await supabase
        .from('pricing_options')
        .delete()
        .eq('id', pricingId)

      if (error) throw error

      await fetchData()
    } catch (err) {
      console.error('Error deleting pricing:', err)
      setError('Failed to delete pricing option')
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

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-appbar-1 to-appbar-2 text-white p-8">
        <div className="max-w-6xl mx-auto">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-white mx-auto"></div>
            <p className="mt-4">Loading subscription plans...</p>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-appbar-1 to-appbar-2 text-white p-8">
      <div className="max-w-6xl mx-auto">
        <div className="mb-8">
          <h1 className="text-4xl font-bold mb-4">Subscription Plans Management</h1>
          <p className="text-light-white">Manage subscription plans and pricing options</p>
        </div>

        {error && (
          <div className="bg-red-500/20 border border-red-500 rounded-lg p-4 mb-6">
            <p className="text-red-200">{error}</p>
          </div>
        )}

        {/* Plans Section */}
        <div className="bg-white/5 border border-border-white-10 rounded-xl p-6 mb-8">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-2xl font-bold">Subscription Plans</h2>
            <button
              onClick={() => setShowAddPlan(true)}
              className="px-6 py-3 bg-gradient-cta text-white font-semibold rounded-full hover:shadow-lg transform hover:scale-105 transition-all duration-200"
            >
              Add New Plan
            </button>
          </div>

          <div className="space-y-4">
            {plans.map((plan) => (
              <div key={plan.id} className="bg-white/5 border border-border-white-10 rounded-lg p-4">
                <div className="flex justify-between items-start">
                  <div className="flex-1">
                    <h3 className="text-xl font-semibold mb-2">{plan.name}</h3>
                    <p className="text-light-white mb-2">{plan.description}</p>
                    <div className="flex gap-4 text-sm">
                      <span>Monthly: {formatPrice(plan.price_monthly)}</span>
                      <span>Yearly: {formatPrice(plan.price_yearly)}</span>
                      <span className={`px-2 py-1 rounded ${plan.is_active ? 'bg-green-500/20 text-green-300' : 'bg-red-500/20 text-red-300'}`}>
                        {plan.is_active ? 'Active' : 'Inactive'}
                      </span>
                    </div>
                    <div className="mt-2">
                      <h4 className="font-semibold mb-1">Features:</h4>
                      <ul className="text-sm text-light-white">
                        {plan.features.map((feature, index) => (
                          <li key={index}>• {feature}</li>
                        ))}
                      </ul>
                    </div>
                  </div>
                  <div className="flex gap-2 ml-4">
                    <button
                      onClick={() => setEditingPlan(plan)}
                      className="px-4 py-2 bg-blue-500/20 text-blue-300 rounded-lg hover:bg-blue-500/30 transition-colors"
                    >
                      Edit
                    </button>
                    <button
                      onClick={() => handleDeletePlan(plan.id)}
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

        {/* Pricing Options Section */}
        <div className="bg-white/5 border border-border-white-10 rounded-xl p-6">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-2xl font-bold">Pricing Options</h2>
            <button
              onClick={() => setShowAddPricing(true)}
              className="px-6 py-3 bg-gradient-cta text-white font-semibold rounded-full hover:shadow-lg transform hover:scale-105 transition-all duration-200"
            >
              Add New Pricing
            </button>
          </div>

          <div className="space-y-4">
            {pricingOptions.map((pricing) => {
              const plan = plans.find(p => p.id === pricing.plan_id)
              return (
                <div key={pricing.id} className="bg-white/5 border border-border-white-10 rounded-lg p-4">
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <h3 className="text-lg font-semibold mb-1">
                        {plan?.name} - {pricing.duration_months} Month{pricing.duration_months > 1 ? 's' : ''}
                      </h3>
                      <div className="flex gap-4 text-sm">
                        <span>Price: {formatPrice(pricing.price)}</span>
                        {pricing.original_price && (
                          <span>Original: {formatPrice(pricing.original_price)}</span>
                        )}
                        {pricing.discount_percentage && (
                          <span className="text-green-300">
                            {pricing.discount_percentage}% OFF
                          </span>
                        )}
                        {pricing.is_popular && (
                          <span className="text-yellow-300">⭐ Most Popular</span>
                        )}
                      </div>
                    </div>
                    <div className="flex gap-2 ml-4">
                      <button
                        onClick={() => setEditingPricing(pricing)}
                        className="px-4 py-2 bg-blue-500/20 text-blue-300 rounded-lg hover:bg-blue-500/30 transition-colors"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => handleDeletePricing(pricing.id)}
                        className="px-4 py-2 bg-red-500/20 text-red-300 rounded-lg hover:bg-red-500/30 transition-colors"
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        </div>

        {/* Add/Edit Plan Modal */}
        {(showAddPlan || editingPlan) && (
          <PlanModal
            plan={editingPlan}
            onSave={handleSavePlan}
            onClose={() => {
              setEditingPlan(null)
              setShowAddPlan(false)
            }}
          />
        )}

        {/* Add/Edit Pricing Modal */}
        {(showAddPricing || editingPricing) && (
          <PricingModal
            pricing={editingPricing}
            plans={plans}
            onSave={handleSavePricing}
            onClose={() => {
              setEditingPricing(null)
              setShowAddPricing(false)
            }}
          />
        )}
      </div>
    </div>
  )
}

// Plan Modal Component
function PlanModal({ plan, onSave, onClose }: {
  plan: SubscriptionPlan | null
  onSave: (plan: Partial<SubscriptionPlan>) => void
  onClose: () => void
}) {
  const [formData, setFormData] = useState({
    name: plan?.name || '',
    description: plan?.description || '',
    price_monthly: plan?.price_monthly || 0,
    price_yearly: plan?.price_yearly || 0,
    features: plan?.features || [],
    is_active: plan?.is_active ?? true,
    sort_order: plan?.sort_order || 0
  })

  const [newFeature, setNewFeature] = useState('')

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    onSave(formData)
  }

  const addFeature = () => {
    if (newFeature.trim()) {
      setFormData(prev => ({
        ...prev,
        features: [...prev.features, newFeature.trim()]
      }))
      setNewFeature('')
    }
  }

  const removeFeature = (index: number) => {
    setFormData(prev => ({
      ...prev,
      features: prev.features.filter((_, i) => i !== index)
    }))
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white/10 backdrop-blur-md border border-border-white-10 rounded-xl p-6 w-full max-w-2xl mx-4">
        <h2 className="text-2xl font-bold mb-6">
          {plan ? 'Edit Plan' : 'Add New Plan'}
        </h2>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-2">Plan Name</label>
            <input
              type="text"
              value={formData.name}
              onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
              className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-pink-500"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">Description</label>
            <textarea
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
              className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-pink-500"
              rows={3}
              required
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Monthly Price (₹)</label>
              <input
                type="number"
                value={formData.price_monthly}
                onChange={(e) => setFormData(prev => ({ ...prev, price_monthly: parseInt(e.target.value) || 0 }))}
                className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-pink-500"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Yearly Price (₹)</label>
              <input
                type="number"
                value={formData.price_yearly}
                onChange={(e) => setFormData(prev => ({ ...prev, price_yearly: parseInt(e.target.value) || 0 }))}
                className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-pink-500"
                required
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">Features</label>
            <div className="space-y-2">
              {formData.features.map((feature, index) => (
                <div key={index} className="flex items-center gap-2">
                  <span className="text-sm text-light-white">• {feature}</span>
                  <button
                    type="button"
                    onClick={() => removeFeature(index)}
                    className="text-red-400 hover:text-red-300"
                  >
                    Remove
                  </button>
                </div>
              ))}
              <div className="flex gap-2">
                <input
                  type="text"
                  value={newFeature}
                  onChange={(e) => setNewFeature(e.target.value)}
                  placeholder="Add new feature"
                  className="flex-1 px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-pink-500"
                />
                <button
                  type="button"
                  onClick={addFeature}
                  className="px-4 py-2 bg-pink-500 text-white rounded-lg hover:bg-pink-600 transition-colors"
                >
                  Add
                </button>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Sort Order</label>
              <input
                type="number"
                value={formData.sort_order}
                onChange={(e) => setFormData(prev => ({ ...prev, sort_order: parseInt(e.target.value) || 0 }))}
                className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-pink-500"
              />
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
          </div>

          <div className="flex gap-4 pt-4">
            <button
              type="submit"
              className="px-6 py-3 bg-gradient-cta text-white font-semibold rounded-full hover:shadow-lg transform hover:scale-105 transition-all duration-200"
            >
              {plan ? 'Update Plan' : 'Create Plan'}
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

// Pricing Modal Component
function PricingModal({ pricing, plans, onSave, onClose }: {
  pricing: PricingOption | null
  plans: SubscriptionPlan[]
  onSave: (pricing: Partial<PricingOption>) => void
  onClose: () => void
}) {
  const [formData, setFormData] = useState({
    plan_id: pricing?.plan_id || '',
    duration_months: pricing?.duration_months || 1,
    price: pricing?.price || 0,
    original_price: pricing?.original_price || null,
    discount_percentage: pricing?.discount_percentage || null,
    is_popular: pricing?.is_popular || false
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    onSave(formData)
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <div className="bg-white/10 backdrop-blur-md border border-border-white-10 rounded-xl p-6 w-full max-w-md mx-4">
        <h2 className="text-2xl font-bold mb-6">
          {pricing ? 'Edit Pricing' : 'Add New Pricing'}
        </h2>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-2">Plan</label>
            <select
              value={formData.plan_id}
              onChange={(e) => setFormData(prev => ({ ...prev, plan_id: e.target.value }))}
              className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-pink-500"
              required
            >
              <option value="">Select a plan</option>
              {plans.map(plan => (
                <option key={plan.id} value={plan.id}>{plan.name}</option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">Duration (Months)</label>
            <input
              type="number"
              value={formData.duration_months}
              onChange={(e) => setFormData(prev => ({ ...prev, duration_months: parseInt(e.target.value) || 1 }))}
              className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-pink-500"
              min="1"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">Price (₹)</label>
            <input
              type="number"
              value={formData.price}
              onChange={(e) => setFormData(prev => ({ ...prev, price: parseInt(e.target.value) || 0 }))}
              className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-pink-500"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">Original Price (₹) - Optional</label>
            <input
              type="number"
              value={formData.original_price || ''}
              onChange={(e) => setFormData(prev => ({ ...prev, original_price: e.target.value ? parseInt(e.target.value) : null }))}
              className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-pink-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">Discount Percentage - Optional</label>
            <input
              type="number"
              value={formData.discount_percentage || ''}
              onChange={(e) => setFormData(prev => ({ ...prev, discount_percentage: e.target.value ? parseInt(e.target.value) : null }))}
              className="w-full px-4 py-2 bg-white/10 border border-border-white-10 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-pink-500"
            />
          </div>

          <div className="flex items-center">
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={formData.is_popular}
                onChange={(e) => setFormData(prev => ({ ...prev, is_popular: e.target.checked }))}
                className="w-4 h-4 text-pink-500 bg-white/10 border-border-white-10 rounded focus:ring-pink-500"
              />
              <span className="text-sm">Most Popular</span>
            </label>
          </div>

          <div className="flex gap-4 pt-4">
            <button
              type="submit"
              className="px-6 py-3 bg-gradient-cta text-white font-semibold rounded-full hover:shadow-lg transform hover:scale-105 transition-all duration-200"
            >
              {pricing ? 'Update Pricing' : 'Create Pricing'}
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
