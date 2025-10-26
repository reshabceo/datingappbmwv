import React from 'react'

type Props = React.ButtonHTMLAttributes<HTMLButtonElement> & { children: React.ReactNode }

export default function PinkGradientButton({ children, className = '', ...rest }: Props) {
  return (
    <button
      {...rest}
      className={`bg-gradient-cta text-white px-6 py-3 rounded-full font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-pink/60 ${className}`}
    >
      {children}
    </button>
  )
}


