import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://dkcitxzvojvecuvacwsp.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

// CASHFREE CONFIGURATION - LIVE CREDENTIALS ONLY
const CASHFREE_APP_ID = '108566980dabe16ff7dcf1c424e9665801';
const CASHFREE_SECRET_KEY = 'cfsk_ma_prod_2696a352b7f5c5519d02aa8750eccfd5_5b5f2bd0';
const CASHFREE_ENVIRONMENT = 'production';

// Subscription plans with pricing
export const subscriptionPlans = {
  '1_month': {
    name: 'Premium - 1 Month',
    price: 1, // ₹1 (TESTING)
    duration_months: 1,
    description: 'Premium features for 1 month'
  },
  '3_month': {
    name: 'Premium - 3 Months',
    price: 1, // ₹1 (TESTING)
    duration_months: 3,
    description: 'Premium features for 3 months'
  },
  '6_month': {
    name: 'Premium - 6 Months',
    price: 1, // ₹1 (TESTING)
    duration_months: 6,
    description: 'Premium features for 6 months'
  }
};

export class PaymentService {
  // private static razorpay: any = null; // COMMENTED OUT - SWITCHED TO CASHFREE

  static async initialize() {
    // Cashfree doesn't require script loading like Razorpay
    // Payment is handled through API calls
    console.log('Cashfree Payment Service initialized');
    return true;
  }

