import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
  'Access-Control-Max-Age': '86400',
}

interface InvoiceData {
  orderId: string;
  paymentId: string;
  amount: number;
  planType: string;
  userEmail: string;
  userName: string;
  paymentDate: string;
  expiryDate: string;
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { 
      status: 200,
      headers: corsHeaders 
    })
  }

  try {
    console.log('📄 PDF Invoice Edge Function called')
    
    const { orderId, paymentId, amount, planType, userEmail, userName, paymentDate, expiryDate } = await req.json()
    
    console.log('PDF Invoice data:', { orderId, paymentId, amount, planType, userEmail, userName })

    // Generate beautiful HTML invoice
    const htmlContent = generateInvoiceHTML({
      orderId,
      paymentId,
      amount,
      planType,
      userEmail,
      userName,
      paymentDate,
      expiryDate
    })

    // Return HTML content for browser to convert to PDF
    // Use proper UTF-8 encoding for Unicode characters
    const htmlBase64 = btoa(unescape(encodeURIComponent(htmlContent)))

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'HTML invoice generated successfully',
        htmlBase64: htmlBase64,
        filename: `invoice-${orderId}.html`
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('❌ PDF Invoice Edge Function Error:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})


function generateInvoiceHTML(data: InvoiceData): string {
  const planNames = {
    '1_month': 'Premium 1 Month',
    '3_month': 'Premium 3 Months', 
    '6_month': 'Premium 6 Months'
  }

  const planName = planNames[data.planType as keyof typeof planNames] || data.planType
  const amountInRupees = data.amount.toFixed(2)

  return `
  <!DOCTYPE html>
  <html lang="en">
  <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Payment Confirmation - ${data.orderId}</title>
      <style>
          * {
              margin: 0;
              padding: 0;
              box-sizing: border-box;
          }
          
          body {
              font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
              line-height: 1.6;
              color: #333;
              background: white;
              padding: 0;
          }
          
          .invoice-container {
              max-width: 800px;
              margin: 0 auto;
              background: white;
              border-radius: 20px;
              box-shadow: 0 10px 30px rgba(0,0,0,0.1);
              overflow: hidden;
          }
          
          .header {
              background: linear-gradient(135deg, #ec4899 0%, #be185d 100%);
              color: white;
              padding: 40px 30px;
              text-align: center;
              position: relative;
          }
          
          .header::before {
              content: '';
              position: absolute;
              top: 0;
              left: 0;
              right: 0;
              bottom: 0;
              background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grain" width="100" height="100" patternUnits="userSpaceOnUse"><circle cx="25" cy="25" r="1" fill="white" opacity="0.1"/><circle cx="75" cy="75" r="1" fill="white" opacity="0.1"/><circle cx="50" cy="10" r="0.5" fill="white" opacity="0.1"/></pattern></defs><rect width="100" height="100" fill="url(%23grain)"/></svg>');
              opacity: 0.3;
          }
          
          .logo {
              width: 80px;
              height: 80px;
              background: white;
              border-radius: 50%;
              margin: 0 auto 20px;
              display: flex;
              align-items: center;
              justify-content: center;
              font-size: 24px;
              font-weight: bold;
              color: #ec4899;
              position: relative;
              z-index: 1;
          }
          
          .company-name {
              font-size: 28px;
              font-weight: bold;
              margin-bottom: 10px;
              position: relative;
              z-index: 1;
          }
          
          .invoice-title {
              font-size: 18px;
              opacity: 0.9;
              position: relative;
              z-index: 1;
          }
          
          .content {
              padding: 40px 30px;
          }
          
          .success-icon {
              text-align: center;
              margin-bottom: 30px;
          }
          
          .success-icon .icon {
              width: 80px;
              height: 80px;
              background: linear-gradient(135deg, #10b981 0%, #059669 100%);
              border-radius: 50%;
              display: inline-flex;
              align-items: center;
              justify-content: center;
              font-size: 40px;
              color: white;
              margin-bottom: 20px;
          }
          
          .success-message {
              font-size: 24px;
              font-weight: bold;
              color: #10b981;
              text-align: center;
              margin-bottom: 30px;
          }
          
          .invoice-details {
              background: #f8fafc;
              border-radius: 15px;
              padding: 30px;
              margin-bottom: 30px;
          }
          
          .detail-row {
              display: flex;
              justify-content: space-between;
              align-items: center;
              padding: 15px 0;
              border-bottom: 1px solid #e2e8f0;
          }
          
          .detail-row:last-child {
              border-bottom: none;
          }
          
          .detail-label {
              font-weight: 600;
              color: #64748b;
          }
          
          .detail-value {
              font-weight: bold;
              color: #1e293b;
          }
          
          .amount-highlight {
              background: linear-gradient(135deg, #ec4899 0%, #be185d 100%);
              color: white;
              padding: 20px;
              border-radius: 15px;
              text-align: center;
              margin: 20px 0;
          }
          
          .amount-highlight .amount {
              font-size: 32px;
              font-weight: bold;
              margin-bottom: 5px;
          }
          
          .amount-highlight .currency {
              font-size: 16px;
              opacity: 0.9;
          }
          
          .features-list {
              background: #f1f5f9;
              border-radius: 15px;
              padding: 25px;
              margin: 30px 0;
          }
          
          .features-title {
              font-size: 18px;
              font-weight: bold;
              color: #1e293b;
              margin-bottom: 20px;
              text-align: center;
          }
          
          .features-grid {
              display: grid;
              grid-template-columns: 1fr 1fr;
              gap: 15px;
          }
          
          .feature-item {
              display: flex;
              align-items: center;
              padding: 10px;
              background: white;
              border-radius: 10px;
              box-shadow: 0 2px 4px rgba(0,0,0,0.05);
          }
          
          .feature-icon {
              width: 20px;
              height: 20px;
              background: #10b981;
              border-radius: 50%;
              display: flex;
              align-items: center;
              justify-content: center;
              margin-right: 10px;
              font-size: 12px;
              color: white;
          }
          
          .footer {
              background: #1e293b;
              color: white;
              padding: 30px;
              text-align: center;
          }
          
          .footer-links {
              margin: 20px 0;
          }
          
          .footer-links a {
              color: #ec4899;
              text-decoration: none;
              margin: 0 15px;
          }
          
          .footer-links a:hover {
              text-decoration: underline;
          }
          
          .social-links {
              margin: 20px 0;
          }
          
          .social-links a {
              display: inline-block;
              width: 40px;
              height: 40px;
              background: #ec4899;
              border-radius: 50%;
              margin: 0 10px;
              text-align: center;
              line-height: 40px;
              color: white;
              text-decoration: none;
              transition: transform 0.3s ease;
          }
          
          .social-links a:hover {
              transform: translateY(-2px);
          }
          
          .divider {
              height: 2px;
              background: linear-gradient(90deg, transparent, #ec4899, transparent);
              margin: 20px 0;
          }
          
          /* PDF specific styles */
          @media print {
              body {
                  background: white !important;
              }
              
              .invoice-container {
                  box-shadow: none !important;
                  border-radius: 0 !important;
              }
              
              .header {
                  page-break-inside: avoid;
              }
              
              .content {
                  page-break-inside: avoid;
              }
              
              .features-list {
                  page-break-inside: avoid;
              }
          }
      </style>
  </head>
  <body>
      <div class="invoice-container">
          <div class="header">
              <div class="logo">💕</div>
              <div class="company-name">DatingApp BMWV</div>
              <div class="invoice-title">Payment Confirmation</div>
          </div>
          
          <div class="content">
              <div class="success-icon">
                  <div class="icon">✓</div>
                  <div class="success-message">Payment Successful!</div>
              </div>
              
              <div class="invoice-details">
                  <div class="detail-row">
                      <span class="detail-label">Order ID:</span>
                      <span class="detail-value">${data.orderId}</span>
                  </div>
                  <div class="detail-row">
                      <span class="detail-label">Payment ID:</span>
                      <span class="detail-value">${data.paymentId}</span>
                  </div>
                  <div class="detail-row">
                      <span class="detail-label">Plan:</span>
                      <span class="detail-value">${planName}</span>
                  </div>
                  <div class="detail-row">
                      <span class="detail-label">Customer:</span>
                      <span class="detail-value">${data.userName}</span>
                  </div>
                  <div class="detail-row">
                      <span class="detail-label">Email:</span>
                      <span class="detail-value">${data.userEmail}</span>
                  </div>
                  <div class="detail-row">
                      <span class="detail-label">Payment Date:</span>
                      <span class="detail-value">${new Date(data.paymentDate).toLocaleDateString('en-IN', { 
                          year: 'numeric', 
                          month: 'long', 
                          day: 'numeric',
                          hour: '2-digit',
                          minute: '2-digit'
                      })}</span>
                  </div>
                  <div class="detail-row">
                      <span class="detail-label">Valid Until:</span>
                      <span class="detail-value">${new Date(data.expiryDate).toLocaleDateString('en-IN', { 
                          year: 'numeric', 
                          month: 'long', 
                          day: 'numeric'
                      })}</span>
                  </div>
              </div>
              
              <div class="amount-highlight">
                  <div class="amount">₹${amountInRupees}</div>
                  <div class="currency">Amount Paid</div>
              </div>
              
              <div class="features-list">
                  <div class="features-title">🎉 Premium Features Unlocked</div>
                  <div class="features-grid">
                      <div class="feature-item">
                          <div class="feature-icon">♾️</div>
                          <span>Unlimited matches</span>
                      </div>
                      <div class="feature-item">
                          <div class="feature-icon">💬</div>
                          <span>Sending messages in chat</span>
                      </div>
                      <div class="feature-item">
                          <div class="feature-icon">👀</div>
                          <span>See who likes you</span>
                      </div>
                      <div class="feature-item">
                          <div class="feature-icon">🔍</div>
                          <span>Advanced filters</span>
                      </div>
                      <div class="feature-item">
                          <div class="feature-icon">⭐</div>
                          <span>Priority visibility</span>
                      </div>
                      <div class="feature-item">
                          <div class="feature-icon">✓</div>
                          <span>Read receipts</span>
                      </div>
                      <div class="feature-item">
                          <div class="feature-icon">🛡️</div>
                          <span>Profile verification</span>
                      </div>
                      <div class="feature-item">
                          <div class="feature-icon">👑</div>
                          <span>VIP support</span>
                      </div>
                  </div>
              </div>
              
              <div class="divider"></div>
              
              <div style="text-align: center; color: #64748b; font-size: 14px; margin-bottom: 20px;">
                  <p>Thank you for choosing DatingApp BMWV! Your premium subscription is now active.</p>
                  <div style="margin-top: 20px;">
                      <a href="https://www.lovebug.live/" style="display: inline-block; background: linear-gradient(135deg, #ec4899 0%, #be185d 100%); color: white; padding: 12px 24px; border-radius: 25px; text-decoration: none; font-weight: bold; font-size: 16px; box-shadow: 0 4px 15px rgba(236, 72, 153, 0.3);">Visit Website</a>
                  </div>
              </div>
          </div>
          
          <div class="footer">
              <div class="footer-links">
                  <a href="https://www.lovebug.live/">Visit Website</a>
                  <a href="https://www.lovebug.live/">Support</a>
              </div>
              
              <div class="divider"></div>
              
              <p style="font-size: 12px; opacity: 0.8;">
                  © 2024 DatingApp BMWV. All rights reserved.<br>
                  This is an automated invoice. Please keep this for your records.
              </p>
          </div>
      </div>
  </body>
  </html>
  `
}
