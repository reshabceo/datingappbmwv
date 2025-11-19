// Welcome Email Service
// This service automatically processes welcome emails for OAuth users

import { supabase } from '../supabaseClient'
import { validateEmail } from '../utils/emailValidation'

export class WelcomeEmailService {
  private static isProcessing = false
  private static intervalId: NodeJS.Timeout | null = null

  // Start automatic processing of welcome emails
  static startProcessing() {
    if (this.isProcessing) return
    
    this.isProcessing = true
    console.log('Welcome email processing started')
    
    // Process immediately
    this.processWelcomeEmails()
    
    // Then process every 30 seconds
    this.intervalId = setInterval(() => {
      this.processWelcomeEmails()
    }, 30000) // 30 seconds
  }

  // Stop automatic processing
  static stopProcessing() {
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = null
    }
    this.isProcessing = false
    console.log('Welcome email processing stopped')
  }

  // Process pending welcome emails
  static async processWelcomeEmails() {
    try {
      // Get pending welcome emails
      const { data: pendingEmails, error: fetchError } = await supabase
        .from('welcome_email_queue')
        .select('*')
        .is('sent_at', null)
        .order('created_at', { ascending: true })
        .limit(5)

      if (fetchError) {
        console.error('Error fetching pending emails:', fetchError)
        return
      }

      if (!pendingEmails || pendingEmails.length === 0) {
        return // No pending emails
      }

      console.log(`Processing ${pendingEmails.length} welcome emails`)

      // Process each pending email
      for (const emailRecord of pendingEmails) {
        try {
          // Validate email before sending
          const emailValidation = validateEmail(emailRecord.email)
          if (!emailValidation.valid) {
            console.warn(`Skipping invalid email: ${emailRecord.email} - ${emailValidation.error}`)
            // Mark as failed to prevent retry
            await supabase
              .from('welcome_email_queue')
              .update({ 
                sent_at: new Date().toISOString(),
                error: `Invalid email: ${emailValidation.error}`
              })
              .eq('id', emailRecord.id)
            continue
          }

          await this.sendWelcomeEmail(emailRecord)
          
          // Mark as sent
          await supabase
            .from('welcome_email_queue')
            .update({ sent_at: new Date().toISOString() })
            .eq('id', emailRecord.id)
            
          console.log(`Welcome email sent to: ${emailRecord.email}`)
        } catch (error) {
          console.error(`Error sending welcome email to ${emailRecord.email}:`, error)
        }
      }
    } catch (error) {
      console.error('Error processing welcome emails:', error)
    }
  }

  // Send welcome email using the edge function
  private static async sendWelcomeEmail(emailRecord: any) {
    const response = await fetch('/functions/v1/send-welcome-email', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        user_id: emailRecord.user_id,
        email: emailRecord.email,
        name: emailRecord.name,
        signup_method: emailRecord.signup_method
      })
    })

    if (!response.ok) {
      throw new Error(`Failed to send welcome email: ${response.statusText}`)
    }

    return response.json()
  }

  // Manual trigger for testing
  static async triggerWelcomeEmail(userId: string, email: string, name: string, signupMethod: string) {
    // Validate email before sending
    const emailValidation = validateEmail(email)
    if (!emailValidation.valid) {
      throw new Error(`Invalid email: ${emailValidation.error}`)
    }

    try {
      const response = await fetch('/functions/v1/send-welcome-email', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          user_id: userId,
          email: email,
          name: name,
          signup_method: signupMethod
        })
      })

      if (!response.ok) {
        throw new Error(`Failed to send welcome email: ${response.statusText}`)
      }

      console.log('Welcome email sent successfully')
      return response.json()
    } catch (error) {
      console.error('Error sending welcome email:', error)
      throw error
    }
  }
}

