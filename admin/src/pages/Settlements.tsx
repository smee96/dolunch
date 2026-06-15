import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api, type Settlement } from '../api/client'
import { PageHeader, Table, Tr, Td, Badge, Btn, Modal, Loading, won } from '../components/ui'

const ST: Record<string, { label: string; color: 'green' | 'yellow' | 'red' | 'gray' | 'blue' }> = {
  pending: { label: '영수증 대기', color: 'yellow' },
  receipt_uploaded: { label: '검토 필요', color: 'blue' },
  processing: { label: '지급 처리중', color: 'yellow' },
  paid: { label: '지급 완료', color: 'green' },
}

export default function Settlements() {
  const [statusFilter, setStatusFilter] = useState('')
  const [selected, setSelected] = useState<Settlement | null>(null)
  const [rejectReason, setRejectReason] = useState('')
  const [mode, setMode] = useState<'approve' | 'reject' | null>(null)
  const qc = useQueryClient()

  const { data, isLoading } = useQuery({
    queryKey: ['settlements', statusFilter],
    queryFn: () => api.settlements(statusFilter || undefined),
    refetchInterval: 15000,
  })

  const approveMut = useMutation({
    mutationFn: (id: string) => api.approveSettlement(id),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['settlements'] }); setSelected(null); setMode(null) },
  })
  const rejectMut = useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) => api.rejectSettlement(id, reason),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['settlements'] }); setSelected(null); setMode(null); setRejectReason('') },
  })
  const paidMut = useMutation({
    mutationFn: (id: string) => api.markPaid(id),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['settlements'] }); setSelected(null); setMode(null) },
  })

  return (
    <div>
      <PageHeader title="정산 관리" sub="영수증 검토 → 승인 → 지급 처리" />
      <div className="px-8 mb-4">
        <div className="flex gap-2">
          {[['', '전체'], ['pending', '영수증 대기'], ['receipt_uploaded', '검토 필요'], ['processing', '지급 처리중'], ['paid', '완료']].map(([v, l]) => (
            <button key={v} onClick={() => setStatusFilter(v)}
              className={`px-4 py-1.5 rounded-full text-xs font-bold border transition-colors
                ${statusFilter === v ? 'bg-gray-900 text-white border-gray-900' : 'bg-white text-gray-600 border-gray-200 hover:bg-gray-50'}`}>
              {l}
            </button>
          ))}
        </div>
      </div>

      <div className="px-8">
        <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
          {isLoading ? <Loading /> : (
            <Table heads={['모임', '호스트', '구분', '총 호스트 몫', '식당비', '순수익', '원천징수', '실지급', '상태', '']}>
              {data?.settlements.map((s) => {
                const st = ST[s.status] ?? { label: s.status, color: 'gray' as const }
                return (
                  <Tr key={s.id} onClick={() => setSelected(s)}>
                    <Td>
                      <div className="font-bold text-sm text-gray-900">{s.room_title}</div>
                      <div className="text-xs text-gray-400">{s.meet_at.slice(0, 10)} · {s.joined_count}명</div>
                    </Td>
                    <Td>
                      <div className="text-sm font-semibold">{s.host_name}</div>
                      <div className="text-xs font-mono text-gray-400">{s.host_handle}</div>
                    </Td>
                    <Td>{s.is_business ? <Badge label="사업자" color="blue" /> : <Badge label="개인" color="gray" />}</Td>
                    <Td><span className="font-bold">{won(s.gross_amount)}</span></Td>
                    <Td>{s.restaurant_cost != null ? won(s.restaurant_cost) : <span className="text-gray-300">미등록</span>}</Td>
                    <Td>{s.net_profit != null ? won(s.net_profit) : '—'}</Td>
                    <Td>{s.withholding_tax != null ? won(s.withholding_tax) : '—'}</Td>
                    <Td><span className="font-black text-green-700">{s.final_payout != null ? won(s.final_payout) : '—'}</span></Td>
                    <Td><Badge label={st.label} color={st.color} /></Td>
                    <Td>
                      {s.status === 'receipt_uploaded' && (
                        <div className="flex gap-1">
                          <Btn size="sm" variant="primary" onClick={(e?: React.MouseEvent) => { e?.stopPropagation(); setSelected(s); setMode('approve') }}>승인</Btn>
                          <Btn size="sm" variant="danger" onClick={(e?: React.MouseEvent) => { e?.stopPropagation(); setSelected(s); setMode('reject') }}>반려</Btn>
                        </div>
                      )}
                      {s.status === 'processing' && (
                        <Btn size="sm" variant="outline" onClick={(e?: React.MouseEvent) => { e?.stopPropagation(); paidMut.mutate(s.id) }}>지급완료</Btn>
                      )}
                    </Td>
                  </Tr>
                )
              })}
            </Table>
          )}
        </div>
      </div>

      {/* 영수증 확인 모달 */}
      <Modal open={!!selected && (mode === 'approve' || mode === 'reject')} onClose={() => { setSelected(null); setMode(null) }}
        title={mode === 'approve' ? '정산 승인' : '정산 반려'}>
        {selected && (
          <>
            <div className="bg-gray-50 rounded-xl p-4 mb-4 space-y-2">
              <div className="flex justify-between text-sm">
                <span className="text-gray-500">총 호스트 몫</span>
                <span className="font-bold">{won(selected.gross_amount)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-500">식당 결제 (영수증)</span>
                <span className="font-bold">{won(selected.restaurant_cost)}</span>
              </div>
              <div className="flex justify-between text-sm border-t border-gray-200 pt-2">
                <span className="text-gray-500">순수익</span>
                <span className="font-bold">{won(selected.net_profit)}</span>
              </div>
              {!selected.is_business && (
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">원천징수 (3.3%)</span>
                  <span className="font-bold text-red-500">-{won(selected.withholding_tax)}</span>
                </div>
              )}
              <div className="flex justify-between text-sm border-t border-gray-200 pt-2">
                <span className="font-bold text-gray-900">실지급액</span>
                <span className="font-black text-green-700 text-lg">{won(selected.final_payout)}</span>
              </div>
            </div>

            {selected.receipt_url && (
              <a href={selected.receipt_url} target="_blank" rel="noreferrer"
                className="block text-center text-sm text-blue-600 font-bold mb-4 hover:underline">
                📄 영수증 보기
              </a>
            )}

            {mode === 'reject' && (
              <>
                <label className="block text-xs font-bold text-gray-500 mb-2 uppercase tracking-wider">반려 사유</label>
                <textarea value={rejectReason} onChange={(e) => setRejectReason(e.target.value)} rows={2}
                  placeholder="영수증 재업로드 요청 등"
                  className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-red-300 resize-none mb-4" />
              </>
            )}

            <div className="flex gap-2 justify-end">
              <Btn variant="outline" onClick={() => { setSelected(null); setMode(null) }}>취소</Btn>
              {mode === 'approve' ? (
                <Btn variant="primary" disabled={approveMut.isPending} onClick={() => approveMut.mutate(selected.id)}>
                  {approveMut.isPending ? '처리 중…' : '승인 — 지급 처리'}
                </Btn>
              ) : (
                <Btn variant="danger" disabled={!rejectReason || rejectMut.isPending}
                  onClick={() => rejectMut.mutate({ id: selected.id, reason: rejectReason })}>
                  {rejectMut.isPending ? '처리 중…' : '반려 — 재등록 요청'}
                </Btn>
              )}
            </div>
          </>
        )}
      </Modal>
    </div>
  )
}
