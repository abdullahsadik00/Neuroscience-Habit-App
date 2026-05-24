import React, { useState } from 'react';
import { X, Plus, Brain, Zap, Shield, Dumbbell, Sparkles } from 'lucide-react';
import { NeuroStack, NeuroSwap } from '../store/useNeuroStore';

type Mode = 'stack' | 'swap';

type StackDraft = Omit<NeuroStack, 'id' | 'myelinationLevel' | 'streak' | 'completions' | 'createdAt' | 'isActive'>;
type SwapDraft = Omit<NeuroSwap, 'id' | 'urgeSurfingCompletions' | 'slips' | 'createdAt' | 'isActive'>;

interface Props {
  onAddStack: (stack: StackDraft) => void;
  onAddSwap: (swap: SwapDraft) => void;
  onClose: () => void;
}

const CATEGORY_META = [
  { key: 'focus', label: 'Focus', icon: Brain, color: 'text-violet-400', bg: 'bg-violet-900/20 border-violet-700/40', activeBg: 'bg-violet-900/40 border-violet-500/60' },
  { key: 'wellness', label: 'Wellness', icon: Sparkles, color: 'text-emerald-400', bg: 'bg-emerald-900/20 border-emerald-700/40', activeBg: 'bg-emerald-900/40 border-emerald-500/60' },
  { key: 'mindset', label: 'Mindset', icon: Zap, color: 'text-cyan-400', bg: 'bg-cyan-900/20 border-cyan-700/40', activeBg: 'bg-cyan-900/40 border-cyan-500/60' },
  { key: 'fitness', label: 'Fitness', icon: Dumbbell, color: 'text-orange-400', bg: 'bg-orange-900/20 border-orange-700/40', activeBg: 'bg-orange-900/40 border-orange-500/60' },
] as const;

const FRICTION_LABELS = ['', 'Minimal', 'Light', 'Moderate', 'Strong', 'Maximum'];

