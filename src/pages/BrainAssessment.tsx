import React, { useState, useEffect } from 'react';
import { useNeuroStore } from '../store/useNeuroStore';
import type { NeuroBrainProfile } from '../store/useNeuroStore';
import { getArchetypeName, getProfileInsights } from '../utils/brainHelpers';

// ── Question definitions ──────────────────────────────────────────────────────

type QuestionKey = keyof Omit<NeuroBrainProfile, 'completedAt'>;

interface Answer {
  label: string;
  sub: string;
  value: string;
}

interface Question {
  key: QuestionKey;
  text: string;
  answers: Answer[];
}

const QUESTIONS: Question[] = [
  {
    key: 'failureStyle',
    text: 'When you miss something important, what\'s your first instinct?',
    answers: [
      { label: 'Get frustrated with myself', sub: 'I set a high bar and I know I missed it', value: 'perfectionist' },
      { label: 'Avoid thinking about it', sub: 'It\'s easier to not look at the gap', value: 'avoider' },
      { label: 'Analyse what went wrong', sub: 'I want to understand the cause before acting', value: 'analyst' },
      { label: 'Just move on', sub: 'I drift to the next thing without much processing', value: 'drifter' },
    ],
  },
  {
    key: 'motivationSource',
    text: 'What usually gets you started on a habit?',
    answers: [
      { label: 'Who I want to become', sub: 'The identity pull is what moves me', value: 'identity' },
      { label: 'A specific outcome', sub: 'I can see the result and I want it', value: 'outcome' },
      { label: 'The process itself', sub: 'I like the system or the ritual', value: 'process' },
      { label: 'Necessity', sub: 'I do it because I have to', value: 'survival' },
    ],
  },
  {
    key: 'peakEnergyWindow',
    text: 'When is your mental energy highest?',
    answers: [
      { label: 'Morning', sub: 'First few hours after waking are my sharpest', value: 'morning' },
      { label: 'Afternoon', sub: 'I warm up and hit a peak mid-day', value: 'afternoon' },
      { label: 'Evening', sub: 'I come alive after 6pm', value: 'evening' },
      { label: 'It varies', sub: 'Depends on the day, sleep, and context', value: 'variable' },
    ],
  },
  {
    key: 'recoverySpeed',
    text: 'After a setback, how long do you usually feel stuck?',
    answers: [
      { label: 'A few minutes', sub: 'I reset and continue fast', value: 'fast' },
      { label: 'A few hours', sub: 'I need time to process', value: 'medium' },
      { label: 'A few days', sub: 'I spiral before recovering', value: 'slow' },
      { label: 'It varies', sub: 'Depends completely on the situation', value: 'variable' },
    ],
  },
  {
    key: 'primaryBlocker',
    text: 'What most often breaks your habits?',
    answers: [
      { label: 'Low energy', sub: 'I just don\'t have the fuel when it\'s time', value: 'energy' },
      { label: 'Overwhelm', sub: 'Too many things competing for my attention', value: 'overwhelm' },
      { label: 'Distraction', sub: 'I get pulled away before I start', value: 'distraction' },
      { label: 'Life events', sub: 'External circumstances knock me off track', value: 'life' },
    ],
  },
  {
    key: 'selfTalkPattern',
    text: 'What does your inner voice say after missing a habit?',
    answers: [
      { label: '"I should have done better"', sub: 'Self-critical and exacting', value: 'self-critical' },
      { label: '"I don\'t want to think about it"', sub: 'I push it away', value: 'avoidant' },
      { label: '"Let me figure out why"', sub: 'Analytical and curious', value: 'rational' },
      { label: '"Maybe this just isn\'t for me"', sub: 'Defeated or hopeless', value: 'hopeless' },
    ],
  },
  {
    key: 'accountabilityStyle',
    text: 'How do you best hold yourself accountable?',
    answers: [
      { label: 'Tracking and metrics', sub: 'Numbers and streaks keep me honest', value: 'tracking' },
      { label: 'Social commitment', sub: 'Knowing someone else knows helps', value: 'external' },
      { label: 'Systems and protocols', sub: 'I follow a clear repeatable process', value: 'systems' },
      { label: 'I don\'t rely on accountability', sub: 'I prefer low-pressure approaches', value: 'none' },
    ],
  },
  {
    key: 'coreDriver',
    text: 'What do you actually want your habits to do for you?',
    answers: [
      { label: 'Feel better daily', sub: 'More energy, less stress, better mood', value: 'feel-better' },
      { label: 'Perform at a higher level', sub: 'Output, capability, results', value: 'perform-better' },
      { label: 'Become a specific person', sub: 'Identity shift is the real goal', value: 'become-someone' },
      { label: 'Survive and function', sub: 'I just need to hold it together', value: 'survive' },
    ],
  },
];

