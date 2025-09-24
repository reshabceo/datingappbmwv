import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.REACT_APP_SUPABASE_URL!,
  process.env.REACT_APP_SUPABASE_ANON_KEY!
);

export interface InvoiceData {
  orderId: string;
  paymentId: string;
  amount: number;
  planType: string;
  userEmail: string;
  userName: string;
  paymentDate: string;
  expiryDate: string;
}

export class InvoiceService {
  private static readonly RESEND_API_KEY = 're_Sq8YgMGg_Lc8v9StTD1gcs9SAbgzSaiK2';
  private static readonly FROM_EMAIL = 'noreply@datingappbmwv.com';
  private static readonly COMPANY_NAME = 'DatingApp BMWV';
  private static readonly COMPANY_LOGO = 'https://your-domain.com/logo.png'; // Update with your actual logo URL

  /**
   * Send invoice email to user after successful payment
   */
  static async sendInvoice(invoiceData: InvoiceData): Promise<boolean> {
    try {
      console.log('📧 Sending invoice email...', invoiceData);

      const htmlContent = this.generateInvoiceHTML(invoiceData);
      
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.RESEND_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: this.FROM_EMAIL,
          to: [invoiceData.userEmail],
          subject: `Payment Confirmation - ${this.COMPANY_NAME}`,
          html: htmlContent,
        }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        console.error('❌ Resend API Error:', errorData);
        return false;
      }

      const result = await response.json();
      console.log('✅ Invoice sent successfully:', result);
      return true;

    } catch (error) {
      console.error('❌ Failed to send invoice:', error);
      return false;
    }
  }

  /**
   * Generate beautiful HTML invoice based on your theme
   */
  private static generateInvoiceHTML(data: InvoiceData): string {
    const planNames = {
      '1_month': 'Premium 1 Month',
      '3_month': 'Premium 3 Months', 
      '6_month': 'Premium 6 Months'
    };

    const planName = planNames[data.planType as keyof typeof planNames] || data.planType;
    const amountInRupees = (data.amount / 100).toFixed(2);

    return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Payment Confirmation</title>
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
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                padding: 20px;
            }
            
            .invoice-container {
                max-width: 600px;
                margin: 0 auto;
                background: white;
                border-radius: 20px;
                box-shadow: 0 20px 40px rgba(0,0,0,0.1);
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
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
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
            
            @media (max-width: 600px) {
                .invoice-container {
                    margin: 10px;
                    border-radius: 15px;
                }
                
                .header, .content, .footer {
                    padding: 20px;
                }
                
                .features-grid {
                    grid-template-columns: 1fr;
                }
            }
        </style>
    </head>
    <body>
        <div class="invoice-container">
            <div class="header">
                <div class="logo">💕</div>
                <div class="company-name">${this.COMPANY_NAME}</div>
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
                            <div class="feature-icon">👀</div>
                            <span>See who liked you</span>
                        </div>
                        <div class="feature-item">
                            <div class="feature-icon">⭐</div>
                            <span>Priority visibility</span>
                        </div>
                        <div class="feature-item">
                            <div class="feature-icon">🔍</div>
                            <span>Advanced filters</span>
                        </div>
                        <div class="feature-item">
                            <div class="feature-icon">💬</div>
                            <span>Read receipts</span>
                        </div>
                        <div class="feature-item">
                            <div class="feature-icon">♾️</div>
                            <span>Unlimited matches</span>
                        </div>
                        <div class="feature-item">
                            <div class="feature-icon">💖</div>
                            <span>Super likes</span>
                        </div>
                        <div class="feature-item">
                            <div class="feature-icon">🚀</div>
                            <span>Profile boost</span>
                        </div>
                    </div>
                </div>
                
                <div class="divider"></div>
                
                <div style="text-align: center; color: #64748b; font-size: 14px;">
                    <p>Thank you for choosing ${this.COMPANY_NAME}! Your premium subscription is now active.</p>
                    <p>If you have any questions, please contact our support team.</p>
                </div>
            </div>
            
            <div class="footer">
                <div class="footer-links">
                    <a href="#">Support</a>
                    <a href="#">Privacy Policy</a>
                    <a href="#">Terms of Service</a>
                </div>
                
                <div class="social-links">
                    <a href="#">📱</a>
                    <a href="#">📧</a>
                    <a href="#">🌐</a>
                </div>
                
                <div class="divider"></div>
                
                <p style="font-size: 12px; opacity: 0.8;">
                    © 2024 ${this.COMPANY_NAME}. All rights reserved.<br>
                    This is an automated invoice. Please keep this for your records.
                </p>
            </div>
        </div>
    </body>
    </html>
    `;
  }

  /**
   * Send invoice after successful payment
   */
  static async sendPaymentInvoice(orderId: string, paymentId: string, amount: number, planType: string, userEmail: string, userName: string): Promise<boolean> {
    try {
      // Get order details from database
      const { data: orderData, error: orderError } = await supabase
        .from('payment_orders')
        .select('*')
        .eq('order_id', orderId)
        .single();

      if (orderError || !orderData) {
        console.error('❌ Failed to fetch order data:', orderError);
        return false;
      }

      // Get subscription details
      const { data: subscriptionData, error: subError } = await supabase
        .from('user_subscriptions')
        .select('end_date')
        .eq('order_id', orderId)
        .single();

      if (subError || !subscriptionData) {
        console.error('❌ Failed to fetch subscription data:', subError);
        return false;
      }

      const invoiceData: InvoiceData = {
        orderId: orderData.order_id,
        paymentId: paymentId,
        amount: amount,
        planType: planType,
        userEmail: userEmail,
        userName: userName,
        paymentDate: orderData.created_at,
        expiryDate: subscriptionData.end_date
      };

      return await this.sendInvoice(invoiceData);

    } catch (error) {
      console.error('❌ Failed to send payment invoice:', error);
      return false;
    }
  }
}
