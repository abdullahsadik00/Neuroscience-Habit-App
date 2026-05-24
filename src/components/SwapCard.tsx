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
const FRICTION_COLOR = ['', 'text-emerald-400', 'text-cyan-400', 'text-amber-400', 'text-orange-400', 'text-rose-400'];

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
    <div className="glass-panel glass-panel-hover rounded-xl p-5">
      <div className="flex items-start justify-between mb-3">
        <div className="flex-1 min-w-0 pr-3">
          <div className="flex items-center gap-2 mb-1">
            <Shield className="w-3.5 h-3.5 text-rose-400" />
            <span className={`text-[10px] font-semibold ${FRICTION_COLOR[swap.frictionLevel]}`}>
              Friction {FRICTION_LABEL[swap.frictionLevel]}
            </span>
          </div>
          <h3 className="text-base font-semibold text-white leading-tight">{swap.title}</h3>
          <p className="text-xs text-slate-500 mt-0.5 line-clamp-1">
            <span className="text-rose-400/80">Intercept:</span> {swap.interceptAction}
          </p>
        </div>
        {resistRate !== null && (
          <div className="text-right shrink-0">
            <div className={`text-xl font-bold font-mono ${resistRate >= 70 ? 'text-emerald-400' : resistRate >= 40 ? 'text-amber-400' : 'text-rose-400'}`}>
              {resistRate}%
            </div>
            <div className="text-[10px] text-slate-500">resist rate</div>
          </div>
        )}
      </div>

      <div className="flex gap-2.5">
        <button
          onClick={() => onUrgeSurf(swap.id)}
          className={`flex-1 py-2.5 rounded-lg border flex items-center justify-center gap-1.5 text-xs font-semibold transition-all button-pulse ${
            urgedToday
              ? 'bg-emerald-900/30 border-emerald-700/40 text-emerald-500'
              : 'bg-emerald-900/20 hover:bg-emerald-800/40 text-emerald-400 border-emerald-800/40'
          }`}
        >
          <CheckCircle2 className="w-3.5 h-3.5" />
          {urgedToday ? 'Surfed today' : 'Urge Surfed'}
        </button>
        <button
          onClick={() => onSlip(swap.id)}
          className="flex-1 py-2.5 rounded-lg border border-rose-800/30 bg-rose-900/10 hover:bg-rose-900/30 text-rose-400 text-xs font-semibold flex items-center justify-center gap-1.5 transition-all button-pulse"
        >
          <AlertOctagon className="w-3.5 h-3.5" />
          {slippedToday ? 'Slipped (logged)' : 'Log Slip'}
        </button>
      </div>
    </div>
  );
}
