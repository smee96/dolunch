import { useQuery } from '@tanstack/react-query'
import { api } from '../api/client'
import { PageHeader, StatCard, won, Loading } from '../components/ui'
import RevenueChart from '../components/charts/RevenueChart'

export default function Dashboard() {
  const { data: stats, isLoading } = useQuery({ queryKey: ['stats'], queryFn: api.stats, refetchInterval: 30000 })
  const { data: rev } = useQuery({ queryKey: ['revenue-daily'], queryFn: api.revenueDaily })

  if (isLoading) return <Loading />

  const s = stats!
  return (
    <div>
      <PageHeader title="대시보드" sub={`마지막 갱신 ${new Date().toLocaleTimeString('ko-KR')}`} />

      {/* 핵심 지표 */}
      <div className="px-8 grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <StatCard label="오늘 수수료" value={won(s.revenue.today)} sub="플랫폼 수수료 30%" accent />
        <StatCard label="누적 수수료" value={won(s.revenue.total)} />
        <StatCard label="예치 보증금" value={won(s.deposits.held)} sub="환불 대기 포함" />
        <StatCard label="신규 가입" value={`+${s.users.newToday}명`} sub={`전체 ${s.users.total.toLocaleString()}명`} />
      </div>

      <div className="px-8 grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <StatCard label="진행중 모임" value={s.rooms.open} sub={`완료 ${s.rooms.done}건`} />
        <StatCard label="대기 지원" value={s.applications.pending} sub={`전체 ${s.applications.total}건`} />
        <StatCard label="정산 대기" value={s.settlements.pending} sub={`영수증 검토 ${s.settlements.receiptReady}건`}
          accent={s.settlements.receiptReady > 0} />
        <StatCard label="노쇼율" value={`${s.attendance.noShowRate}%`}
          sub={`노쇼 ${s.attendance.noShow} / 참석 ${s.attendance.attended}`}
          accent={s.attendance.noShowRate > 20} />
      </div>

      {/* 매출 차트 */}
      <div className="px-8 mb-8">
        <div className="bg-white rounded-2xl border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <div>
              <div className="text-base font-black text-gray-900">플랫폼 수수료 추이</div>
              <div className="text-xs text-gray-400 mt-0.5">최근 30일</div>
            </div>
          </div>
          {rev?.data ? <RevenueChart data={rev.data} /> : <div className="h-48 flex items-center justify-center text-gray-300 text-sm">데이터 없음</div>}
        </div>
      </div>

      {/* 알림 카드 */}
      {(s.settlements.receiptReady > 0 || s.applications.pending > 10) && (
        <div className="px-8 mb-8 space-y-3">
          <div className="text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">액션 필요</div>
          {s.settlements.receiptReady > 0 && (
            <div className="flex items-center gap-3 bg-amber-50 border border-amber-200 rounded-xl px-4 py-3">
              <span className="text-lg">📋</span>
              <div>
                <div className="text-sm font-bold text-amber-800">영수증 검토 대기 {s.settlements.receiptReady}건</div>
                <div className="text-xs text-amber-600">정산 → 영수증 검토에서 승인 처리하세요</div>
              </div>
              <a href="/settlements" className="ml-auto text-xs font-bold text-amber-700 hover:underline">이동 →</a>
            </div>
          )}
          {s.applications.pending > 10 && (
            <div className="flex items-center gap-3 bg-blue-50 border border-blue-200 rounded-xl px-4 py-3">
              <span className="text-lg">⏳</span>
              <div>
                <div className="text-sm font-bold text-blue-800">대기 지원 {s.applications.pending}건</div>
                <div className="text-xs text-blue-600">호스트가 미처리 중인 지원이 많습니다</div>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
