import React from 'react'

export function PageHeader({ title, sub }: { title: string; sub?: string }) {
  return (
    <div className="px-8 pt-8 pb-4">
      <h1 className="text-2xl font-black text-gray-900 tracking-tight">{title}</h1>
      {sub && <p className="text-sm text-gray-500 mt-1">{sub}</p>}
    </div>
  )
}

export function StatCard({ label, value, sub, accent }: { label: string; value: string | number; sub?: string; accent?: boolean }) {
  return (
    <div className={`bg-white rounded-2xl border p-5 ${accent ? 'border-rose-200 bg-rose-50' : 'border-gray-200'}`}>
      <div className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">{label}</div>
      <div className={`text-3xl font-black tracking-tight ${accent ? 'text-rose-600' : 'text-gray-900'}`}>{value}</div>
      {sub && <div className="text-xs text-gray-400 mt-1">{sub}</div>}
    </div>
  )
}

export function Badge({ label, color }: { label: string; color: 'green' | 'yellow' | 'red' | 'gray' | 'blue' }) {
  const cls = {
    green: 'bg-green-100 text-green-700',
    yellow: 'bg-yellow-100 text-yellow-700',
    red: 'bg-red-100 text-red-700',
    gray: 'bg-gray-100 text-gray-600',
    blue: 'bg-blue-100 text-blue-700',
  }[color]
  return <span className={`inline-block px-2 py-0.5 rounded-full text-xs font-bold ${cls}`}>{label}</span>
}

export function Table({ heads, children }: { heads: string[]; children: React.ReactNode }) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm text-left">
        <thead>
          <tr className="border-b border-gray-100">
            {heads.map((h) => (
              <th key={h} className="px-4 py-3 text-xs font-bold text-gray-400 uppercase tracking-wider whitespace-nowrap">{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>{children}</tbody>
      </table>
    </div>
  )
}

export function Tr({ children, onClick }: { children: React.ReactNode; onClick?: () => void }) {
  return (
    <tr onClick={onClick}
      className={`border-b border-gray-50 ${onClick ? 'cursor-pointer hover:bg-rose-50/30 transition-colors' : ''}`}>
      {children}
    </tr>
  )
}

export function Td({ children, mono }: { children: React.ReactNode; mono?: boolean }) {
  return <td className={`px-4 py-3 ${mono ? 'font-mono text-xs' : ''}`}>{children}</td>
}

export function Btn({
  children, onClick, variant = 'primary', size = 'md', disabled,
}: {
  children: React.ReactNode; onClick?: (e?: React.MouseEvent) => void
  variant?: 'primary' | 'danger' | 'ghost' | 'outline'; size?: 'sm' | 'md'; disabled?: boolean
}) {
  const base = 'inline-flex items-center font-bold rounded-lg transition-colors disabled:opacity-40'
  const sz = size === 'sm' ? 'px-3 py-1.5 text-xs' : 'px-4 py-2 text-sm'
  const v = {
    primary: 'bg-rose-500 hover:bg-rose-600 text-white',
    danger: 'bg-red-500 hover:bg-red-600 text-white',
    ghost: 'text-gray-500 hover:bg-gray-100',
    outline: 'border border-gray-200 text-gray-700 hover:bg-gray-50',
  }[variant]
  return <button onClick={onClick} disabled={disabled} className={`${base} ${sz} ${v}`}>{children}</button>
}

export function Input({ value, onChange, placeholder, className }: {
  value: string; onChange: (v: string) => void; placeholder?: string; className?: string
}) {
  return (
    <input value={value} onChange={(e) => onChange(e.target.value)} placeholder={placeholder}
      className={`border border-gray-200 rounded-lg px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-rose-300 ${className ?? ''}`}
    />
  )
}

export function Modal({ open, onClose, title, children }: {
  open: boolean; onClose: () => void; title: string; children: React.ReactNode
}) {
  if (!open) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-md mx-4 p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-black text-gray-900">{title}</h3>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 text-xl leading-none">×</button>
        </div>
        {children}
      </div>
    </div>
  )
}

export function Loading() {
  return <div className="flex items-center justify-center py-20 text-gray-400 text-sm">로딩 중...</div>
}

export function won(n: number | undefined | null) {
  if (n == null) return '—'
  return n.toLocaleString('ko-KR') + '원'
}
