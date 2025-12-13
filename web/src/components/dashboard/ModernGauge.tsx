import { useEffect, useState } from 'react'

interface ModernGaugeProps {
  value: number
  max: number
  label: string
  size?: number
  colors?: [string, string] // [startColor, endColor] for gradient
  showPercentage?: boolean
}

export function ModernGauge({
  value,
  max,
  label,
  size = 180,
  colors = ['#10b981', '#06b6d4'], // emerald to cyan
  showPercentage = false
}: ModernGaugeProps) {
  const [animatedValue, setAnimatedValue] = useState(0)
  const percentage = Math.min((value / max) * 100, 100)
  const displayValue = showPercentage ? `${Math.round(percentage)}%` : value

  useEffect(() => {
    const timer = setTimeout(() => {
      setAnimatedValue(percentage)
    }, 100)
    return () => clearTimeout(timer)
  }, [percentage])

  const radius = (size - 24) / 2
  const circumference = 2 * Math.PI * radius
  const strokeDashoffset = circumference - (animatedValue / 100) * circumference

  // Create gradient ID
  const gradientId = `gauge-gradient-${Math.random().toString(36).substr(2, 9)}`

  return (
    <div className="relative inline-flex flex-col items-center gap-3">
      <svg width={size} height={size} className="transform -rotate-90">
        <defs>
          <linearGradient id={gradientId} x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor={colors[0]} />
            <stop offset="100%" stopColor={colors[1]} />
          </linearGradient>

          {/* Glow filter */}
          <filter id={`glow-${gradientId}`} x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation="4" result="coloredBlur"/>
            <feMerge>
              <feMergeNode in="coloredBlur"/>
              <feMergeNode in="SourceGraphic"/>
            </feMerge>
          </filter>
        </defs>

        {/* Background track - darker */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="rgba(148, 163, 184, 0.1)"
          strokeWidth="12"
        />

        {/* Progress arc with gradient and glow */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={`url(#${gradientId})`}
          strokeWidth="12"
          strokeLinecap="round"
          strokeDasharray={circumference}
          strokeDashoffset={strokeDashoffset}
          className="transition-all duration-1000 ease-out"
          filter={`url(#glow-${gradientId})`}
          style={{
            filter: 'drop-shadow(0 0 8px currentColor)'
          }}
        />

        {/* Inner glow circle */}
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius - 20}
          fill="none"
          stroke={colors[1]}
          strokeWidth="1"
          opacity="0.2"
        />
      </svg>

      {/* Center content */}
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <div className="text-xs text-slate-400 mb-1 font-medium">Total</div>
        <div className="text-4xl font-bold text-white tracking-tight">
          {displayValue}
        </div>
      </div>

      {/* Label below */}
      <div className="text-sm font-medium text-slate-300">{label}</div>
    </div>
  )
}
