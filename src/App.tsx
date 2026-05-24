import React, { useState } from 'react';
import Dashboard from './pages/Dashboard';

function App() {
  const [started, setStarted] = useState(false);

  // If the user clicked start, show the Dashboard
  if (started) {
    return <Dashboard />;
  }

  // Otherwise, show the landing page
  return (
    <div className="min-h-screen bg-gray-950 text-slate-200 flex flex-col items-center justify-center font-sans">
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,rgba(34,211,238,0.08)_0%,transparent_70%)] pointer-events-none"></div>

      <div className="z-10 text-center">
        <h1 className="text-6xl font-bold tracking-tight mb-4 text-cyan-400 drop-shadow-[0_0_25px_rgba(34,211,238,0.3)]">
          Neuro<span className="text-slate-100">Sync</span>
        </h1>
        <p className="text-lg text-slate-400 mb-10 max-w-md mx-auto leading-relaxed">
          Rewiring neural pathways through friction engineering and dopamine regulation.
        </p>
        <button
          onClick={() => setStarted(true)}
          className="px-8 py-4 bg-cyan-600 hover:bg-cyan-500 text-gray-950 font-bold text-lg rounded-full transition-all shadow-[0_0_20px_rgba(34,211,238,0.4)] hover:shadow-[0_0_30px_rgba(34,211,238,0.6)] transform hover:-translate-y-1"
        >
          Initialize Brain Map
        </button>
      </div>
    </div>
  );
}

export default App;
