import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { adminLogin } from '../api/client'

export default function Login() {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const nav = useNavigate()

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError('')
    try {
      const token = await adminLogin(username, password)
      localStorage.setItem('admin_token', token)
      nav('/')
    } catch (err: unknown) {
      setError((err as Error).message)
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
            <label className="block text-xs font-bold text-gray-500 mb-1.5 uppercase tracking-wider">아이디</label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="admin"
              className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-rose-300"
              autoFocus
              autoComplete="username"
            />
          </div>
          <div>
            <label className="block text-xs font-bold text-gray-500 mb-1.5 uppercase tracking-wider">비밀번호</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm outline-none focus:ring-2 focus:ring-rose-300"
              autoComplete="current-password"
            />
          </div>
          {error && <p className="text-red-500 text-xs font-semibold bg-red-50 rounded-lg px-3 py-2">{error}</p>}
          <button
            type="submit"
            disabled={!username || !password || loading}
            className="w-full py-3 rounded-xl bg-gradient-to-r from-orange-400 via-rose-500 to-rose-600 text-white font-bold text-sm disabled:opacity-50 transition-opacity mt-2"
          >
            {loading ? '로그인 중...' : '로그인'}
          </button>
        </form>
      </div>
    </div>
  )
}
