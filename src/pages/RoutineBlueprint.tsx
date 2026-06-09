import { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Sun, Moon, RefreshCw, X, ChevronRight } from 'lucide-react';
import { useNeuroStore } from '../store/useNeuroStore';
import { useTheme } from '../contexts/ThemeContext';
import { buildBlueprint, getAlternativesFor } from '../utils/blueprintEngine';
import { getArchetypeName } from '../utils/brainHelpers';
import type { HabitTemplate } from '../data/habitLibrary';

const CAT_BADGE: Record<string, string> = {
  focus:    'bg-indigo-50 text-indigo-600 dark:bg-indigo-500/15 dark:text-indigo-400',
  wellness: 'bg-emerald-50 text-emerald-600 dark:bg-emerald-500/15 dark:text-emerald-400',
  mindset:  'bg-sky-50 text-sky-600 dark:bg-sky-500/15 dark:text-sky-400',
  fitness:  'bg-amber-50 text-amber-600 dark:bg-amber-500/15 dark:text-amber-400',
};

const TIMING_LABEL: Record<string, string> = {
  morning: '🌅 Morning',
  evening: '🌙 Evening',
  anytime: '⏱ Anytime',
};

const ENERGY_LABEL: Record<string, string> = {
  low: 'Low effort',
  medium: 'Medium effort',
  high: 'High effort',
};

const DURATION_LABEL: Record<string, string> = {
  '2min': '2 min', '5min': '5 min', '10min': '10 min',
  '15min': '15 min', '30min': '30 min',
};

