import React, { useState } from 'react';
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
    <div className="glass-panel rounded-xl overflow-hidden">
      <button
        onClick={() => setExpanded((v) => !v)}
        className="w-full flex items-center justify-between px-5 py-4 text-left hover:bg-white/[0.02] transition-colors"
      >
        <div className="flex items-center gap-3">
          <BookOpen className="w-4 h-4 text-amber-400" />
          <span className="text-sm font-semibold text-white">Personal Recovery Playbook</span>
          <span className="text-[10px] font-mono text-amber-400 bg-amber-900/20 border border-amber-800/30 px-2 py-0.5 rounded-full">
            {comebacks.length} comeback{comebacks.length !== 1 ? 's' : ''}
          </span>
        </div>
        {expanded ? (
          <ChevronUp className="w-4 h-4 text-slate-500" />
        ) : (
          <ChevronDown className="w-4 h-4 text-slate-500" />
        )}
      </button>

      {expanded && (
        <div className="px-5 pb-5 border-t border-white/[0.04]">

          {/* Insights */}
          {insights.length > 0 && (
            <div className="mt-4 space-y-2">
              {insights.map((insight, i) => (
                <div key={i} className="flex gap-2.5 p-3 rounded-lg bg-amber-900/10 border border-amber-800/20">
                  <Lightbulb className="w-3.5 h-3.5 text-amber-400 shrink-0 mt-0.5" />
                  <p className="text-xs text-slate-300 leading-relaxed">{insight}</p>
                </div>
              ))}
            </div>
          )}

          {comebacks.length === 0 ? (
            <div className="mt-4 text-center py-8">
              <BookOpen className="w-8 h-8 text-slate-700 mx-auto mb-2" />
              <p className="text-xs text-slate-500">Your comeback history will appear here.</p>
              <p className="text-[10px] text-slate-600 mt-1">Every acknowledged failure builds your playbook.</p>
            </div>
          ) : (
            <>
              <div className="mt-4 flex items-center justify-between mb-3">
                <span className="text-[10px] text-slate-500 font-mono uppercase tracking-wider">Recent comebacks</span>
                <span className={`text-[10px] font-semibold font-mono ${completionRate >= 70 ? 'text-emerald-400' : completionRate >= 40 ? 'text-amber-400' : 'text-slate-400'}`}>
                  {completionRate}% with micro-actions
                </span>
              </div>

              <div className="space-y-2">
                {recent.map((cb) => (
                  <div key={cb.id} className="flex items-center justify-between py-2.5 px-3 rounded-lg bg-white/[0.02] border border-white/[0.04]">
                    <div className="flex-1 min-w-0 pr-3">
                      <p className="text-xs text-slate-300 truncate">{stackMap[cb.stackId] ?? 'Unknown habit'}</p>
                      <p className="text-[10px] text-slate-600 font-mono mt-0.5">{cb.date}</p>
                    </div>
                    {cb.microActionsCompleted ? (
                      <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400 shrink-0" />
                    ) : (
                      <X className="w-3.5 h-3.5 text-slate-600 shrink-0" />
                    )}
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
