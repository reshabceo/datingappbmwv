import React, { useEffect, useState } from 'react'
import { supabase } from '../supabaseClient'

export default function Admin() {
  const [users, setUsers] = useState<any[]>([])

  useEffect(() => {
    const load = async () => {
      const { data } = await supabase.from('profiles').select('id,name,email,created_at,is_active')
      setUsers(data || [])
    }
    load()
  }, [])

  const toggleActive = async (id: string, current: boolean) => {
    if (!confirm('Confirm?')) return
    await supabase.from('profiles').update({ is_active: !current }).eq('id', id)
    setUsers((s) => s.map((u) => (u.id === id ? { ...u, is_active: !current } : u)))
  }

  const deleteUser = async (id: string) => {
    if (!confirm('Delete user permanently?')) return
    await supabase.from('profiles').delete().eq('id', id)
    setUsers((s) => s.filter((u) => u.id !== id))
  }

  return (
    <div className="min-h-screen bg-light-bg">
      <div className="max-w-6xl mx-auto p-4">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-800 mb-2">Admin Dashboard</h1>
          <p className="text-gray-600">Manage users and system settings</p>
        </div>

        <div className="bg-light-card rounded-2xl shadow-xl border border-border-black-10 overflow-hidden">
          <div className="bg-gradient-appbar px-6 py-4">
            <h2 className="text-xl font-semibold text-white">User Management</h2>
            <p className="text-light-white text-sm">Total users: {users.length}</p>
          </div>
          
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead className="bg-gray-50 border-b border-border-black-10">
                <tr>
                  <th className="px-6 py-4 text-sm font-semibold text-gray-700">Name</th>
                  <th className="px-6 py-4 text-sm font-semibold text-gray-700">Email</th>
                  <th className="px-6 py-4 text-sm font-semibold text-gray-700">Status</th>
                  <th className="px-6 py-4 text-sm font-semibold text-gray-700">Joined</th>
                  <th className="px-6 py-4 text-sm font-semibold text-gray-700">Actions</th>
                </tr>
              </thead>
              <tbody>
                {users.map((u) => (
                  <tr key={u.id} className="border-b border-border-black-10 hover:bg-gray-50 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center space-x-3">
                        <div className="w-8 h-8 bg-gradient-to-br from-secondary to-primary rounded-full flex items-center justify-center text-white text-sm font-semibold">
                          {u.name ? u.name.charAt(0).toUpperCase() : 'U'}
                        </div>
                        <span className="font-medium text-gray-800 capitalize">{u.name || 'Unknown'}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">{u.email || 'No email'}</td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                        u.is_active 
                          ? 'bg-green-100 text-green-800' 
                          : 'bg-red-100 text-red-800'
                      }`}>
                        {u.is_active ? 'Active' : 'Blocked'}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {u.created_at ? new Date(u.created_at).toLocaleDateString() : 'Unknown'}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex space-x-2">
                        <button 
                          onClick={() => toggleActive(u.id, u.is_active)} 
                          className={`px-3 py-1 text-xs font-medium rounded-lg transition-colors ${
                            u.is_active
                              ? 'bg-red-100 text-red-700 hover:bg-red-200'
                              : 'bg-green-100 text-green-700 hover:bg-green-200'
                          }`}
                        >
                          {u.is_active ? 'Block' : 'Unblock'}
                        </button>
                        <button 
                          onClick={() => deleteUser(u.id)} 
                          className="px-3 py-1 text-xs font-medium rounded-lg bg-red-100 text-red-700 hover:bg-red-200 transition-colors"
                        >
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  )
}


