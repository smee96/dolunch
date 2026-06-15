import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api, type Room } from '../api/client'
import { PageHeader, Table, Tr, Td, Badge, Btn, Input, Modal, Loading, won, kst } from '../components/ui'

const STATUS_LABEL: Record<string, { label: string; color: 'green' | 'yellow' | 'red' | 'gray' | 'blue' }> = {
  open: { label: '모집중', color: 'green' },
  full: { label: '정원마감', color: 'yellow' },
  done: { label: '완료', color: 'gray' },
  cancelled: { label: '취소됨', color: 'red' },
}

export default function Rooms() {
  const [q, setQ] = useState('')
  const [status, setStatus] = useState('')
  const [target, setTarget] = useState<Room | null>(null)
  const [reason, setReason] = useState('')
  const qc = useQueryClient()

  const { data, isLoading } = useQuery({
    queryKey: ['rooms', q, status],
    queryFn: () => api.rooms({ q, status }),
  })

  const cancelMut = useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) => api.cancelRoom(id, reason),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['rooms'] }); setTarget(null); setReason('') },
  })

  return (
    <div>
      <PageHeader title="모임 관리" />
      <div className="px-8 mb-4 flex gap-3 items-center flex-wrap">
        <Input value={q} onChange={setQ} placeholder="방 제목 / 장소 검색" className="w-64" />
        <select value={status} onChange={(e) => setStatus(e.target.value)}
          className="border border-gray-200 rounded-lg px-3 py-2 text-sm outline-none">
          <option value="">전체 상태</option>
          <option value="open">모집중</option>
          <option value="full">정원마감</option>
          <option value="done">완료</option>
          <option value="cancelled">취소됨</option>
        </select>
      </div>

      <div className="px-8">
        <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
          {isLoading ? <Loading /> : (
            <Table heads={['방 제목', '호스트', '일시', '인원', '1인 금액', '플랫폼 수수료', '상태', '']}>
              {data?.rooms.map((r) => {
                const st = STATUS_LABEL[r.status] ?? { label: r.status, color: 'gray' as const }
                return (
                  <Tr key={r.id}>
                    <Td>
                      <div className="font-bold text-gray-900 text-sm">{r.title}</div>
                      <div className="text-xs text-gray-400">{r.place_name}</div>
                    </Td>
                    <Td><span className="text-xs font-mono">{r.host_handle ?? r.host_name}</span></Td>
                    <Td><div className="text-xs">{kst(r.meet_at)}</div></Td>
                    <Td>
                      <div className="text-sm">
                        <span className="font-bold">{r.joined_count}</span>
                        <span className="text-gray-400">/{r.capacity}</span>
                      </div>
                    </Td>
                    <Td><span className="font-bold text-sm">{won(r.price_per_person)}</span></Td>
                    <Td><span className="font-bold text-rose-600">{won(r.platform_fee * r.joined_count)}</span></Td>
                    <Td><Badge label={st.label} color={st.color} /></Td>
                    <Td>
                      {r.status !== 'done' && r.status !== 'cancelled' && (
                        <Btn size="sm" variant="danger" onClick={() => setTarget(r)}>강제취소</Btn>
                      )}
                    </Td>
                  </Tr>
                )
              })}
            </Table>
          )}
        </div>
      </div>

      <Modal open={!!target} onClose={() => { setTarget(null); setReason('') }} title="모임 강제 취소">
        {target && (
          <>
            <div className="bg-red-50 rounded-xl p-4 mb-4 text-sm text-red-700">
              <strong>{target.title}</strong>을 취소하면 모든 게스트에게 자동 환불됩니다.
            </div>
            <label className="block text-xs font-bold text-gray-500 mb-2 uppercase tracking-wider">취소 사유 (게스트에게 전달)</label>
            <textarea value={reason} onChange={(e) => setReason(e.target.value)} rows={3}
              placeholder="취소 사유를 입력하세요"
              className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-red-300 resize-none mb-4" />
            <div className="flex gap-2 justify-end">
              <Btn variant="outline" onClick={() => { setTarget(null); setReason('') }}>취소</Btn>
              <Btn variant="danger" disabled={!reason || cancelMut.isPending}
                onClick={() => cancelMut.mutate({ id: target.id, reason })}>
                {cancelMut.isPending ? '처리 중…' : '확인 — 전액 환불'}
              </Btn>
            </div>
          </>
        )}
      </Modal>
    </div>
  )
}
