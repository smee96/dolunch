import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api, type PaymentLog } from '../api/client'
import { PageHeader, Table, Tr, Td, Badge, Btn, Modal, Input, Loading, won } from '../components/ui'

const TYPE_COLOR: Record<string, 'green' | 'yellow' | 'red' | 'gray' | 'blue'> = {
  deposit: 'yellow', main: 'green', refund: 'red', deduction: 'gray',
}
const TYPE_LABEL: Record<string, string> = {
  deposit: '보증금', main: '본결제', refund: '환불', deduction: '차감',
}

export default function Payments() {
  const [typeFilter, setTypeFilter] = useState('')
  const [refundModal, setRefundModal] = useState<PaymentLog | null>(null)
  const [refundAmount, setRefundAmount] = useState('')
  const [refundReason, setRefundReason] = useState('')
  const qc = useQueryClient()

  const { data, isLoading } = useQuery({
    queryKey: ['payments', typeFilter],
    queryFn: () => api.payments(typeFilter || undefined),
    refetchInterval: 20000,
  })

  const refundMut = useMutation({
    mutationFn: ({ paymentKey, amount, reason }: { paymentKey: string; amount: number; reason: string }) =>
      api.refund(paymentKey, amount, reason),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['payments'] })
      setRefundModal(null); setRefundAmount(''); setRefundReason('')
    },
  })

  return (
    <div>
      <PageHeader title="결제 로그" sub="Toss 결제 내역 및 수동 환불 처리" />
      <div className="px-8 mb-4 flex gap-2">
        {[['', '전체'], ['deposit', '보증금'], ['main', '본결제'], ['refund', '환불'], ['deduction', '차감']].map(([v, l]) => (
          <button key={v} onClick={() => setTypeFilter(v)}
            className={`px-4 py-1.5 rounded-full text-xs font-bold border transition-colors
              ${typeFilter === v ? 'bg-gray-900 text-white border-gray-900' : 'bg-white text-gray-600 border-gray-200 hover:bg-gray-50'}`}>
            {l}
          </button>
        ))}
      </div>

      <div className="px-8">
        <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
          {isLoading ? <Loading /> : (
            <Table heads={['결제 시각', '유형', '금액', 'Toss 상태', 'Payment Key', 'Order ID', '']}>
              {data?.payments.map((p) => (
                <Tr key={p.id}>
                  <Td><span className="text-xs text-gray-500 font-mono">{p.created_at.slice(0, 16).replace('T', ' ')}</span></Td>
                  <Td><Badge label={TYPE_LABEL[p.type] ?? p.type} color={TYPE_COLOR[p.type] ?? 'gray'} /></Td>
                  <Td><span className={`font-bold ${p.type === 'refund' ? 'text-red-500' : 'text-gray-900'}`}>{won(p.amount)}</span></Td>
                  <Td><span className="text-xs font-mono text-gray-600">{p.status}</span></Td>
                  <Td><span className="text-xs font-mono text-gray-400 max-w-32 truncate block">{p.payment_key}</span></Td>
                  <Td><span className="text-xs font-mono text-gray-400">{p.order_id}</span></Td>
                  <Td>
                    {p.type !== 'refund' && (
                      <Btn size="sm" variant="ghost" onClick={() => setRefundModal(p)}>환불</Btn>
                    )}
                  </Td>
                </Tr>
              ))}
            </Table>
          )}
        </div>
      </div>

      <Modal open={!!refundModal} onClose={() => { setRefundModal(null); setRefundAmount(''); setRefundReason('') }} title="수동 환불">
        {refundModal && (
          <>
            <div className="bg-gray-50 rounded-xl p-4 mb-4 text-sm space-y-1">
              <div className="flex justify-between">
                <span className="text-gray-500">결제키</span>
                <span className="font-mono text-xs">{refundModal.payment_key.slice(0, 20)}…</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">원래 금액</span>
                <span className="font-bold">{won(refundModal.amount)}</span>
              </div>
            </div>
            <div className="space-y-3 mb-4">
              <div>
                <label className="block text-xs font-bold text-gray-500 mb-1.5 uppercase tracking-wider">환불 금액 (원)</label>
                <Input value={refundAmount} onChange={setRefundAmount} placeholder={String(refundModal.amount)} className="w-full" />
              </div>
              <div>
                <label className="block text-xs font-bold text-gray-500 mb-1.5 uppercase tracking-wider">환불 사유</label>
                <textarea value={refundReason} onChange={(e) => setRefundReason(e.target.value)} rows={2}
                  className="w-full border border-gray-200 rounded-xl px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-red-300 resize-none"
                  placeholder="환불 사유를 입력하세요" />
              </div>
            </div>
            <div className="flex gap-2 justify-end">
              <Btn variant="outline" onClick={() => { setRefundModal(null); setRefundAmount(''); setRefundReason('') }}>취소</Btn>
              <Btn variant="danger"
                disabled={!refundReason || !refundAmount || refundMut.isPending}
                onClick={() => refundMut.mutate({
                  paymentKey: refundModal.payment_key,
                  amount: Number(refundAmount),
                  reason: refundReason,
                })}>
                {refundMut.isPending ? '처리 중…' : `${Number(refundAmount || 0).toLocaleString()}원 환불`}
              </Btn>
            </div>
          </>
        )}
      </Modal>
    </div>
  )
}
