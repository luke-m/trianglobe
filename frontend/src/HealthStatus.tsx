import { useEffect, useState } from 'react'

type HealthState =
  | { status: 'loading' }
  | { status: 'ok'; version: string }
  | { status: 'error' }

/**
 * Walking-skeleton proof that the frontend can reach the backend:
 * fetches /api/health once on mount and renders the result.
 */
export function HealthStatus() {
  const [state, setState] = useState<HealthState>({ status: 'loading' })

  useEffect(() => {
    let cancelled = false
    fetch('/api/health')
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.json() as Promise<{ status: string; version: string }>
      })
      .then((body) => {
        if (!cancelled) setState({ status: 'ok', version: body.version })
      })
      .catch(() => {
        if (!cancelled) setState({ status: 'error' })
      })
    return () => {
      cancelled = true
    }
  }, [])

  return (
    <>
      {state.status === "loading" && <p className="text-gray-500">checking backend..</p>}
      {state.status === "ok" && <p className="text-green-700 animate-pulse">backend online with version <span className='font-mono'>{state.version}</span>!</p>}
      {state.status === "error" && <p className="text-red-400">backend offline :(</p>}
    </>
  )
}
