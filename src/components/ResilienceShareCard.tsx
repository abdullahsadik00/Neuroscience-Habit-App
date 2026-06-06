import React, { useState } from 'react';
import { Share2, Check } from 'lucide-react';
import RecoveryHeatmap from './RecoveryHeatmap';
import type { HeatmapDay } from '../utils/statsHelpers';

interface Props {
  archetype: string;
  resilienceScore: number;
  comebackStreak: number;
  totalComebacks: number;
  weeks: HeatmapDay[][];
}

export default function ResilienceShareCard({
  archetype,
  resilienceScore,
  comebackStreak,
  totalComebacks,
  weeks,
}: Props) {
  const [copied, setCopied] = useState(false);

  const scoreColor =
    resilienceScore >= 70 ? 'text-emerald-600 dark:text-emerald-400'
    : resilienceScore >= 40 ? 'text-amber-600 dark:text-amber-400'
    : 'text-rose-600 dark:text-rose-400';

  function handleShare() {
    const text = [
      `🧠 NeuroSync Recovery Story`,
      `Archetype: ${archetype}`,
      `Resilience Score: ${resilienceScore}/100`,
      `Comeback Streak: ${comebackStreak} days`,
      `Total Comebacks: ${totalComebacks}`,
      ``,
      `The flex isn't a perfect streak. It's recovery.`,
    ].join('\n');

    if (navigator.share) {
      navigator.share({ title: 'My NeuroSync Recovery Story', text }).catch(() => null);
    } else {
      navigator.clipboard.writeText(text).then(() => {
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
      });
    }
  }

  return (
    <div className="card p-5 rounded-2xl space-y-4">
      {/* Header row */}
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-[10px] font-semibold uppercase tracking-widest text-[color:var(--text-3)] mb-0.5">
            Recovery Story
          </p>
          <p className="text-[15px] font-bold text-[color:var(--text-1)]">{archetype}</p>
        </div>
        <div className="flex items-center gap-3 shrink-0">
          {/* Resilience Score badge */}
          <div className="card-2 px-3 py-2 text-center rounded-xl">
            <div className={`text-[20px] font-bold tracking-tight leading-none ${scoreColor}`}>
              {resilienceScore}
            </div>
            <div className="text-[9px] font-semibold uppercase tracking-wider text-[color:var(--text-3)] mt-0.5">
              Resilience
            </div>
          </div>
          {/* Comeback Streak badge */}
          <div className="card-2 px-3 py-2 text-center rounded-xl">
            <div className="text-[20px] font-bold tracking-tight leading-none text-amber-600 dark:text-amber-400">
              {comebackStreak}
            </div>
            <div className="text-[9px] font-semibold uppercase tracking-wider text-[color:var(--text-3)] mt-0.5">
              Streak
            </div>
          </div>
        </div>
      </div>

      {/* Heatmap */}
      <div className="overflow-x-auto">
        <RecoveryHeatmap weeks={weeks} />
      </div>

      {/* Share button */}
      <button
        onClick={handleShare}
        className="w-full flex items-center justify-center gap-2 py-2.5 rounded-xl text-[13px] font-semibold border border-[color:var(--border)] hover:bg-[color:var(--surface-2)] transition-colors text-[color:var(--text-2)]"
      >
        {copied
          ? <><Check className="w-4 h-4 text-emerald-500" /> Copied to clipboard</>
          : <><Share2 className="w-4 h-4" /> Share your recovery story</>
        }
      </button>
    </div>
  );
}
