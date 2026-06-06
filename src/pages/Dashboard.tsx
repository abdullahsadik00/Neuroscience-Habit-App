import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Brain, Shield, Plus, Zap, BookOpen, Sun, Moon, ChevronDown } from 'lucide-react';
import { useNeuroStore } from '../store/useNeuroStore';
import { useTheme } from '../contexts/ThemeContext';
import ComebackProtocol from '../components/ComebackProtocol';
import NeurochemHUD from '../components/NeurochemHUD';
import StatsBar from '../components/StatsBar';
import HabitCard from '../components/HabitCard';
import SwapCard from '../components/SwapCard';
import RecoveryPlaybook from '../components/RecoveryPlaybook';
import AddHabitModal from '../components/AddHabitModal';
import FreemiumBanner from '../components/FreemiumBanner';
import BrainProfileCard from '../components/BrainProfileCard';
import WeeklyCheckin from '../components/WeeklyCheckin';
import RecalibrationSuggestions from '../components/RecalibrationSuggestions';
import ComebackGateModal from '../components/ComebackGateModal';
import MilestoneCelebration from '../components/MilestoneCelebration';
import { runRecalibration } from '../utils/recalibrationEngine';
import type { RecalibrationSuggestion } from '../store/useNeuroStore';
import { getMissedStacks } from '../utils/comebackHelpers';
import {
  calcRecoveryRate,
  calcBrainScore,
  getBestStreak,
  getDaysInSystem,
  getComebacksThisMonth,
  getRecoveryInsights,
  calcComebackStreak,
} from '../utils/statsHelpers';

const CHECKIN_INTERVAL_DAYS = 7;

const TABS = [
  { key: 'habits', label: 'Habits', icon: Brain },
  { key: 'swaps', label: 'Swaps', icon: Shield },
  { key: 'log', label: 'Activity', icon: BookOpen },
] as const;

type Tab = typeof TABS[number]['key'];

