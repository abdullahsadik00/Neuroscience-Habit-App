import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { X, Plus, Brain, Zap, Shield, Dumbbell, Sparkles } from 'lucide-react';
import type { NeuroStack, NeuroSwap } from '../store/useNeuroStore';

type Mode = 'stack' | 'swap';

type StackDraft = Omit<NeuroStack, 'id' | 'myelinationLevel' | 'streak' | 'completions' | 'createdAt' | 'isActive'>;
type SwapDraft = Omit<NeuroSwap, 'id' | 'urgeSurfingCompletions' | 'slips' | 'createdAt' | 'isActive'>;

interface Props {
  onAddStack: (stack: StackDraft) => void;
  onAddSwap: (swap: SwapDraft) => void;
  onClose: () => void;
}

const CATEGORY_META = [
  { key: 'focus',    label: 'Focus',    icon: Brain,    badge: 'bg-indigo-50 text-indigo-600 dark:bg-indigo-500/15 dark:text-indigo-400', active: 'ring-2 ring-indigo-400' },
  { key: 'wellness', label: 'Wellness', icon: Sparkles, badge: 'bg-emerald-50 text-emerald-600 dark:bg-emerald-500/15 dark:text-emerald-400', active: 'ring-2 ring-emerald-400' },
  { key: 'mindset',  label: 'Mindset',  icon: Zap,      badge: 'bg-sky-50 text-sky-600 dark:bg-sky-500/15 dark:text-sky-400', active: 'ring-2 ring-sky-400' },
  { key: 'fitness',  label: 'Fitness',  icon: Dumbbell, badge: 'bg-amber-50 text-amber-600 dark:bg-amber-500/15 dark:text-amber-400', active: 'ring-2 ring-amber-400' },
] as const;

const FRICTION_LABELS = ['', 'Minimal', 'Light', 'Moderate', 'Strong', 'Maximum'];