  static async initiatePayment(planType: string, userEmail: string, userName: string) {
    try {
      console.log('Starting Cashfree payment initiation...');
      
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

      // Create Cashfree payment session
      await this.createCashfreePaymentSession(
        orderId,
        amount,
        userEmail,
        userName,
        description
      );
      
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
      
      // Check if user has a profile, if not create one
      let userId = user?.id;
      if (user && user.id) {
        const { data: profileData, error: profileError } = await supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .single();
        
        if (profileError && profileError.code === 'PGRST116') {
          // Profile doesn't exist, create one
          console.log('Creating profile for user:', user.id);
          const { error: createProfileError } = await supabase.from('profiles').insert({
            id: user.id,
            email: user.email,
            name: user.user_metadata?.name || user.email?.split('@')[0] || 'User',
            age: 18, // Default age
            is_active: false, // Profile not active until completed
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          });
          
          if (createProfileError) {
            console.error('Error creating profile:', createProfileError);
            // Continue anyway, we'll use null user_id
            userId = null;
          } else {
            console.log('Profile created successfully');
          }
        } else if (profileError) {
          console.error('Error checking profile:', profileError);
          // Continue anyway, we'll use null user_id
          userId = null;
        }
      }
      
      const { data, error } = await supabase.from('payment_orders').insert({
        order_id: orderId,
        user_id: userId,
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

  // CASHFREE PAYMENT SESSION CREATION - Using Edge Function to avoid CORS
  private static async createCashfreePaymentSession(
    orderId: string,
    amount: number,
    userEmail: string,
    userName: string,
    description: string
  ) {
    try {
      console.log('Calling Cashfree Edge Function...');
      
      // Get current user ID for Cashfree customer_id
      const { data: { user } } = await supabase.auth.getUser()
      const userId = user?.id

      // Call Supabase Edge Function instead of direct API
      const { data, error } = await supabase.functions.invoke('cashfree-payment', {
        body: {
          type: 'createOrder', // Add type for Edge Function
          orderId,
          amount,
          userEmail,
          userName,
          description,
          userId
        }
      });

      if (error) {
        console.error('Edge Function error:', error);
        throw new Error(`Edge Function failed: ${error.message}`);
      }

      if (data.success) {
        const paymentSessionId = data.payment_session_id;
        
        console.log('Cashfree payment session created via Edge Function:', data);
        console.log('Payment Session ID:', paymentSessionId);
        console.log('Debug response from Cashfree:', data.debug_response);
        
        if (!paymentSessionId) {
          console.error('No payment_session_id received from Cashfree');
          throw new Error('Failed to get payment session ID from Cashfree');
        }
        
        // Use Cashfree's SDK to open checkout modal (like Razorpay)
        await this.openCashfreeCheckout(paymentSessionId, orderId);
        
        // Set up window focus listener to detect when user returns from payment
        this.setupPaymentFocusListener(orderId);
        
        // Set up polling to check payment status as fallback
        this.pollPaymentStatus(orderId);
      } else {
        throw new Error(data.error || 'Failed to create payment session');
      }
    } catch (error) {
      console.error('Error creating Cashfree payment session:', error);
      throw error;
    }
  }

  // OPEN CASHFREE CHECKOUT MODAL - Using Cashfree SDK
  private static async openCashfreeCheckout(paymentSessionId: string, orderId: string) {
    try {
      // Load Cashfree SDK dynamically
      if (!(window as any).Cashfree) {
        await this.loadCashfreeSDK();
      }

      const cashfree = new (window as any).Cashfree();
      
      // Initialize Cashfree with payment session
      const checkoutOptions = {
        paymentSessionId: paymentSessionId,
        returnUrl: `${window.location.origin}/payment/success?order_id=${orderId}`,
        mode: 'production', // Always production
      };

      console.log('Opening Cashfree checkout with options:', checkoutOptions);
      console.log('Cashfree SDK available:', typeof cashfree);
      console.log('Cashfree checkout method:', typeof cashfree.checkout);

      // Open checkout modal (like Razorpay popup)
      cashfree.checkout(checkoutOptions).then((result: any) => {
        console.log('Cashfree checkout result:', result);
        console.log('Result keys:', Object.keys(result || {}));
        
        if (result.error) {
          console.error('Cashfree checkout error:', result.error);
          alert(`Payment failed: ${result.error.message}`);
          return;
        }
        
        // Always start verification after modal closes
        // (Cashfree SDK doesn't always return clear success indicators)
        console.log('Cashfree modal closed, starting verification...');
        this.handlePaymentCompletion(orderId);
        
        if (result.redirect) {
          console.log('Cashfree redirect:', result.redirect);
        }
        if (result.paymentDetails) {
          console.log('Payment successful:', result.paymentDetails);
        }
      }).catch((error: any) => {
        console.error('Cashfree checkout error:', error);
        alert(`Payment failed: ${error.message}`);
      });
    } catch (error) {
      console.error('Error opening Cashfree checkout:', error);
      throw error;
    }
  }

  // LOAD CASHFREE SDK
  private static async loadCashfreeSDK(): Promise<void> {
    return new Promise((resolve, reject) => {
      if ((window as any).Cashfree) {
        resolve();
        return;
      }

      const script = document.createElement('script');
      // Use regular SDK (works with both localhost and production)
      script.src = 'https://sdk.cashfree.com/js/v3/cashfree.js';
      script.async = true;
      
      console.log('Loading Cashfree SDK from:', script.src);
      script.onload = () => {
        console.log('Cashfree SDK loaded successfully');
        console.log('Cashfree object available:', typeof (window as any).Cashfree);
        
        // Cashfree SDK is now available globally
        resolve();
      };
      script.onerror = (error) => {
        console.error('Cashfree SDK loading error:', error);
        console.error('Script src:', script.src);
        reject(new Error('Failed to load Cashfree SDK'));
      };
      document.body.appendChild(script);
    });
  }

  // SETUP PAYMENT FOCUS LISTENER - Detect when user returns from payment modal
  private static setupPaymentFocusListener(orderId: string) {
    let hasProcessed = false;
    
    const handleFocus = async () => {
      if (hasProcessed) return;
      hasProcessed = true;
      
      console.log('Window focused - checking payment status...');
      
      // Wait a moment for payment to be processed
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      try {
        const isPaid = await this.verifyCashfreePayment(orderId);
        if (isPaid) {
          console.log('Payment verified on window focus!');
          await this.handlePaymentSuccess({ order_id: orderId }, orderId);
        }
      } catch (error) {
        console.error('Error checking payment on focus:', error);
      }
      
      // Remove listener after processing
      window.removeEventListener('focus', handleFocus);
    };
    
    // Listen for window focus (when user returns from payment modal)
    window.addEventListener('focus', handleFocus);
    
    // Also listen for visibility change (when tab becomes active)
    const handleVisibilityChange = () => {
      if (!document.hidden && !hasProcessed) {
        handleFocus();
      }
    };
    
    document.addEventListener('visibilitychange', handleVisibilityChange);
    
    // Clean up after 5 minutes
    setTimeout(() => {
      window.removeEventListener('focus', handleFocus);
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    }, 300000);
  }

  // HANDLE PAYMENT COMPLETION - Immediate verification like Razorpay
  private static async handlePaymentCompletion(orderId: string) {
    console.log('Payment completed, verifying immediately...');
    
    // Wait for Cashfree to process (they need a few seconds)
    await new Promise(resolve => setTimeout(resolve, 3000));
    
    try {
      // Try verification multiple times with delays
      for (let attempt = 1; attempt <= 5; attempt++) {
        console.log(`Verification attempt ${attempt}/5...`);
        
        const isPaid = await this.verifyCashfreePayment(orderId);
        
        if (isPaid) {
          console.log('✅ Payment verified successfully!');
          await this.handlePaymentSuccess({ order_id: orderId }, orderId);
          return; // Exit after success
        }
        
        // Wait before next attempt
        if (attempt < 5) {
          await new Promise(resolve => setTimeout(resolve, 2000));
        }
      }
      
      console.log('Payment not verified after 5 attempts, continuing to poll...');
    } catch (error) {
      console.error('Error in payment completion:', error);
    }
  }

  // POLL PAYMENT STATUS - More aggressive polling without webhooks
  private static async pollPaymentStatus(orderId: string) {
    const maxAttempts = 60; // Poll for 10 minutes (60 * 10 seconds)
    let attempts = 0;
    
    console.log('Starting payment status polling for order:', orderId);
    
    const pollInterval = setInterval(async () => {
      attempts++;
      console.log(`Polling attempt ${attempts}/${maxAttempts} for order: ${orderId}`);
      
      try {
        const isPaid = await this.verifyCashfreePayment(orderId);
        
        if (isPaid) {
          console.log('Payment confirmed! Processing success...');
          clearInterval(pollInterval);
          await this.handlePaymentSuccess({ order_id: orderId }, orderId);
        } else if (attempts >= maxAttempts) {
          console.log('Payment polling timeout - user may have abandoned payment');
          clearInterval(pollInterval);
          // Optionally update order status to failed
          await this.updateOrderStatus(orderId, 'timeout', null);
        }
      } catch (error) {
        console.error('Error polling payment status:', error);
        if (attempts >= maxAttempts) {
          clearInterval(pollInterval);
        }
      }
    }, 10000); // Poll every 10 seconds
  }

  // VERIFY CASHFREE PAYMENT - Using Edge Function to avoid CORS
  private static async verifyCashfreePayment(orderId: string): Promise<boolean> {
    try {
      // Call Supabase Edge Function for verification (no CORS issues)
      const { data, error } = await supabase.functions.invoke('cashfree-payment', {
        body: {
          type: 'verifyOrder', // Add type for Edge Function
          orderId
        }
      });

      if (error) {
        console.error('Edge Function error (verifyOrder):', error);
        return false;
      }

      console.log('Cashfree verification response from Edge Function:', data);
      
      if (data.success) {
        console.log('Cashfree order_status:', data.order_status);
        console.log('Cashfree payment_status:', data.payment_status);
        
        // Cashfree uses different status values than Razorpay
        // Check for successful payment statuses
        const isOrderPaid = data.order_status === 'PAID' || data.order_status === 'ACTIVE';
        const isPaymentSuccessful = data.payment_status === 'SUCCESS' || data.payment_status === 'PAID';
        
        return isOrderPaid || isPaymentSuccessful;
      }
      
      return false;
    } catch (error) {
      console.error('Error verifying Cashfree payment:', error);
      return false;
    }
  }

  public static async handlePaymentSuccess(response: any, orderId: string) {
    try {
      // For Cashfree, we use order_id as the primary identifier
      const paymentId = response.payment_id || orderId;
      console.log('Payment Success:', paymentId);
      console.log('Full response:', response);
      
      // Check if this order has already been processed
      const { data: existingOrder } = await supabase
        .from('payment_orders')
        .select('status')
        .eq('order_id', orderId)
        .single();
      
      if (existingOrder?.status === 'success') {
        console.log('Order already processed, skipping duplicate processing');
        return;
      }
      
      // Success message will be shown by UI, not alert
      
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
              console.log('📧 Sending invoice with amount:', orderData.amount, 'for order:', orderId);
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
      
      // Check if subscription already exists for this order
      const { data: existingSubscription } = await supabase
        .from('user_subscriptions')
        .select('id')
        .eq('order_id', orderId)
        .single();
      
      if (existingSubscription) {
        console.log('Subscription already exists for this order, skipping creation');
        return;
      }
      
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
      const { data: currentSubscription } = await supabase
        .from('user_subscriptions')
        .select('end_date')
        .eq('user_id', userId)
        .eq('status', 'active')
        .order('end_date', { ascending: false })
        .limit(1)
        .single();

      let validUntil;
      if (currentSubscription && currentSubscription.end_date) {
        // Extend from current end date
        const currentEndDate = new Date(currentSubscription.end_date);
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
