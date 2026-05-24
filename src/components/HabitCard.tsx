import React from 'react';
import { CheckCircle2, AlertTriangle } from 'lucide-react';
import type { NeuroStack, ComebackRecord } from '../store/useNeuroStore';
import { getLocalDateString } from '../utils/neuroHelpers';
import { getWeekGrid } from '../utils/statsHelpers';
import { getDaysMissed } from '../utils/comebackHelpers';
import WeeklyGrid from './WeeklyGrid';

const CATEGORY_COLORS: Record<string, string> = {
  focus: 'text-violet-400 bg-violet-900/20 border-violet-800/30',
  wellness: 'text-emerald-400 bg-emerald-900/20 border-emerald-800/30',
  mindset: 'text-cyan-400 bg-cyan-900/20 border-cyan-800/30',
  fitness: 'text-orange-400 bg-orange-900/20 border-orange-800/30',
};

const MYELIN_COLOR = (level: number) => {
  if (level >= 70) return 'bg-emerald-400';
  if (level >= 40) return 'bg-violet-400';
  return 'bg-cyan-500';
};

interface Props {
  stack: NeuroStack;
  comebacks: ComebackRecord[];
  onComplete: (id: string) => void;
}

export default function HabitCard({ stack, comebacks, onComplete }: Props) {
  const weekDays = getWeekGrid(stack, comebacks);
  const today = getLocalDateString(new Date());
  const completedToday = stack.completions.includes(today);
  const daysMissed = completedToday ? 0 : getDaysMissed(stack);
  const isMissed = daysMissed > 1;
  const catStyle = CATEGORY_COLORS[stack.category] ?? 'text-slate-400 bg-slate-800/30 border-slate-700/30';

  return (
    <div
      className={`glass-panel glass-panel-hover rounded-xl p-5 transition-all ${
        completedToday ? 'border-emerald-800/30' : isMissed ? 'border-amber-800/30' : ''
      }`}
    >
      <div className="flex items-start justify-between mb-3">
        <div className="flex-1 min-w-0 pr-3">
          <div className="flex items-center gap-2 mb-1">
            <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full border ${catStyle}`}>
              {stack.category}
            </span>
            {completedToday && (
              <span className="text-[10px] text-emerald-400 font-semibold">Done today</span>
            )}
            {isMissed && !completedToday && (
              <span className="flex items-center gap-1 text-[10px] text-amber-400 font-semibold">
                <AlertTriangle className="w-3 h-3" />
                {daysMissed}d gap
              </span>
            )}
          </div>
          <h3 className="text-base font-semibold text-white leading-tight truncate">{stack.title}</h3>
          <p className="text-xs text-slate-500 mt-0.5 line-clamp-1">
            <span className="text-slate-400">Cue:</span> {stack.anchorCue}
          </p>
        </div>
        <div className="text-right shrink-0">
          <div className="text-xl font-bold text-white font-mono">{stack.streak}</div>
          <div className="text-[10px] text-slate-500">streak</div>
        </div>
      </div>

      {/* Myelination */}
      <div className="mb-3">
        <div className="flex justify-between items-center mb-1">
          <span className="text-[10px] text-slate-500 font-mono tracking-wider uppercase">Myelination</span>
          <span className="text-[10px] font-mono text-slate-400">{stack.myelinationLevel}%</span>
        </div>
        <div className="w-full bg-gray-800 rounded-full h-1">
          <div
            className={`${MYELIN_COLOR(stack.myelinationLevel)} h-1 rounded-full transition-all duration-1000`}
            style={{ width: `${stack.myelinationLevel}%` }}
          />
        </div>
      </div>

      {/* Weekly grid */}
      <div className="mb-4">
        <WeeklyGrid days={weekDays} />
      </div>

      <button
        onClick={() => onComplete(stack.id)}
        disabled={completedToday}
        className={`w-full py-2.5 rounded-lg flex items-center justify-center gap-2 text-sm font-semibold transition-all button-pulse ${
          completedToday
            ? 'bg-emerald-900/20 text-emerald-600 cursor-default border border-emerald-800/30'
            : 'bg-indigo-600/20 hover:bg-indigo-600/40 text-indigo-300 border border-indigo-500/30 hover:shadow-[0_0_12px_rgba(99,102,241,0.2)]'
        }`}
      >
        <CheckCircle2 className="w-4 h-4" />
        {completedToday ? 'Completed' : 'Mark Complete'}
      </button>
    </div>
  );
}
