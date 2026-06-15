import { useState } from 'react'
import { useNavigate } from 'react-router-dom'

export default function Login() {
  const [token, setToken] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const nav = useNavigate()

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      const res = await fetch(`${import.meta.env.VITE_API_URL ?? 'http://localhost:8787'}/admin/stats`, {
        headers: { 'X-Admin-Token': token },
      })
      if (!res.ok) throw new Error('토큰이 올바르지 않습니다')
      localStorage.setItem('admin_token', token)
      nav('/')
    } catch (e: unknown) {
      setError((e as Error).message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-orange-400 via-rose-500 to-purple-700">
      <div className="bg-white rounded-3xl shadow-2xl w-full max-w-sm mx-4 p-8">
        <div className="text-center mb-8">
          <div className="text-2xl font-black text-gray-900 tracking-tight">점심어때</div>
          <div className="text-xs text-gray-400 mt-1 font-mono tracking-widest">ADMIN CONSOLE</div>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-bold text-gray-500 mb-1.5 uppercase tracking-wider">Admin Token</label>
            <input
              type="password"
              value={token}
              onChange={(e) => setToken(e.target.value)}
              placeholder="토큰을 입력하세요"
              className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-rose-300 font-mono"
              autoFocus
            />
          </div>
          {error && <p className="text-red-500 text-xs font-semibold">{error}</p>}
          <button type="submit" disabled={!token || loading}
            className="w-full py-3 rounded-xl bg-gradient-to-r from-orange-400 via-rose-500 to-rose-600 text-white font-bold text-sm disabled:opacity-50 transition-opacity">
            {loading ? '확인 중...' : '로그인'}
          </button>
        </form>
      </div>
    </div>
  )
}
