import { useState } from 'react';
import { ChevronDown, ChevronUp } from 'lucide-react';
import type { NeuroBrainProfile } from '../store/useNeuroStore';
import {
  getArchetypeName,
  getFailureStyleLabel,
  getPeakWindowLabel,
  getSelfTalkLabel,
} from '../utils/brainHelpers';
import { useNeuroStore } from '../store/useNeuroStore';

interface Props {
  profile: NeuroBrainProfile;
}

const STYLE_BADGE: Record<string, string> = {
  perfectionist: 'bg-indigo-50 text-indigo-600 dark:bg-indigo-500/15 dark:text-indigo-400',
  avoider:       'bg-amber-50 text-amber-600 dark:bg-amber-500/15 dark:text-amber-400',
  analyst:       'bg-sky-50 text-sky-600 dark:bg-sky-500/15 dark:text-sky-400',
  drifter:       'bg-emerald-50 text-emerald-600 dark:bg-emerald-500/15 dark:text-emerald-400',
};

export default function BrainProfileCard({ profile }: Props) {
  const [expanded, setExpanded] = useState(false);
  const setBrainProfile = useNeuroStore(s => s.setBrainProfile);

  const archetype = getArchetypeName(profile);
  const styleBadge = STYLE_BADGE[profile.failureStyle] ?? 'bg-[color:var(--surface-2)] text-[color:var(--text-2)]';

  function handleRetake() {
    setBrainProfile(null as unknown as NeuroBrainProfile);
  }

  return (
    <div className="card overflow-hidden">
      <button
        onClick={() => setExpanded(e => !e)}
        className="w-full px-5 py-4 flex items-center justify-between hover:bg-[color:var(--surface-2)] transition-colors"
      >
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-[color:var(--accent-s)] flex items-center justify-center text-lg shrink-0">
            🧠
          </div>
          <div className="text-left">
            <p className="section-header mb-0.5">Neural Profile</p>
            <p className="text-[14px] font-semibold text-[color:var(--text-1)] leading-tight">{archetype}</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-full ${styleBadge}`}>
            {getFailureStyleLabel(profile.failureStyle)}
          </span>
          {expanded
            ? <ChevronUp className="w-4 h-4 text-[color:var(--text-3)]" />
            : <ChevronDown className="w-4 h-4 text-[color:var(--text-3)]" />
          }
        </div>
      </button>

      {expanded && (
        <div className="px-5 pb-5 border-t border-[color:var(--border)]">
          <div className="grid grid-cols-2 gap-4 mt-4">
            <StatRow label="Peak energy" value={getPeakWindowLabel(profile.peakEnergyWindow)} />
            <StatRow label="Recovery speed" value={profile.recoverySpeed} capitalize />
            <StatRow label="Primary blocker" value={profile.primaryBlocker} capitalize />
            <StatRow label="Self-talk" value={getSelfTalkLabel(profile.selfTalkPattern)} />
            <StatRow label="Accountability" value={profile.accountabilityStyle} capitalize />
            <StatRow label="Core driver" value={profile.coreDriver.replace(/-/g, ' ')} capitalize />
          </div>
          <button
            onClick={handleRetake}
            className="btn-ghost w-full mt-4 text-[13px]"
          >
            Retake assessment
          </button>
        </div>
      )}
    </div>
  );
}

function StatRow({ label, value, capitalize }: { label: string; value: string; capitalize?: boolean }) {
  return (
    <div>
      <p className="text-[10px] font-semibold uppercase tracking-wider text-[color:var(--text-3)] mb-0.5">{label}</p>
      <p className={`text-[13px] font-medium text-[color:var(--text-1)] ${capitalize ? 'capitalize' : ''}`}>{value}</p>
    </div>
  );
}