export default function AddHabitModal({ onAddStack, onAddSwap, onClose }: Props) {
  const [mode, setMode] = useState<Mode>('stack');

  const [stackDraft, setStackDraft] = useState<StackDraft>({
    title: '',
    anchorCue: '',
    action: '',
    reward: '',
    category: 'focus',
    acetylcholineDuration: 10,
  });

  const [swapDraft, setSwapDraft] = useState<SwapDraft>({
    title: '',
    cue: '',
    badResponse: '',
    interceptAction: '',
    frictionLevel: 3,
    frictionSteps: ['', '', ''],
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
      <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" onClick={onClose} />

      <div className="relative w-full max-w-lg max-h-[90vh] overflow-y-auto glass-panel rounded-2xl shadow-2xl">
        <div className="sticky top-0 glass-panel rounded-t-2xl px-5 py-4 flex items-center justify-between border-b border-white/[0.06] z-10">
          <h2 className="text-base font-semibold text-white">Add to your system</h2>
          <button onClick={onClose} className="p-1.5 rounded-lg hover:bg-white/10 transition-colors">
            <X className="w-4 h-4 text-slate-400" />
          </button>
        </div>

        <div className="p-5">
          {/* Mode toggle */}
          <div className="flex gap-2 mb-6 bg-gray-900/60 rounded-xl p-1">
            <button
              onClick={() => setMode('stack')}
              className={`flex-1 py-2 rounded-lg text-xs font-semibold transition-all ${
                mode === 'stack' ? 'bg-indigo-600/30 text-indigo-300 border border-indigo-500/40' : 'text-slate-500 hover:text-slate-300'
              }`}
            >
              <Brain className="w-3.5 h-3.5 inline mr-1.5 -mt-0.5" />
              Good Habit (Neuro-Stack)
            </button>
            <button
              onClick={() => setMode('swap')}
              className={`flex-1 py-2 rounded-lg text-xs font-semibold transition-all ${
                mode === 'swap' ? 'bg-rose-600/20 text-rose-300 border border-rose-500/30' : 'text-slate-500 hover:text-slate-300'
              }`}
            >
              <Shield className="w-3.5 h-3.5 inline mr-1.5 -mt-0.5" />
              Bad Habit (Neuro-Swap)
            </button>
          </div>

          {mode === 'stack' ? (
            <form onSubmit={handleStackSubmit} className="space-y-4">
              <div>
                <label className="block text-[10px] text-slate-500 font-mono uppercase tracking-wider mb-1.5">Habit name *</label>
                <input
                  type="text"
                  value={stackDraft.title}
                  onChange={(e) => setStackDraft({ ...stackDraft, title: e.target.value })}
                  placeholder="e.g. Morning cold shower"
                  className="w-full bg-gray-900/60 border border-gray-700/60 rounded-lg px-3 py-2.5 text-sm text-white placeholder-slate-600 focus:outline-none focus:border-indigo-500/60 transition-colors"
                />
              </div>

              <div>
                <label className="block text-[10px] text-slate-500 font-mono uppercase tracking-wider mb-1.5">Anchor cue *</label>
                <input
                  type="text"
                  value={stackDraft.anchorCue}
                  onChange={(e) => setStackDraft({ ...stackDraft, anchorCue: e.target.value })}
                  placeholder="After I... / When I..."
                  className="w-full bg-gray-900/60 border border-gray-700/60 rounded-lg px-3 py-2.5 text-sm text-white placeholder-slate-600 focus:outline-none focus:border-indigo-500/60 transition-colors"
                />
              </div>

              <div>
                <label className="block text-[10px] text-slate-500 font-mono uppercase tracking-wider mb-1.5">Action (specific behavior)</label>
                <input
                  type="text"
                  value={stackDraft.action}
                  onChange={(e) => setStackDraft({ ...stackDraft, action: e.target.value })}
                  placeholder="I will..."
                  className="w-full bg-gray-900/60 border border-gray-700/60 rounded-lg px-3 py-2.5 text-sm text-white placeholder-slate-600 focus:outline-none focus:border-indigo-500/60 transition-colors"
                />
              </div>

              <div>
                <label className="block text-[10px] text-slate-500 font-mono uppercase tracking-wider mb-1.5">Neural reward</label>
                <input
                  type="text"
                  value={stackDraft.reward}
                  onChange={(e) => setStackDraft({ ...stackDraft, reward: e.target.value })}
                  placeholder="I will celebrate by..."
                  className="w-full bg-gray-900/60 border border-gray-700/60 rounded-lg px-3 py-2.5 text-sm text-white placeholder-slate-600 focus:outline-none focus:border-indigo-500/60 transition-colors"
                />
              </div>

              <div>
                <label className="block text-[10px] text-slate-500 font-mono uppercase tracking-wider mb-2">Category</label>
                <div className="grid grid-cols-2 gap-2">
                  {CATEGORY_META.map(({ key, label, icon: Icon, color, bg, activeBg }) => (
                    <button
                      key={key}
                      type="button"
                      onClick={() => setStackDraft({ ...stackDraft, category: key })}
                      className={`flex items-center gap-2 px-3 py-2 rounded-lg border text-xs font-semibold transition-all ${
                        stackDraft.category === key ? `${activeBg} ${color}` : `${bg} text-slate-400 hover:text-white`
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
                className="w-full py-2.5 rounded-xl bg-indigo-600/30 hover:bg-indigo-600/50 text-indigo-300 font-semibold text-sm border border-indigo-500/40 transition-all disabled:opacity-40 disabled:cursor-not-allowed flex items-center justify-center gap-2 button-pulse"
              >
                <Plus className="w-4 h-4" />
                Add Habit to Stack
              </button>
            </form>
          ) : (
            <form onSubmit={handleSwapSubmit} className="space-y-4">
              <div>
                <label className="block text-[10px] text-slate-500 font-mono uppercase tracking-wider mb-1.5">Bad habit name *</label>
                <input
                  type="text"
                  value={swapDraft.title}
                  onChange={(e) => setSwapDraft({ ...swapDraft, title: e.target.value })}
                  placeholder="e.g. Mindless social media"
                  className="w-full bg-gray-900/60 border border-gray-700/60 rounded-lg px-3 py-2.5 text-sm text-white placeholder-slate-600 focus:outline-none focus:border-rose-500/60 transition-colors"
                />
              </div>

              <div>
                <label className="block text-[10px] text-slate-500 font-mono uppercase tracking-wider mb-1.5">Trigger cue</label>
                <input
                  type="text"
                  value={swapDraft.cue}
                  onChange={(e) => setSwapDraft({ ...swapDraft, cue: e.target.value })}
                  placeholder="When I feel..."
                  className="w-full bg-gray-900/60 border border-gray-700/60 rounded-lg px-3 py-2.5 text-sm text-white placeholder-slate-600 focus:outline-none focus:border-rose-500/60 transition-colors"
                />
              </div>

              <div>
                <label className="block text-[10px] text-slate-500 font-mono uppercase tracking-wider mb-1.5">Intercept action *</label>
                <input
                  type="text"
                  value={swapDraft.interceptAction}
                  onChange={(e) => setSwapDraft({ ...swapDraft, interceptAction: e.target.value })}
                  placeholder="Instead I will..."
                  className="w-full bg-gray-900/60 border border-gray-700/60 rounded-lg px-3 py-2.5 text-sm text-white placeholder-slate-600 focus:outline-none focus:border-rose-500/60 transition-colors"
                />
              </div>

              <div>
                <label className="block text-[10px] text-slate-500 font-mono uppercase tracking-wider mb-2">
                  Friction level: <span className="text-rose-400">{FRICTION_LABELS[swapDraft.frictionLevel]}</span>
                </label>
                <input
                  type="range"
                  min={1}
                  max={5}
                  value={swapDraft.frictionLevel}
                  onChange={(e) => setSwapDraft({ ...swapDraft, frictionLevel: Number(e.target.value) })}
                  className="w-full accent-rose-500"
                />
                <div className="flex justify-between text-[9px] text-slate-600 mt-1 font-mono">
                  <span>Minimal</span><span>Maximum</span>
                </div>
              </div>

              <button
                type="submit"
                disabled={!swapDraft.title.trim() || !swapDraft.interceptAction.trim()}
                className="w-full py-2.5 rounded-xl bg-rose-600/20 hover:bg-rose-600/40 text-rose-300 font-semibold text-sm border border-rose-500/30 transition-all disabled:opacity-40 disabled:cursor-not-allowed flex items-center justify-center gap-2 button-pulse"
              >
                <Shield className="w-4 h-4" />
                Add Friction Protocol
              </button>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}
