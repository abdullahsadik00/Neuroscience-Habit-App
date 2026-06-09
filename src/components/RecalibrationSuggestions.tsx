import { useState } from 'react';
import { motion } from 'framer-motion';
import { Check, X, ChevronRight, TrendingDown, RefreshCw, Zap } from 'lucide-react';
import type { RecalibrationSuggestion, RecalibrationEvent } from '../store/useNeuroStore';

interface Props {
  suggestions: RecalibrationSuggestion[];
  onApply: (event: RecalibrationEvent) => void;
  onDismiss: () => void;
}

const TYPE_META: Record<RecalibrationSuggestion['type'], {
  label: string;
  icon: React.ReactNode;
  color: string;
  bg: string;
}> = {
  SCALE_DOWN: {
    label: 'Scale down',
    icon: <TrendingDown className="w-3.5 h-3.5" />,
    color: 'text-amber-600 dark:text-amber-400',
    bg: 'bg-amber-50 dark:bg-amber-500/10',
  },
  REPLACE: {
    label: 'Replace habit',
    icon: <RefreshCw className="w-3.5 h-3.5" />,
    color: 'text-rose-600 dark:text-rose-400',
    bg: 'bg-rose-50 dark:bg-rose-500/10',
  },
  UPDATE_MICRO: {
    label: 'Update re-entry actions',
    icon: <Zap className="w-3.5 h-3.5" />,
    color: 'text-blue-600 dark:text-blue-400',
    bg: 'bg-blue-50 dark:bg-blue-500/10',
  },
};

export default function RecalibrationSuggestions({ suggestions, onApply, onDismiss }: Props) {
  const [decisions, setDecisions] = useState<Record<string, 'accept' | 'reject' | null>>(
    Object.fromEntries(suggestions.map(s => [s.id, null]))
  );

  const allDecided = Object.values(decisions).every(d => d !== null);

  function decide(id: string, verdict: 'accept' | 'reject') {
    setDecisions(prev => ({ ...prev, [id]: verdict }));
  }

  function handleApply() {
    const accepted = Object.entries(decisions)
      .filter(([, v]) => v === 'accept').map(([k]) => k);
    const rejected = Object.entries(decisions)
      .filter(([, v]) => v === 'reject').map(([k]) => k);

    const event: RecalibrationEvent = {
      id: `recal-${Date.now()}`,
      date: new Date().toISOString(),
      trigger: 'weekly-checkin',
      suggestions,
      accepted,
      rejected,
    };

    onApply(event);
  }

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
        className="relative w-full max-w-lg bg-[color:var(--surface)] rounded-t-[28px] shadow-[var(--shadow-modal)] overflow-hidden pb-safe"
      >
        {/* Handle */}
        <div className="flex justify-center pt-4 pb-2">
          <div className="w-10 h-1 bg-[color:var(--surface-3)] rounded-full" />
        </div>

        {/* Header */}
        <div className="px-6 pb-4">
          <p className="section-header mb-1">Recalibration Engine</p>
          <h2 className="text-[18px] font-semibold text-[color:var(--text-1)] leading-snug">
            Your system needs adjusting
          </h2>
          <p className="text-[13px] text-[color:var(--text-2)] mt-1">
            Based on your check-in and habit data — {suggestions.length} suggestion{suggestions.length !== 1 ? 's' : ''}. Accept or reject each one.
          </p>
        </div>

        {/* Suggestions */}
        <div className="px-6 pb-4 flex flex-col gap-3 max-h-[55vh] overflow-y-auto">
          {suggestions.map((s, i) => {
            const meta = TYPE_META[s.type];
            const decision = decisions[s.id];

            return (
              <motion.div
                key={s.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.07 }}
                className={`card p-4 transition-all ${
                  decision === 'accept'
                    ? 'ring-2 ring-emerald-400 dark:ring-emerald-500'
                    : decision === 'reject'
                    ? 'opacity-50'
                    : ''
                }`}
              >
                {/* Type badge */}
                <div className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[10px] font-semibold mb-2 ${meta.bg} ${meta.color}`}>
                  {meta.icon}
                  {meta.label}
                </div>

                {/* Habit name */}
                {s.habitTitle && (
                  <p className="text-[11px] font-semibold uppercase tracking-wider text-[color:var(--text-3)] mb-1">
                    {s.habitTitle}
                  </p>
                )}

                {/* Reason */}
                <p className="text-[13px] text-[color:var(--text-1)] leading-relaxed mb-3">
                  {s.reason}
                </p>

                {/* Change preview */}
                <div className="card-2 px-3 py-2.5 rounded-xl flex items-center gap-2 mb-3 text-[12px]">
                  <span className="text-[color:var(--text-2)] line-through truncate flex-1">{s.fromValue}</span>
                  <ChevronRight className="w-3.5 h-3.5 text-[color:var(--text-3)] shrink-0" />
                  <span className="text-[color:var(--text-1)] font-medium truncate flex-1 text-right">{s.toValue}</span>
                </div>

                {/* Accept / Reject */}
                <div className="flex gap-2">
                  <button
                    onClick={() => decide(s.id, 'accept')}
                    className={`flex-1 h-9 rounded-xl text-[12px] font-semibold flex items-center justify-center gap-1.5 transition-all ${
                      decision === 'accept'
                        ? 'bg-emerald-500 text-white'
                        : 'bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 hover:bg-emerald-100 dark:hover:bg-emerald-500/20'
                    }`}
                  >
                    <Check className="w-3.5 h-3.5" />
                    Accept
                  </button>
                  <button
                    onClick={() => decide(s.id, 'reject')}
                    className={`flex-1 h-9 rounded-xl text-[12px] font-semibold flex items-center justify-center gap-1.5 transition-all ${
                      decision === 'reject'
                        ? 'bg-[color:var(--surface-3)] text-[color:var(--text-2)]'
                        : 'card-2 text-[color:var(--text-2)] hover:text-[color:var(--text-1)]'
                    }`}
                  >
                    <X className="w-3.5 h-3.5" />
                    Skip
                  </button>
                </div>
              </motion.div>
            );
          })}
        </div>

        {/* Footer */}
        <div className="px-6 pb-8 pt-2 border-t border-[color:var(--border)]">
          <button
            onClick={handleApply}
            disabled={!allDecided}
            className="btn-primary w-full h-12 disabled:opacity-40 disabled:cursor-not-allowed"
          >
            Apply decisions
            <ChevronRight className="w-4 h-4" />
          </button>
          <button
            onClick={onDismiss}
            className="w-full mt-3 text-[12px] text-[color:var(--text-3)] hover:text-[color:var(--text-2)] transition-colors"
          >
            Decide later
          </button>
        </div>
      </motion.div>
    </div>
  );
}
