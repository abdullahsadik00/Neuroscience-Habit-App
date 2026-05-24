import React from 'react';
import type { WeekDay } from '../utils/statsHelpers';

export default function WeeklyGrid({ days }: { days: WeekDay[] }) {
  return (
    <div className="flex items-center gap-1.5">
      {days.map((day) => (
        <div key={day.dateStr} className="flex flex-col items-center gap-1">
          <span className="text-[9px] text-slate-600 font-mono">{day.label[0]}</span>
          <div
            title={day.dateStr}
            className={`w-5 h-5 rounded-sm transition-all ${
              day.isFuture
                ? 'bg-gray-900 border border-gray-800'
                : day.completed
                ? 'bg-emerald-500 shadow-[0_0_6px_rgba(52,211,153,0.5)]'
                : day.comeback
                ? 'bg-amber-500 shadow-[0_0_6px_rgba(251,191,36,0.4)]'
                : day.missed
                ? 'bg-gray-800 border border-gray-700'
                : 'bg-gray-900 border border-gray-800'
            } ${day.isToday ? 'ring-1 ring-cyan-500/50' : ''}`}
          />
        </div>
      ))}
    </div>
  );
}
