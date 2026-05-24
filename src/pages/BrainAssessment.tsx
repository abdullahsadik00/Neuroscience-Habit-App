import React, { useState, useEffect } from 'react';
import { Sun, Moon } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { useNeuroStore } from '../store/useNeuroStore';
import { useTheme } from '../contexts/ThemeContext';
import type { NeuroBrainProfile } from '../store/useNeuroStore';
import { getArchetypeName, getProfileInsights } from '../utils/brainHelpers';

type QuestionKey = keyof Omit<NeuroBrainProfile, 'completedAt'>;
interface Answer { label: string; sub: string; value: string; }
interface Question { key: QuestionKey; text: string; icon: string; answers: Answer[]; }

const QUESTIONS: Question[] = [
  { key: 'failureStyle', icon: '🧠', text: 'When you miss something important, what\'s your first instinct?',
    answers: [
      { label: 'Get frustrated with myself', sub: 'I set a high bar and I know I missed it', value: 'perfectionist' },
      { label: 'Avoid thinking about it', sub: 'It\'s easier to not look at the gap', value: 'avoider' },
      { label: 'Analyse what went wrong', sub: 'I want to understand the cause before acting', value: 'analyst' },
      { label: 'Just move on', sub: 'I drift to the next thing without much processing', value: 'drifter' },
    ],
  },
  { key: 'motivationSource', icon: '⚡', text: 'What usually gets you started on a habit?',
    answers: [
      { label: 'Who I want to become', sub: 'The identity pull is what moves me', value: 'identity' },
      { label: 'A specific outcome', sub: 'I can see the result and I want it', value: 'outcome' },
      { label: 'The process itself', sub: 'I like the system or the ritual', value: 'process' },
      { label: 'Necessity', sub: 'I do it because I have to', value: 'survival' },
    ],
  },
  { key: 'peakEnergyWindow', icon: '🕐', text: 'When is your mental energy highest?',
    answers: [
      { label: 'Morning', sub: 'First few hours after waking are my sharpest', value: 'morning' },
      { label: 'Afternoon', sub: 'I warm up and hit a peak mid-day', value: 'afternoon' },
      { label: 'Evening', sub: 'I come alive after 6pm', value: 'evening' },
      { label: 'It varies', sub: 'Depends on the day, sleep, and context', value: 'variable' },
    ],
  },
  { key: 'recoverySpeed', icon: '🔄', text: 'After a setback, how long do you usually feel stuck?',
    answers: [
      { label: 'A few minutes', sub: 'I reset and continue fast', value: 'fast' },
      { label: 'A few hours', sub: 'I need time to process', value: 'medium' },
      { label: 'A few days', sub: 'I spiral before recovering', value: 'slow' },
      { label: 'It varies', sub: 'Depends completely on the situation', value: 'variable' },
    ],
  },
  { key: 'primaryBlocker', icon: '🧱', text: 'What most often breaks your habits?',
    answers: [
      { label: 'Low energy', sub: 'I just don\'t have the fuel when it\'s time', value: 'energy' },
      { label: 'Overwhelm', sub: 'Too many things competing for my attention', value: 'overwhelm' },
      { label: 'Distraction', sub: 'I get pulled away before I start', value: 'distraction' },
      { label: 'Life events', sub: 'External circumstances knock me off track', value: 'life' },
    ],
  },
  { key: 'selfTalkPattern', icon: '💬', text: 'What does your inner voice say after missing a habit?',
    answers: [
      { label: '"I should have done better"', sub: 'Self-critical and exacting', value: 'self-critical' },
      { label: '"I don\'t want to think about it"', sub: 'I push it away', value: 'avoidant' },
      { label: '"Let me figure out why"', sub: 'Analytical and curious', value: 'rational' },
      { label: '"Maybe this just isn\'t for me"', sub: 'Defeated or hopeless', value: 'hopeless' },
    ],
  },
  { key: 'accountabilityStyle', icon: '📊', text: 'How do you best hold yourself accountable?',
    answers: [
      { label: 'Tracking and metrics', sub: 'Numbers and streaks keep me honest', value: 'tracking' },
      { label: 'Social commitment', sub: 'Knowing someone else knows helps', value: 'external' },
      { label: 'Systems and protocols', sub: 'I follow a clear repeatable process', value: 'systems' },
      { label: 'I don\'t rely on accountability', sub: 'I prefer low-pressure approaches', value: 'none' },
    ],
  },
  { key: 'coreDriver', icon: '🎯', text: 'What do you actually want your habits to do for you?',
    answers: [
      { label: 'Feel better daily', sub: 'More energy, less stress, better mood', value: 'feel-better' },
      { label: 'Perform at a higher level', sub: 'Output, capability, results', value: 'perform-better' },
      { label: 'Become a specific person', sub: 'Identity shift is the real goal', value: 'become-someone' },
      { label: 'Survive and function', sub: 'I just need to hold it together', value: 'survive' },
    ],
  },
];

