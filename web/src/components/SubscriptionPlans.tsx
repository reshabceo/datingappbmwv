import React, { useState, useEffect } from 'react';
import { PaymentService, subscriptionPlans } from '../services/paymentService';
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://dkcitxzvojvecuvacwsp.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

interface SubscriptionPlansProps {
  onClose?: () => void;
}

const SubscriptionPlans: React.FC<SubscriptionPlansProps> = ({ onClose }) => {
  const [isLoading, setIsLoading] = useState(false);
  const [hasActiveSubscription, setHasActiveSubscription] = useState(false);
  const [subscriptionDetails, setSubscriptionDetails] = useState<any>(null);
  const [user, setUser] = useState<any>(null);

  useEffect(() => {
    initializePayment();
    checkSubscriptionStatus();
    getCurrentUser();
  }, []);

  const initializePayment = async () => {
    try {
      await PaymentService.initialize();
    } catch (error) {
      console.error('Error initializing payment:', error);
    }
  };

  const checkSubscriptionStatus = async () => {
    try {
      const hasSubscription = await PaymentService.hasActiveSubscription();
      setHasActiveSubscription(hasSubscription);
      
      if (hasSubscription) {
        const details = await PaymentService.getSubscriptionDetails();
        setSubscriptionDetails(details);
      }
    } catch (error) {
      console.error('Error checking subscription status:', error);
    }
  };

  const getCurrentUser = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      setUser(user);
    } catch (error) {
      console.error('Error getting current user:', error);
    }
  };

  const handlePayment = async (planType: string) => {
    if (!user) {
      alert('Please login first');
      return;
    }

    try {
      setIsLoading(true);
      
      // Get user profile for name
      const { data: profile } = await supabase
        .from('profiles')
        .select('name')
        .eq('id', user.id)
        .single();

      const userName = profile?.name || 'User';
      const userEmail = user.email || '';

      await PaymentService.initiatePayment(planType, userEmail, userName);
    } catch (error) {
      console.error('Error initiating payment:', error);
      alert('Failed to initiate payment');
    } finally {
      setIsLoading(false);
    }
  };

  const handleCancelSubscription = async () => {
    if (window.confirm('Are you sure you want to cancel your subscription?')) {
      try {
        setIsLoading(true);
        await PaymentService.cancelSubscription();
        await checkSubscriptionStatus();
      } catch (error) {
        console.error('Error cancelling subscription:', error);
        alert('Failed to cancel subscription');
      } finally {
        setIsLoading(false);
      }
    }
  };

  const getSubscriptionStatusText = () => {
    if (hasActiveSubscription && subscriptionDetails) {
      const endDate = new Date(subscriptionDetails.end_date);
      const daysRemaining = Math.ceil((endDate.getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24));
      
      if (daysRemaining > 0) {
        return `Premium active - ${daysRemaining} days remaining`;
      } else {
        return 'Premium expired';
      }
    }
    return 'Free Plan';
  };

  const getPlanTypeText = () => {
    if (subscriptionDetails) {
      const planType = subscriptionDetails.plan_type;
      switch (planType) {
        case '1_month':
          return 'Premium - 1 Month';
        case '3_month':
          return 'Premium - 3 Months';
        case '6_month':
          return 'Premium - 6 Months';
        default:
          return 'Premium';
      }
    }
    return 'Free';
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-purple-900 to-violet-900">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center space-x-4">
            <button
              onClick={onClose}
              className="p-2 bg-white bg-opacity-10 rounded-lg hover:bg-opacity-20 transition-colors"
            >
              <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </button>
            <h1 className="text-3xl font-bold text-white">Choose Your Plan</h1>
          </div>
        </div>

        {/* Pre-launch banner */}
        <div className="mb-8 p-4 bg-gradient-to-r from-orange-500 to-red-500 rounded-lg">
          <div className="flex items-center space-x-3">
            <svg className="w-6 h-6 text-white" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M12.395 2.553a1 1 0 00-1.45-.385c-.345.23-.614.558-.822.88-.214.33-.403.713-.57 1.116-.334.804-.614 1.768-.84 2.734a31.365 31.365 0 00-.613 3.58 2.64 2.64 0 01-.945-1.067c-.328-.68-.398-1.534-.398-2.654A1 1 0 005.05 6.05 6.981 6.981 0 003 11a7 7 0 1011.95-4.95c-.592-.591-.98-.985-1.348-1.467-.363-.476-.724-1.063-1.207-2.03zM12.12 15.12A3 3 0 017 13s.879.5 2.5.5c0-1 .5-4 1.25-4.5.5 1 .786 1.293 1.371 1.879A2.99 2.99 0 0113 13a2.99 2.99 0 01-.879 2.121z" clipRule="evenodd" />
            </svg>
            <div>
              <h3 className="text-lg font-bold text-white">Pre-Launch Offer</h3>
              <p className="text-sm text-white text-opacity-90">All plans include 25% pre-launch discount</p>
            </div>
          </div>
        </div>

        {/* Current subscription status */}
        {hasActiveSubscription && (
          <div className="mb-8 p-4 bg-gradient-to-r from-pink-500 to-purple-600 rounded-lg">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <svg className="w-6 h-6 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                </svg>
                <div>
                  <h3 className="text-lg font-bold text-white">Premium Active</h3>
                  <p className="text-sm text-white text-opacity-90">{getSubscriptionStatusText()}</p>
                </div>
              </div>
              <div className="flex space-x-2">
                <button
                  onClick={handleCancelSubscription}
                  disabled={isLoading}
                  className="px-4 py-2 bg-red-500 bg-opacity-20 text-red-300 rounded-lg hover:bg-opacity-30 transition-colors disabled:opacity-50"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Subscription Plans */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {/* Free Plan */}
          <div className="bg-white bg-opacity-10 backdrop-blur-lg rounded-xl p-6 border border-white border-opacity-20">
            <div className="flex items-center space-x-3 mb-4">
              <svg className="w-6 h-6 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M11.3 1.046A1 1 0 0112 2v5h4a1 1 0 01.82 1.573l-7 10A1 1 0 018 18v-5H4a1 1 0 01-.82-1.573l7-10a1 1 0 011.12-.38z" clipRule="evenodd" />
              </svg>
              <h3 className="text-xl font-bold text-white">Free</h3>
              <span className="text-gray-300">Forever</span>
            </div>
            
            <ul className="space-y-3 mb-6">
              {[
                'Browse public profiles',
                'View limited stories',
                'Basic search filters',
                'Create your profile',
                'Limited matches',
              ].map((feature, index) => (
                <li key={index} className="flex items-center space-x-3">
                  <svg className="w-5 h-5 text-green-400" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                  <span className="text-gray-300">{feature}</span>
                </li>
              ))}
            </ul>
            
            <button
              onClick={onClose}
              className="w-full py-3 bg-gray-500 bg-opacity-20 text-white rounded-lg hover:bg-opacity-30 transition-colors"
            >
              Start Free
            </button>
          </div>

          {/* Premium Plans */}
          {Object.entries(subscriptionPlans).map(([planType, plan]) => (
            <div
              key={planType}
              className={`bg-white bg-opacity-10 backdrop-blur-lg rounded-xl p-6 border-2 ${
                planType === '6_month' 
                  ? 'border-pink-500' 
                  : 'border-white border-opacity-20'
              }`}
            >
              {planType === '6_month' && (
                <div className="absolute -top-3 right-4 bg-pink-500 text-white px-3 py-1 rounded-full text-sm font-bold">
                  ★ Most Popular
                </div>
              )}
              
              <div className="flex items-center space-x-3 mb-4">
                <svg className="w-6 h-6 text-pink-500" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                </svg>
                <h3 className="text-xl font-bold text-white">{plan.name}</h3>
              </div>
              
              <div className="mb-4">
                <div className="flex items-baseline space-x-2">
                  <span className="text-3xl font-bold text-white">
                    ₹{(plan.price / 100).toFixed(2)}
                  </span>
                  <span className="text-lg text-gray-400 line-through">
                    ₹{((plan.price * 1.33) / 100).toFixed(2)}
                  </span>
                  <span className="bg-green-500 text-white px-2 py-1 rounded text-sm font-bold">
                    {planType === '1_month' ? '25%' : planType === '3_month' ? '50%' : '60%'} OFF
                  </span>
                </div>
              </div>
              
              <ul className="space-y-3 mb-6">
                {[
                  'Everything in Free',
                  'See who liked you',
                  'Priority visibility',
                  'Advanced filters',
                  'Read receipts',
                  'Unlimited matches',
                  'Super likes',
                  'Profile boost',
                ].map((feature, index) => (
                  <li key={index} className="flex items-center space-x-3">
                    <svg className="w-5 h-5 text-green-400" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                    </svg>
                    <span className="text-gray-300">{feature}</span>
                  </li>
                ))}
              </ul>
              
              <button
                onClick={() => handlePayment(planType)}
                disabled={isLoading}
                className="w-full py-3 bg-gradient-to-r from-pink-500 to-purple-600 text-white rounded-lg hover:from-pink-600 hover:to-purple-700 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isLoading ? 'Processing...' : 'Upgrade to Premium'}
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default SubscriptionPlans;
