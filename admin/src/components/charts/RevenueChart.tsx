import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts'
import { type DailyRevenue } from '../../api/client'

const fmt = (v: number) => (v / 10000).toFixed(0) + '만'

export default function RevenueChart({ data }: { data: DailyRevenue[] }) {
  return (
    <ResponsiveContainer width="100%" height={200}>
      <AreaChart data={data} margin={{ top: 4, right: 4, bottom: 0, left: 0 }}>
        <defs>
          <linearGradient id="rv" x1="0" y1="0" x2="0" y2="1">
            <stop offset="10%" stopColor="#F0457E" stopOpacity={0.25} />
            <stop offset="95%" stopColor="#F0457E" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke="#f0e6e6" />
        <XAxis dataKey="day" tick={{ fontSize: 10, fill: '#9B7E89' }} tickFormatter={(d: string) => d.slice(5)} />
        <YAxis tick={{ fontSize: 10, fill: '#9B7E89' }} tickFormatter={fmt} width={36} />
        <Tooltip
          formatter={(v) => [Number(v).toLocaleString() + '원', '플랫폼 수수료']}
          labelStyle={{ fontSize: 11 }} contentStyle={{ borderRadius: 10, border: '1px solid #F0E6E6', fontSize: 12 }}
        />
        <Area type="monotone" dataKey="revenue" stroke="#F0457E" strokeWidth={2} fill="url(#rv)" />
      </AreaChart>
    </ResponsiveContainer>
  )
}
