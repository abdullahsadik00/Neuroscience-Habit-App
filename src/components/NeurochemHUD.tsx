import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X } from 'lucide-react';
import type { Neurochemistry, NeuroLog } from '../store/useNeuroStore';
import { getLocalDateString } from '../utils/neuroHelpers';

interface ChemConfig {
  key: keyof Neurochemistry;
  label: string;
  abbr: string;
  barColor: string;
  description: string;
  explainer: string;
  raisedBy: string;
  loweredBy: string;
}

const CHEMS: ChemConfig[] = [
  {
    key: 'dopamine',
    label: 'Dopamine',
    abbr: 'DA',
    barColor: 'bg-sky-400',
    description: 'Anticipation & motivation — fires before the reward, not after',
    explainer: 'Dopamine releases in anticipation of a reward, not when you receive it — this is why wanting feels more intense than having. Completing habits you were uncertain about doing creates the strongest dopamine signal, training the brain to crave the behavior itself.',
    raisedBy: 'Completing habits, logging comebacks, urge surfing',
    loweredBy: 'Time (natural decay to baseline), slips, skipped habits',
  },
  {
    key: 'acetylcholine',
    label: 'Acetylcholine',
    abbr: 'ACh',
    barColor: 'bg-violet-400',
    description: 'Focus & learning depth — gates neuroplasticity',
    explainer: 'Acetylcholine gates which experiences get encoded into long-term memory and myelinated pathways. It peaks during focused, effortful work — which is why slightly challenging habits build neural pathways faster than easy ones.',
    raisedBy: 'Completing habits, logging comebacks, any focused action',
    loweredBy: 'Time (natural decay), prolonged inactivity',
  },
  {
    key: 'epinephrine',
    label: 'Epinephrine',
    abbr: 'EPI',
    barColor: 'bg-rose-400',
    description: 'Arousal & urgency — your brain flagging this moment as important',
    explainer: 'Epinephrine (adrenaline) signals that the current moment matters and amplifies memory consolidation for experiences the brain marks as important. A slip temporarily spikes epinephrine — your brain uses this as a teaching signal, which is why acknowledging failure is neurologically productive.',
    raisedBy: 'Logging slips (error-correction signal)',
    loweredBy: 'Urge surfing, logging comebacks, completing habits',
  },
  {
    key: 'gaba',
    label: 'GABA',
    abbr: 'GABA',
    barColor: 'bg-emerald-400',
    description: 'Calm & recovery — inhibitory brake on stress circuits',
    explainer: 'GABA is the brain\'s primary inhibitory neurotransmitter — it calms the amygdala\'s stress response and is essential for recovery between bouts of effort. Urge surfing dramatically boosts GABA by activating prefrontal inhibitory pathways over the craving circuitry.',
    raisedBy: 'Urge surfing, completing habits, logging comebacks',
    loweredBy: 'Slips, high epinephrine, time (natural decay)',
  },
];

function getTodayMovements(chemKey: keyof Neurochemistry, logs: NeuroLog[]): { label: string; delta: number }[] {
  const today = getLocalDateString(new Date());
  const todayLogs = logs.filter((l) => l.timestamp.startsWith(today));

  const changeKey: Record<keyof Neurochemistry, keyof NeuroLog> = {
    dopamine: 'dopamineChange',
    acetylcholine: 'acetylcholineChange',
    epinephrine: 'epinephrineChange',
    gaba: 'gabaChange',
  };

  return todayLogs
    .map((l) => ({ label: l.itemTitle, delta: l[changeKey[chemKey]] as number }))
    .filter((m) => m.delta !== 0);
}

interface Props {
  neurochemistry: Neurochemistry;
  logs: NeuroLog[];
}