export default function RoutineBlueprint() {
  const { brainProfile, addNeuroStack, acceptBlueprint, neurochemistry } = useNeuroStore();
  const { theme, toggleTheme } = useTheme();

  const initialBlueprint = useMemo(() => {
    if (!brainProfile) return [];
    return buildBlueprint(brainProfile, neurochemistry);
  }, [brainProfile, neurochemistry]);

  const [habits, setHabits] = useState<HabitTemplate[]>(initialBlueprint);
  const [swapTarget, setSwapTarget] = useState<string | null>(null);
  const [swapOptions, setSwapOptions] = useState<HabitTemplate[]>([]);
  const [confirming, setConfirming] = useState(false);

  if (!brainProfile) return null;

  const archetype = getArchetypeName(brainProfile);

  function openSwap(habitId: string) {
    const excludeIds = habits.map(h => h.id);
    const alts = getAlternativesFor(habitId, brainProfile!, excludeIds);
    setSwapOptions(alts);
    setSwapTarget(habitId);
  }

  function applySwap(replacement: HabitTemplate) {
    setHabits(prev => prev.map(h => h.id === swapTarget ? replacement : h));
    setSwapTarget(null);
    setSwapOptions([]);
  }

  function removeHabit(habitId: string) {
    setHabits(prev => prev.filter(h => h.id !== habitId));
  }

  function handleConfirm() {
    setConfirming(true);
    habits.forEach(template => {
      addNeuroStack({
        title: template.title,
        anchorCue: template.anchorCue,
        action: template.action,
        reward: template.reward,
        category: template.category,
        acetylcholineDuration: template.duration === '30min' ? 30
          : template.duration === '15min' ? 15
          : template.duration === '10min' ? 10
          : 5,
      });
    });
    setTimeout(() => acceptBlueprint(), 600);
  }

  return (
    <div className="min-h-screen bg-[#FAFAF8] dark:bg-[#0F1115]">
      {/* Theme toggle */}
      <button onClick={toggleTheme} className="theme-toggle fixed top-5 right-5 z-50">
        {theme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
      </button>

      <div className="max-w-md mx-auto px-6 py-12">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="flex flex-col gap-6"
        >
          {/* Header */}
          <div className="text-center">
            <p className="section-header mb-3">Your Starter Routine</p>
            <h1 className="text-[26px] font-bold text-[color:var(--text-1)] tracking-tight leading-tight">
              Built for the {archetype}
            </h1>
            <p className="text-[13px] text-[color:var(--text-2)] mt-2 leading-relaxed">
              {habits.length} habits matched to your profile. Review, swap, or remove any before starting.
            </p>
          </div>

          {/* Habit cards */}
          <div className="flex flex-col gap-3">
            <AnimatePresence mode="popLayout">
              {habits.map((habit, i) => (
                <motion.div
                  key={habit.id}
                  layout
                  initial={{ opacity: 0, y: 12 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, x: -20, scale: 0.95 }}
                  transition={{ duration: 0.25, delay: i * 0.06 }}
                  className="card p-5"
                >
                  {/* Top row */}
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex flex-wrap gap-1.5">
                      <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full capitalize ${CAT_BADGE[habit.category]}`}>
                        {habit.category}
                      </span>
                      <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-[color:var(--surface-2)] text-[color:var(--text-3)]">
                        {TIMING_LABEL[habit.timing]}
                      </span>
                      <span className="text-[10px] font-medium px-2 py-0.5 rounded-full bg-[color:var(--surface-2)] text-[color:var(--text-3)]">
                        {DURATION_LABEL[habit.duration]}
                      </span>
                    </div>
                    {habits.length > 1 && (
                      <button
                        onClick={() => removeHabit(habit.id)}
                        className="p-1 rounded-lg hover:bg-[color:var(--surface-2)] transition-colors shrink-0 ml-1"
                      >
                        <X className="w-3.5 h-3.5 text-[color:var(--text-3)]" />
                      </button>
                    )}
                  </div>

                  <h3 className="text-[15px] font-semibold text-[color:var(--text-1)] leading-snug mb-1">
                    {habit.title}
                  </h3>
                  <p className="text-[12px] text-[color:var(--text-3)] leading-relaxed mb-3">
                    {habit.description}
                  </p>

                  {/* Cue preview */}
                  <div className="card-2 px-3 py-2.5 rounded-xl mb-3">
                    <p className="text-[10px] font-semibold uppercase tracking-wider text-[color:var(--text-3)] mb-0.5">When</p>
                    <p className="text-[12px] text-[color:var(--text-1)]">{habit.anchorCue}</p>
                  </div>

                  {/* Effort + swap */}
                  <div className="flex items-center justify-between">
                    <span className="text-[11px] text-[color:var(--text-3)]">{ENERGY_LABEL[habit.energyRequired]}</span>
                    <button
                      onClick={() => openSwap(habit.id)}
                      className="flex items-center gap-1 text-[12px] font-semibold text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 dark:hover:text-indigo-300 transition-colors"
                    >
                      <RefreshCw className="w-3 h-3" />
                      Swap
                    </button>
                  </div>
                </motion.div>
              ))}
            </AnimatePresence>
          </div>

          {habits.length === 0 && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="card py-10 flex flex-col items-center text-center"
            >
              <div className="text-3xl mb-3">🧠</div>
              <p className="text-[14px] font-semibold text-[color:var(--text-1)] mb-1">All habits removed</p>
              <p className="text-[13px] text-[color:var(--text-2)]">Add some from your dashboard after starting.</p>
            </motion.div>
          )}

          {/* CTA */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.4 }}
            className="flex flex-col gap-3"
          >
            <button
              onClick={handleConfirm}
              disabled={confirming || habits.length === 0}
              className="btn-primary w-full h-14 rounded-[16px] text-[15px] disabled:opacity-60"
            >
              {confirming ? 'Starting your routine…' : `Start my routine (${habits.length} habit${habits.length !== 1 ? 's' : ''})`}
              {!confirming && <ChevronRight className="w-4 h-4" />}
            </button>
            <button
              onClick={() => acceptBlueprint()}
              className="text-[12px] text-[color:var(--text-3)] hover:text-[color:var(--text-2)] text-center transition-colors"
            >
              Skip — I'll add habits myself
            </button>
          </motion.div>

          <p className="text-center text-[11px] text-[color:var(--text-3)]">
            You can always edit, add, or remove habits from the dashboard
          </p>
        </motion.div>
      </div>

      {/* Swap sheet */}
      <AnimatePresence>
        {swapTarget && (
          <>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              className="fixed inset-0 bg-black/40 dark:bg-black/60 backdrop-blur-sm z-40"
              onClick={() => { setSwapTarget(null); setSwapOptions([]); }}
            />
            <motion.div
              initial={{ opacity: 0, y: 40 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 40 }}
              transition={{ duration: 0.25, ease: [0.25, 0.46, 0.45, 0.94] }}
              className="fixed bottom-0 left-0 right-0 z-50 bg-[color:var(--surface)] rounded-t-[28px] px-6 pt-6 pb-safe max-w-lg mx-auto shadow-[var(--shadow-modal)]"
            >
              <div className="w-10 h-1 bg-[color:var(--surface-3)] rounded-full mx-auto mb-5" />
              <p className="section-header mb-4">Swap with another habit</p>

              {swapOptions.length === 0 ? (
                <p className="text-[13px] text-[color:var(--text-2)] text-center py-4">
                  No more alternatives in this category.
                </p>
              ) : (
                <div className="flex flex-col gap-2.5">
                  {swapOptions.map(alt => (
                    <button
                      key={alt.id}
                      onClick={() => applySwap(alt)}
                      className="card card-hover w-full text-left p-4"
                    >
                      <div className="flex items-start justify-between gap-3">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-1.5 mb-1.5">
                            <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full capitalize ${CAT_BADGE[alt.category]}`}>
                              {alt.category}
                            </span>
                            <span className="text-[10px] text-[color:var(--text-3)]">{DURATION_LABEL[alt.duration]}</span>
                          </div>
                          <p className="text-[13px] font-semibold text-[color:var(--text-1)] leading-snug">{alt.title}</p>
                          <p className="text-[11px] text-[color:var(--text-3)] mt-0.5 leading-relaxed line-clamp-2">{alt.description}</p>
                        </div>
                        <ChevronRight className="w-4 h-4 text-[color:var(--text-3)] shrink-0 mt-1" />
                      </div>
                    </button>
                  ))}
                </div>
              )}

              <button
                onClick={() => { setSwapTarget(null); setSwapOptions([]); }}
                className="btn-ghost w-full mt-4"
              >
                Cancel
              </button>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </div>
  );
}
