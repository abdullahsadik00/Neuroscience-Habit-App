import React, { useState } from 'react';
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

const DRIVER_COLORS: Record<string, string> = {
  'feel-better':    'text-emerald-400',
  'perform-better': 'text-cyan-400',
  'become-someone': 'text-indigo-400',
  'survive':        'text-amber-400',
};

const STYLE_COLORS: Record<string, string> = {
  perfectionist: 'bg-indigo-500/15 text-indigo-300',
  avoider:       'bg-amber-500/15 text-amber-300',
  analyst:       'bg-cyan-500/15 text-cyan-300',
  drifter:       'bg-emerald-500/15 text-emerald-300',
};

export default function BrainProfileCard({ profile }: Props) {
  const [expanded, setExpanded] = useState(false);
  const setBrainProfile = useNeuroStore(s => s.setBrainProfile);

  const archetype = getArchetypeName(profile);
  const driverColor = DRIVER_COLORS[profile.coreDriver] ?? 'text-white/60';
  const styleColor = STYLE_COLORS[profile.failureStyle] ?? 'bg-white/10 text-white/60';

  function handleRetake() {
    // Clearing the brain profile re-routes App to BrainAssessment
    setBrainProfile(null as unknown as NeuroBrainProfile);
  }

  return (
    <div className="bg-white/4 border border-white/8 rounded-2xl overflow-hidden">
      {/* Compact header — always visible */}
      <button
        onClick={() => setExpanded(e => !e)}
        className="w-full px-4 py-4 flex items-center justify-between hover:bg-white/3 transition-colors"
      >
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-xl bg-indigo-500/20 flex items-center justify-center text-base shrink-0">
            🧠
          </div>
          <div className="text-left">
            <p className="text-white/40 text-[10px] uppercase tracking-wider">Neural Profile</p>
            <p className="text-white/85 text-sm font-medium leading-tight">{archetype}</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <span className={`text-xs px-2 py-0.5 rounded-full ${styleColor}`}>
            {getFailureStyleLabel(profile.failureStyle)}
          </span>
          <span className="text-white/25 text-xs">{expanded ? '▲' : '▼'}</span>
        </div>
      </button>

      {/* Expanded detail */}
      {expanded && (
        <div className="px-4 pb-4 border-t border-white/6">
          <div className="grid grid-cols-2 gap-3 mt-4">
            <Stat label="Peak energy" value={getPeakWindowLabel(profile.peakEnergyWindow)} />
            <Stat label="Recovery speed" value={profile.recoverySpeed} capitalize />
            <Stat label="Primary blocker" value={profile.primaryBlocker} capitalize />
            <Stat label="Self-talk" value={getSelfTalkLabel(profile.selfTalkPattern)} />
            <Stat label="Accountability" value={profile.accountabilityStyle} capitalize />
            <div className="flex flex-col gap-0.5">
              <span className="text-white/30 text-[10px] uppercase tracking-wide">Core driver</span>
              <span className={`text-xs capitalize font-medium ${driverColor}`}>
                {profile.coreDriver.replace(/-/g, ' ')}
              </span>
            </div>
          </div>

          <button
            onClick={handleRetake}
            className="mt-4 w-full text-white/30 text-xs py-2 rounded-xl border border-white/8 hover:text-white/50 hover:border-white/15 transition-all"
          >
            Retake assessment
          </button>
        </div>
      )}
    </div>
  );
}

function Stat({ label, value, capitalize }: { label: string; value: string; capitalize?: boolean }) {
  return (
    <div className="flex flex-col gap-0.5">
      <span className="text-white/30 text-[10px] uppercase tracking-wide">{label}</span>
      <span className={`text-white/70 text-xs ${capitalize ? 'capitalize' : ''}`}>{value}</span>
    </div>
  );
}
