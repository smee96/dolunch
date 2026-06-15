import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api, type AdminUser } from '../api/client'
import { PageHeader, Table, Tr, Td, Badge, Btn, Input, Modal, Loading, won, kst } from '../components/ui'

function userBadge(u: AdminUser) {
  if (u.is_business) return <Badge label="사업자" color="blue" />
  return <Badge label="개인" color="gray" />
}

export default function Users() {
  const [q, setQ] = useState('')
  const [sort, setSort] = useState('created_at')
  const [selected, setSelected] = useState<AdminUser | null>(null)
  const qc = useQueryClient()

  const { data, isLoading } = useQuery({
    queryKey: ['users', q, sort],
    queryFn: () => api.users({ q, sort }),
  })

  const patchMut = useMutation({
    mutationFn: ({ id, body }: { id: string; body: Partial<AdminUser> }) => api.patchUser(id, body),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['users'] }); setSelected(null) },
  })

  return (
    <div>
      <PageHeader title="유저 관리" sub={`전체 ${data?.total ?? '…'}명`} />
      <div className="px-8 mb-4 flex gap-3 items-center">
        <Input value={q} onChange={setQ} placeholder="이름 / 핸들 / 전화번호 검색" className="w-72" />
        <select value={sort} onChange={(e) => setSort(e.target.value)}
          className="border border-gray-200 rounded-lg px-3 py-2 text-sm outline-none">
          <option value="created_at">최근 가입순</option>
          <option value="hosting_count">호스팅 많은순</option>
          <option value="follower_count">팔로워 많은순</option>
          <option value="rating">평점 높은순</option>
        </select>
      </div>

      <div className="px-8">
        <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
          {isLoading ? <Loading /> : (
            <Table heads={['이름', '핸들', '연락처', '구분', '호스팅', '평점', '누적 결제', '가입일', '']}>
              {data?.users.map((u) => (
                <Tr key={u.id} onClick={() => setSelected(u)}>
                  <Td><span className="font-bold text-gray-900">{u.name}</span></Td>
                  <Td><span className="text-xs font-mono text-gray-500">{u.handle}</span></Td>
                  <Td><span className="font-mono text-xs">{u.phone ?? '카카오'}</span></Td>
                  <Td>{userBadge(u)}</Td>
                  <Td><span className="font-bold">{u.hosting_count}</span>회</Td>
                  <Td>⭐ {u.rating.toFixed(1)}</Td>
                  <Td>{won(u.total_spent)}</Td>
                  <Td><span className="text-xs text-gray-400">{kst(u.created_at, { hour: undefined, minute: undefined })}</span></Td>
                  <Td>
                    <Btn size="sm" variant="ghost" onClick={(e?: React.MouseEvent) => { e?.stopPropagation(); setSelected(u) }}>상세</Btn>
                  </Td>
                </Tr>
              ))}
            </Table>
          )}
        </div>
      </div>

      <UserModal
        user={selected}
        onClose={() => setSelected(null)}
        onSave={(id, body) => patchMut.mutate({ id, body })}
        saving={patchMut.isPending}
      />
    </div>
  )
}

function UserModal({ user, onClose, onSave, saving }: {
  user: AdminUser | null; onClose: () => void
  onSave: (id: string, body: Partial<AdminUser>) => void; saving: boolean
}) {
  const [isBiz, setIsBiz] = useState(0)
  const [bizNo, setBizNo] = useState('')

  const { data, isLoading } = useQuery({
    queryKey: ['user', user?.id],
    queryFn: () => api.user(user!.id),
    enabled: !!user,
  })

  if (!user) return null

  return (
    <Modal open={!!user} onClose={onClose} title={`${user.name} (${user.handle})`}>
      {isLoading ? <Loading /> : (
        <>
          <div className="grid grid-cols-3 gap-3 mb-4">
            <div className="bg-gray-50 rounded-xl p-3 text-center">
              <div className="text-lg font-black text-gray-900">{data?.rooms.length ?? 0}</div>
              <div className="text-xs text-gray-500">만든 방</div>
            </div>
            <div className="bg-gray-50 rounded-xl p-3 text-center">
              <div className="text-lg font-black text-gray-900">{data?.applications.length ?? 0}</div>
              <div className="text-xs text-gray-500">지원 수</div>
            </div>
            <div className="bg-gray-50 rounded-xl p-3 text-center">
              <div className="text-lg font-black text-gray-900">{won(user.total_spent)}</div>
              <div className="text-xs text-gray-500">누적 결제</div>
            </div>
          </div>

          <div className="space-y-3 mb-4">
            <label className="block text-xs font-bold text-gray-500 uppercase tracking-wider">사업자 구분</label>
            <select defaultValue={user.is_business} onChange={(e) => setIsBiz(Number(e.target.value))}
              className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm outline-none">
              <option value={0}>개인 (3.3% 원천징수)</option>
              <option value={1}>사업자 (세금계산서 발행)</option>
            </select>
            {(isBiz || user.is_business) ? (
              <>
                <label className="block text-xs font-bold text-gray-500 uppercase tracking-wider">사업자등록번호</label>
                <input defaultValue={user.biz_reg_no ?? ''} onChange={(e) => setBizNo(e.target.value)}
                  placeholder="000-00-00000"
                  className="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm outline-none font-mono" />
              </>
            ) : null}
          </div>

          <div className="flex gap-2 justify-end">
            <Btn variant="outline" onClick={onClose}>취소</Btn>
            <Btn variant="primary" disabled={saving}
              onClick={() => onSave(user.id, { is_business: isBiz, biz_reg_no: bizNo || undefined })}>
              {saving ? '저장 중…' : '저장'}
            </Btn>
          </div>
        </>
      )}
    </Modal>
  )
}