function ArchivedSection({
  stacks,
  comebacks,
  onRestore,
}: {
  stacks: import('../store/useNeuroStore').NeuroStack[];
  comebacks: import('../store/useNeuroStore').ComebackRecord[];
  onRestore: (id: string) => void;
}) {
  const [open, setOpen] = useState(false);
  return (
    <div className="mt-4">
      <button
        onClick={() => setOpen((v) => !v)}
        className="flex items-center gap-2 text-[12px] font-semibold text-[color:var(--text-3)] hover:text-[color:var(--text-2)] transition-colors"
      >
        <ChevronDown className={`w-3.5 h-3.5 transition-transform ${open ? 'rotate-180' : ''}`} />
        Archived habits ({stacks.length})
      </button>
      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            transition={{ duration: 0.2 }}
            className="overflow-hidden"
          >
            <div className="flex flex-col gap-2 mt-3">
              {stacks.map((stack) => (
                <div key={stack.id} className="card-2 p-4 rounded-xl flex items-center justify-between gap-3 opacity-60">
                  <div className="min-w-0">
                    <p className="text-[13px] font-semibold text-[color:var(--text-1)] truncate">{stack.title}</p>
                    <p className="text-[11px] text-[color:var(--text-3)] mt-0.5">{stack.myelinationLevel}% myelinated · {stack.completions.length} completions</p>
                  </div>
                  <button
                    onClick={() => onRestore(stack.id)}
                    className="shrink-0 text-[12px] font-semibold text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 dark:hover:text-indigo-300 transition-colors px-3 py-1.5 rounded-lg hover:bg-indigo-50 dark:hover:bg-indigo-500/10"
                  >
                    Restore
                  </button>
                </div>
              ))}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

export default function Dashboard() {
  const {
    stacks, swaps, logs, comebacks, neurochemistry, dopaminePoints, userProfile,
    isPro, brainProfile, completeNeuroStack, logUrgeSurf, logSlip, addNeuroStack,
    addNeuroSwap, acknowledgeComeback, getTodayComebackIds, decayNeurochemistry,
    lastCheckinDate, submitCheckin, checkinHistory, applyRecalibration, updateNeuroStack,
    pendingMilestone, clearMilestone,
  } = useNeuroStore();

  const { theme, toggleTheme } = useTheme();

  const [missedStacks, setMissedStacks] = useState(() =>
    getMissedStacks(stacks, getTodayComebackIds())
  );
  const [showComeback, setShowComeback] = useState(() => {
    const missed = getMissedStacks(stacks, getTodayComebackIds());
    if (missed.length === 0) return false;
    const used = getComebacksThisMonth(comebacks);
    return isPro || used < 3;
  });
  const [pendingComebackAfterUpgrade] = useState(missedStacks.length > 0);
  const [showAddModal, setShowAddModal] = useState(false);
  const [activeTab, setActiveTab] = useState<Tab>('habits');
  const [showCheckin, setShowCheckin] = useState(() => {
    if (!lastCheckinDate) return true;
    const daysSince = (Date.now() - new Date(lastCheckinDate).getTime()) / 86_400_000;
    return daysSince >= CHECKIN_INTERVAL_DAYS;
  });
  const [recalSuggestions, setRecalSuggestions] = useState<RecalibrationSuggestion[]>([]);
  const [showComebackGate, setShowComebackGate] = useState(false);

  const FREE_COMEBACK_LIMIT = 3;

  useEffect(() => {
    const interval = setInterval(() => decayNeurochemistry(), 60000);
    return () => clearInterval(interval);
  }, [decayNeurochemistry]);

  // On mount: if there are missed stacks but the free limit is hit, show gate instead
  useEffect(() => {
    if (missedStacks.length > 0 && !isPro && comebacksThisMonth >= FREE_COMEBACK_LIMIT) {
      setShowComebackGate(true);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const activeStacks = stacks.filter((s) => s.isActive);
  const archivedStacks = stacks.filter((s) => !s.isActive);
  const activeSwaps = swaps.filter((s) => s.isActive);

  const recoveryRate = calcRecoveryRate(comebacks);
  const brainScore = calcBrainScore(stacks, comebacks, neurochemistry);
  const bestStreak = getBestStreak(stacks);
  const daysInSystem = getDaysInSystem(stacks);
  const comebacksThisMonth = getComebacksThisMonth(comebacks);
  const comebackStreak = calcComebackStreak(comebacks);
  const insights = getRecoveryInsights(stacks, comebacks, swaps);

  const brainScoreColor =
    brainScore >= 70 ? 'text-emerald-600 dark:text-emerald-400'
    : brainScore >= 40 ? 'text-amber-600 dark:text-amber-400'
    : 'text-rose-600 dark:text-rose-400';

  return (
    <div className="min-h-screen bg-[#FAFAF8] dark:bg-[#0F1115]">
      {/* Weekly Check-in */}
      <AnimatePresence>
        {showCheckin && (
          <WeeklyCheckin
            onSubmit={(record) => {
              submitCheckin(record);
              setShowCheckin(false);
              // Run recalibration engine after checkin saves
              const latestHistory = [
                { ...record, id: 'pending', recalibrationApplied: false },
                ...checkinHistory,
              ];
              const suggestions = runRecalibration(stacks, latestHistory, brainProfile);
              if (suggestions.length > 0) setRecalSuggestions(suggestions);
            }}
            onDismiss={() => setShowCheckin(false)}
          />
        )}
      </AnimatePresence>

      {/* Recalibration suggestions */}
      <AnimatePresence>
        {recalSuggestions.length > 0 && (
          <RecalibrationSuggestions
            suggestions={recalSuggestions}
            onApply={(event) => {
              applyRecalibration(event);
              setRecalSuggestions([]);
            }}
            onDismiss={() => setRecalSuggestions([])}
          />
        )}
      </AnimatePresence>

      {/* Comeback gate */}
      <AnimatePresence>
        {showComebackGate && (
          <ComebackGateModal
            used={comebacksThisMonth}
            onUpgrade={() => { setShowComebackGate(false); window.open('https://neurosync.app/upgrade', '_blank'); }}
            onDismiss={() => setShowComebackGate(false)}
          />
        )}
      </AnimatePresence>

      {/* Modals */}
      {showComeback && missedStacks.length > 0 && (
        <ComebackProtocol
          missedStacks={missedStacks}
          onComplete={(stackId, stackTitle, microActionsCompleted) => {
            acknowledgeComeback(stackId, stackTitle, microActionsCompleted);
          }}
          onDismiss={() => { setShowComeback(false); setMissedStacks([]); }}
        />
      )}
      {showAddModal && (
        <AddHabitModal
          onAddStack={addNeuroStack}
          onAddSwap={addNeuroSwap}
          onClose={() => setShowAddModal(false)}
        />
      )}

      {/* Myelination milestone celebration */}
      <AnimatePresence>
        {pendingMilestone && (
          <MilestoneCelebration event={pendingMilestone} onDismiss={clearMilestone} />
        )}
      </AnimatePresence>

      <div className="max-w-2xl mx-auto px-4 py-8 space-y-6">

        {/* ── HEADER ── */}
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <p className="section-header mb-1">NeuroSync</p>
            <h1 className="text-[22px] sm:text-[26px] font-bold text-[color:var(--text-1)] tracking-tight leading-none truncate">
              Hey, {userProfile.name}
            </h1>
            <p className="text-[12px] text-[color:var(--text-2)] mt-1 truncate">{userProfile.role}</p>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            {/* Brain Score */}
            <div className="card px-3 py-2.5 text-center min-w-[58px]">
              <div className={`text-[18px] font-bold tracking-tight leading-none ${brainScoreColor}`}>
                {brainScore}
              </div>
              <div className="text-[9px] font-semibold uppercase tracking-wider text-[color:var(--text-3)] mt-0.5">Brain</div>
            </div>

            {/* DP Points */}
            <div className="card px-3 py-2.5 text-center min-w-[58px]">
              <div className="flex items-center gap-0.5 justify-center">
                <Zap className="w-3 h-3 text-indigo-500 dark:text-indigo-400" />
                <span className="text-[18px] font-bold tracking-tight leading-none text-indigo-600 dark:text-indigo-400">
                  {dopaminePoints}
                </span>
              </div>
              <div className="text-[9px] font-semibold uppercase tracking-wider text-[color:var(--text-3)] mt-0.5">Points</div>
            </div>

            {/* Theme toggle */}
            <button onClick={toggleTheme} className="theme-toggle">
              {theme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
            </button>
          </div>
        </div>

        {/* ── FREEMIUM BANNER ── */}
        <FreemiumBanner
          comebacksThisMonth={comebacksThisMonth}
          isPro={isPro}
          onUpgrade={() => window.open('https://neurosync.app/upgrade', '_blank')}
        />

        {/* ── NEUROCHEMISTRY ── */}
        <section>
          <SectionHeader label="Neurochemistry" />
          <NeurochemHUD neurochemistry={neurochemistry} logs={logs} />
        </section>

        {/* ── STATS ── */}
        <section>
          <SectionHeader label="Your Numbers" />
          <StatsBar
            recoveryRate={recoveryRate}
            totalComebacks={comebacks.length}
            bestStreak={bestStreak}
            activeHabits={activeStacks.length}
            daysInSystem={daysInSystem}
            brainScore={brainScore}
            comebackStreak={comebackStreak}
          />
        </section>

        {/* ── BRAIN PROFILE ── */}
        {brainProfile && (
          <section>
            <SectionHeader label="Neural Profile" />
            <BrainProfileCard profile={brainProfile} />
          </section>
        )}

        {/* ── RECOVERY PLAYBOOK ── */}
        <RecoveryPlaybook comebacks={comebacks} stacks={stacks} insights={insights} />

        {/* ── TABS ── */}
        <div className="card p-1 flex gap-1">
          {TABS.map(({ key, label, icon: Icon }) => {
            const count = key === 'habits' ? activeStacks.length : key === 'swaps' ? activeSwaps.length : null;
            return (
              <button
                key={key}
                onClick={() => setActiveTab(key)}
                className={`flex-1 flex items-center justify-center gap-1.5 py-2.5 rounded-[14px] text-[13px] font-semibold transition-all min-w-0 ${
                  activeTab === key
                    ? 'bg-[color:var(--accent)] text-white shadow-sm'
                    : 'text-[color:var(--text-3)] hover:text-[color:var(--text-2)] hover:bg-[color:var(--surface-2)]'
                }`}
              >
                <Icon className="w-3.5 h-3.5 shrink-0" />
                <span className="truncate">{label}</span>
                {count !== null && (
                  <span className="hidden sm:inline text-[11px] opacity-70">({count})</span>
                )}
              </button>
            );
          })}
        </div>

        {/* ── TAB CONTENT ── */}
        <AnimatePresence mode="wait">
          <motion.div
            key={activeTab}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            transition={{ duration: 0.2, ease: [0.25, 0.46, 0.45, 0.94] }}
          >
            {activeTab === 'habits' && (
              <section>
                <div className="flex items-center justify-between mb-4">
                  <SectionHeader label="Neuro-Stacks" inline />
                  <button
                    onClick={() => setShowAddModal(true)}
                    className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-[color:var(--accent-s)] hover:bg-indigo-100 dark:hover:bg-indigo-500/20 text-indigo-600 dark:text-indigo-400 text-[12px] font-semibold transition-colors"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    Add habit
                  </button>
                </div>
                {activeStacks.length === 0 ? (
                  <EmptyState
                    icon="🧠"
                    title="No habits yet"
                    description="Add your first neuro-stack to start building myelination."
                    action="Add your first habit"
                    onAction={() => setShowAddModal(true)}
                  />
                ) : (
                  <div className="flex flex-col gap-3">
                    {activeStacks.map((stack) => (
                      <HabitCard
                        key={stack.id}
                        stack={stack}
                        comebacks={comebacks}
                        onComplete={completeNeuroStack}
                        onArchive={(id) => updateNeuroStack(id, { isActive: false })}
                      />
                    ))}
                  </div>
                )}

                {/* Archived habits */}
                {archivedStacks.length > 0 && (
                  <ArchivedSection
                    stacks={archivedStacks}
                    comebacks={comebacks}
                    onRestore={(id) => updateNeuroStack(id, { isActive: true })}
                  />
                )}
              </section>
            )}

            {activeTab === 'swaps' && (
              <section>
                <div className="flex items-center justify-between mb-4">
                  <SectionHeader label="Friction Protocols" inline />
                  <button
                    onClick={() => setShowAddModal(true)}
                    className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-rose-50 dark:bg-rose-500/10 hover:bg-rose-100 dark:hover:bg-rose-500/20 text-rose-600 dark:text-rose-400 text-[12px] font-semibold transition-colors"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    Add swap
                  </button>
                </div>
                {activeSwaps.length === 0 ? (
                  <EmptyState
                    icon="🛡️"
                    title="No friction protocols"
                    description="Add a bad habit to intercept and build your resistance protocols."
                    action="Add friction protocol"
                    onAction={() => setShowAddModal(true)}
                  />
                ) : (
                  <div className="flex flex-col gap-3">
                    {activeSwaps.map((swap) => (
                      <SwapCard key={swap.id} swap={swap} onUrgeSurf={logUrgeSurf} onSlip={logSlip} />
                    ))}
                  </div>
                )}
              </section>
            )}

            {activeTab === 'log' && (
              <section>
                <SectionHeader label="Activity Log" className="mb-4" />
                {logs.length === 0 ? (
                  <EmptyState
                    icon="📖"
                    title="No activity yet"
                    description="Complete habits, urge-surf, or log comebacks to see your neural activity here."
                  />
                ) : (
                  <div className="flex flex-col gap-2">
                    {logs.slice(0, 20).map((log) => {
                      const cfg = {
                        completion: { dot: 'bg-emerald-500', label: 'Completed', color: 'text-emerald-600 dark:text-emerald-400' },
                        urge_surf: { dot: 'bg-sky-500', label: 'Urge Surfed', color: 'text-sky-600 dark:text-sky-400' },
                        slip: { dot: 'bg-rose-500', label: 'Slip', color: 'text-rose-600 dark:text-rose-400' },
                        comeback: { dot: 'bg-amber-500', label: 'Comeback', color: 'text-amber-600 dark:text-amber-400' },
                      }[log.type] ?? { dot: 'bg-[color:var(--text-3)]', label: log.type, color: 'text-[color:var(--text-2)]' };

                      return (
                        <div key={log.id} className="card-2 px-4 py-3 flex items-start justify-between gap-3 rounded-xl">
                          <div className="flex items-start gap-3 flex-1 min-w-0">
                            <div className={`w-1.5 h-1.5 rounded-full ${cfg.dot} mt-1.5 shrink-0`} />
                            <div className="flex-1 min-w-0">
                              <div className="flex items-center gap-2 mb-0.5">
                                <span className={`text-[11px] font-semibold ${cfg.color}`}>{cfg.label}</span>
                                <span className="text-[11px] text-[color:var(--text-3)]">
                                  {new Date(log.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                </span>
                              </div>
                              <p className="text-[13px] text-[color:var(--text-1)] truncate">{log.itemTitle}</p>
                            </div>
                          </div>
                          {log.dopamineChange !== 0 && (
                            <span className={`text-[11px] font-semibold shrink-0 ${log.dopamineChange > 0 ? 'text-indigo-600 dark:text-indigo-400' : 'text-rose-600 dark:text-rose-400'}`}>
                              {log.dopamineChange > 0 ? '+' : ''}{log.dopamineChange}
                            </span>
                          )}
                        </div>
                      );
                    })}
                  </div>
                )}
              </section>
            )}
          </motion.div>
        </AnimatePresence>

        {/* Footer */}
        <p className="text-center text-[11px] text-[color:var(--text-3)] py-2">
          Every comeback strengthens your playbook
        </p>
      </div>
    </div>
  );
}

function SectionHeader({ label, inline, className }: { label: string; inline?: boolean; className?: string }) {
  if (inline) {
    return <p className={`section-header ${className ?? ''}`}>{label}</p>;
  }
  return (
    <div className={`flex items-center gap-3 mb-4 ${className ?? ''}`}>
      <p className="section-header">{label}</p>
      <div className="flex-1 h-px bg-[color:var(--border)]" />
    </div>
  );
}

function EmptyState({
  icon, title, description, action, onAction,
}: {
  icon: string;
  title: string;
  description: string;
  action?: string;
  onAction?: () => void;
}) {
  return (
    <div className="card py-12 flex flex-col items-center text-center">
      <div className="text-3xl mb-3">{icon}</div>
      <p className="text-[14px] font-semibold text-[color:var(--text-1)] mb-1">{title}</p>
      <p className="text-[13px] text-[color:var(--text-2)] max-w-xs leading-relaxed">{description}</p>
      {action && onAction && (
        <button onClick={onAction} className="btn-primary mt-5 px-5 py-2.5 text-[13px]">
          <Plus className="w-3.5 h-3.5" />
          {action}
        </button>
      )}
    </div>
  );
}
