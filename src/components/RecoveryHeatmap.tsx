import React, { useState } from 'react';
import type { HeatmapDay } from '../utils/statsHelpers';

interface Props {
  weeks: HeatmapDay[][];
}

const MONTH_LABELS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

function cellColor(day: HeatmapDay): string {
  if (day.isFuture) return 'bg-transparent';
  if (day.completions > 0) return 'bg-emerald-500 dark:bg-emerald-400';
  if (day.hasComeback) return 'bg-amber-400 dark:bg-amber-300';
  if (day.isMiss) return 'bg-slate-200 dark:bg-slate-700';
  return 'bg-transparent';
}

function cellTitle(day: HeatmapDay): string {
  if (day.isFuture) return '';
  if (day.completions > 0 && day.hasComeback)
    return `${day.dateStr} — Comeback + ${day.completions} habit${day.completions > 1 ? 's' : ''}`;
  if (day.completions > 0)
    return `${day.dateStr} — ${day.completions} habit${day.completions > 1 ? 's' : ''} completed`;
  if (day.hasComeback) return `${day.dateStr} — Comeback day`;
  if (day.isMiss) return `${day.dateStr} — Missed`;
  return day.dateStr;
}

export default function RecoveryHeatmap({ weeks }: Props) {
  const [tooltip, setTooltip] = useState<string | null>(null);

  // Compute which weeks start a new month for labels
  const monthMarkers: { weekIndex: number; label: string }[] = [];
  weeks.forEach((week, wi) => {
    const firstDay = week.find(d => !d.isFuture && d.dateStr.length === 10);
    if (!firstDay) return;
    const month = parseInt(firstDay.dateStr.slice(5, 7), 10) - 1;
    const dayOfMonth = parseInt(firstDay.dateStr.slice(8, 10), 10);
    if (dayOfMonth <= 7 && (wi === 0 || monthMarkers[monthMarkers.length - 1]?.label !== MONTH_LABELS[month])) {
      monthMarkers.push({ weekIndex: wi, label: MONTH_LABELS[month] });
    }
  });

  return (
    <div className="space-y-1.5">
      {/* Month label row */}
      <div className="flex gap-[3px]">
        {weeks.map((_, wi) => {
          const marker = monthMarkers.find(m => m.weekIndex === wi);
          return (
            <div key={wi} className="w-[10px] shrink-0">
              {marker && (
                <span className="text-[8px] text-[color:var(--text-3)] font-medium leading-none whitespace-nowrap">
                  {marker.label}
                </span>
              )}
            </div>
          );
        })}
      </div>

      {/* Day rows (Sun–Sat) */}
      {[0, 1, 2, 3, 4, 5, 6].map(dayIndex => (
        <div key={dayIndex} className="flex gap-[3px]">
          {weeks.map((week, wi) => {
            const day = week[dayIndex];
            const color = cellColor(day);
            const title = cellTitle(day);
            return (
              <div
                key={wi}
                className={`w-[10px] h-[10px] rounded-[2px] shrink-0 cursor-default transition-opacity hover:opacity-80 ${color} ${day.isToday ? 'ring-1 ring-indigo-500 dark:ring-indigo-400' : ''}`}
                title={title}
                onMouseEnter={() => setTooltip(title)}
                onMouseLeave={() => setTooltip(null)}
              />
            );
          })}
        </div>
      ))}

      {/* Legend */}
      <div className="flex items-center gap-4 pt-1">
        <span className="text-[10px] text-[color:var(--text-3)]">Less</span>
        <div className="flex gap-1">
          <div className="w-[10px] h-[10px] rounded-[2px] bg-slate-200 dark:bg-slate-700" />
          <div className="w-[10px] h-[10px] rounded-[2px] bg-amber-400 dark:bg-amber-300" />
          <div className="w-[10px] h-[10px] rounded-[2px] bg-emerald-500 dark:bg-emerald-400" />
        </div>
        <span className="text-[10px] text-[color:var(--text-3)]">More</span>
        {tooltip && (
          <span className="text-[10px] text-[color:var(--text-2)] ml-auto truncate max-w-[160px]">{tooltip}</span>
        )}
      </div>
    </div>
  );
}
