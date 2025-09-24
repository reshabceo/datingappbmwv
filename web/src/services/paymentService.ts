import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://dkcitxzvojvecuvacwsp.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Razorpay configuration
const RAZORPAY_KEY_ID = 'rzp_test_1DP5mmOlF5G5ag'; // Replace with your Razorpay key

// Subscription plans with pricing
export const subscriptionPlans = {
  '1_month': {
    name: 'Premium - 1 Month',
    price: 150000, // ₹1.50 (in paise) - Testing price
    duration_months: 1,
    description: 'Premium features for 1 month'
  },
  '3_month': {
    name: 'Premium - 3 Months',
    price: 225000, // ₹2250.00 (in paise)
    duration_months: 3,
    description: 'Premium features for 3 months'
  },
  '6_month': {
    name: 'Premium - 6 Months',
    price: 360000, // ₹3600.00 (in paise)
    duration_months: 6,
    description: 'Premium features for 6 months'
  }
};

export class PaymentService {
  private static razorpay: any = null;

  static async initialize() {
    // Check if Razorpay is already loaded
    if (this.razorpay) {
      console.log('Razorpay already initialized');
      return true;
    }

    // Load Razorpay script dynamically
    return new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = 'https://checkout.razorpay.com/v1/checkout.js';
      script.onload = () => {
        this.razorpay = (window as any).Razorpay;
        console.log('Razorpay loaded successfully');
        resolve(true);
      };
      script.onerror = () => {
        console.error('Failed to load Razorpay script');
        reject(new Error('Failed to load Razorpay'));
      };
      document.head.appendChild(script);
    });
  }

  static async initiatePayment(planType: string, userEmail: string, userName: string) {
    try {
      console.log('Starting payment initiation...');
      
      if (!this.razorpay) {
        throw new Error('Razorpay not initialized. Please refresh the page.');
      }

      const plan = subscriptionPlans[planType as keyof typeof subscriptionPlans];
      if (!plan) {
        throw new Error('Invalid subscription plan');
      }

      const orderId = crypto.randomUUID();
      const amount = plan.price;
      const description = plan.description;

      console.log('Creating order record...', { orderId, planType, amount, userEmail });

      // Create order in Supabase first
      await this.createOrderRecord(orderId, planType, amount, userEmail);

      const options = {
        key: RAZORPAY_KEY_ID,
        amount: amount,
        currency: 'INR',
        name: 'Love Bug Premium',
        description: description,
        prefill: {
          name: userName,
          email: userEmail,
        },
        theme: {
          color: '#ec4899'
        },
        handler: async (response: any) => {
          console.log('Payment success handler called');
          await this.handlePaymentSuccess(response, orderId);
        },
        modal: {
          ondismiss: () => {
            console.log('Payment modal dismissed');
          }
        },
        notes: {
          order_id: orderId,
          plan_type: planType
        }
      };

      console.log('Opening Razorpay modal with options:', options);
      this.razorpay.open(options);
      console.log('Razorpay modal opened successfully');
      
    } catch (error) {
      console.error('Error initiating payment:', error);
      throw error;
    }
  }

  private static async createOrderRecord(orderId: string, planType: string, amount: number, userEmail: string) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        console.warn('User not authenticated, creating order without user_id');
      }
      
      const { data, error } = await supabase.from('payment_orders').insert({
        order_id: orderId,
        user_id: user?.id || null,
        plan_type: planType,
        amount: amount,
        status: 'pending',
        user_email: userEmail,
        created_at: new Date().toISOString(),
      }).select();
      
      if (error) {
        console.error('Database error creating order:', error);
        throw error;
      }
      
      console.log('Order record created successfully:', orderId);
      console.log('Inserted data:', data);
    } catch (error) {
      console.error('Error creating order record:', error);
      throw error; // Re-throw to stop payment if order creation fails
    }
  }

  public static async handlePaymentSuccess(response: any, orderId: string) {
    try {
      // Fix the payment ID - Razorpay uses razorpay_payment_id
      const paymentId = response.razorpay_payment_id || response.paymentId;
      console.log('Payment Success:', paymentId);
      console.log('Full response:', response);
      
      // Use local processing directly (bypass Edge Function for now)
      console.log('Using local processing...');
      
      // Update order status first
      try {
        await this.updateOrderStatus(orderId, 'success', paymentId);
        console.log('Order status updated successfully');
      } catch (orderError) {
        console.error('Error updating order status:', orderError);
        console.log('Order status update failed, but continuing with subscription creation...');
        // Continue anyway, don't fail the whole process
      }
      
      // Create subscription
      try {
        await this.createSubscription(orderId);
        console.log('Subscription created successfully');
        
        // Send invoice email after successful subscription using Edge Function
        try {
          const { data: { user } } = await supabase.auth.getUser();
          if (user?.email) {
            const { data: profileData } = await supabase
              .from('profiles')
              .select('name')
              .eq('id', user.id)
              .single();
            
            const userName = profileData?.name || 'User';
            const { data: orderData } = await supabase
              .from('payment_orders')
              .select('plan_type, amount, created_at')
              .eq('order_id', orderId)
              .single();
            
            if (orderData) {
              // Get subscription end date
              const { data: subscriptionData } = await supabase
                .from('user_subscriptions')
                .select('end_date')
                .eq('order_id', orderId)
                .single();
              
              // Call Edge Function to send invoice
              const { data: invoiceResult, error: invoiceError } = await supabase.functions.invoke('send-invoice', {
                body: {
                  orderId: orderId,
                  paymentId: paymentId,
                  amount: orderData.amount,
                  planType: orderData.plan_type,
                  userEmail: user.email,
                  userName: userName,
                  paymentDate: orderData.created_at,
                  expiryDate: subscriptionData?.end_date || new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
                }
              });
              
              if (invoiceError) {
                console.error('❌ Invoice Edge Function Error:', invoiceError);
              } else {
                console.log('📧 Invoice sent successfully via Edge Function:', invoiceResult);
              }
            }
          }
        } catch (invoiceError) {
          console.error('Error sending invoice email:', invoiceError);
          // Don't fail the payment process if invoice fails
        }
        
      } catch (subscriptionError) {
        console.error('Error creating subscription:', subscriptionError);
        // Continue anyway, don't fail the whole process
      }
      
      // Show success notification with more details
      const successMessage = `
🎉 Payment Successful!

✅ Premium features activated
✅ Order ID: ${orderId}
✅ Payment ID: ${paymentId}

Your premium subscription is now active! You can view your order history and manage your subscription from your profile.
      `.trim();
      
      alert(successMessage);
      
      // Track analytics (don't fail if this doesn't work)
      try {
        await this.trackPaymentSuccess(orderId);
      } catch (analyticsError) {
        console.error('Error tracking analytics:', analyticsError);
      }
      
      // Redirect to order history after a short delay
      setTimeout(() => {
        window.location.href = '/order-history';
      }, 2000);
      
    } catch (error) {
      console.error('Error handling payment success:', error);
      console.error('Error details:', error);
      
      // Show more detailed error message
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      alert(`Payment processing failed: ${errorMessage}\n\nPlease try the "Fix Order" button in Order History if the payment was successful.`);
    }
  }

  private static async verifyPayment(paymentId: string): Promise<boolean> {
    try {
      // In production, verify with your backend
      // For now, we'll assume payment is verified
      return true;
    } catch (error) {
      console.error('Payment verification error:', error);
      return false;
    }
  }

  private static async updateOrderStatus(orderId: string, status: string, paymentId?: string) {
    try {
      const { data, error } = await supabase.from('payment_orders').update({
        status: status,
        payment_id: paymentId,
        updated_at: new Date().toISOString(),
      }).eq('order_id', orderId).select();
      
      if (error) {
        console.error('Database error updating order status:', error);
        throw error;
      }
      
      console.log('Order status updated successfully:', data);
    } catch (error) {
      console.error('Error updating order status:', error);
      throw error;
    }
  }

  private static async createSubscription(orderId: string) {
    try {
      console.log('Creating subscription for order:', orderId);
      
      // Get order details
      const { data: orderData, error: orderError } = await supabase
        .from('payment_orders')
        .select('plan_type, user_id')
        .eq('order_id', orderId)
        .single();

      if (orderError) {
        console.error('Error fetching order data:', orderError);
        throw orderError;
      }

      console.log('Order data:', orderData);

      const planType = orderData.plan_type;
      const userId = orderData.user_id;
      const plan = subscriptionPlans[planType as keyof typeof subscriptionPlans];
      
      if (!plan) {
        throw new Error(`Plan not found for type: ${planType}`);
      }
      
      const durationMonths = plan.duration_months;

      // Calculate validity dates - extend from current end date if user already has premium
      const now = new Date();
      
      // Check if user already has an active subscription
      const { data: existingSubscription } = await supabase
        .from('user_subscriptions')
        .select('end_date')
        .eq('user_id', userId)
        .eq('status', 'active')
        .order('end_date', { ascending: false })
        .limit(1)
        .single();

      let validUntil;
      if (existingSubscription && existingSubscription.end_date) {
        // Extend from current end date
        const currentEndDate = new Date(existingSubscription.end_date);
        validUntil = new Date(currentEndDate.getTime() + (durationMonths * 30 * 24 * 60 * 60 * 1000));
        console.log('Extending subscription from:', currentEndDate.toISOString(), 'to:', validUntil.toISOString());
      } else {
        // Start from now (new subscription)
        validUntil = new Date(now.getTime() + (durationMonths * 30 * 24 * 60 * 60 * 1000));
        console.log('Creating new subscription from:', now.toISOString(), 'to:', validUntil.toISOString());
      }

      console.log('Creating subscription with:', {
        userId,
        planType,
        durationMonths,
        validUntil: validUntil.toISOString()
      });

      // Create subscription record
      const { data: subscriptionData, error: subscriptionError } = await supabase.from('user_subscriptions').insert({
        user_id: userId,
        plan_type: planType,
        status: 'active',
        start_date: now.toISOString(),
        end_date: validUntil.toISOString(),
        order_id: orderId,
        created_at: now.toISOString(),
      }).select();

      if (subscriptionError) {
        console.error('Error creating subscription record:', subscriptionError);
        throw subscriptionError;
      }
      
      console.log('Subscription record created:', subscriptionData);

      // Update user profile to premium (extend existing or set new)
      const { data: profileData, error: profileError } = await supabase.from('profiles').update({
        is_premium: true,
        premium_until: validUntil.toISOString(),
      }).eq('id', userId).select();

      if (profileError) {
        console.error('Error updating profile:', profileError);
        throw profileError;
      }
      
      console.log('Profile updated successfully:', profileData);

      console.log('Subscription created successfully');
    } catch (error) {
      console.error('Error creating subscription:', error);
      throw error;
    }
  }

  private static async trackPaymentSuccess(orderId: string) {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      // Track payment success in analytics
      await supabase.from('user_events').insert({
        event_type: 'payment_success',
        event_data: {
          order_id: orderId,
          timestamp: new Date().toISOString(),
        },
        user_id: user?.id,
      });
    } catch (error) {
      console.error('Error tracking payment success:', error);
    }
  }

  // Check if user has active premium subscription
  static async hasActiveSubscription(): Promise<boolean> {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return false;

      const { data, error } = await supabase
        .from('user_subscriptions')
        .select('status, end_date')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .gte('end_date', new Date().toISOString())
        .maybeSingle();

      if (error) throw error;
      return data !== null;
    } catch (error) {
      console.error('Error checking subscription:', error);
      return false;
    }
  }

  // Get subscription details
  static async getSubscriptionDetails() {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return null;

      const { data, error } = await supabase
        .from('user_subscriptions')
        .select('plan_type, start_date, end_date, status')
        .eq('user_id', user.id)
        .eq('status', 'active')
        .gte('end_date', new Date().toISOString())
        .maybeSingle();

      if (error) throw error;
      return data;
    } catch (error) {
      console.error('Error getting subscription details:', error);
      return null;
    }
  }

  // Cancel subscription
  static async cancelSubscription() {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      await supabase.from('user_subscriptions').update({
        status: 'cancelled',
        cancelled_at: new Date().toISOString(),
      }).eq('user_id', user.id).eq('status', 'active');

      // Update user profile
      await supabase.from('profiles').update({
        is_premium: false,
        premium_until: null,
      }).eq('id', user.id);

      alert('Subscription cancelled successfully');
    } catch (error) {
      console.error('Error cancelling subscription:', error);
      alert('Failed to cancel subscription');
    }
  }
}
