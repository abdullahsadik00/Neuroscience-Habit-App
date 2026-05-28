import React, { useState, useRef, useEffect } from 'react';
import { CheckCircle2, AlertTriangle, ArrowDown, HelpCircle, X, MoreVertical, Archive } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
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
  onArchive: (id: string) => void;
}

export default function HabitCard({ stack, comebacks, onComplete, onArchive }: Props) {
  const [showMyelinInfo, setShowMyelinInfo] = useState(false);
  const [showMenu, setShowMenu] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);
  const weekDays = getWeekGrid(stack, comebacks);
  const today = getLocalDateString(new Date());
  const completedToday = stack.completions.includes(today);
  const daysMissed = completedToday ? 0 : getDaysMissed(stack);
  const isMissed = daysMissed > 1;
  const catStyle = CAT_BADGE[stack.category] ?? 'bg-[color:var(--surface-2)] text-[color:var(--text-2)]';

  useEffect(() => {
    if (!showMenu) return;
    function handleClick(e: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setShowMenu(false);
      }
    }
    document.addEventListener('mousedown', handleClick);
    return () => document.removeEventListener('mousedown', handleClick);
  }, [showMenu]);

  return (
    <div className={`card card-hover p-5 ${completedToday ? 'ring-1 ring-emerald-200 dark:ring-emerald-500/20' : ''}`}>
      <div className="flex items-start justify-between mb-3">
        <div className="flex-1 min-w-0 pr-2">
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

        <div className="flex items-center gap-2 shrink-0">
          <div className="text-right">
            <div className="text-[22px] font-bold text-[color:var(--text-1)] leading-none">{stack.streak}</div>
            <div className="text-[10px] text-[color:var(--text-3)]">streak</div>
          </div>

          {/* Kebab menu */}
          <div className="relative" ref={menuRef}>
            <button
              onClick={() => setShowMenu((v) => !v)}
              className="p-1.5 rounded-lg hover:bg-[color:var(--surface-2)] transition-colors"
              aria-label="Habit options"
            >
              <MoreVertical className="w-4 h-4 text-[color:var(--text-3)]" />
            </button>
            <AnimatePresence>
              {showMenu && (
                <motion.div
                  initial={{ opacity: 0, scale: 0.95, y: -4 }}
                  animate={{ opacity: 1, scale: 1, y: 0 }}
                  exit={{ opacity: 0, scale: 0.95, y: -4 }}
                  transition={{ duration: 0.12 }}
                  className="absolute right-0 top-full mt-1 z-20 card shadow-[var(--shadow-modal)] rounded-xl overflow-hidden min-w-[140px]"
                >
                  <button
                    onClick={() => { setShowMenu(false); onArchive(stack.id); }}
                    className="w-full flex items-center gap-2.5 px-4 py-3 text-[13px] text-[color:var(--text-2)] hover:bg-[color:var(--surface-2)] transition-colors"
                  >
                    <Archive className="w-3.5 h-3.5 text-[color:var(--text-3)]" />
                    Archive habit
                  </button>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
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
          <div className="flex items-center gap-1">
            <span className="text-[10px] font-semibold uppercase tracking-wider text-[color:var(--text-3)]">Neural Pathway</span>
            <button
              onClick={(e) => { e.stopPropagation(); setShowMyelinInfo((v) => !v); }}
              className="p-0.5 rounded-full hover:bg-[color:var(--surface-2)] transition-colors"
              aria-label="What is myelination?"
            >
              <HelpCircle className="w-3 h-3 text-[color:var(--text-3)]" />
            </button>
          </div>
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
        <div className="h-[4px] progress-track mb-2">
          <motion.div
            className="h-full rounded-full bg-indigo-500 dark:bg-indigo-400"
            initial={false}
            animate={{ width: `${stack.myelinationLevel}%` }}
            transition={{ duration: 0.8, ease: [0.4, 0, 0.2, 1] }}
          />
        </div>
        <AnimatePresence>
          {showMyelinInfo && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              transition={{ duration: 0.18 }}
              className="overflow-hidden"
            >
              <div className="card p-3 rounded-lg mt-1 relative">
                <button
                  onClick={() => setShowMyelinInfo(false)}
                  className="absolute top-2 right-2 p-0.5 rounded hover:bg-[color:var(--surface-2)] transition-colors"
                >
                  <X className="w-3 h-3 text-[color:var(--text-3)]" />
                </button>
                <p className="text-[11px] font-semibold text-indigo-500 dark:text-indigo-400 mb-1">What is myelination?</p>
                <p className="text-[11px] text-[color:var(--text-2)] leading-relaxed pr-4">
                  Myelin is a fatty sheath that wraps nerve fibers, speeding signal conduction — the more you repeat a behavior, the faster and more automatic it feels. This bar maps to research by Lally et al. (2010): habit automaticity takes 18–254 days on average, reaching full strength at around 57–66 completions.
                </p>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
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