type Answers = Partial<Record<QuestionKey, string>>;
type Phase = 'questions' | 'processing' | 'reveal';

export default function BrainAssessment() {
  const setBrainProfile = useNeuroStore(s => s.setBrainProfile);
  const { theme, toggleTheme } = useTheme();

  const [currentQ, setCurrentQ] = useState(0);
  const [answers, setAnswers] = useState<Answers>({});
  const [selected, setSelected] = useState<string | null>(null);
  const [phase, setPhase] = useState<Phase>('questions');
  const [dir, setDir] = useState(1);
  const [profile, setProfile] = useState<NeuroBrainProfile | null>(null);

  const question = QUESTIONS[currentQ];
  const progress = ((currentQ) / QUESTIONS.length) * 100;

  function handleSelect(value: string) {
    if (selected) return;
    setSelected(value);
    setTimeout(() => advance(value), 300);
  }

  function advance(value: string) {
    const next = { ...answers, [question.key]: value };
    setAnswers(next);

    if (currentQ < QUESTIONS.length - 1) {
      setDir(1);
      setTimeout(() => {
        setCurrentQ(q => q + 1);
        setSelected(null);
      }, 200);
    } else {
      const built: NeuroBrainProfile = {
        failureStyle: (next.failureStyle ?? 'analyst') as NeuroBrainProfile['failureStyle'],
        peakEnergyWindow: (next.peakEnergyWindow ?? 'morning') as NeuroBrainProfile['peakEnergyWindow'],
        recoverySpeed: (next.recoverySpeed ?? 'medium') as NeuroBrainProfile['recoverySpeed'],
        primaryBlocker: (next.primaryBlocker ?? 'energy') as NeuroBrainProfile['primaryBlocker'],
        selfTalkPattern: (next.selfTalkPattern ?? 'rational') as NeuroBrainProfile['selfTalkPattern'],
        motivationSource: (next.motivationSource ?? 'outcome') as NeuroBrainProfile['motivationSource'],
        accountabilityStyle: (next.accountabilityStyle ?? 'tracking') as NeuroBrainProfile['accountabilityStyle'],
        coreDriver: (next.coreDriver ?? 'feel-better') as NeuroBrainProfile['coreDriver'],
        completedAt: new Date().toISOString(),
      };
      setProfile(built);
      setPhase('processing');
    }
  }

  useEffect(() => {
    if (phase === 'processing') {
      const t = setTimeout(() => setPhase('reveal'), 1800);
      return () => clearTimeout(t);
    }
  }, [phase]);

  function handleApply() {
    if (profile) setBrainProfile(profile);
  }

  // ── Processing ──────────────────────────────────────────────────────────────
  if (phase === 'processing') {
    return (
      <div className="min-h-screen bg-[#FAFAF8] dark:bg-[#0F1115] flex flex-col items-center justify-center px-6">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.4 }}
          className="flex flex-col items-center gap-6"
        >
          <div className="relative w-16 h-16">
            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 2, repeat: Infinity, ease: 'linear' }}
              className="absolute inset-0 rounded-full border-2 border-transparent border-t-indigo-500 dark:border-t-indigo-400"
            />
            <div className="absolute inset-2 flex items-center justify-center text-2xl">🧠</div>
          </div>
          <div className="text-center">
            <p className="text-[13px] font-medium text-[color:var(--text-2)] tracking-widest uppercase mb-3">
              Mapping your profile
            </p>
            <div className="flex gap-1.5 justify-center">
              {[0, 1, 2].map(i => (
                <motion.span
                  key={i}
                  className="w-1.5 h-1.5 rounded-full bg-indigo-400 dark:bg-indigo-500"
                  animate={{ opacity: [0.3, 1, 0.3] }}
                  transition={{ duration: 1.2, repeat: Infinity, delay: i * 0.2 }}
                />
              ))}
            </div>
          </div>
        </motion.div>
      </div>
    );
  }

  // ── Reveal ──────────────────────────────────────────────────────────────────
  if (phase === 'reveal' && profile) {
    const archetype = getArchetypeName(profile);
    const insights = getProfileInsights(profile);

    return (
      <div className="min-h-screen bg-[#FAFAF8] dark:bg-[#0F1115] px-6 py-12">
        <div className="max-w-md mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="flex flex-col gap-6"
          >
            {/* Header */}
            <div className="text-center">
              <p className="section-header mb-3">Your Neural Profile</p>
              <h1 className="text-[28px] font-bold text-[color:var(--text-1)] tracking-tight leading-tight">
                {archetype}
              </h1>
              <p className="text-[13px] text-[color:var(--text-2)] mt-2">
                Based on your 8 responses — this shapes everything in the app.
              </p>
            </div>

            {/* Insights */}
            <div className="flex flex-col gap-3">
              {insights.map((insight, i) => (
                <motion.div
                  key={i}
                  initial={{ opacity: 0, y: 12 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.35, delay: 0.1 + i * 0.08 }}
                  className="card-2 px-4 py-4 rounded-xl flex gap-3 items-start"
                >
                  <span className="text-indigo-500 dark:text-indigo-400 text-sm mt-0.5 shrink-0">✦</span>
                  <p className="text-[13px] text-[color:var(--text-1)] leading-relaxed">{insight}</p>
                </motion.div>
              ))}
            </div>

            {/* Profile dimensions */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.5 }}
              className="card p-5"
            >
              <p className="section-header mb-4">Profile Dimensions</p>
              <div className="grid grid-cols-2 gap-4">
                {([
                  ['Failure style', profile.failureStyle],
                  ['Peak energy', profile.peakEnergyWindow],
                  ['Primary blocker', profile.primaryBlocker],
                  ['Recovery speed', profile.recoverySpeed],
                  ['Accountability', profile.accountabilityStyle],
                  ['Core driver', profile.coreDriver],
                ] as [string, string][]).map(([label, val]) => (
                  <div key={label}>
                    <p className="text-[10px] font-semibold uppercase tracking-wider text-[color:var(--text-3)] mb-0.5">{label}</p>
                    <p className="text-[13px] font-medium text-[color:var(--text-1)] capitalize">{val.replace(/-/g, ' ')}</p>
                  </div>
                ))}
              </div>
            </motion.div>

            {/* CTA */}
            <motion.button
              onClick={handleApply}
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.6 }}
              className="btn-primary w-full h-14 rounded-[16px]"
            >
              Apply to my system →
            </motion.button>

            <p className="text-center text-[11px] text-[color:var(--text-3)]">
              You can retake the assessment later from Settings
            </p>
          </motion.div>
        </div>
      </div>
    );
  }

  // ── Questions ────────────────────────────────────────────────────────────────
  return (
    <div className="min-h-screen bg-[#FAFAF8] dark:bg-[#0F1115] flex flex-col">
      {/* Theme toggle */}
      <button onClick={toggleTheme} className="theme-toggle fixed top-5 right-5 z-50">
        {theme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
      </button>

      {/* Progress bar */}
      <div className="px-6 pt-8 pb-6 max-w-md mx-auto w-full">
        <div className="flex items-center justify-between mb-5">
          <p className="text-[12px] font-medium text-[color:var(--text-3)]">
            Question {currentQ + 1} of {QUESTIONS.length}
          </p>
          <button
            onClick={() => advance('analyst')}
            className="text-[12px] font-medium text-[color:var(--text-3)] hover:text-[color:var(--text-2)] transition-colors"
          >
            Skip →
          </button>
        </div>
        <div className="h-[3px] progress-track">
          <motion.div
            className="progress-fill bg-indigo-500 dark:bg-indigo-400"
            initial={false}
            animate={{ width: `${progress}%` }}
            transition={{ duration: 0.4, ease: 'easeOut' }}
          />
        </div>
      </div>

      {/* Question */}
      <div className="flex-1 px-6 pb-10 max-w-md mx-auto w-full">
        <AnimatePresence mode="wait">
          <motion.div
            key={currentQ}
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={{ duration: 0.22, ease: [0.25, 0.46, 0.45, 0.94] }}
          >
            <div className="mb-8">
              <div className="text-3xl mb-4">{question.icon}</div>
              <h2 className="text-[22px] font-semibold text-[color:var(--text-1)] leading-snug tracking-tight">
                {question.text}
              </h2>
            </div>

            <div className="flex flex-col gap-3">
              {question.answers.map(ans => {
                const isSelected = selected === ans.value;
                return (
                  <button
                    key={ans.value}
                    onClick={() => handleSelect(ans.value)}
                    disabled={!!selected}
                    className={`w-full text-left card p-4 transition-all ${
                      isSelected
                        ? 'ring-2 ring-indigo-500 dark:ring-indigo-400 bg-indigo-50 dark:!bg-indigo-500/10'
                        : 'card-hover'
                    }`}
                  >
                    <p className={`text-[14px] font-semibold leading-snug mb-0.5 ${
                      isSelected ? 'text-indigo-600 dark:text-indigo-300' : 'text-[color:var(--text-1)]'
                    }`}>
                      {ans.label}
                    </p>
                    <p className={`text-[12px] leading-relaxed ${
                      isSelected ? 'text-indigo-500/70 dark:text-indigo-400/70' : 'text-[color:var(--text-3)]'
                    }`}>
                      {ans.sub}
                    </p>
                  </button>
                );
              })}
            </div>
          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  );
}