// ── Component ─────────────────────────────────────────────────────────────────

type Answers = Partial<Record<QuestionKey, string>>;

type Phase = 'questions' | 'processing' | 'reveal';

const CATEGORY_ICONS: Record<string, string> = {
  failureStyle: '🧠',
  motivationSource: '⚡',
  peakEnergyWindow: '🕐',
  recoverySpeed: '🔄',
  primaryBlocker: '🧱',
  selfTalkPattern: '💬',
  accountabilityStyle: '📊',
  coreDriver: '🎯',
};

export default function BrainAssessment() {
  const setBrainProfile = useNeuroStore(s => s.setBrainProfile);

  const [currentQ, setCurrentQ] = useState(0);
  const [answers, setAnswers] = useState<Answers>({});
  const [selected, setSelected] = useState<string | null>(null);
  const [phase, setPhase] = useState<Phase>('questions');
  const [animDir, setAnimDir] = useState<'in' | 'out'>('in');
  const [profile, setProfile] = useState<NeuroBrainProfile | null>(null);

  const question = QUESTIONS[currentQ];
  const progress = ((currentQ) / QUESTIONS.length) * 100;

  function handleSelect(value: string) {
    if (selected) return; // already chosen, waiting for transition
    setSelected(value);
    setTimeout(() => advance(value), 320);
  }

  function advance(value: string) {
    const next = { ...answers, [question.key]: value };
    setAnswers(next);

    if (currentQ < QUESTIONS.length - 1) {
      setAnimDir('out');
      setTimeout(() => {
        setCurrentQ(q => q + 1);
        setSelected(null);
        setAnimDir('in');
      }, 220);
    } else {
      // All answered — build profile and go to processing
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

  function handleSkip() {
    advance('analyst'); // fallback value for current question
  }

  // Auto-advance from processing to reveal after 1.5s
  useEffect(() => {
    if (phase === 'processing') {
      const t = setTimeout(() => setPhase('reveal'), 1600);
      return () => clearTimeout(t);
    }
  }, [phase]);

  function handleApply() {
    if (profile) setBrainProfile(profile);
  }

  // ── Render ────────────────────────────────────────────────────────────────

  if (phase === 'processing') {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-[#0a0a0f] px-6">
        <div className="flex flex-col items-center gap-6">
          <div className="relative w-20 h-20">
            <div className="absolute inset-0 rounded-full border-2 border-indigo-500/30 animate-ping" />
            <div className="absolute inset-2 rounded-full border-2 border-indigo-400/50 animate-pulse" />
            <div className="absolute inset-4 rounded-full bg-indigo-500/20 flex items-center justify-center text-2xl animate-pulse">
              🧠
            </div>
          </div>
          <div className="text-center">
            <p className="text-white/60 text-sm tracking-widest uppercase">Mapping your profile</p>
            <div className="mt-3 flex gap-1 justify-center">
              {[0, 1, 2].map(i => (
                <span
                  key={i}
                  className="w-1.5 h-1.5 rounded-full bg-indigo-400 animate-bounce"
                  style={{ animationDelay: `${i * 0.15}s` }}
                />
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (phase === 'reveal' && profile) {
    const archetype = getArchetypeName(profile);
    const insights = getProfileInsights(profile);
    return (
      <div className="min-h-screen bg-[#0a0a0f] px-6 py-12 flex flex-col items-center">
        <div className="w-full max-w-md flex flex-col gap-8 animate-fade-in">
          {/* Header */}
          <div className="text-center">
            <p className="text-white/40 text-xs tracking-widest uppercase mb-3">Your neural profile</p>
            <h1 className="text-2xl font-semibold text-white leading-tight">
              {archetype}
            </h1>
            <p className="text-white/40 text-sm mt-2">
              Based on your 8 responses — this shapes everything in the app.
            </p>
          </div>

          {/* Insight cards */}
          <div className="flex flex-col gap-3">
            {insights.map((insight, i) => (
              <div
                key={i}
                className="bg-white/5 border border-white/8 rounded-2xl px-4 py-4 flex gap-3 items-start"
                style={{ animationDelay: `${i * 0.1}s` }}
              >
                <span className="text-indigo-400 text-sm mt-0.5 shrink-0">✦</span>
                <p className="text-white/75 text-sm leading-relaxed">{insight}</p>
              </div>
            ))}
          </div>

          {/* Profile dimensions summary */}
          <div className="bg-white/3 border border-white/8 rounded-2xl px-4 py-4">
            <p className="text-white/30 text-xs tracking-widest uppercase mb-3">Profile dimensions</p>
            <div className="grid grid-cols-2 gap-2">
              {([
                ['Failure style', profile.failureStyle],
                ['Peak energy', profile.peakEnergyWindow],
                ['Primary blocker', profile.primaryBlocker],
                ['Recovery speed', profile.recoverySpeed],
                ['Accountability', profile.accountabilityStyle],
                ['Core driver', profile.coreDriver],
              ] as [string, string][]).map(([label, val]) => (
                <div key={label} className="flex flex-col gap-0.5">
                  <span className="text-white/30 text-[10px] uppercase tracking-wide">{label}</span>
                  <span className="text-white/70 text-xs capitalize">{val.replace(/-/g, ' ')}</span>
                </div>
              ))}
            </div>
          </div>

          {/* CTA */}
          <button
            onClick={handleApply}
            className="w-full bg-indigo-600 hover:bg-indigo-500 active:scale-95 text-white font-medium py-4 rounded-2xl transition-all duration-200 text-base"
          >
            Apply to my system →
          </button>

          <p className="text-center text-white/25 text-xs">
            You can retake the assessment later from Settings
          </p>
        </div>
      </div>
    );
  }

  // ── Questions phase ───────────────────────────────────────────────────────

  return (
    <div className="min-h-screen bg-[#0a0a0f] flex flex-col">
      {/* Progress bar + header */}
      <div className="px-6 pt-safe pt-6 pb-4">
        <div className="flex items-center justify-between mb-4">
          <div className="flex gap-1.5 items-center">
            {QUESTIONS.map((_, i) => (
              <div
                key={i}
                className={`h-1 rounded-full transition-all duration-300 ${
                  i < currentQ
                    ? 'bg-indigo-500 w-5'
                    : i === currentQ
                    ? 'bg-indigo-400 w-5'
                    : 'bg-white/10 w-3'
                }`}
              />
            ))}
          </div>
          <button
            onClick={handleSkip}
            className="text-white/30 text-xs hover:text-white/50 transition-colors"
          >
            Skip →
          </button>
        </div>
        <p className="text-white/30 text-xs">
          Question {currentQ + 1} of {QUESTIONS.length}
        </p>
      </div>

      {/* Question content */}
      <div
        className="flex-1 flex flex-col px-6 pb-8"
        style={{
          opacity: animDir === 'in' ? 1 : 0,
          transform: animDir === 'in' ? 'translateY(0)' : 'translateY(12px)',
          transition: 'opacity 0.22s ease, transform 0.22s ease',
        }}
      >
        <div className="mb-8 mt-2">
          <div className="text-3xl mb-3">{CATEGORY_ICONS[question.key]}</div>
          <h2 className="text-xl font-medium text-white leading-snug">
            {question.text}
          </h2>
        </div>

        <div className="flex flex-col gap-3">
          {question.answers.map((ans) => {
            const isSelected = selected === ans.value;
            return (
              <button
                key={ans.value}
                onClick={() => handleSelect(ans.value)}
                disabled={!!selected}
                className={`w-full text-left px-4 py-4 rounded-2xl border transition-all duration-200 active:scale-98 ${
                  isSelected
                    ? 'bg-indigo-600/30 border-indigo-500/60 scale-[0.98]'
                    : 'bg-white/4 border-white/10 hover:bg-white/7 hover:border-white/20'
                }`}
              >
                <p className={`font-medium text-sm leading-snug ${isSelected ? 'text-indigo-200' : 'text-white/85'}`}>
                  {ans.label}
                </p>
                <p className={`text-xs mt-0.5 leading-relaxed ${isSelected ? 'text-indigo-300/70' : 'text-white/35'}`}>
                  {ans.sub}
                </p>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
