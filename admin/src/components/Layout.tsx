import { Link, useLocation } from 'react-router-dom'

const NAV = [
  { to: '/', label: '대시보드', icon: '📊' },
  { to: '/users', label: '유저 관리', icon: '👤' },
  { to: '/rooms', label: '모임 관리', icon: '🍽' },
  { to: '/settlements', label: '정산 관리', icon: '💰' },
  { to: '/payments', label: '결제 로그', icon: '🧾' },
]

export default function Layout({ children }: { children: React.ReactNode }) {
  const loc = useLocation()

  return (
    <div className="flex min-h-screen bg-gray-50">
      {/* 사이드바 */}
      <aside className="w-56 bg-white border-r border-gray-200 flex flex-col">
        <div className="px-5 py-5 border-b border-gray-100">
          <div className="text-lg font-black text-gray-900 tracking-tight">점심어때</div>
          <div className="text-xs text-gray-400 mt-0.5 font-mono">ADMIN</div>
        </div>
        <nav className="flex-1 py-4 px-3">
          {NAV.map(({ to, label, icon }) => {
            const active = to === '/' ? loc.pathname === '/' : loc.pathname.startsWith(to)
            return (
              <Link key={to} to={to}
                className={`flex items-center gap-2.5 px-3 py-2.5 rounded-lg mb-1 text-sm font-semibold transition-colors
                  ${active ? 'bg-rose-50 text-rose-600' : 'text-gray-600 hover:bg-gray-100'}`}>
                <span>{icon}</span>
                {label}
              </Link>
            )
          })}
        </nav>
        <div className="px-4 py-4 border-t border-gray-100">
          <button onClick={() => { localStorage.removeItem('admin_token'); window.location.href = '/login' }}
            className="text-xs text-gray-400 hover:text-gray-700 transition-colors">
            로그아웃
          </button>
        </div>
      </aside>

      {/* 본문 */}
      <main className="flex-1 overflow-auto">
        {children}
      </main>
    </div>
  )
}
