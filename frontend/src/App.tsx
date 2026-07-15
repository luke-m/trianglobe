import { HealthStatus } from './HealthStatus'

function App() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-6 bg-slate-950 text-slate-100">
      <h1 className="text-5xl font-bold tracking-tight">Trianglobe</h1>
      <p className="text-slate-400">Find the five. Solve the sphere.</p>
      <HealthStatus />
    </main>
  )
}

export default App
