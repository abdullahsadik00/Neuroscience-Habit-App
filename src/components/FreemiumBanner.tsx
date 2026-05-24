import React from 'react';
import { Zap, Lock } from 'lucide-react';

const FREE_LIMIT = 3;

interface Props {
  comebacksThisMonth: number;
  isPro: boolean;
  onUpgrade: () => void;
}

export default function FreemiumBanner({ comebacksThisMonth, isPro, onUpgrade }: Props) {
  if (isPro) return null;

  const used = Math.min(comebacksThisMonth, FREE_LIMIT);
  const remaining = Math.max(0, FREE_LIMIT - used);
  const isAtLimit = remaining === 0;

  return (
    <div className={`card-2 rounded-xl px-4 py-3.5 flex items-center justify-between gap-4 border-l-2 ${
      isAtLimit ? 'border-l-rose-500' : 'border-l-[color:var(--accent)]'
    }`}>
      <div className="flex items-center gap-3 flex-1 min-w-0">
        <div className={`p-1.5 rounded-lg shrink-0 ${isAtLimit ? 'bg-rose-50 dark:bg-rose-500/10' : 'bg-[color:var(--accent-s)]'}`}>
          {isAtLimit
            ? <Lock className="w-3.5 h-3.5 text-rose-500 dark:text-rose-400" />
            : <Zap className="w-3.5 h-3.5 text-[color:var(--accent)]" />
          }
        </div>
        <div>
          <p className={`text-[12px] font-semibold ${isAtLimit ? 'text-rose-600 dark:text-rose-400' : 'text-[color:var(--text-1)]'}`}>
            {isAtLimit ? 'Free comeback limit reached' : `${remaining} free comeback${remaining !== 1 ? 's' : ''} remaining`}
          </p>
          <p className="text-[11px] text-[color:var(--text-3)] mt-0.5">
            {isAtLimit
              ? 'Unlock unlimited comebacks + full recovery analytics'
              : `${used} of ${FREE_LIMIT} used · Full Recovery Engine from $9/mo`}
          </p>
        </div>
      </div>
      <button onClick={onUpgrade} className="btn-secondary shrink-0 px-3 py-1.5 text-[12px] rounded-lg">
        Upgrade
      </button>
    </div>
  );
}
