import { render, screen } from '@testing-library/react'
import { afterEach, expect, test, vi } from 'vitest'
import { HealthStatus } from './HealthStatus'

afterEach(() => {
  vi.restoreAllMocks()
})

test('shows the backend version when the health check succeeds', async () => {
  vi.stubGlobal(
    'fetch',
    vi.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve({ status: 'ok', version: '0.0.1-SNAPSHOT' }),
    } as Response),
  )

  render(<HealthStatus />)

  expect(await screen.findByText(/0\.0\.1-SNAPSHOT/)).toBeInTheDocument()
})

test('shows an error state when the backend is unreachable', async () => {
  vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('network down')))

  render(<HealthStatus />)

  expect(await screen.findByText(/offline|error|unreachable/i)).toBeInTheDocument()
})
