import React from 'react';
import { motion } from 'framer-motion';
import type { Neurochemistry } from '../store/useNeuroStore';

interface ChemConfig {
  key: keyof Neurochemistry;
  label: string;
  abbr: string;
  barColor: string;
  description: string;
}

const CHEMS: ChemConfig[] = [
  { key: 'dopamine',      label: 'Dopamine',      abbr: 'DA',   barColor: 'bg-sky-400',     description: 'Motivation & reward drive' },
  { key: 'acetylcholine', label: 'Acetylcholine', abbr: 'ACh',  barColor: 'bg-violet-400',  description: 'Focus & learning depth' },
  { key: 'epinephrine',   label: 'Epinephrine',   abbr: 'EPI',  barColor: 'bg-rose-400',    description: 'Stress & urgency signal' },
  { key: 'gaba',          label: 'GABA',          abbr: 'GABA', barColor: 'bg-emerald-400', description: 'Calm & recovery state' },
];

export default function NeurochemHUD({ neurochemistry }: { neurochemistry: Neurochemistry }) {
  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
      {CHEMS.map((chem) => {
        const value = neurochemistry[chem.key];
        const level = value >= 70 ? 'High' : value >= 40 ? 'Normal' : 'Low';
        const levelColor = level === 'High'
          ? 'bg-emerald-50 text-emerald-600 dark:bg-emerald-500/15 dark:text-emerald-400'
          : level === 'Low'
          ? 'bg-rose-50 text-rose-600 dark:bg-rose-500/15 dark:text-rose-400'
          : 'bg-[color:var(--surface-2)] text-[color:var(--text-2)]';

        return (
          <div key={chem.key} className="card-2 p-4 rounded-xl">
            <div className="flex items-center justify-between mb-2">
              <span className="text-[10px] font-semibold uppercase tracking-wider text-[color:var(--text-3)]">
                {chem.abbr}
              </span>
              <span className={`text-[10px] font-semibold px-1.5 py-0.5 rounded-full ${levelColor}`}>
                {level}
              </span>
            </div>
            <div className="text-[22px] font-bold text-[color:var(--text-1)] leading-none mb-2">
              {Math.round(value)}
            </div>
            <div className="h-[3px] progress-track mb-2">
              <motion.div
                className={`h-full rounded-full ${chem.barColor}`}
                initial={false}
                animate={{ width: `${value}%` }}
                transition={{ duration: 0.7, ease: [0.4, 0, 0.2, 1] }}
              />
            </div>
            <div className="text-[11px] text-[color:var(--text-3)] leading-tight">{chem.description}</div>
          </div>
        );
      })}
    </div>
  );
}
