import React, { useEffect, useState } from 'react';
import { useNeuroStore } from '../store/useNeuroStore';
import { Brain, Shield, Plus, Zap, BookOpen, ChevronRight, User } from 'lucide-react';
import ComebackProtocol from '../components/ComebackProtocol';
import NeurochemHUD from '../components/NeurochemHUD';
import StatsBar from '../components/StatsBar';
import HabitCard from '../components/HabitCard';
import SwapCard from '../components/SwapCard';
import RecoveryPlaybook from '../components/RecoveryPlaybook';
import AddHabitModal from '../components/AddHabitModal';
import FreemiumBanner from '../components/FreemiumBanner';
import { getMissedStacks } from '../utils/comebackHelpers';
import {
  calcRecoveryRate,
  calcBrainScore,
  getBestStreak,
  getDaysInSystem,
  getComebacksThisMonth,
  getRecoveryInsights,
} from '../utils/statsHelpers';

export default function Dashboard() {
  const {
    stacks,
    swaps,
    logs,
    comebacks,
    neurochemistry,
    dopaminePoints,
    userProfile,
    isPro,
    completeNeuroStack,
    logUrgeSurf,
    logSlip,
    addNeuroStack,
    addNeuroSwap,
    acknowledgeComeback,
    getTodayComebackIds,
    upgradeToPro,
    decayNeurochemistry,
  } = useNeuroStore();

  const [missedStacks, setMissedStacks] = useState(() =>
    getMissedStacks(stacks, getTodayComebackIds())
  );
  const [showComeback, setShowComeback] = useState(missedStacks.length > 0);
  const [showAddModal, setShowAddModal] = useState(false);
  const [activeTab, setActiveTab] = useState<'habits' | 'swaps' | 'log'>('habits');

  useEffect(() => {
    const interval = setInterval(() => decayNeurochemistry(), 60000);
    return () => clearInterval(interval);
  }, [decayNeurochemistry]);

  const activeStacks = stacks.filter((s) => s.isActive);
  const activeSwaps = swaps.filter((s) => s.isActive);

  const recoveryRate = calcRecoveryRate(comebacks);
  const brainScore = calcBrainScore(stacks, comebacks, neurochemistry);
  const bestStreak = getBestStreak(stacks);
  const daysInSystem = getDaysInSystem(stacks);
  const comebacksThisMonth = getComebacksThisMonth(comebacks);
  const insights = getRecoveryInsights(stacks, comebacks, swaps);

  const brainScoreColor =
    brainScore >= 70 ? 'text-emerald-400' : brainScore >= 40 ? 'text-amber-400' : 'text-rose-400';
  const brainScoreGlow =
    brainScore >= 70
      ? 'shadow-[0_0_20px_rgba(52,211,153,0.3)]'
      : brainScore >= 40
      ? 'shadow-[0_0_20px_rgba(251,191,36,0.2)]'
      : 'shadow-[0_0_20px_rgba(251,113,133,0.2)]';

  return (
    <div className="min-h-screen bg-gray-950 text-slate-200 font-sans">
      {/* Background glow */}
      <div className="fixed inset-0 pointer-events-none overflow-hidden">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[800px] h-[400px] bg-indigo-900/10 rounded-full blur-3xl" />
        <div className="absolute bottom-0 left-0 w-[400px] h-[400px] bg-cyan-900/10 rounded-full blur-3xl" />
      </div>

      <div className="relative max-w-3xl mx-auto px-4 py-6 space-y-6">

        {/* Comeback Protocol overlay */}
        {showComeback && missedStacks.length > 0 && (
          <ComebackProtocol
            missedStacks={missedStacks}
            onComplete={(stackId, stackTitle, microActionsCompleted) => {
              acknowledgeComeback(stackId, stackTitle, microActionsCompleted);
            }}
            onDismiss={() => {
              setShowComeback(false);
              setMissedStacks([]);
            }}
          />
        )}

        {/* Add Habit Modal */}
        {showAddModal && (
          <AddHabitModal
            onAddStack={addNeuroStack}
            onAddSwap={addNeuroSwap}
            onClose={() => setShowAddModal(false)}
          />
        )}

        {/* ── HEADER ── */}
        <div className="flex items-center justify-between">
          <div>
            <div className="flex items-center gap-2 mb-0.5">
              <div className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
              <span className="text-[10px] text-slate-500 font-mono uppercase tracking-widest">NeuroSync</span>
            </div>
            <h1 className="text-2xl font-bold text-white tracking-tight leading-none">
              Hey, {userProfile.name}
            </h1>
            <p className="text-xs text-slate-500 mt-0.5">{userProfile.role} · Building your playbook</p>
          </div>

          <div className="flex items-center gap-3">
            {/* Brain Score */}
            <div className={`glass-panel rounded-xl px-4 py-2.5 text-center ${brainScoreGlow} transition-all`}>
              <div className={`text-2xl font-bold font-mono tracking-tight ${brainScoreColor}`}>
                {brainScore}
              </div>
              <div className="text-[9px] text-slate-500 font-mono uppercase tracking-wider">Brain Score</div>
            </div>

            {/* Dopamine Points */}
            <div className="glass-panel rounded-xl px-4 py-2.5 text-center border-cyan-800/30">
              <div className="flex items-center gap-1 justify-center">
                <Zap className="w-3.5 h-3.5 text-cyan-400" />
                <span className="text-xl font-bold font-mono text-cyan-400">{dopaminePoints}</span>
              </div>
              <div className="text-[9px] text-slate-500 font-mono uppercase tracking-wider">DP Points</div>
            </div>
          </div>
        </div>

        {/* ── FREEMIUM BANNER ── */}
        <FreemiumBanner
          comebacksThisMonth={comebacksThisMonth}
          isPro={isPro}
          onUpgrade={upgradeToPro}
        />

        {/* ── NEUROCHEMISTRY HUD ── */}
        <section>
          <div className="flex items-center gap-2 mb-3">
            <div className="w-4 h-px bg-slate-700" />
            <span className="text-[10px] text-slate-500 font-mono uppercase tracking-widest">Neurochemistry</span>
            <div className="flex-1 h-px bg-slate-800" />
          </div>
          <NeurochemHUD neurochemistry={neurochemistry} />
        </section>

        {/* ── STATS BAR ── */}
        <section>
          <div className="flex items-center gap-2 mb-3">
            <div className="w-4 h-px bg-slate-700" />
            <span className="text-[10px] text-slate-500 font-mono uppercase tracking-widest">Your Numbers</span>
            <div className="flex-1 h-px bg-slate-800" />
          </div>
          <StatsBar
            recoveryRate={recoveryRate}
            totalComebacks={comebacks.length}
            bestStreak={bestStreak}
            activeHabits={activeStacks.length}
            daysInSystem={daysInSystem}
            brainScore={brainScore}
          />
        </section>

        {/* ── RECOVERY PLAYBOOK ── */}
        <RecoveryPlaybook comebacks={comebacks} stacks={stacks} insights={insights} />

        {/* ── TABS ── */}
        <div className="flex items-center gap-1 bg-gray-900/60 rounded-xl p-1">
          <TabButton
            active={activeTab === 'habits'}
            onClick={() => setActiveTab('habits')}
            icon={<Brain className="w-3.5 h-3.5" />}
            label={`Habits (${activeStacks.length})`}
          />
          <TabButton
            active={activeTab === 'swaps'}
            onClick={() => setActiveTab('swaps')}
            icon={<Shield className="w-3.5 h-3.5" />}
            label={`Swaps (${activeSwaps.length})`}
          />
          <TabButton
            active={activeTab === 'log'}
            onClick={() => setActiveTab('log')}
            icon={<BookOpen className="w-3.5 h-3.5" />}
            label={`Activity Log`}
          />
        </div>

        {/* ── HABITS TAB ── */}
        {activeTab === 'habits' && (
          <section>
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <Brain className="w-4 h-4 text-indigo-400" />
                <span className="text-sm font-semibold text-white">Neuro-Stacks</span>
              </div>
              <button
                onClick={() => setShowAddModal(true)}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-indigo-600/20 hover:bg-indigo-600/40 text-indigo-300 text-xs font-semibold border border-indigo-500/30 transition-all"
              >
                <Plus className="w-3.5 h-3.5" />
                Add habit
              </button>
            </div>

            {activeStacks.length === 0 ? (
              <EmptyState
                icon={<Brain className="w-8 h-8 text-slate-700" />}
                title="No habits yet"
                description="Add your first neuro-stack habit to start building myelination."
                action="Add your first habit"
                onAction={() => setShowAddModal(true)}
              />
            ) : (
              <div className="grid gap-3">
                {activeStacks.map((stack) => (
                  <HabitCard
                    key={stack.id}
                    stack={stack}
                    comebacks={comebacks}
                    onComplete={completeNeuroStack}
                  />
                ))}
              </div>
            )}
          </section>
        )}

        {/* ── SWAPS TAB ── */}
        {activeTab === 'swaps' && (
          <section>
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <Shield className="w-4 h-4 text-rose-400" />
                <span className="text-sm font-semibold text-white">Friction Protocols</span>
              </div>
              <button
                onClick={() => setShowAddModal(true)}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-rose-600/10 hover:bg-rose-600/30 text-rose-300 text-xs font-semibold border border-rose-500/20 transition-all"
              >
                <Plus className="w-3.5 h-3.5" />
                Add swap
              </button>
            </div>

            {activeSwaps.length === 0 ? (
              <EmptyState
                icon={<Shield className="w-8 h-8 text-slate-700" />}
                title="No friction protocols"
                description="Add a bad habit to intercept and build your resistance protocols."
                action="Add friction protocol"
                onAction={() => setShowAddModal(true)}
              />
            ) : (
              <div className="grid gap-3">
                {activeSwaps.map((swap) => (
                  <SwapCard
                    key={swap.id}
                    swap={swap}
                    onUrgeSurf={logUrgeSurf}
                    onSlip={logSlip}
                  />
                ))}
              </div>
            )}
          </section>
        )}

        {/* ── ACTIVITY LOG TAB ── */}
        {activeTab === 'log' && (
          <section>
            <div className="flex items-center gap-2 mb-3">
              <BookOpen className="w-4 h-4 text-slate-400" />
              <span className="text-sm font-semibold text-white">Activity Log</span>
            </div>

            {logs.length === 0 ? (
              <EmptyState
                icon={<BookOpen className="w-8 h-8 text-slate-700" />}
                title="No activity yet"
                description="Complete habits, urge-surf, or log comebacks to see your neural activity here."
              />
            ) : (
              <div className="space-y-2">
                {logs.slice(0, 20).map((log) => {
                  const typeConfig = {
                    completion: { color: 'text-emerald-400', bg: 'bg-emerald-900/20 border-emerald-800/20', label: 'Completed' },
                    urge_surf: { color: 'text-cyan-400', bg: 'bg-cyan-900/20 border-cyan-800/20', label: 'Urge Surfed' },
                    slip: { color: 'text-rose-400', bg: 'bg-rose-900/20 border-rose-800/20', label: 'Slip' },
                    comeback: { color: 'text-amber-400', bg: 'bg-amber-900/20 border-amber-800/20', label: 'Comeback' },
                  }[log.type] ?? { color: 'text-slate-400', bg: 'bg-gray-900/40 border-gray-800/20', label: log.type };

                  return (
                    <div key={log.id} className={`flex items-start justify-between gap-3 p-3 rounded-lg border ${typeConfig.bg}`}>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-0.5">
                          <span className={`text-[10px] font-semibold ${typeConfig.color}`}>{typeConfig.label}</span>
                          <span className="text-[10px] text-slate-600 font-mono">
                            {new Date(log.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                          </span>
                        </div>
                        <p className="text-xs text-slate-300 truncate">{log.itemTitle}</p>
                        {log.notes && (
                          <p className="text-[10px] text-slate-500 mt-0.5 line-clamp-1">{log.notes}</p>
                        )}
                      </div>
                      {log.dopamineChange !== 0 && (
                        <span className={`text-[10px] font-mono font-semibold shrink-0 ${log.dopamineChange > 0 ? 'text-cyan-400' : 'text-rose-400'}`}>
                          {log.dopamineChange > 0 ? '+' : ''}{log.dopamineChange} DA
                        </span>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </section>
        )}

        {/* Footer */}
        <div className="text-center py-4">
          <p className="text-[10px] text-slate-700 font-mono">
            NeuroSync · Every comeback strengthens your playbook
          </p>
        </div>
      </div>
    </div>
  );
}

function TabButton({
  active,
  onClick,
  icon,
  label,
}: {
  active: boolean;
  onClick: () => void;
  icon: React.ReactNode;
  label: string;
}) {
  return (
    <button
      onClick={onClick}
      className={`flex-1 flex items-center justify-center gap-1.5 py-2 rounded-lg text-xs font-semibold transition-all ${
        active
          ? 'bg-white/10 text-white shadow-sm'
          : 'text-slate-500 hover:text-slate-300'
      }`}
    >
      {icon}
      {label}
    </button>
  );
}

function EmptyState({
  icon,
  title,
  description,
  action,
  onAction,
}: {
  icon: React.ReactNode;
  title: string;
  description: string;
  action?: string;
  onAction?: () => void;
}) {
  return (
    <div className="glass-panel rounded-xl py-12 flex flex-col items-center text-center">
      <div className="mb-3">{icon}</div>
      <p className="text-sm font-semibold text-slate-400 mb-1">{title}</p>
      <p className="text-xs text-slate-600 max-w-xs">{description}</p>
      {action && onAction && (
        <button
          onClick={onAction}
          className="mt-4 flex items-center gap-1.5 px-4 py-2 rounded-lg bg-indigo-600/20 hover:bg-indigo-600/40 text-indigo-300 text-xs font-semibold border border-indigo-500/30 transition-all"
        >
          <Plus className="w-3.5 h-3.5" />
          {action}
          <ChevronRight className="w-3 h-3" />
        </button>
      )}
    </div>
  );
}
