import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ArrowRight, CheckSquare, Square, X } from 'lucide-react';
import type { NeuroStack } from '../store/useNeuroStore';
import { getComebackMessage, generateMicroActions, getDaysMissed } from '../utils/comebackHelpers';

interface Props {
  missedStacks: NeuroStack[];
  onComplete: (stackId: string, stackTitle: string, microActionsCompleted: boolean) => void;
  onDismiss: () => void;
}

export default function ComebackProtocol({ missedStacks, onComplete, onDismiss }: Props) {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [checked, setChecked] = useState<boolean[]>([false, false, false]);
  const [phase, setPhase] = useState<'reframe' | 'actions'>('reframe');

  const stack = missedStacks[currentIndex];
  if (!stack) return null;

  const daysMissed = getDaysMissed(stack);
  const message = getComebackMessage(daysMissed);
  const microActions = generateMicroActions(stack);
  const allChecked = checked.every(Boolean);
  const anyChecked = checked.some(Boolean);

  function toggleCheck(i: number) {
    setChecked((prev) => prev.map((v, idx) => (idx === i ? !v : v)));
  }

  function handleContinue() {
    onComplete(stack.id, stack.title, allChecked);
    const next = currentIndex + 1;
    if (next < missedStacks.length) {
      setCurrentIndex(next);
      setChecked([false, false, false]);
      setPhase('reframe');
    } else {
      onDismiss();
    }
  }

  function handleSkip() {
    onComplete(stack.id, stack.title, false);
    const next = currentIndex + 1;
    if (next < missedStacks.length) {
      setCurrentIndex(next);
      setChecked([false, false, false]);
      setPhase('reframe');
    } else {
      onDismiss();
    }
  }

  const isLast = currentIndex === missedStacks.length - 1;
  const totalCount = missedStacks.length;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 dark:bg-black/60 backdrop-blur-md px-4">
      <motion.div
        initial={{ opacity: 0, scale: 0.95, y: 8 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.95, y: 8 }}
        transition={{ duration: 0.22, ease: [0.25, 0.46, 0.45, 0.94] }}
        className="w-full max-w-lg card shadow-[var(--shadow-modal)] overflow-hidden"
      >
        {/* Top bar */}
        <div className="flex items-center justify-between px-6 pt-5 pb-4 border-b border-[color:var(--border)]">
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 rounded-full bg-amber-500 animate-pulse" />
            <span className="text-[11px] font-semibold uppercase tracking-widest text-amber-600 dark:text-amber-400">
              Comeback Protocol
            </span>
          </div>
          <div className="flex items-center gap-3">
            {totalCount > 1 && (
              <span className="text-[12px] text-[color:var(--text-3)]">
                {currentIndex + 1} / {totalCount}
              </span>
            )}
            <button
              onClick={onDismiss}
              className="p-1 rounded-lg hover:bg-[color:var(--surface-2)] transition-colors"
            >
              <X className="w-4 h-4 text-[color:var(--text-3)]" />
            </button>
          </div>
        </div>

        <div className="px-6 py-6">
          <div className="section-header mb-1">Habit paused</div>
          <div className="text-[16px] font-semibold text-[color:var(--text-1)] mb-5">{stack.title}</div>

          <AnimatePresence mode="wait">
            {phase === 'reframe' && (
              <motion.div
                key="reframe"
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -8 }}
                transition={{ duration: 0.18 }}
              >
                <div className="card-2 p-5 rounded-xl mb-5">
                  <p className="text-[16px] font-semibold text-amber-600 dark:text-amber-300 mb-2 leading-snug">
                    {message.headline}
                  </p>
                  <p className="text-[13px] text-[color:var(--text-2)] leading-relaxed">
                    {message.body}
                  </p>
                </div>
                {daysMissed > 1 && (
                  <p className="text-[12px] text-[color:var(--text-3)] mb-5 text-center">
                    {daysMissed} day{daysMissed > 1 ? 's' : ''} since last completion
                  </p>
                )}
                <button
                  onClick={() => setPhase('actions')}
                  className="btn-primary w-full h-12"
                >
                  Show me the re-entry plan
                  <ArrowRight className="w-4 h-4" />
                </button>
              </motion.div>
            )}

            {phase === 'actions' && (
              <motion.div
                key="actions"
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -8 }}
                transition={{ duration: 0.18 }}
              >
                <p className="text-[13px] text-[color:var(--text-2)] mb-4 leading-relaxed">
                  Three micro-actions. Do any one and you are continuing — not restarting.
                </p>
                <div className="flex flex-col gap-2.5 mb-5">
                  {microActions.map((action, i) => (
                    <button
                      key={i}
                      onClick={() => toggleCheck(i)}
                      className={`w-full text-left p-4 rounded-xl border transition-all flex items-start gap-3 ${
                        checked[i]
                          ? 'bg-emerald-50 dark:bg-emerald-500/10 border-emerald-200 dark:border-emerald-500/30 card-hover'
                          : 'card card-hover'
                      }`}
                    >
                      <span className="mt-0.5 shrink-0">
                        {checked[i]
                          ? <CheckSquare className="w-5 h-5 text-emerald-500 dark:text-emerald-400" />
                          : <Square className="w-5 h-5 text-[color:var(--text-3)]" />
                        }
                      </span>
                      <span className={`text-[13px] leading-relaxed ${checked[i] ? 'text-emerald-700 dark:text-emerald-300' : 'text-[color:var(--text-1)]'}`}>
                        {action}
                      </span>
                    </button>
                  ))}
                </div>

                <button
                  onClick={handleContinue}
                  disabled={!anyChecked}
                  className={`w-full h-12 font-semibold rounded-xl flex items-center justify-center gap-2 text-[14px] transition-all ${
                    anyChecked
                      ? 'bg-emerald-500 hover:bg-emerald-600 dark:bg-emerald-500 dark:hover:bg-emerald-400 text-white'
                      : 'bg-[color:var(--surface-2)] text-[color:var(--text-3)] cursor-not-allowed border border-[color:var(--border)]'
                  }`}
                >
                  {anyChecked
                    ? isLast ? "I'm continuing" : 'Continue — next habit'
                    : 'Complete at least one action'}
                </button>

                <button
                  onClick={handleSkip}
                  className="w-full mt-3 py-2 text-[12px] text-[color:var(--text-3)] hover:text-[color:var(--text-2)] transition-colors"
                >
                  Skip actions — just acknowledge
                </button>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </motion.div>
    </div>
  );
}
