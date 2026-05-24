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
    <div
      className={`rounded-xl p-4 border flex items-center justify-between gap-4 ${
        isAtLimit
          ? 'bg-rose-900/10 border-rose-800/30'
          : 'bg-amber-900/10 border-amber-800/20'
      }`}
    >
      <div className="flex items-start gap-3 flex-1 min-w-0">
        <div className={`p-1.5 rounded-lg shrink-0 ${isAtLimit ? 'bg-rose-900/30' : 'bg-amber-900/30'}`}>
          {isAtLimit ? (
            <Lock className="w-3.5 h-3.5 text-rose-400" />
          ) : (
            <Zap className="w-3.5 h-3.5 text-amber-400" />
          )}
        </div>
        <div>
          <p className={`text-xs font-semibold ${isAtLimit ? 'text-rose-300' : 'text-amber-300'}`}>
            {isAtLimit
              ? 'Free comeback limit reached'
              : `${remaining} free comeback${remaining !== 1 ? 's' : ''} remaining`}
          </p>
          <p className="text-[10px] text-slate-500 mt-0.5">
            {isAtLimit
              ? 'Unlock unlimited comebacks + full recovery analytics'
              : `${used} of ${FREE_LIMIT} used this month · Full Recovery Engine from $9/mo`}
          </p>
        </div>
      </div>

      <button
        onClick={onUpgrade}
        className={`shrink-0 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all button-pulse ${
          isAtLimit
            ? 'bg-rose-600/30 hover:bg-rose-600/50 text-rose-300 border border-rose-700/40'
            : 'bg-amber-600/20 hover:bg-amber-600/40 text-amber-300 border border-amber-700/30'
        }`}
      >
        Upgrade
      </button>
    </div>
  );
}
