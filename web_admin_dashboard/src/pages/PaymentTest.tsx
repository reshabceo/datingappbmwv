import React, { useEffect, useState } from 'react'
import { PaymentService } from '../services/paymentService'

export default function PaymentTest() {
  const [isLoading, setIsLoading] = useState(false)

  useEffect(() => {
    const init = async () => {
      try {
        await PaymentService.initialize()
        console.log('Payment service initialized')
      } catch (error) {
        console.error('Failed to initialize payment service:', error)
      }
    }
    init()
  }, [])

  const testPayment = async () => {
    try {
      setIsLoading(true)
      await PaymentService.initiatePayment('1_month', 'test@example.com', 'Test User')
    } catch (error) {
      console.error('Payment failed:', error)
      alert('Payment failed: ' + error.message)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gray-900 flex items-center justify-center">
      <div className="bg-white p-8 rounded-lg shadow-lg">
        <h1 className="text-2xl font-bold mb-4">Payment Test</h1>
        <button
          onClick={testPayment}
          disabled={isLoading}
          className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 disabled:opacity-50"
        >
          {isLoading ? 'Processing...' : 'Test 1 Month Payment (₹15)'}
        </button>
      </div>
    </div>
  )
}
