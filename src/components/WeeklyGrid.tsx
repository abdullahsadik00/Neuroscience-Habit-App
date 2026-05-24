import React from 'react';
import type { WeekDay } from '../utils/statsHelpers';

export default function WeeklyGrid({ days }: { days: WeekDay[] }) {
  return (
    <div className="flex items-center gap-1.5">
      {days.map((day) => (
        <div key={day.dateStr} className="flex flex-col items-center gap-1">
          <span className="text-[9px] font-medium text-[color:var(--text-3)]">{day.label[0]}</span>
          <div
            title={day.dateStr}
            className={`w-5 h-5 rounded-md transition-all ${
              day.isFuture
                ? 'bg-[color:var(--surface-2)] border border-[color:var(--border)]'
                : day.completed
                ? 'bg-emerald-400 dark:bg-emerald-500'
                : day.comeback
                ? 'bg-amber-400 dark:bg-amber-500'
                : day.missed
                ? 'bg-[color:var(--surface-2)] border border-[color:var(--border)]'
                : 'bg-[color:var(--surface-2)] border border-[color:var(--border)]'
            } ${day.isToday ? 'ring-2 ring-indigo-300/60 dark:ring-indigo-400/40' : ''}`}
          />
        </div>
      ))}
    </div>
  );
}
