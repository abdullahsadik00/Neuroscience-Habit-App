import { useState } from 'react';
import { BookOpen, ChevronDown, ChevronUp, CheckCircle2, X, Lightbulb } from 'lucide-react';
import type { ComebackRecord, NeuroStack } from '../store/useNeuroStore';

interface Props {
  comebacks: ComebackRecord[];
  stacks: NeuroStack[];
  insights: string[];
}

export default function RecoveryPlaybook({ comebacks, stacks, insights }: Props) {
  const [expanded, setExpanded] = useState(false);

  const stackMap = Object.fromEntries(stacks.map((s) => [s.id, s.title]));
  const recent = [...comebacks].sort((a, b) => b.completedAt.localeCompare(a.completedAt)).slice(0, 5);

  const withActions = comebacks.filter((c) => c.microActionsCompleted).length;
  const completionRate = comebacks.length > 0
    ? Math.round((withActions / comebacks.length) * 100)
    : 0;

  return (
    <div className="card overflow-hidden">
      <button
        onClick={() => setExpanded((v) => !v)}
        className="w-full flex items-center justify-between px-5 py-4 hover:bg-[color:var(--surface-2)] transition-colors"
      >
        <div className="flex items-center gap-3">
          <BookOpen className="w-4 h-4 text-amber-500 dark:text-amber-400" />
          <span className="text-[14px] font-semibold text-[color:var(--text-1)]">Personal Recovery Playbook</span>
          <span className="text-[10px] font-semibold px-2 py-0.5 rounded-full bg-amber-50 dark:bg-amber-500/10 text-amber-600 dark:text-amber-400">
            {comebacks.length} comeback{comebacks.length !== 1 ? 's' : ''}
          </span>
        </div>
        {expanded
          ? <ChevronUp className="w-4 h-4 text-[color:var(--text-3)]" />
          : <ChevronDown className="w-4 h-4 text-[color:var(--text-3)]" />
        }
      </button>

      {expanded && (
        <div className="px-5 pb-5 border-t border-[color:var(--border)]">
          {insights.length > 0 && (
            <div className="mt-4 flex flex-col gap-2">
              {insights.map((insight, i) => (
                <div key={i} className="card-2 flex gap-2.5 p-3 rounded-xl">
                  <Lightbulb className="w-3.5 h-3.5 text-amber-500 dark:text-amber-400 shrink-0 mt-0.5" />
                  <p className="text-[12px] text-[color:var(--text-1)] leading-relaxed">{insight}</p>
                </div>
              ))}
            </div>
          )}

          {comebacks.length === 0 ? (
            <div className="mt-4 text-center py-8">
              <BookOpen className="w-8 h-8 text-[color:var(--text-3)] mx-auto mb-2" />
              <p className="text-[13px] text-[color:var(--text-2)]">Your comeback history will appear here.</p>
              <p className="text-[11px] text-[color:var(--text-3)] mt-1">Every acknowledged failure builds your playbook.</p>
            </div>
          ) : (
            <>
              <div className="mt-4 flex items-center justify-between mb-3">
                <span className="section-header">Recent comebacks</span>
                <span className={`text-[11px] font-semibold ${
                  completionRate >= 70 ? 'text-emerald-600 dark:text-emerald-400'
                  : completionRate >= 40 ? 'text-amber-600 dark:text-amber-400'
                  : 'text-[color:var(--text-3)]'
                }`}>
                  {completionRate}% with micro-actions
                </span>
              </div>
              <div className="flex flex-col gap-1.5">
                {recent.map((cb) => (
                  <div key={cb.id} className="card-2 flex items-center justify-between py-2.5 px-3 rounded-xl">
                    <div className="flex-1 min-w-0 pr-3">
                      <p className="text-[13px] text-[color:var(--text-1)] truncate">{stackMap[cb.stackId] ?? 'Unknown habit'}</p>
                      <p className="text-[11px] text-[color:var(--text-3)] mt-0.5">{cb.date}</p>
                    </div>
                    {cb.microActionsCompleted
                      ? <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500 dark:text-emerald-400 shrink-0" />
                      : <X className="w-3.5 h-3.5 text-[color:var(--text-3)] shrink-0" />
                    }
                  </div>
                ))}
              </div>
            </>
          )}
        </div>
      )}
    </div>
  );
}
