import React, { useEffect, useState } from 'react'
import { supabase } from '../supabaseClient'

export default function AdminSubscriptions() {
  const [rows, setRows] = useState<any[]>([])

  useEffect(() => {
    const load = async () => {
      // Try common table names: subscriptions, payments
      let data = null
      try { const r = await supabase.from('subscriptions').select('*').limit(100); data = r.data } catch (_) {}
      if (!data) {
        try { const r = await supabase.from('payments').select('*').limit(100); data = r.data } catch (_) {}
      }
      setRows(data || [])
    }
    load()
  }, [])

  return (
    <div>
      <h1 className="text-xl font-semibold mb-4">Subscriptions / Payments</h1>
      <div className="bg-white shadow rounded p-3">
        {rows.length === 0 ? <div className="text-sm text-gray-600">No subscription records found.</div> : (
          <table className="w-full text-left table-auto">
            <thead className="bg-gray-50"><tr>{Object.keys(rows[0] || {}).map((k) => <th key={k} className="p-2">{k}</th>)}</tr></thead>
            <tbody>
              {rows.map((r, idx) => (
                <tr key={idx} className="border-t">
                  {Object.keys(r).map((k) => <td key={k} className="p-2">{String(r[k])}</td>)}
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}


