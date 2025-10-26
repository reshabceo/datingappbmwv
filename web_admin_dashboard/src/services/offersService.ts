import { supabase } from '../supabaseClient'

export interface Offer {
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

export interface OfferApplication {
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

export interface DiscountedPricing extends PricingOption {
  offer_id?: string
  offer_name?: string
  offer_type?: string
  discount_value?: number
  reason?: string
  discounted_price: number
  savings: number
}

export const offersService = {
  // Get all active offers
  async getActiveOffers(): Promise<Offer[]> {
    const { data, error } = await supabase
      .from('offers')
      .select('*')
      .eq('is_active', true)
      .gte('start_date', new Date().toISOString())
      .or('end_date.is.null,end_date.gte.' + new Date().toISOString())
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Error fetching active offers:', error)
      throw error
    }

    return data || []
  },

  // Get all active special offers
  async getActiveSpecialOffers(): Promise<any[]> {
    const { data, error } = await supabase
      .from('special_offers')
      .select('*')
      .eq('is_active', true)
      .gte('start_date', new Date().toISOString())
      .or('end_date.is.null,end_date.gte.' + new Date().toISOString())
      .order('created_at', { ascending: false })

    if (error) {
      console.error('Error fetching active special offers:', error)
      throw error
    }

    return data || []
  },

  // Get applicable offers for a user and plan
  async getApplicableOffers(
    userId: string, 
    planId: string, 
    durationMonths: number
  ): Promise<Offer[]> {
    const { data, error } = await supabase
      .rpc('get_applicable_offers', {
        p_user_id: userId,
        p_plan_id: planId,
        p_duration_months: durationMonths
      })

    if (error) {
      console.error('Error fetching applicable offers:', error)
      throw error
    }

    return data || []
  },

  // Get pricing with applied offers
  async getPricingWithOffers(
    userId: string,
    planId: string,
    durationMonths: number
  ): Promise<DiscountedPricing[]> {
    try {
      // Get pricing options for the plan and duration
      const { data: pricingData, error: pricingError } = await supabase
        .from('pricing_options')
        .select('*')
        .eq('plan_id', planId)
        .eq('duration_months', durationMonths)

      if (pricingError) throw pricingError

      if (!pricingData || pricingData.length === 0) {
        return []
      }

      // Get applicable offers
      const offers = await this.getApplicableOffers(userId, planId, durationMonths)

      // Apply offers to pricing
      const discountedPricing: DiscountedPricing[] = pricingData.map(pricing => {
        // Find the best offer for this pricing
        const bestOffer = offers.reduce((best, offer) => {
          const currentDiscount = this.calculateDiscount(pricing.price, offer)
          const bestDiscount = best ? this.calculateDiscount(pricing.price, best) : 0
          return currentDiscount > bestDiscount ? offer : best
        }, null as Offer | null)

        if (bestOffer) {
          const discountedPrice = this.calculateDiscountedPrice(pricing.price, bestOffer)
          const savings = pricing.price - discountedPrice

          return {
            ...pricing,
            offer_id: bestOffer.id,
            offer_name: bestOffer.name,
            offer_type: bestOffer.offer_type,
            discount_value: bestOffer.discount_value,
            reason: bestOffer.reason,
            discounted_price,
            savings
          }
        }

        return {
          ...pricing,
          discounted_price: pricing.price,
          savings: 0
        }
      })

      return discountedPricing
    } catch (error) {
      console.error('Error getting pricing with offers:', error)
      throw error
    }
  },

  // Calculate discount amount
  calculateDiscount(originalPrice: number, offer: Offer): number {
    switch (offer.offer_type) {
      case 'percentage':
        return originalPrice * (offer.discount_value / 100)
      case 'fixed_amount':
        return Math.min(offer.discount_value, originalPrice)
      case 'free':
        return originalPrice
      default:
        return 0
    }
  },

  // Calculate discounted price
  calculateDiscountedPrice(originalPrice: number, offer: Offer): number {
    const discount = this.calculateDiscount(originalPrice, offer)
    return Math.max(0, originalPrice - discount)
  },

  // Apply an offer to a pricing option
  async applyOffer(
    userId: string,
    offerId: string,
    planId: string,
    pricingOptionId: string
  ): Promise<OfferApplication> {
    try {
      // Get the offer details
      const { data: offer, error: offerError } = await supabase
        .from('offers')
        .select('*')
        .eq('id', offerId)
        .single()

      if (offerError) throw offerError

      // Get the pricing option details
      const { data: pricing, error: pricingError } = await supabase
        .from('pricing_options')
        .select('*')
        .eq('id', pricingOptionId)
        .single()

      if (pricingError) throw pricingError

      // Calculate discounted price
      const discountedPrice = this.calculateDiscountedPrice(pricing.price, offer)
      const discountAmount = pricing.price - discountedPrice

      // Create the application record
      const { data: application, error: applicationError } = await supabase
        .from('offer_applications')
        .insert([{
          offer_id: offerId,
          user_id: userId,
          plan_id: planId,
          pricing_option_id: pricingOptionId,
          original_price: pricing.price,
          discounted_price,
          discount_amount: discountAmount
        }])
        .select()
        .single()

      if (applicationError) throw applicationError

      // Update the offer's current uses count
      const { error: updateError } = await supabase
        .from('offers')
        .update({ 
          current_uses: offer.current_uses + 1,
          updated_at: new Date().toISOString()
        })
        .eq('id', offerId)

      if (updateError) throw updateError

      return application
    } catch (error) {
      console.error('Error applying offer:', error)
      throw error
    }
  },

  // Check if user is eligible for women's free subscription
  async isEligibleForWomenFree(userId: string): Promise<boolean> {
    try {
      // Check if user is female
      const { data: profile, error: profileError } = await supabase
        .from('profiles')
        .select('gender')
        .eq('id', userId)
        .single()

      if (profileError) {
        console.error('Error checking user profile:', profileError)
        return false
      }

      return profile?.gender === 'female'
    } catch (error) {
      console.error('Error checking women free eligibility:', error)
      return false
    }
  },

  // Get user's offer applications
  async getUserOfferApplications(userId: string): Promise<OfferApplication[]> {
    const { data, error } = await supabase
      .from('offer_applications')
      .select('*')
      .eq('user_id', userId)
      .order('applied_at', { ascending: false })

    if (error) {
      console.error('Error fetching user offer applications:', error)
      throw error
    }

    return data || []
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
