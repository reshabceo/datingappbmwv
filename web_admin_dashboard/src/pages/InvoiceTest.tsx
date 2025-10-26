import React, { useState } from 'react';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://dkcitxzvojvecuvacwsp.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw'
);

const InvoiceTest: React.FC = () => {
  const [isLoading, setIsLoading] = useState(false);
  const [result, setResult] = useState<string>('');

  const testInvoice = async () => {
    setIsLoading(true);
    setResult('');

    try {
      const testData = {
        orderId: 'test-order-' + Date.now(),
        paymentId: 'pay_test_' + Date.now(),
        amount: 150000, // ₹1500 in paise
        planType: '1_month',
        userEmail: 'test@example.com',
        userName: 'Test User',
        paymentDate: new Date().toISOString(),
        expiryDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString() // 30 days from now
      };

      console.log('🧪 Testing invoice with data:', testData);
      
      // Call Edge Function to send invoice
      const { data, error } = await supabase.functions.invoke('send-invoice', {
        body: testData
      });
      
      if (error) {
        console.error('❌ Edge Function Error:', error);
        setResult('❌ Failed to send invoice: ' + error.message);
      } else {
        console.log('✅ Invoice sent successfully:', data);
        setResult('✅ Invoice sent successfully! Check the email inbox.');
      }
    } catch (error) {
      console.error('Invoice test error:', error);
      setResult('❌ Error: ' + (error as Error).message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-2xl mx-auto px-4">
        <div className="bg-white rounded-lg shadow-lg p-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-6 text-center">
            📧 Invoice Email Test
          </h1>
          
          <div className="space-y-6">
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
              <h3 className="font-semibold text-blue-900 mb-2">Test Details:</h3>
              <ul className="text-sm text-blue-800 space-y-1">
                <li>• Order ID: test-order-{Date.now()}</li>
                <li>• Amount: ₹1500.00</li>
                <li>• Plan: Premium 1 Month</li>
                <li>• Email: test@example.com</li>
                <li>• Using Resend API</li>
              </ul>
            </div>

            <button
              onClick={testInvoice}
              disabled={isLoading}
              className={`w-full py-3 px-6 rounded-lg font-semibold text-white transition-colors ${
                isLoading
                  ? 'bg-gray-400 cursor-not-allowed'
                  : 'bg-pink-600 hover:bg-pink-700'
              }`}
            >
              {isLoading ? '⏳ Sending Invoice...' : '📧 Send Test Invoice'}
            </button>

            {result && (
              <div className={`p-4 rounded-lg ${
                result.includes('✅') 
                  ? 'bg-green-50 border border-green-200 text-green-800' 
                  : 'bg-red-50 border border-red-200 text-red-800'
              }`}>
                {result}
              </div>
            )}

            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
              <h4 className="font-semibold text-yellow-900 mb-2">Note:</h4>
              <p className="text-sm text-yellow-800">
                This will send a real email using the Resend API. Make sure your API key is valid and the email address is accessible.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default InvoiceTest;
