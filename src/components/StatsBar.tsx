import { TrendingUp, RefreshCw, Flame, Calendar, RotateCcw, Shield } from 'lucide-react';

interface Props {
  recoveryRate: number;
  totalComebacks: number;
  bestStreak: number;
  activeHabits: number;
  daysInSystem: number;
  resilienceScore: number;
  comebackStreak: number;
}

const STATS = (p: Props) => [
  { label: 'Resilience',      value: p.resilienceScore,      sub: 'adaptability score', icon: Shield,      color: 'text-indigo-600 dark:text-indigo-400' },
  { label: 'Recovery Rate',   value: `${p.recoveryRate}%`,   sub: 'comebacks done',     icon: TrendingUp,  color: 'text-emerald-600 dark:text-emerald-400' },
  { label: 'Comeback Streak', value: `${p.comebackStreak}d`, sub: 'consecutive',        icon: RotateCcw,   color: 'text-amber-600 dark:text-amber-400' },
  { label: 'Comebacks',       value: p.totalComebacks,       sub: 'total',              icon: RefreshCw,   color: 'text-sky-600 dark:text-sky-400' },
  { label: 'Best Streak',     value: `${p.bestStreak}d`,     sub: 'habit streak',       icon: Flame,       color: 'text-orange-600 dark:text-orange-400' },
  { label: 'Days In',         value: p.daysInSystem,         sub: 'in system',          icon: Calendar,    color: 'text-violet-600 dark:text-violet-400' },
];

export default function StatsBar(props: Props) {
  return (
    <div className="grid grid-cols-3 sm:grid-cols-3 lg:grid-cols-6 gap-3">
      {STATS(props).map((stat) => {
        const Icon = stat.icon;
        return (
          <div key={stat.label} className="card-2 p-4 rounded-xl">
            <div className={`flex items-center gap-1.5 mb-2 ${stat.color}`}>
              <Icon className="w-3.5 h-3.5" />
              <span className="text-[10px] font-semibold uppercase tracking-wider text-[color:var(--text-3)] hidden sm:block">
                {stat.label}
              </span>
            </div>
            <div className={`text-[20px] font-bold tracking-tight leading-none ${stat.color}`}>
              {stat.value}
            </div>
            <div className="text-[10px] text-[color:var(--text-3)] mt-0.5 leading-snug">{stat.sub}</div>
          </div>
        );
      })}
    </div>
  );
}
