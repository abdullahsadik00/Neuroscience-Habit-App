// src/pages/Dashboard.tsx
import React, { useEffect } from 'react';
import { useNeuroStore } from '../store/useNeuroStore';
import { Brain, Zap, ShieldAlert, CheckCircle2, AlertOctagon } from 'lucide-react';

export default function Dashboard() {
  const {
    stacks,
    swaps,
    neurochemistry,
    dopaminePoints,
    completeNeuroStack,
    logUrgeSurf,
    logSlip,
    decayNeurochemistry
  } = useNeuroStore();

  // Simulate brain chemistry returning to normal over time
  useEffect(() => {
    const interval = setInterval(() => {
      decayNeurochemistry();
    }, 60000); // Decays slightly every minute
    return () => clearInterval(interval);
  }, [decayNeurochemistry]);

  return (
    <div className="min-h-screen bg-gray-950 text-slate-200 p-6 font-sans">

      {/* HEADER & DOPAMINE POINTS */}
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold text-white tracking-tight">Neural Control</h1>
          <p className="text-slate-400 text-sm">System Calibration: Optimal</p>
        </div>
        <div className="bg-cyan-950/40 border border-cyan-800/50 px-4 py-2 rounded-lg flex items-center gap-2 shadow-[0_0_10px_rgba(34,211,238,0.2)]">
          <Zap className="text-cyan-400 w-5 h-5" />
          <span className="font-mono text-xl font-bold text-cyan-400">{dopaminePoints}</span>
        </div>
      </div>

      {/* NEUROCHEMICAL HUD (Heads Up Display) */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-10">
        <ChemicalBar name="Dopamine" value={neurochemistry.dopamine} color="bg-cyan-400" />
        <ChemicalBar name="Acetylcholine" value={neurochemistry.acetylcholine} color="bg-indigo-400" />
        <ChemicalBar name="Epinephrine" value={neurochemistry.epinephrine} color="bg-rose-500" />
        <ChemicalBar name="GABA" value={neurochemistry.gaba} color="bg-emerald-400" />
      </div>

      {/* POSITIVE HABITS (NEURO-STACKS) */}
      <h2 className="text-xl font-semibold mb-4 flex items-center gap-2 border-b border-gray-800 pb-2">
        <Brain className="text-indigo-400" /> Myelination Targets (Habits)
      </h2>
      <div className="grid gap-4 mb-10">
        {stacks.map((stack) => (
          <div key={stack.id} className="bg-gray-900 border border-gray-800 rounded-xl p-5 hover:border-indigo-500/30 transition-all">
            <div className="flex justify-between items-start mb-2">
              <h3 className="text-lg font-medium text-white">{stack.title}</h3>
              <span className="text-xs font-mono bg-gray-800 px-2 py-1 rounded text-slate-300">Streak: {stack.streak}</span>
            </div>
            <p className="text-sm text-slate-400 mb-4"><span className="text-indigo-400 font-semibold">Cue:</span> {stack.anchorCue}</p>

            {/* Myelination Progress */}
            <div className="w-full bg-gray-800 rounded-full h-1.5 mb-4">
              <div className="bg-indigo-500 h-1.5 rounded-full transition-all duration-1000" style={{ width: `${stack.myelinationLevel}%` }}></div>
            </div>

            <button
              onClick={() => completeNeuroStack(stack.id)}
              className="w-full py-2 bg-indigo-600/20 hover:bg-indigo-600/40 text-indigo-300 rounded-lg flex items-center justify-center gap-2 border border-indigo-500/30 transition-colors"
            >
              <CheckCircle2 className="w-4 h-4" /> Execute Action
            </button>
          </div>
        ))}
      </div>

      {/* BAD HABITS (NEURO-SWAPS) */}
      <h2 className="text-xl font-semibold mb-4 flex items-center gap-2 border-b border-gray-800 pb-2">
        <ShieldAlert className="text-rose-400" /> Friction Protocols (Bad Habits)
      </h2>
      <div className="grid gap-4 pb-10">
        {swaps.map((swap) => (
          <div key={swap.id} className="bg-gray-900 border border-gray-800 rounded-xl p-5">
            <h3 className="text-lg font-medium text-white mb-2">{swap.title}</h3>
            <p className="text-sm text-slate-400 mb-4"><span className="text-rose-400 font-semibold">Intercept:</span> {swap.interceptAction}</p>

            <div className="flex gap-3">
              <button
                onClick={() => logUrgeSurf(swap.id)}
                className="flex-1 py-2 bg-emerald-900/30 hover:bg-emerald-800/50 text-emerald-400 rounded-lg border border-emerald-800/50 transition-colors"
              >
                Urge Surfed (Success)
              </button>
              <button
                onClick={() => logSlip(swap.id)}
                className="flex-1 py-2 bg-rose-900/20 hover:bg-rose-900/40 text-rose-400 rounded-lg border border-rose-800/30 flex items-center justify-center gap-2 transition-colors"
              >
                <AlertOctagon className="w-4 h-4" /> Slipped
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// Small helper component for the Chemical Bars
function ChemicalBar({ name, value, color }: { name: string, value: number, color: string }) {
  return (
    <div className="bg-gray-900 border border-gray-800 p-3 rounded-lg">
      <div className="text-xs text-slate-400 mb-1 uppercase tracking-wider">{name}</div>
      <div className="w-full bg-gray-800 rounded-full h-2">
        <div className={`${color} h-2 rounded-full transition-all duration-700`} style={{ width: `${value}%` }}></div>
      </div>
    </div>
  );
}
