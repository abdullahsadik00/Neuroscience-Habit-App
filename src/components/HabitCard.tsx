import React from 'react';
import { CheckCircle2, AlertTriangle, ArrowDown } from 'lucide-react';
import { motion } from 'framer-motion';
import type { NeuroStack, ComebackRecord } from '../store/useNeuroStore';
import { getLocalDateString } from '../utils/neuroHelpers';
import { getWeekGrid } from '../utils/statsHelpers';
import { getDaysMissed } from '../utils/comebackHelpers';
import WeeklyGrid from './WeeklyGrid';

const CAT_BADGE: Record<string, string> = {
  focus:    'bg-indigo-50 text-indigo-600 dark:bg-indigo-500/15 dark:text-indigo-400',
  wellness: 'bg-emerald-50 text-emerald-600 dark:bg-emerald-500/15 dark:text-emerald-400',
  mindset:  'bg-sky-50 text-sky-600 dark:bg-sky-500/15 dark:text-sky-400',
  fitness:  'bg-amber-50 text-amber-600 dark:bg-amber-500/15 dark:text-amber-400',
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
  const catStyle = CAT_BADGE[stack.category] ?? 'bg-[color:var(--surface-2)] text-[color:var(--text-2)]';

  return (
    <div className={`card card-hover p-5 ${completedToday ? 'ring-1 ring-emerald-200 dark:ring-emerald-500/20' : ''}`}>
      <div className="flex items-start justify-between mb-3">
        <div className="flex-1 min-w-0 pr-3">
          <div className="flex items-center gap-2 mb-1.5">
            <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full capitalize ${catStyle}`}>
              {stack.category}
            </span>
            {completedToday && (
              <span className="text-[10px] font-semibold text-emerald-600 dark:text-emerald-400">Done today</span>
            )}
            {isMissed && !completedToday && (
              <span className="flex items-center gap-1 text-[10px] font-semibold text-amber-600 dark:text-amber-400">
                <AlertTriangle className="w-3 h-3" />
                {daysMissed}d gap
              </span>
            )}
          </div>
          <h3 className="text-[15px] font-semibold text-[color:var(--text-1)] leading-snug truncate">{stack.title}</h3>
        </div>
        <div className="text-right shrink-0">
          <div className="text-[22px] font-bold text-[color:var(--text-1)] leading-none">{stack.streak}</div>
          <div className="text-[10px] text-[color:var(--text-3)]">streak</div>
        </div>
      </div>

      {/* Implementation Intention — When → Then */}
      {(stack.anchorCue || stack.action) && (
        <div className="card-2 p-3 rounded-xl mb-3 space-y-2">
          {stack.anchorCue && (
            <div>
              <span className="text-[9px] font-semibold uppercase tracking-wider text-[color:var(--text-3)]">When</span>
              <p className="text-[12px] text-[color:var(--text-2)] leading-snug line-clamp-2 mt-0.5">{stack.anchorCue}</p>
            </div>
          )}
          {stack.anchorCue && stack.action && (
            <ArrowDown className="w-3 h-3 text-indigo-400 dark:text-indigo-500 mx-auto" />
          )}
          {stack.action && (
            <div>
              <span className="text-[9px] font-semibold uppercase tracking-wider text-indigo-500 dark:text-indigo-400">I will</span>
              <p className="text-[12px] font-medium text-[color:var(--text-1)] leading-snug line-clamp-2 mt-0.5">{stack.action}</p>
            </div>
          )}
        </div>
      )}

      {/* Myelination */}
      <div className="mb-3">
        <div className="flex justify-between items-center mb-1.5">
          <span className="text-[10px] font-semibold uppercase tracking-wider text-[color:var(--text-3)]">Neural Pathway</span>
          <span className="text-[10px] font-semibold text-[color:var(--text-2)]">
            {stack.myelinationLevel}%
            {' · '}
            {stack.myelinationLevel >= 86 ? 'Well-established'
              : stack.myelinationLevel >= 66 ? 'Established'
              : stack.myelinationLevel >= 41 ? 'Strengthening'
              : stack.myelinationLevel >= 21 ? 'Building'
              : 'Forming'}
          </span>
        </div>
        <div className="h-[4px] progress-track">
          <motion.div
            className="h-full rounded-full bg-indigo-500 dark:bg-indigo-400"
            initial={false}
            animate={{ width: `${stack.myelinationLevel}%` }}
            transition={{ duration: 0.8, ease: [0.4, 0, 0.2, 1] }}
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
        className={`w-full h-11 rounded-xl flex items-center justify-center gap-2 text-[13px] font-semibold transition-all ${
          completedToday
            ? 'bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 cursor-default'
            : 'btn-primary'
        }`}
      >
        <CheckCircle2 className="w-4 h-4" />
        {completedToday ? 'Completed' : 'Mark Complete'}
      </button>
    </div>
  );
}
