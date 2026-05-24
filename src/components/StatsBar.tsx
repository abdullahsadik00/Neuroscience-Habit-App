import React from 'react';
import { TrendingUp, RefreshCw, Flame, Activity, Calendar } from 'lucide-react';

interface Stat {
  label: string;
  value: string | number;
  sub?: string;
  icon: React.ReactNode;
  color: string;
}

interface Props {
  recoveryRate: number;
  totalComebacks: number;
  bestStreak: number;
  activeHabits: number;
  daysInSystem: number;
  brainScore: number;
}

export default function StatsBar({
  recoveryRate,
  totalComebacks,
  bestStreak,
  activeHabits,
  daysInSystem,
}: Props) {
  const stats: Stat[] = [
    {
      label: 'Recovery Rate',
      value: `${recoveryRate}%`,
      sub: 'comebacks completed',
      icon: <TrendingUp className="w-4 h-4" />,
      color: 'text-emerald-400',
    },
    {
      label: 'Comebacks Used',
      value: totalComebacks,
      sub: 'total activations',
      icon: <RefreshCw className="w-4 h-4" />,
      color: 'text-amber-400',
    },
    {
      label: 'Best Streak',
      value: `${bestStreak}d`,
      sub: 'consecutive days',
      icon: <Flame className="w-4 h-4" />,
      color: 'text-orange-400',
    },
    {
      label: 'Active Habits',
      value: activeHabits,
      sub: 'in your system',
      icon: <Activity className="w-4 h-4" />,
      color: 'text-violet-400',
    },
    {
      label: 'Days in System',
      value: daysInSystem,
      sub: 'building playbook',
      icon: <Calendar className="w-4 h-4" />,
      color: 'text-cyan-400',
    },
  ];

  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
      {stats.map((stat) => (
        <div key={stat.label} className="glass-panel rounded-xl p-4">
          <div className={`flex items-center gap-1.5 mb-2 ${stat.color}`}>
            {stat.icon}
            <span className="text-[10px] font-mono tracking-widest uppercase text-slate-500">
              {stat.label}
            </span>
          </div>
          <div className={`text-2xl font-bold tracking-tight ${stat.color}`}>{stat.value}</div>
          {stat.sub && <div className="text-[10px] text-slate-600 mt-0.5">{stat.sub}</div>}
        </div>
      ))}
    </div>
  );
}
