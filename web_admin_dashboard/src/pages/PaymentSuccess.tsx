import React, { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { PaymentService } from '../services/paymentService';

export default function PaymentSuccess() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [status, setStatus] = useState<'processing' | 'success' | 'error'>('processing');
  const [message, setMessage] = useState('Processing your payment...');

  useEffect(() => {
    const orderId = searchParams.get('order_id');
    
    if (!orderId) {
      setStatus('error');
      setMessage('Invalid payment session');
      setTimeout(() => navigate('/plans'), 3000);
      return;
    }

    console.log('Payment success page loaded for order:', orderId);
    
    // Verify and process the payment
    const processPayment = async () => {
      try {
        setMessage('Verifying your payment...');
        
        // Wait a moment for Cashfree to process
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        // Try verification multiple times
        for (let attempt = 1; attempt <= 5; attempt++) {
          console.log(`Verification attempt ${attempt}/5 for order: ${orderId}`);
          
          const isPaid = await (PaymentService as any).verifyCashfreePayment(orderId);
          
          if (isPaid) {
            console.log('✅ Payment verified successfully!');
            setMessage('Payment successful! Creating your subscription...');
            
            // Process the payment success silently (no alerts from here)
            await (PaymentService as any).createSubscription(orderId);
            
            // Send invoice via handlePaymentSuccess (this will also update order status)
            console.log('🔍 Calling handlePaymentSuccess to send invoice...');
            await (PaymentService as any).handlePaymentSuccess({ payment_id: orderId }, orderId);
            
            setStatus('success');
            setMessage('Your premium subscription is now active!');
            
            // Redirect to home after 3 seconds
            setTimeout(() => navigate('/'), 3000);
            return;
          }
          
          if (attempt < 5) {
            setMessage(`Verifying payment... (${attempt}/5)`);
            await new Promise(resolve => setTimeout(resolve, 3000));
          }
        }
        
        // If we get here, verification failed
        setStatus('error');
        setMessage('Payment verification failed. Please contact support with order ID: ' + orderId);
        
      } catch (error) {
        console.error('Error processing payment:', error);
        setStatus('error');
        setMessage('Error processing payment. Please contact support.');
      }
    };

    processPayment();
  }, [searchParams, navigate]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-blue-900 to-indigo-900 flex items-center justify-center p-4">
      <div className="bg-white/10 backdrop-blur-md border border-white/20 rounded-2xl p-8 max-w-md w-full text-center">
        {status === 'processing' && (
          <>
            <div className="w-16 h-16 border-4 border-pink-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
            <h1 className="text-2xl font-bold text-white mb-4">Processing Payment</h1>
            <p className="text-light-white">{message}</p>
          </>
        )}
        
        {status === 'success' && (
          <>
            <div className="w-16 h-16 bg-green-500 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <h1 className="text-2xl font-bold text-white mb-4">Payment Successful!</h1>
            <p className="text-light-white">{message}</p>
            <p className="text-sm text-light-white mt-4">Redirecting to home page...</p>
          </>
        )}
        
        {status === 'error' && (
          <>
            <div className="w-16 h-16 bg-red-500 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg className="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </div>
            <h1 className="text-2xl font-bold text-white mb-4">Payment Issue</h1>
            <p className="text-light-white">{message}</p>
            <button
              onClick={() => navigate('/plans')}
              className="mt-4 px-6 py-2 bg-pink-500 text-white rounded-lg hover:bg-pink-600 transition-colors"
            >
              Back to Plans
            </button>
          </>
        )}
      </div>
    </div>
  );
}
