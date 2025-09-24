const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  'https://dkcitxzvojvecuvacwsp.supabase.co',
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw'
);

async function testPDFGeneration() {
  try {
    console.log('🧪 Testing PDF Generation Edge Function...');
    
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
    
    const { data, error } = await supabase.functions.invoke('generate-invoice-pdf', {
      body: testData
    });
    
    if (error) {
      console.log('❌ Edge Function Error:', error.message);
      console.log('Error details:', error);
    } else {
      console.log('✅ Edge Function Success:', data);
      if (data?.success) {
        console.log('📄 PDF generated successfully!');
        console.log('Filename:', data.filename);
        console.log('PDF size:', data.pdfBase64 ? data.pdfBase64.length : 'N/A');
      }
    }
  } catch (err) {
    console.log('CATCH ERROR:', err.message);
  }
}

testPDFGeneration();
