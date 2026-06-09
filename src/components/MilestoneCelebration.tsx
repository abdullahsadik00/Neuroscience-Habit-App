import { useEffect } from 'react';
import { motion } from 'framer-motion';
import type { MilestoneEvent } from '../store/useNeuroStore';

const MILESTONE_COPY: Record<number, { headline: string; science: string }> = {
  10:  {
    headline: 'Your pathway is forming.',
    science:  'Early repetitions lay down the initial neural traces in the basal ganglia. Each completion makes the next one slightly easier.',
  },
  25:  {
    headline: 'Momentum is building.',
    science:  'At this stage, the behavior starts competing with older, more established patterns. Keep going — it gets easier from here.',
  },
  50:  {
    headline: 'Halfway myelinated.',
    science:  'Your brain has wrapped this pathway in enough myelin that the signal is noticeably faster. The habit is becoming part of your identity.',
  },
  75:  {
    headline: 'Strengthening fast.',
    science:  'Research by Lally et al. shows most habits reach near-automaticity between 66–100 repetitions. You\'re in the final stretch.',
  },
  100: {
    headline: 'Pathway well-established.',
    science:  'This behavior no longer requires deliberate effort — it\'s wired in. Your brain now expends minimal glucose to execute it.',
  },
};

interface Props {
  event: MilestoneEvent;
  onDismiss: () => void;
}

export default function MilestoneCelebration({ event, onDismiss }: Props) {
  const copy = MILESTONE_COPY[event.milestone];

  useEffect(() => {
    const t = setTimeout(onDismiss, 4000);
    return () => clearTimeout(t);
  }, [onDismiss]);

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center pb-8 px-4 pointer-events-none">
      <motion.div
        initial={{ opacity: 0, y: 40, scale: 0.95 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, y: 20, scale: 0.97 }}
        transition={{ duration: 0.3, ease: [0.25, 0.46, 0.45, 0.94] }}
        className="pointer-events-auto w-full max-w-sm"
        onClick={onDismiss}
      >
        <div className="card shadow-[var(--shadow-modal)] p-5 rounded-2xl overflow-hidden relative">
          {/* Glow pulse */}
          <motion.div
            className="absolute inset-0 bg-indigo-400/10 dark:bg-indigo-400/8 rounded-2xl"
            animate={{ opacity: [0.4, 0.8, 0.4] }}
            transition={{ duration: 2, repeat: Infinity, ease: 'easeInOut' }}
          />

          <div className="relative">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <motion.div
                  animate={{ scale: [1, 1.15, 1] }}
                  transition={{ duration: 0.6, repeat: 2 }}
                  className="text-[22px] leading-none"
                >
                  ⚡
                </motion.div>
                <span className="text-[10px] font-semibold uppercase tracking-widest text-indigo-600 dark:text-indigo-400">
                  Myelination milestone
                </span>
              </div>
              <span className="text-[22px] font-bold text-indigo-600 dark:text-indigo-400 leading-none">
                {event.milestone}%
              </span>
            </div>

            <p className="text-[15px] font-semibold text-[color:var(--text-1)] mb-1 leading-snug">
              {copy.headline}
            </p>
            <p className="text-[11px] text-[color:var(--text-3)] mb-3 leading-snug italic">
              {event.habitTitle}
            </p>
            <p className="text-[12px] text-[color:var(--text-2)] leading-relaxed">
              {copy.science}
            </p>

            {/* Progress bar animating to milestone */}
            <div className="h-[3px] progress-track mt-4">
              <motion.div
                className="h-full rounded-full bg-indigo-500"
                initial={{ width: `${Math.max(0, event.milestone - 15)}%` }}
                animate={{ width: `${event.milestone}%` }}
                transition={{ duration: 1, delay: 0.2, ease: [0.4, 0, 0.2, 1] }}
              />
            </div>
            <div className="flex justify-between mt-1">
              <span className="text-[9px] text-[color:var(--text-3)]">{event.stageName}</span>
              <span className="text-[9px] text-[color:var(--text-3)]">tap to dismiss</span>
            </div>
          </div>
        </div>
      </motion.div>
    </div>
  );
}
