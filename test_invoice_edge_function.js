const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  'https://dkcitxzvojvecuvacwsp.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw'
);

async function testInvoiceEdgeFunction() {
  try {
    console.log('🧪 Testing Invoice Edge Function...');
    
    const testData = {
      orderId: 'test-order-' + Date.now(),
      paymentId: 'pay_test_' + Date.now(),
      amount: 150000, // ₹1500 in paise
      planType: '1_month',
      userEmail: 'test@example.com',
      userName: 'Test User',
      paymentDate: new Date().toISOString(),
      expiryDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString()
    };
    
    console.log('Test data:', testData);
    
    const { data, error } = await supabase.functions.invoke('send-invoice', {
      body: testData
    });
    
    if (error) {
      console.log('❌ Edge Function Error:', error.message);
      console.log('Error details:', error);
    } else {
      console.log('✅ Edge Function Success:', data);
    }
  } catch (err) {
    console.log('CATCH ERROR:', err.message);
  }
}

testInvoiceEdgeFunction();