export default function NeurochemHUD({ neurochemistry, logs }: Props) {
  const [expandedKey, setExpandedKey] = useState<keyof Neurochemistry | null>(null);

  return (
    <>
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {CHEMS.map((chem) => {
          const value = neurochemistry[chem.key];
          const level = value >= 70 ? 'High' : value >= 40 ? 'Normal' : 'Low';
          const levelColor = level === 'High'
            ? 'bg-emerald-50 text-emerald-600 dark:bg-emerald-500/15 dark:text-emerald-400'
            : level === 'Low'
            ? 'bg-rose-50 text-rose-600 dark:bg-rose-500/15 dark:text-rose-400'
            : 'bg-[color:var(--surface-2)] text-[color:var(--text-2)]';

          return (
            <button
              key={chem.key}
              onClick={() => setExpandedKey(expandedKey === chem.key ? null : chem.key)}
              className="card-2 p-4 rounded-xl text-left transition-all hover:ring-1 hover:ring-[color:var(--border-2)] active:scale-[0.98]"
            >
              <div className="flex items-center justify-between mb-2">
                <span className="text-[10px] font-semibold uppercase tracking-wider text-[color:var(--text-3)]">
                  {chem.abbr}
                </span>
                <span className={`text-[10px] font-semibold px-1.5 py-0.5 rounded-full ${levelColor}`}>
                  {level}
                </span>
              </div>
              <div className="text-[22px] font-bold text-[color:var(--text-1)] leading-none mb-2">
                {Math.round(value)}
              </div>
              <div className="h-[3px] progress-track mb-2">
                <motion.div
                  className={`h-full rounded-full ${chem.barColor}`}
                  initial={false}
                  animate={{ width: `${value}%` }}
                  transition={{ duration: 0.7, ease: [0.4, 0, 0.2, 1] }}
                />
              </div>
              <div className="text-[11px] text-[color:var(--text-3)] leading-tight line-clamp-2">{chem.description}</div>
            </button>
          );
        })}
      </div>

      {/* Expanded detail drawer */}
      <AnimatePresence>
        {expandedKey && (() => {
          const chem = CHEMS.find((c) => c.key === expandedKey)!;
          const movements = getTodayMovements(expandedKey, logs);
          return (
            <motion.div
              key={expandedKey}
              initial={{ opacity: 0, y: -6, height: 0 }}
              animate={{ opacity: 1, y: 0, height: 'auto' }}
              exit={{ opacity: 0, y: -6, height: 0 }}
              transition={{ duration: 0.2, ease: [0.4, 0, 0.2, 1] }}
              className="overflow-hidden"
            >
              <div className="card-2 p-5 rounded-xl mt-3">
                <div className="flex items-start justify-between mb-3">
                  <div>
                    <span className="text-[10px] font-semibold uppercase tracking-wider text-[color:var(--text-3)]">{chem.abbr}</span>
                    <h3 className="text-[15px] font-semibold text-[color:var(--text-1)] mt-0.5">{chem.label}</h3>
                  </div>
                  <button
                    onClick={() => setExpandedKey(null)}
                    className="p-1 rounded-lg hover:bg-[color:var(--surface-2)] transition-colors"
                  >
                    <X className="w-4 h-4 text-[color:var(--text-3)]" />
                  </button>
                </div>

                <p className="text-[13px] text-[color:var(--text-2)] leading-relaxed mb-4">{chem.explainer}</p>

                <div className="grid grid-cols-2 gap-3 mb-4">
                  <div className="card p-3 rounded-lg">
                    <p className="text-[9px] font-semibold uppercase tracking-wider text-emerald-500 mb-1">Raised by</p>
                    <p className="text-[11px] text-[color:var(--text-2)] leading-snug">{chem.raisedBy}</p>
                  </div>
                  <div className="card p-3 rounded-lg">
                    <p className="text-[9px] font-semibold uppercase tracking-wider text-rose-500 mb-1">Lowered by</p>
                    <p className="text-[11px] text-[color:var(--text-2)] leading-snug">{chem.loweredBy}</p>
                  </div>
                </div>

                {movements.length > 0 && (
                  <div>
                    <p className="text-[9px] font-semibold uppercase tracking-wider text-[color:var(--text-3)] mb-2">Today's movements</p>
                    <div className="space-y-1.5">
                      {movements.map((m, i) => (
                        <div key={i} className="flex items-center justify-between">
                          <span className="text-[12px] text-[color:var(--text-2)] truncate mr-3">{m.label}</span>
                          <span className={`text-[12px] font-semibold shrink-0 ${m.delta > 0 ? 'text-emerald-500' : 'text-rose-500'}`}>
                            {m.delta > 0 ? '+' : ''}{m.delta}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
                {movements.length === 0 && (
                  <p className="text-[11px] text-[color:var(--text-3)] italic">No activity logged today yet.</p>
                )}
              </div>
            </motion.div>
          );
        })()}
      </AnimatePresence>
    </>
  );
}
