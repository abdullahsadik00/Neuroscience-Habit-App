import type { WeekDay } from '../utils/statsHelpers';

export default function WeeklyGrid({ days }: { days: WeekDay[] }) {
  return (
    <div className="flex items-center gap-1.5">
      {days.map((day, i) => {
        // A comeback that follows at least one missed day is a recovery comeback
        const isRecoveryComeback = day.comeback && i > 0 && days[i - 1].missed;

        return (
          <div key={day.dateStr} className="flex flex-col items-center gap-1">
            <span className="text-[9px] font-medium text-[color:var(--text-3)]">{day.label[0]}</span>
            <div className="relative">
              <div
                title={isRecoveryComeback ? 'Recovery comeback' : day.dateStr}
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
                } ${day.isToday ? 'ring-2 ring-indigo-300/60 dark:ring-indigo-400/40' : ''}
                  ${isRecoveryComeback ? 'ring-2 ring-amber-400/70 dark:ring-amber-400/60' : ''}`}
              />
              {isRecoveryComeback && (
                <span
                  className="absolute -top-1 -right-1 text-[7px] leading-none bg-amber-400 dark:bg-amber-500 text-white rounded-full w-3 h-3 flex items-center justify-center font-bold"
                  title="Recovery comeback"
                >
                  ↩
                </span>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}
