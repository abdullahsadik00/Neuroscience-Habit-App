import React from 'react';
import { TrendingUp, RefreshCw, Flame, Activity, Calendar } from 'lucide-react';

interface Props {
  recoveryRate: number;
  totalComebacks: number;
  bestStreak: number;
  activeHabits: number;
  daysInSystem: number;
  brainScore: number;
}

const STATS = (p: Props) => [
  { label: 'Recovery Rate', value: `${p.recoveryRate}%`, sub: 'comebacks done', icon: TrendingUp, color: 'text-emerald-600 dark:text-emerald-400' },
  { label: 'Comebacks',     value: p.totalComebacks,    sub: 'total',           icon: RefreshCw,  color: 'text-amber-600 dark:text-amber-400' },
  { label: 'Best Streak',   value: `${p.bestStreak}d`,  sub: 'consecutive',     icon: Flame,      color: 'text-orange-600 dark:text-orange-400' },
  { label: 'Habits',        value: p.activeHabits,      sub: 'active',          icon: Activity,   color: 'text-indigo-600 dark:text-indigo-400' },
  { label: 'Days In',       value: p.daysInSystem,      sub: 'in system',       icon: Calendar,   color: 'text-sky-600 dark:text-sky-400' },
];

export default function StatsBar(props: Props) {
  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
      {STATS(props).map((stat, i) => {
        const Icon = stat.icon;
        // On xs: 5th item spans both columns to avoid orphaned single card
        const spanClass = i === 4 ? 'sm:col-span-1 col-span-2' : '';
        return (
          <div key={stat.label} className={`card-2 p-4 rounded-xl ${spanClass}`}>
            <div className={`flex items-center gap-1.5 mb-2 ${stat.color}`}>
              <Icon className="w-3.5 h-3.5" />
              <span className="text-[10px] font-semibold uppercase tracking-wider text-[color:var(--text-3)]">
                {stat.label}
              </span>
            </div>
            <div className={`text-[22px] font-bold tracking-tight leading-none ${stat.color}`}>
              {stat.value}
            </div>
            {stat.sub && <div className="text-[11px] text-[color:var(--text-3)] mt-0.5">{stat.sub}</div>}
          </div>
        );
      })}
    </div>
  );
}
