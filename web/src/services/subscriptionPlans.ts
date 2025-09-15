import { supabase } from '../supabaseClient'

export interface SubscriptionPlan {
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

export interface PricingOption {
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

export interface PlanWithPricing extends SubscriptionPlan {
  pricing_options: PricingOption[]
}

export const subscriptionPlansService = {
  // Get all active subscription plans
  async getPlans(): Promise<SubscriptionPlan[]> {
    const { data, error } = await supabase
      .from('subscription_plans')
      .select('*')
      .eq('is_active', true)
      .order('sort_order')

    if (error) {
      console.error('Error fetching subscription plans:', error)
      throw error
    }

    return data || []
  },

  // Get plans with pricing options
  async getPlansWithPricing(): Promise<PlanWithPricing[]> {
    const { data, error } = await supabase
      .from('subscription_plans')
      .select(`
        *,
        pricing_options (*)
      `)
      .eq('is_active', true)
      .order('sort_order')

    if (error) {
      console.error('Error fetching plans with pricing:', error)
      throw error
    }

    return data || []
  },

  // Get pricing options for a specific plan
  async getPricingOptions(planId: string): Promise<PricingOption[]> {
    const { data, error } = await supabase
      .from('pricing_options')
      .select('*')
      .eq('plan_id', planId)
      .order('duration_months')

    if (error) {
      console.error('Error fetching pricing options:', error)
      throw error
    }

    return data || []
  },

  // Calculate savings for a pricing option
  calculateSavings(price: number, originalPrice: number | null): number {
    if (!originalPrice) return 0
    return Math.round(((originalPrice - price) / originalPrice) * 100)
  },

  // Format price for display
  formatPrice(price: number): string {
    return new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(price)
  },

  // Get monthly equivalent price
  getMonthlyPrice(price: number, durationMonths: number): number {
    return Math.round(price / durationMonths)
  }
}
