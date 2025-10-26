import React from 'react'

export default function WizardShell({ step, total = 6, children }: { step: number; total?: number; children: React.ReactNode }) {
  const percent = Math.round((step / total) * 100)
  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <div className="w-full max-w-xl">
        <div className="rounded-2xl p-8 bg-gradient-card-pink border border-pink-30 backdrop-blur-md shadow-card-soft">
          <div className="mb-6">
            <h2 className="text-2xl md:text-3xl font-bold text-white">Complete Your Profile</h2>
            <div className="mt-2 text-light-white">Step {step} of {total}</div>
            <div className="mt-3 h-2 w-full bg-white/10 rounded-full overflow-hidden">
              <div className="h-full bg-light-pink" style={{ width: `${percent}%` }} />
            </div>
          </div>
          {children}
        </div>
      </div>
    </div>
  )
}


