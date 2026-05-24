import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, ChevronRight } from 'lucide-react';
import type { CheckinRecord } from '../store/useNeuroStore';

type Draft = Omit<CheckinRecord, 'id' | 'recalibrationApplied'>;

interface Props {
  onSubmit: (record: Draft) => void;
  onDismiss: () => void;
}

const STEPS = 4;

const BLOCKER_OPTIONS = [
  { value: 'energy',       label: 'Low energy',     sub: 'Didn't have the fuel when it was time' },
  { value: 'overwhelm',    label: 'Overwhelm',       sub: 'Too many things competing for attention' },
  { value: 'distraction',  label: 'Distraction',     sub: 'Got pulled away before I started' },
  { value: 'life',         label: 'Life events',     sub: 'External circumstances knocked me off' },
];

const CONSISTENCY_LABELS: Record<number, string> = {
  1: 'Very inconsistent',
  2: 'Mostly missed',
  3: 'Hit or miss',
  4: 'Mostly consistent',
  5: 'Almost every day',
};

const ENERGY_OPTIONS = [
  { value: 'low',    label: 'Low',    emoji: '🪫', desc: 'Often tired or drained' },
  { value: 'normal', label: 'Normal', emoji: '⚡', desc: 'Typical baseline' },
  { value: 'high',   label: 'High',   emoji: '🔋', desc: 'Energised and sharp' },
] as const;

export default function WeeklyCheckin({ onSubmit, onDismiss }: Props) {
  const [step, setStep] = useState(0);
  const [dir, setDir] = useState(1);
  const [draft, setDraft] = useState<Partial<Draft>>({
    date: new Date().toISOString(),
  });

  function next(updates: Partial<Draft>) {
    const merged = { ...draft, ...updates };
    setDraft(merged);
    if (step < STEPS - 1) {
      setDir(1);
      setStep(s => s + 1);
    } else {
      onSubmit(merged as Draft);
    }
  }

  function back() {
    setDir(-1);
    setStep(s => s - 1);
  }

  const progress = ((step + 1) / STEPS) * 100;

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center">
      {/* Backdrop */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="absolute inset-0 bg-black/40 dark:bg-black/60 backdrop-blur-sm"
        onClick={onDismiss}
      />

      {/* Sheet */}
      <motion.div
        initial={{ y: '100%' }}
        animate={{ y: 0 }}
        exit={{ y: '100%' }}
        transition={{ type: 'spring', stiffness: 300, damping: 30 }}
        className="relative w-full max-w-lg bg-[color:var(--surface)] rounded-t-[28px] shadow-[var(--shadow-modal)] overflow-hidden"
      >
        {/* Handle */}
        <div className="flex justify-center pt-4 pb-2">
          <div className="w-10 h-1 bg-[color:var(--surface-3)] rounded-full" />
        </div>

        {/* Header */}
        <div className="flex items-center justify-between px-6 pb-4">
          <div className="flex-1">
            <p className="section-header mb-0.5">Weekly Check-in</p>
            <p className="text-[11px] text-[color:var(--text-3)]">Question {step + 1} of {STEPS}</p>
          </div>
          <button
            onClick={onDismiss}
            className="p-1.5 rounded-lg hover:bg-[color:var(--surface-2)] transition-colors"
          >
            <X className="w-4 h-4 text-[color:var(--text-3)]" />
          </button>
        </div>

        {/* Progress bar */}
        <div className="mx-6 mb-5 h-[3px] progress-track">
          <motion.div
            className="progress-fill bg-indigo-500 dark:bg-indigo-400"
            initial={false}
            animate={{ width: `${progress}%` }}
            transition={{ duration: 0.4, ease: 'easeOut' }}
          />
        </div>

        {/* Step content */}
        <div className="px-6 pb-8 min-h-[320px]">
          <AnimatePresence mode="wait" custom={dir}>
            <motion.div
              key={step}
              custom={dir}
              initial={{ opacity: 0, x: dir * 24 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: dir * -24 }}
              transition={{ duration: 0.22, ease: [0.25, 0.46, 0.45, 0.94] }}
            >
              {step === 0 && (
                <StepConsistency
                  value={(draft.consistency as number) ?? 0}
                  onSelect={(v) => next({ consistency: v as Draft['consistency'] })}
                />
              )}
              {step === 1 && (
                <StepBlocker
                  value={draft.weeklyBlocker ?? ''}
                  onSelect={(v) => next({ weeklyBlocker: v })}
                />
              )}
              {step === 2 && (
                <StepEnergy
                  value={draft.energyLevel ?? ''}
                  onSelect={(v) => next({ energyLevel: v as Draft['energyLevel'] })}
                />
              )}
              {step === 3 && (
                <StepRoutine
                  changed={draft.routineChanged ?? false}
                  note={draft.routineNote ?? ''}
                  onSubmit={(changed, note) => next({ routineChanged: changed, routineNote: note })}
                />
              )}
            </motion.div>
          </AnimatePresence>
        </div>

        {/* Back nav */}
        {step > 0 && (
          <div className="px-6 pb-6">
            <button
              onClick={back}
              className="text-[12px] text-[color:var(--text-3)] hover:text-[color:var(--text-2)] transition-colors"
            >
              ← Back
            </button>
          </div>
        )}
      </motion.div>
    </div>
  );
}

// ── Step 1: Consistency ───────────────────────────────────────────────────────
function StepConsistency({ value, onSelect }: { value: number; onSelect: (v: number) => void }) {
  const [hovered, setHovered] = useState(0);
  const display = hovered || value;

  return (
    <div>
      <h2 className="text-[20px] font-semibold text-[color:var(--text-1)] leading-snug tracking-tight mb-1">
        How consistent were you this week?
      </h2>
      <p className="text-[13px] text-[color:var(--text-2)] mb-6">
        Across all your active habits combined.
      </p>
      <div className="flex gap-3 justify-center mb-4">
        {[1, 2, 3, 4, 5].map((n) => (
          <button
            key={n}
            onClick={() => onSelect(n)}
            onMouseEnter={() => setHovered(n)}
            onMouseLeave={() => setHovered(0)}
            className={`w-12 h-12 rounded-2xl text-[18px] font-bold transition-all ${
              n <= display
                ? 'bg-indigo-500 dark:bg-indigo-500 text-white scale-105 shadow-sm'
                : 'card-2 text-[color:var(--text-3)] hover:scale-105'
            }`}
          >
            {n}
          </button>
        ))}
      </div>
      <p className={`text-center text-[13px] font-medium transition-colors ${display ? 'text-indigo-600 dark:text-indigo-400' : 'text-[color:var(--text-3)]'}`}>
        {display ? CONSISTENCY_LABELS[display] : 'Tap a number'}
      </p>
    </div>
  );
}

// ── Step 2: Blocker ───────────────────────────────────────────────────────────
function StepBlocker({ value, onSelect }: { value: string; onSelect: (v: string) => void }) {
  return (
    <div>
      <h2 className="text-[20px] font-semibold text-[color:var(--text-1)] leading-snug tracking-tight mb-1">
        What was your biggest blocker?
      </h2>
      <p className="text-[13px] text-[color:var(--text-2)] mb-5">
        The main thing that got in the way this week.
      </p>
      <div className="flex flex-col gap-2.5">
        {BLOCKER_OPTIONS.map((opt) => (
          <button
            key={opt.value}
            onClick={() => onSelect(opt.value)}
            className={`w-full text-left card p-4 transition-all ${
              value === opt.value
                ? 'ring-2 ring-indigo-500 dark:ring-indigo-400 bg-indigo-50 dark:!bg-indigo-500/10'
                : 'card-hover'
            }`}
          >
            <p className={`text-[14px] font-semibold leading-snug mb-0.5 ${
              value === opt.value ? 'text-indigo-600 dark:text-indigo-300' : 'text-[color:var(--text-1)]'
            }`}>
              {opt.label}
            </p>
            <p className={`text-[12px] ${
              value === opt.value ? 'text-indigo-500/70 dark:text-indigo-400/70' : 'text-[color:var(--text-3)]'
            }`}>
              {opt.sub}
            </p>
          </button>
        ))}
      </div>
    </div>
  );
}

// ── Step 3: Energy ────────────────────────────────────────────────────────────
function StepEnergy({ value, onSelect }: { value: string; onSelect: (v: string) => void }) {
  return (
    <div>
      <h2 className="text-[20px] font-semibold text-[color:var(--text-1)] leading-snug tracking-tight mb-1">
        How has your overall energy been?
      </h2>
      <p className="text-[13px] text-[color:var(--text-2)] mb-6">
        Think about your average across the week.
      </p>
      <div className="flex flex-col gap-3">
        {ENERGY_OPTIONS.map((opt) => (
          <button
            key={opt.value}
            onClick={() => onSelect(opt.value)}
            className={`w-full text-left card p-4 flex items-center gap-4 transition-all ${
              value === opt.value
                ? 'ring-2 ring-indigo-500 dark:ring-indigo-400 bg-indigo-50 dark:!bg-indigo-500/10'
                : 'card-hover'
            }`}
          >
            <span className="text-2xl">{opt.emoji}</span>
            <div>
              <p className={`text-[14px] font-semibold ${
                value === opt.value ? 'text-indigo-600 dark:text-indigo-300' : 'text-[color:var(--text-1)]'
              }`}>
                {opt.label}
              </p>
              <p className={`text-[12px] ${
                value === opt.value ? 'text-indigo-500/70 dark:text-indigo-400/70' : 'text-[color:var(--text-3)]'
              }`}>
                {opt.desc}
              </p>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}

// ── Step 4: Routine changes ───────────────────────────────────────────────────
function StepRoutine({
  changed, note, onSubmit,
}: {
  changed: boolean;
  note: string;
  onSubmit: (changed: boolean, note: string) => void;
}) {
  const [localChanged, setLocalChanged] = useState(changed);
  const [localNote, setLocalNote] = useState(note);

  return (
    <div>
      <h2 className="text-[20px] font-semibold text-[color:var(--text-1)] leading-snug tracking-tight mb-1">
        Any big changes to your routine?
      </h2>
      <p className="text-[13px] text-[color:var(--text-2)] mb-5">
        Travel, new job, illness, family — anything that shifted your baseline.
      </p>
      <div className="flex gap-3 mb-5">
        {[false, true].map((val) => (
          <button
            key={String(val)}
            onClick={() => setLocalChanged(val)}
            className={`flex-1 py-3 rounded-xl text-[14px] font-semibold transition-all ${
              localChanged === val
                ? 'bg-indigo-500 dark:bg-indigo-500 text-white shadow-sm'
                : 'card-2 text-[color:var(--text-2)] hover:text-[color:var(--text-1)]'
            }`}
          >
            {val ? 'Yes' : 'No'}
          </button>
        ))}
      </div>

      <AnimatePresence>
        {localChanged && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.2 }}
            className="overflow-hidden mb-5"
          >
            <label className="ns-label">What changed? (optional)</label>
            <textarea
              value={localNote}
              onChange={(e) => setLocalNote(e.target.value)}
              placeholder="Briefly describe what was different…"
              rows={3}
              className="ns-input resize-none"
            />
          </motion.div>
        )}
      </AnimatePresence>

      <button
        onClick={() => onSubmit(localChanged, localNote)}
        className="btn-primary w-full h-12"
      >
        Submit check-in
        <ChevronRight className="w-4 h-4" />
      </button>
    </div>
  );
}
