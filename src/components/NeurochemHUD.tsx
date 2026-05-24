import React from 'react';
import { Neurochemistry } from '../store/useNeuroStore';

interface ChemConfig {
  key: keyof Neurochemistry;
  label: string;
  abbr: string;
  color: string;
  glow: string;
  description: string;
}

const CHEMS: ChemConfig[] = [
  {
    key: 'dopamine',
    label: 'Dopamine',
    abbr: 'DA',
    color: 'bg-cyan-400',
    glow: 'shadow-[0_0_8px_rgba(34,211,238,0.4)]',
    description: 'Motivation & reward drive',
  },
  {
    key: 'acetylcholine',
    label: 'Acetylcholine',
    abbr: 'ACh',
    color: 'bg-violet-400',
    glow: 'shadow-[0_0_8px_rgba(167,139,250,0.4)]',
    description: 'Focus & learning depth',
  },
  {
    key: 'epinephrine',
    label: 'Epinephrine',
    abbr: 'EPI',
    color: 'bg-rose-400',
    glow: 'shadow-[0_0_8px_rgba(251,113,133,0.4)]',
    description: 'Stress & urgency signal',
  },
  {
    key: 'gaba',
    label: 'GABA',
    abbr: 'GABA',
    color: 'bg-emerald-400',
    glow: 'shadow-[0_0_8px_rgba(52,211,153,0.4)]',
    description: 'Calm & recovery state',
  },
];

export default function NeurochemHUD({ neurochemistry }: { neurochemistry: Neurochemistry }) {
  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
      {CHEMS.map((chem) => {
        const value = neurochemistry[chem.key];
        const level = value >= 70 ? 'High' : value >= 40 ? 'Normal' : 'Low';
        return (
          <div
            key={chem.key}
            className="glass-panel rounded-xl p-3 group relative overflow-hidden"
          >
            <div className="flex items-center justify-between mb-2">
              <span className="text-[10px] font-mono tracking-widest text-slate-500 uppercase">
                {chem.abbr}
              </span>
              <span
                className={`text-[10px] font-semibold px-1.5 py-0.5 rounded-full ${
                  level === 'High'
                    ? 'bg-emerald-900/40 text-emerald-400'
                    : level === 'Low'
                    ? 'bg-rose-900/40 text-rose-400'
                    : 'bg-slate-800 text-slate-400'
                }`}
              >
                {level}
              </span>
            </div>
            <div className="text-sm font-semibold text-white mb-1">{Math.round(value)}</div>
            <div className="w-full bg-gray-800 rounded-full h-1.5 mb-2">
              <div
                className={`${chem.color} ${chem.glow} h-1.5 rounded-full transition-all duration-700`}
                style={{ width: `${value}%` }}
              />
            </div>
            <div className="text-[10px] text-slate-500 leading-tight">{chem.description}</div>
          </div>
        );
      })}
    </div>
  );
}
