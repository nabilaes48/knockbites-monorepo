import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts'

interface DonutData {
  name: string
  value: number
  color: string
}

interface Modern3DDonutProps {
  data: DonutData[]
  title?: string
  subtitle?: string
  centerValue?: string | number
  size?: number
}

export function Modern3DDonut({
  data,
  title,
  subtitle,
  centerValue,
  size = 300
}: Modern3DDonutProps) {
  // Calculate total and percentages
  const total = data.reduce((sum, item) => sum + item.value, 0)

  const renderCustomLabel = (entry: any) => {
    const percent = ((entry.value / total) * 100).toFixed(0)
    return `${percent}%`
  }

  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload
      const percent = ((data.value / total) * 100).toFixed(1)
      return (
        <div className="bg-slate-900/95 backdrop-blur-sm border border-slate-700 rounded-lg px-4 py-3 shadow-xl">
          <div className="flex items-center gap-2 mb-1">
            <div
              className="w-3 h-3 rounded-full"
              style={{ backgroundColor: data.color }}
            />
            <p className="text-sm font-medium text-white">{data.name}</p>
          </div>
          <p className="text-lg font-bold text-white">{data.value}</p>
          <p className="text-xs text-slate-400">{percent}% of total</p>
        </div>
      )
    }
    return null
  }

  const renderLegend = (props: any) => {
    const { payload } = props
    return (
      <div className="flex flex-col gap-2 mt-4">
        {payload.map((entry: any, index: number) => {
          const percent = ((entry.payload.value / total) * 100).toFixed(1)
          return (
            <div
              key={`legend-${index}`}
              className="flex items-center justify-between px-3 py-2 rounded-lg bg-slate-800/30 hover:bg-slate-800/50 transition-colors"
            >
              <div className="flex items-center gap-3">
                <div
                  className="w-3 h-3 rounded-full shadow-lg"
                  style={{
                    backgroundColor: entry.color,
                    boxShadow: `0 0 10px ${entry.color}40`
                  }}
                />
                <span className="text-sm text-slate-200 font-medium">
                  {entry.value}
                </span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-sm font-medium text-white">
                  {entry.payload.value}
                </span>
                <span className="text-xs text-slate-400">
                  ({percent}%)
                </span>
              </div>
            </div>
          )
        })}
      </div>
    )
  }

  return (
    <div className="w-full">
      {(title || subtitle) && (
        <div className="mb-6">
          {title && (
            <h3 className="text-xl font-bold text-white mb-1">{title}</h3>
          )}
          {subtitle && (
            <p className="text-sm text-slate-400">{subtitle}</p>
          )}
        </div>
      )}

      <div className="relative">
        <ResponsiveContainer width="100%" height={size}>
          <PieChart>
            <defs>
              {data.map((entry, index) => (
                <linearGradient
                  key={`gradient-${index}`}
                  id={`gradient-${index}`}
                  x1="0"
                  y1="0"
                  x2="0"
                  y2="1"
                >
                  <stop
                    offset="5%"
                    stopColor={entry.color}
                    stopOpacity={1}
                  />
                  <stop
                    offset="95%"
                    stopColor={entry.color}
                    stopOpacity={0.7}
                  />
                </linearGradient>
              ))}

              {/* 3D shadow effect */}
              <filter id="shadow3d" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur in="SourceAlpha" stdDeviation="3"/>
                <feOffset dx="0" dy="4" result="offsetblur"/>
                <feComponentTransfer>
                  <feFuncA type="linear" slope="0.3"/>
                </feComponentTransfer>
                <feMerge>
                  <feMergeNode/>
                  <feMergeNode in="SourceGraphic"/>
                </feMerge>
              </filter>
            </defs>

            <Pie
              data={data}
              cx="50%"
              cy="50%"
              innerRadius="60%"
              outerRadius="85%"
              paddingAngle={2}
              dataKey="value"
              label={renderCustomLabel}
              labelLine={false}
              filter="url(#shadow3d)"
              animationBegin={0}
              animationDuration={800}
              animationEasing="ease-out"
            >
              {data.map((entry, index) => (
                <Cell
                  key={`cell-${index}`}
                  fill={`url(#gradient-${index})`}
                  stroke="rgba(15, 23, 42, 0.8)"
                  strokeWidth={3}
                  style={{
                    filter: `drop-shadow(0 4px 8px ${entry.color}40)`,
                    cursor: 'pointer'
                  }}
                />
              ))}
            </Pie>
            <Tooltip content={<CustomTooltip />} />
            <Legend content={renderLegend} />
          </PieChart>
        </ResponsiveContainer>

        {/* Center value overlay */}
        {centerValue && (
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
            <div className="text-center">
              <div className="text-3xl font-bold text-white">
                {centerValue}
              </div>
              <div className="text-xs text-slate-400 mt-1">
                Total
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
