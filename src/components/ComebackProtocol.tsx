import React, { useState } from 'react';
import { NeuroStack } from '../store/useNeuroStore';
import { getComebackMessage, generateMicroActions, getDaysMissed } from '../utils/comebackHelpers';
import { ArrowRight, CheckSquare, Square } from 'lucide-react';

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
    const microActionsCompleted = allChecked;
    onComplete(stack.id, stack.title, microActionsCompleted);

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
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-gray-950/90 backdrop-blur-sm px-4">
      <div className="w-full max-w-lg bg-gray-900 border border-amber-800/30 rounded-2xl shadow-[0_0_60px_rgba(251,191,36,0.08)] overflow-hidden">

        {/* Top bar */}
        <div className="flex items-center justify-between px-6 pt-5 pb-4 border-b border-gray-800">
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 rounded-full bg-amber-400 animate-pulse" />
            <span className="text-xs font-mono text-amber-400 tracking-widest uppercase">
              Comeback Protocol
            </span>
          </div>
          {totalCount > 1 && (
            <span className="text-xs text-slate-500 font-mono">
              {currentIndex + 1} / {totalCount}
            </span>
          )}
        </div>

        <div className="px-6 py-6">
          {/* Habit label */}
          <div className="text-xs text-slate-500 uppercase tracking-wider mb-1">Habit paused</div>
          <div className="text-base font-semibold text-white mb-5">{stack.title}</div>

          {phase === 'reframe' && (
            <>
              {/* Reframe message */}
              <div className="bg-gray-800/60 border border-gray-700/50 rounded-xl p-5 mb-6">
                <p className="text-lg font-semibold text-amber-300 mb-2 leading-snug">
                  {message.headline}
                </p>
                <p className="text-sm text-slate-400 leading-relaxed">
                  {message.body}
                </p>
              </div>

              {daysMissed > 1 && (
                <p className="text-xs text-slate-500 mb-6 text-center">
                  {daysMissed} day{daysMissed > 1 ? 's' : ''} since last completion
                </p>
              )}

              <button
                onClick={() => setPhase('actions')}
                className="w-full py-3.5 bg-amber-500/15 hover:bg-amber-500/25 border border-amber-500/30 text-amber-300 font-semibold rounded-xl flex items-center justify-center gap-2 transition-all"
              >
                Show me the re-entry plan
                <ArrowRight className="w-4 h-4" />
              </button>
            </>
          )}

          {phase === 'actions' && (
            <>
              <div className="mb-2">
                <p className="text-sm text-slate-400 mb-4">
                  Three micro-actions. Do any one of them and you are continuing — not restarting.
                </p>

                <div className="space-y-3 mb-6">
                  {microActions.map((action, i) => (
                    <button
                      key={i}
                      onClick={() => toggleCheck(i)}
                      className={`w-full text-left p-4 rounded-xl border transition-all flex items-start gap-3 ${
                        checked[i]
                          ? 'bg-emerald-900/20 border-emerald-600/40 text-emerald-300'
                          : 'bg-gray-800/50 border-gray-700/50 text-slate-300 hover:border-gray-600'
                      }`}
                    >
                      <span className="mt-0.5 shrink-0">
                        {checked[i]
                          ? <CheckSquare className="w-5 h-5 text-emerald-400" />
                          : <Square className="w-5 h-5 text-slate-500" />
                        }
                      </span>
                      <span className="text-sm leading-relaxed">{action}</span>
                    </button>
                  ))}
                </div>
              </div>

              <button
                onClick={handleContinue}
                disabled={!anyChecked && !allChecked}
                className={`w-full py-3.5 font-bold rounded-xl flex items-center justify-center gap-2 transition-all ${
                  anyChecked
                    ? 'bg-emerald-600 hover:bg-emerald-500 text-white shadow-[0_0_20px_rgba(52,211,153,0.2)]'
                    : 'bg-gray-800 text-slate-500 cursor-not-allowed border border-gray-700'
                }`}
              >
                {anyChecked
                  ? isLast
                    ? "I'm continuing"
                    : 'Continue — next habit'
                  : 'Complete at least one action to continue'
                }
              </button>

              <button
                onClick={() => {
                  onComplete(stack.id, stack.title, false);
                  const next = currentIndex + 1;
                  if (next < missedStacks.length) {
                    setCurrentIndex(next);
                    setChecked([false, false, false]);
                    setPhase('reframe');
                  } else {
                    onDismiss();
                  }
                }}
                className="w-full mt-3 py-2 text-sm text-slate-500 hover:text-slate-400 transition-colors"
              >
                Skip actions — just acknowledge
              </button>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
