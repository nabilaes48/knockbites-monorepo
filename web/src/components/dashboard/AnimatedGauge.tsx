import { useEffect, useState } from 'react'

interface AnimatedGaugeProps {
  value: number
  max: number
  label: string
  color?: 'blue' | 'purple' | 'emerald' | 'orange'
  size?: 'sm' | 'md' | 'lg'
}

export function AnimatedGauge({ value, max, label, color = 'blue', size = 'md' }: AnimatedGaugeProps) {
  const [animatedValue, setAnimatedValue] = useState(0)
  const percentage = (value / max) * 100

  useEffect(() => {
    const timer = setTimeout(() => {
      setAnimatedValue(value)
    }, 100)
    return () => clearTimeout(timer)
  }, [value])

  const sizes = {
    sm: { outer: 120, inner: 100, stroke: 8, text: 'text-2xl' },
    md: { outer: 160, inner: 136, stroke: 10, text: 'text-3xl' },
    lg: { outer: 200, inner: 172, stroke: 12, text: 'text-4xl' }
  }

  const colors = {
    blue: { gradient: 'from-blue-500 to-cyan-400', stroke: 'stroke-blue-500', glow: 'shadow-blue-500/50' },
    purple: { gradient: 'from-purple-500 to-pink-400', stroke: 'stroke-purple-500', glow: 'shadow-purple-500/50' },
    emerald: { gradient: 'from-emerald-500 to-green-400', stroke: 'stroke-emerald-500', glow: 'shadow-emerald-500/50' },
    orange: { gradient: 'from-orange-500 to-yellow-400', stroke: 'stroke-orange-500', glow: 'shadow-orange-500/50' }
  }

  const config = sizes[size]
  const colorConfig = colors[color]
  const circumference = 2 * Math.PI * (config.inner / 2)
  const strokeDashoffset = circumference - (percentage / 100) * circumference

  return (
    <div className="relative flex flex-col items-center gap-4">
      <div className="relative">
        <svg width={config.outer} height={config.outer} className="transform -rotate-90">
          {/* Background circle */}
          <circle
            cx={config.outer / 2}
            cy={config.outer / 2}
            r={config.inner / 2}
            fill="none"
            stroke="rgba(148, 163, 184, 0.1)"
            strokeWidth={config.stroke}
          />

          {/* Animated progress circle */}
          <circle
            cx={config.outer / 2}
            cy={config.outer / 2}
            r={config.inner / 2}
            fill="none"
            className={`${colorConfig.stroke} transition-all duration-1000 ease-out`}
            strokeWidth={config.stroke}
            strokeLinecap="round"
            strokeDasharray={circumference}
            strokeDashoffset={strokeDashoffset}
            style={{
              filter: 'drop-shadow(0 0 8px currentColor)'
            }}
          />
        </svg>

        {/* Center content */}
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <div className={`${config.text} font-bold text-white`}>
            {Math.round(animatedValue)}
          </div>
          <div className="text-xs text-slate-400 mt-1">
            of {max}
          </div>
        </div>

        {/* Glow effect */}
        <div className={`absolute inset-0 bg-gradient-to-br ${colorConfig.gradient} opacity-10 rounded-full blur-xl ${colorConfig.glow}`}></div>
      </div>

      {/* Label */}
      <div className="text-center">
        <div className="text-sm font-medium text-slate-300">{label}</div>
        <div className="text-xs text-slate-500 mt-1">{percentage.toFixed(1)}% Complete</div>
      </div>
    </div>
  )
}