export default function AddHabitModal({ onAddStack, onAddSwap, onClose }: Props) {
  const [mode, setMode] = useState<Mode>('stack');

  const [stackDraft, setStackDraft] = useState<StackDraft>({
    title: '', anchorCue: '', action: '', reward: '', category: 'focus', acetylcholineDuration: 10,
  });

  const [swapDraft, setSwapDraft] = useState<SwapDraft>({
    title: '', cue: '', badResponse: '', interceptAction: '', frictionLevel: 3, frictionSteps: ['', '', ''],
  });

  function handleStackSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!stackDraft.title.trim() || !stackDraft.anchorCue.trim()) return;
    onAddStack(stackDraft);
    onClose();
  }

  function handleSwapSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!swapDraft.title.trim() || !swapDraft.interceptAction.trim()) return;
    onAddSwap({ ...swapDraft, frictionSteps: swapDraft.frictionSteps.filter(Boolean) });
    onClose();
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/40 dark:bg-black/60 backdrop-blur-md" onClick={onClose} />
      <motion.div
        initial={{ opacity: 0, scale: 0.95, y: 8 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.95 }}
        transition={{ duration: 0.22, ease: [0.25, 0.46, 0.45, 0.94] }}
        className="relative w-full max-w-lg max-h-[90vh] overflow-y-auto card shadow-[var(--shadow-modal)]"
      >
        {/* Header */}
        <div className="sticky top-0 bg-[color:var(--surface)] px-5 py-4 flex items-center justify-between border-b border-[color:var(--border)] z-10 rounded-t-[20px]">
          <h2 className="text-[15px] font-semibold text-[color:var(--text-1)]">Add to your system</h2>
          <button onClick={onClose} className="p-1.5 rounded-lg hover:bg-[color:var(--surface-2)] transition-colors">
            <X className="w-4 h-4 text-[color:var(--text-2)]" />
          </button>
        </div>

        <div className="p-5">
          {/* Mode tabs */}
          <div className="bg-[color:var(--surface-2)] border border-[color:var(--border)] flex gap-1 mb-6 p-1 rounded-[10px]">
            <button
              onClick={() => setMode('stack')}
              className={`flex-1 py-2 rounded-[8px] text-[12px] font-semibold flex items-center justify-center gap-1.5 transition-all ${
                mode === 'stack'
                  ? 'bg-[color:var(--surface)] text-[color:var(--text-1)] shadow-[0_1px_3px_rgba(0,0,0,0.08)]'
                  : 'text-[color:var(--text-3)] hover:text-[color:var(--text-2)]'
              }`}
            >
              <Brain className="w-3.5 h-3.5" />
              Good Habit
            </button>
            <button
              onClick={() => setMode('swap')}
              className={`flex-1 py-2 rounded-[8px] text-[12px] font-semibold flex items-center justify-center gap-1.5 transition-all ${
                mode === 'swap'
                  ? 'bg-[color:var(--surface)] text-rose-600 dark:text-rose-400 shadow-[0_1px_3px_rgba(0,0,0,0.08)]'
                  : 'text-[color:var(--text-3)] hover:text-[color:var(--text-2)]'
              }`}
            >
              <Shield className="w-3.5 h-3.5" />
              Bad Habit
            </button>
          </div>

          {mode === 'stack' ? (
            <form onSubmit={handleStackSubmit} className="space-y-4">
              <div>
                <label className="ns-label">Habit name *</label>
                <input
                  type="text"
                  value={stackDraft.title}
                  onChange={(e) => setStackDraft({ ...stackDraft, title: e.target.value })}
                  placeholder="e.g. Morning cold shower"
                  className="ns-input"
                />
              </div>
              <div>
                <label className="ns-label">Anchor cue — when does it fire? *</label>
                <input
                  type="text"
                  value={stackDraft.anchorCue}
                  onChange={(e) => setStackDraft({ ...stackDraft, anchorCue: e.target.value })}
                  placeholder="After I pour my morning coffee..."
                  className="ns-input"
                />
                <p className="text-[10px] text-[color:var(--text-3)] mt-1.5 leading-snug">
                  Specific triggers 3× more effective than vague ones. Try: "After I sit at my desk" not "In the morning."
                </p>
              </div>
              <div>
                <label className="ns-label">Action — exactly what will you do?</label>
                <input
                  type="text"
                  value={stackDraft.action}
                  onChange={(e) => setStackDraft({ ...stackDraft, action: e.target.value })}
                  placeholder="I will open my notebook and write one sentence..."
                  className="ns-input"
                />
              </div>

              {/* Live implementation intention preview */}
              {stackDraft.anchorCue.trim() && stackDraft.action.trim() && (
                <div className="card-2 p-4 rounded-xl border border-indigo-100 dark:border-indigo-500/20">
                  <p className="text-[9px] font-semibold uppercase tracking-wider text-indigo-500 dark:text-indigo-400 mb-2">
                    Your implementation intention
                  </p>
                  <p className="text-[13px] text-[color:var(--text-1)] leading-relaxed">
                    <span className="text-[color:var(--text-3)]">When </span>
                    <span className="font-medium">{stackDraft.anchorCue.replace(/^(after i |when i |after |when )/i, '')}</span>
                    <span className="text-[color:var(--text-3)]">, I will </span>
                    <span className="font-medium">{stackDraft.action.replace(/^(i will |i'll |i )/i, '')}</span>
                  </p>
                </div>
              )}
              <div>
                <label className="ns-label">Neural reward</label>
                <input
                  type="text"
                  value={stackDraft.reward}
                  onChange={(e) => setStackDraft({ ...stackDraft, reward: e.target.value })}
                  placeholder="I will celebrate by..."
                  className="ns-input"
                />
              </div>
              <div>
                <label className="ns-label">Category</label>
                <div className="grid grid-cols-2 gap-2">
                  {CATEGORY_META.map(({ key, label, icon: Icon, badge, active }) => (
                    <button
                      key={key}
                      type="button"
                      onClick={() => setStackDraft({ ...stackDraft, category: key })}
                      className={`card-2 flex items-center gap-2 px-3 py-2.5 rounded-xl text-[12px] font-semibold transition-all ${badge} ${
                        stackDraft.category === key ? active : 'hover:ring-1 hover:ring-[color:var(--border-2)]'
                      }`}
                    >
                      <Icon className="w-3.5 h-3.5" />
                      {label}
                    </button>
                  ))}
                </div>
              </div>
              <button
                type="submit"
                disabled={!stackDraft.title.trim() || !stackDraft.anchorCue.trim()}
                className="btn-primary w-full h-12"
              >
                <Plus className="w-4 h-4" />
                Add Habit to Stack
              </button>
            </form>
          ) : (
            <form onSubmit={handleSwapSubmit} className="space-y-4">
              <div>
                <label className="ns-label">Bad habit name *</label>
                <input
                  type="text"
                  value={swapDraft.title}
                  onChange={(e) => setSwapDraft({ ...swapDraft, title: e.target.value })}
                  placeholder="e.g. Mindless social media"
                  className="ns-input"
                />
              </div>
              <div>
                <label className="ns-label">Trigger cue</label>
                <input
                  type="text"
                  value={swapDraft.cue}
                  onChange={(e) => setSwapDraft({ ...swapDraft, cue: e.target.value })}
                  placeholder="When I feel..."
                  className="ns-input"
                />
              </div>
              <div>
                <label className="ns-label">Intercept action *</label>
                <input
                  type="text"
                  value={swapDraft.interceptAction}
                  onChange={(e) => setSwapDraft({ ...swapDraft, interceptAction: e.target.value })}
                  placeholder="Instead I will..."
                  className="ns-input"
                />
              </div>
              <div>
                <label className="ns-label">
                  Friction level: <span className="text-rose-500 dark:text-rose-400 normal-case">{FRICTION_LABELS[swapDraft.frictionLevel]}</span>
                </label>
                <input
                  type="range" min={1} max={5}
                  value={swapDraft.frictionLevel}
                  onChange={(e) => setSwapDraft({ ...swapDraft, frictionLevel: Number(e.target.value) })}
                  className="w-full accent-rose-500 mt-1"
                />
                <div className="flex justify-between text-[10px] text-[color:var(--text-3)] mt-1">
                  <span>Minimal</span><span>Maximum</span>
                </div>
              </div>
              <button
                type="submit"
                disabled={!swapDraft.title.trim() || !swapDraft.interceptAction.trim()}
                className="w-full h-12 rounded-xl bg-rose-500 hover:bg-rose-600 dark:bg-rose-500 dark:hover:bg-rose-400 text-white font-semibold text-[14px] flex items-center justify-center gap-2 transition-all disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <Shield className="w-4 h-4" />
                Add Friction Protocol
              </button>
            </form>
          )}
        </div>
      </motion.div>
    </div>
  );
}
