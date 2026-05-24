import React from 'react';
import { CheckCircle2, AlertOctagon, Shield } from 'lucide-react';
import type { NeuroSwap } from '../store/useNeuroStore';
import { getLocalDateString } from '../utils/neuroHelpers';

interface Props {
  swap: NeuroSwap;
  onUrgeSurf: (id: string) => void;
  onSlip: (id: string) => void;
}

const FRICTION_LABEL = ['', 'Minimal', 'Light', 'Moderate', 'Strong', 'Maximum'];
const FRICTION_COLOR = [
  '', 'text-emerald-600 dark:text-emerald-400', 'text-sky-600 dark:text-sky-400',
  'text-amber-600 dark:text-amber-400', 'text-orange-600 dark:text-orange-400', 'text-rose-600 dark:text-rose-400',
];

export default function SwapCard({ swap, onUrgeSurf, onSlip }: Props) {
  const today = getLocalDateString(new Date());
  const urgedToday = swap.urgeSurfingCompletions.includes(today);
  const slippedToday = swap.slips.includes(today);

  const totalUrges = swap.urgeSurfingCompletions.length;
  const totalSlips = swap.slips.length;
  const resistRate = totalUrges + totalSlips > 0
    ? Math.round((totalUrges / (totalUrges + totalSlips)) * 100)
    : null;

  return (
    <div className="card card-hover p-5">
      <div className="flex items-start justify-between mb-4">
        <div className="flex-1 min-w-0 pr-3">
          <div className="flex items-center gap-2 mb-1.5">
            <Shield className="w-3.5 h-3.5 text-rose-500 dark:text-rose-400" />
            <span className={`text-[11px] font-semibold ${FRICTION_COLOR[swap.frictionLevel]}`}>
              Friction {FRICTION_LABEL[swap.frictionLevel]}
            </span>
          </div>
          <h3 className="text-[15px] font-semibold text-[color:var(--text-1)] leading-snug">{swap.title}</h3>
          <p className="text-[12px] text-[color:var(--text-3)] mt-0.5 line-clamp-1">
            <span className="text-rose-500/80 dark:text-rose-400/80">Intercept:</span> {swap.interceptAction}
          </p>
        </div>
        {resistRate !== null && (
          <div className="text-right shrink-0">
            <div className={`text-[22px] font-bold leading-none ${
              resistRate >= 70 ? 'text-emerald-600 dark:text-emerald-400'
              : resistRate >= 40 ? 'text-amber-600 dark:text-amber-400'
              : 'text-rose-600 dark:text-rose-400'
            }`}>
              {resistRate}%
            </div>
            <div className="text-[10px] text-[color:var(--text-3)]">resist rate</div>
          </div>
        )}
      </div>

      <div className="flex gap-2.5">
        <button
          onClick={() => onUrgeSurf(swap.id)}
          className={`flex-1 h-10 rounded-xl border flex items-center justify-center gap-1.5 text-[12px] font-semibold transition-all ${
            urgedToday
              ? 'bg-emerald-50 dark:bg-emerald-500/10 border-emerald-200 dark:border-emerald-500/20 text-emerald-600 dark:text-emerald-400'
              : 'bg-emerald-50 dark:bg-emerald-500/10 hover:bg-emerald-100 dark:hover:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 border-emerald-200 dark:border-emerald-500/20'
          }`}
        >
          <CheckCircle2 className="w-3.5 h-3.5" />
          {urgedToday ? 'Surfed today' : 'Urge Surfed'}
        </button>
        <button
          onClick={() => onSlip(swap.id)}
          className="flex-1 h-10 rounded-xl border bg-rose-50 dark:bg-rose-500/10 hover:bg-rose-100 dark:hover:bg-rose-500/20 text-rose-600 dark:text-rose-400 border-rose-200 dark:border-rose-500/20 text-[12px] font-semibold flex items-center justify-center gap-1.5 transition-all"
        >
          <AlertOctagon className="w-3.5 h-3.5" />
          {slippedToday ? 'Slipped (logged)' : 'Log Slip'}
        </button>
      </div>
    </div>
  );
}
