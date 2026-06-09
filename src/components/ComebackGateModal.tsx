import { motion } from 'framer-motion';
import { Lock, Zap, X } from 'lucide-react';

const FREE_LIMIT = 3;

interface Props {
  used: number;
  onUpgrade: () => void;
  onDismiss: () => void;
}

export default function ComebackGateModal({ onUpgrade, onDismiss }: Props) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center px-4">
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="absolute inset-0 bg-black/40 dark:bg-black/60 backdrop-blur-md"
        onClick={onDismiss}
      />
      <motion.div
        initial={{ opacity: 0, scale: 0.95, y: 8 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.95 }}
        transition={{ duration: 0.22, ease: [0.25, 0.46, 0.45, 0.94] }}
        className="relative w-full max-w-sm card shadow-[var(--shadow-modal)] p-6"
      >
        <button
          onClick={onDismiss}
          className="absolute top-4 right-4 p-1.5 rounded-lg hover:bg-[color:var(--surface-2)] transition-colors"
        >
          <X className="w-4 h-4 text-[color:var(--text-3)]" />
        </button>

        {/* Icon */}
        <div className="w-12 h-12 rounded-2xl bg-rose-50 dark:bg-rose-500/10 flex items-center justify-center mb-4">
          <Lock className="w-5 h-5 text-rose-500 dark:text-rose-400" />
        </div>

        {/* Copy */}
        <h2 className="text-[18px] font-bold text-[color:var(--text-1)] tracking-tight leading-snug mb-2">
          Monthly comeback limit reached
        </h2>
        <p className="text-[13px] text-[color:var(--text-2)] leading-relaxed mb-1">
          You've used all {FREE_LIMIT} free comebacks this month. The Comeback Protocol is the most important part of this system — don't lose access to it.
        </p>
        <p className="text-[13px] text-[color:var(--text-2)] leading-relaxed mb-5">
          Upgrade to Pro for unlimited comebacks, full Recovery Analytics, and the Recalibration Engine.
        </p>

        {/* Value prop */}
        <div className="flex items-center gap-2 card-2 px-3 py-2 rounded-xl mb-5">
          <Zap className="w-3.5 h-3.5 text-blue-500 dark:text-blue-400 shrink-0" />
          <p className="text-[12px] text-[color:var(--text-2)]">
            Pro unlocks unlimited comebacks, multi-device sync, and Failure Signature analysis.
          </p>
        </div>

        {/* CTAs */}
        <button onClick={onUpgrade} className="btn-primary w-full h-12 mb-2.5">
          Upgrade to Pro — $9/mo
        </button>
        <button
          onClick={onDismiss}
          className="w-full text-[12px] text-[color:var(--text-3)] hover:text-[color:var(--text-2)] transition-colors py-1"
        >
          Maybe later
        </button>
      </motion.div>
    </div>
  );
}
