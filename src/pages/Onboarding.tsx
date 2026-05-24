import React, { useState, useRef } from 'react';
import { Brain, Zap, ArrowRight, Check, RefreshCw, ChevronRight } from 'lucide-react';
import { useNeuroStore } from '../store/useNeuroStore';
import type { NeuroStack } from '../store/useNeuroStore';

// ── Types ────────────────────────────────────────────────────────────────────

type Role = 'Builder' | 'Designer' | 'Athlete' | 'Student' | 'Other';

type HabitSuggestion = Omit<NeuroStack,
  'id' | 'myelinationLevel' | 'streak' | 'completions' | 'createdAt' | 'isActive'
>;

// ── Role-aware habit suggestions ─────────────────────────────────────────────

const SUGGESTIONS: Record<Role, HabitSuggestion[]> = {
  Builder: [
    {
      title: 'Morning Deep Work',
      anchorCue: 'After I sit at my desk and open my laptop',
      action: 'I will write down my one critical task and work on only that for 25 minutes',
      reward: 'I will take a 5-minute walk and acknowledge what I shipped',
      category: 'focus',
      acetylcholineDuration: 25,
    },
    {
      title: 'No-Phone First Hour',
      anchorCue: 'When I wake up and silence my alarm',
      action: 'I will leave my phone face-down on my desk and not check it for one hour',
      reward: 'I will make a drink of my choice and appreciate the clarity',
      category: 'mindset',
      acetylcholineDuration: 60,
    },
    {
      title: 'End-of-Day Shutdown',
      anchorCue: 'Before I close my laptop for the last time',
      action: 'I will write 3 things I shipped today and my one priority for tomorrow',
      reward: 'I will close everything and fully disconnect for the evening',
      category: 'focus',
      acetylcholineDuration: 10,
    },
  ],
  Designer: [
    {
      title: 'Morning Sketch',
      anchorCue: 'After breakfast, before opening any design tools',
      action: 'I will sketch one idea — anything — on paper for 10 minutes',
      reward: 'I will photograph the sketch and keep it as a record',
      category: 'focus',
      acetylcholineDuration: 10,
    },
    {
      title: 'Daily Inspiration Block',
      anchorCue: 'After lunch, when energy naturally dips',
      action: 'I will browse design references for exactly 15 minutes, no more',
      reward: 'I will save three things that genuinely surprised me',
      category: 'mindset',
      acetylcholineDuration: 15,
    },
    {
      title: 'Screen-Free Wind Down',
      anchorCue: 'One hour before I plan to sleep',
      action: 'I will put all screens away and do something analog — read, sketch, or walk',
      reward: 'I will notice how differently my brain feels without a screen',
      category: 'wellness',
      acetylcholineDuration: 60,
    },
  ],
  Athlete: [
    {
      title: 'Morning Training',
      anchorCue: 'After I wake up and put on my training kit',
      action: 'I will complete my planned session without checking my phone beforehand',
      reward: 'I will log it immediately and acknowledge I showed up',
      category: 'fitness',
      acetylcholineDuration: 45,
    },
    {
      title: 'Daily Mobility Work',
      anchorCue: 'After every main training session, before stretching',
      action: 'I will do 10 minutes of targeted mobility work for my weak area',
      reward: 'I will appreciate the small compound gain happening in my body',
      category: 'fitness',
      acetylcholineDuration: 10,
    },
    {
      title: 'Lights Out by 10pm',
      anchorCue: 'When my phone alarm goes off at 9:30pm',
      action: 'I will stop all screens and begin my sleep preparation',
      reward: 'I will wake up with the satisfaction of having respected recovery',
      category: 'wellness',
      acetylcholineDuration: 30,
    },
  ],
  Student: [
    {
      title: 'Daily Review Session',
      anchorCue: 'When I sit down at my study space and put my phone away',
      action: 'I will review yesterday\'s notes for 15 minutes before any new material',
      reward: 'I will acknowledge how much more I\'m retaining than most people',
      category: 'focus',
      acetylcholineDuration: 15,
    },
    {
      title: 'Deep Work Block',
      anchorCue: 'After I\'ve set up my study environment and started a timer',
      action: 'I will work on my hardest task for 45 minutes with zero interruptions',
      reward: 'I will take a real break — leave the room and do something physical',
      category: 'focus',
      acetylcholineDuration: 45,
    },
    {
      title: 'Morning Intention',
      anchorCue: 'While having breakfast, before touching my phone',
      action: 'I will write one sentence: what is the one thing I need to accomplish today?',
      reward: 'I will read it once more before starting and let it anchor my day',
      category: 'mindset',
      acetylcholineDuration: 5,
    },
  ],
  Other: [
    {
      title: 'Morning Grounding',
      anchorCue: 'After I wake up and before checking any screen',
      action: 'I will sit quietly for 5 minutes — no input, just presence',
      reward: 'I will acknowledge that I started the day on my terms',
      category: 'mindset',
      acetylcholineDuration: 5,
    },
    {
      title: 'Daily Movement',
      anchorCue: 'Every day at 2pm when my energy flags',
      action: 'I will step outside and walk for at least 10 minutes',
      reward: 'I will notice how my thinking sharpens after movement',
      category: 'fitness',
      acetylcholineDuration: 10,
    },
    {
      title: 'Evening Reflection',
      anchorCue: 'Before I get into bed, pen and paper only',
      action: 'I will write 3 things: one that went well, one I\'ll improve, one I\'m grateful for',
      reward: 'I will close the notebook and leave the day behind',
      category: 'mindset',
      acetylcholineDuration: 10,
    },
  ],
};

// ── Category colours ──────────────────────────────────────────────────────────

const CAT_STYLE: Record<string, { badge: string; dot: string }> = {
  focus:    { badge: 'text-violet-400 bg-violet-900/20 border-violet-800/30', dot: 'bg-violet-400' },
  wellness: { badge: 'text-emerald-400 bg-emerald-900/20 border-emerald-800/30', dot: 'bg-emerald-400' },
  mindset:  { badge: 'text-cyan-400 bg-cyan-900/20 border-cyan-800/30', dot: 'bg-cyan-400' },
  fitness:  { badge: 'text-orange-400 bg-orange-900/20 border-orange-800/30', dot: 'bg-orange-400' },
};

const ROLES: Role[] = ['Builder', 'Designer', 'Athlete', 'Student', 'Other'];

// ── Onboarding ────────────────────────────────────────────────────────────────

export default function Onboarding() {
  const { setUserProfile, addNeuroStack, completeOnboarding } = useNeuroStore();

  const [step, setStep] = useState(0);
  const [direction, setDirection] = useState<'forward' | 'back'>('forward');
  const [animating, setAnimating] = useState(false);

  const [name, setName] = useState('');
  const [role, setRole] = useState<Role | null>(null);
  const [selectedHabit, setSelectedHabit] = useState<HabitSuggestion | null>(null);

  const TOTAL_STEPS = 4; // 0=welcome 1=profile 2=habit 3=protocol

  function navigate(to: number) {
    if (animating) return;
    setDirection(to > step ? 'forward' : 'back');
    setAnimating(true);
    setTimeout(() => {
      setStep(to);
      setAnimating(false);
    }, 280);
  }

  function handleFinish() {
    setUserProfile({ name: name.trim() || 'You', role: role ?? 'Builder' });
    if (selectedHabit) addNeuroStack(selectedHabit);
    completeOnboarding();
  }

  const slideClass = animating
    ? direction === 'forward' ? 'animate-slide-out-left' : 'animate-slide-out-right'
    : direction === 'forward' ? 'animate-slide-in-right' : 'animate-slide-in-left';

  const suggestions = role ? SUGGESTIONS[role] : SUGGESTIONS['Builder'];
  const canProceedProfile = name.trim().length > 0 && role !== null;

  return (
    <div className="min-h-screen bg-gray-950 text-slate-200 font-sans flex items-center justify-center overflow-hidden">
      {/* Ambient background */}
      <div className="fixed inset-0 pointer-events-none">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[600px] h-[500px] bg-indigo-900/10 rounded-full blur-3xl" />
        <div className="absolute bottom-0 right-0 w-[400px] h-[400px] bg-cyan-900/8 rounded-full blur-3xl" />
        <div className="bg-grid-glow absolute inset-0 opacity-40" />
      </div>

      <div className="relative w-full max-w-md px-6 py-8 min-h-screen flex flex-col">

        {/* Progress dots — shown on steps 1-3 */}
        {step > 0 && (
          <div className="flex items-center justify-between mb-8 pt-2">
            <button
              onClick={() => navigate(step - 1)}
              className="text-xs text-slate-500 hover:text-slate-300 transition-colors flex items-center gap-1"
            >
              ← Back
            </button>
            <div className="flex gap-1.5">
              {[1, 2, 3].map(i => (
                <div
                  key={i}
                  className={`h-1 rounded-full transition-all duration-300 ${
                    i < step ? 'w-6 bg-indigo-500' :
                    i === step ? 'w-6 bg-indigo-400' :
                    'w-3 bg-slate-700'
                  }`}
                />
              ))}
            </div>
            <div className="w-12" /> {/* spacer */}
          </div>
        )}

        {/* Step content */}
        <div className={`flex-1 flex flex-col ${slideClass}`} key={step}>

          {/* ── STEP 0: WELCOME ── */}
          {step === 0 && (
            <div className="flex-1 flex flex-col justify-center">
              <div className="mb-10">
                <div className="flex items-center gap-2.5 mb-8">
                  <div className="w-9 h-9 rounded-xl bg-indigo-600/20 border border-indigo-500/30 flex items-center justify-center">
                    <Brain className="w-5 h-5 text-indigo-400" />
                  </div>
                  <span className="text-sm font-semibold text-slate-400 tracking-wide">NeuroSync</span>
                </div>

                <h1 className="text-4xl font-bold text-white tracking-tight leading-[1.15] mb-5">
                  Build habits that<br />
                  <span className="text-indigo-400">survive failure.</span>
                </h1>

                <p className="text-slate-400 text-base leading-relaxed max-w-sm">
                  Most apps reward you for not failing. This one helps you recover
                  when you do — faster every time.
                </p>
              </div>

              <div className="space-y-3 mb-8">
                {[
                  { icon: Brain, color: 'text-violet-400', bg: 'bg-violet-900/20 border-violet-800/30', text: 'Track habits with myelination science' },
                  { icon: RefreshCw, color: 'text-amber-400', bg: 'bg-amber-900/20 border-amber-800/30', text: 'Activate the Comeback Protocol on failure' },
                  { icon: Zap, color: 'text-cyan-400', bg: 'bg-cyan-900/20 border-cyan-800/30', text: 'Build your personal recovery playbook' },
                ].map(({ icon: Icon, color, bg, text }) => (
                  <div key={text} className="flex items-center gap-3 glass-panel rounded-xl px-4 py-3">
                    <div className={`w-7 h-7 rounded-lg border flex items-center justify-center flex-shrink-0 ${bg}`}>
                      <Icon className={`w-3.5 h-3.5 ${color}`} />
                    </div>
                    <span className="text-sm text-slate-300">{text}</span>
                  </div>
                ))}
              </div>

              <button
                onClick={() => navigate(1)}
                className="w-full h-14 bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-base rounded-2xl flex items-center justify-center gap-2 transition-all button-pulse shadow-[0_0_20px_rgba(99,102,241,0.3)] hover:shadow-[0_0_30px_rgba(99,102,241,0.45)]"
              >
                Get started
                <ArrowRight className="w-4 h-4" />
              </button>

              <p className="text-center text-xs text-slate-600 mt-4">No account needed · Stored locally</p>
            </div>
          )}

          {/* ── STEP 1: PROFILE ── */}
          {step === 1 && (
            <div className="flex-1 flex flex-col justify-center">
              <div className="mb-8">
                <h2 className="text-3xl font-bold text-white tracking-tight mb-2">
                  What should we call you?
                </h2>
                <p className="text-slate-500 text-sm">This personalises your recovery plans.</p>
              </div>

              <div className="space-y-6">
                <div>
                  <input
                    type="text"
                    value={name}
                    onChange={e => setName(e.target.value)}
                    onKeyDown={e => e.key === 'Enter' && canProceedProfile && navigate(2)}
                    placeholder="Your name"
                    maxLength={32}
                    autoFocus
                    className="w-full bg-slate-900/60 border border-slate-700/60 rounded-xl px-4 py-4 text-lg text-white placeholder-slate-600 focus:outline-none focus:border-indigo-500/60 transition-colors"
                  />
                </div>

                <div>
                  <p className="text-xs font-semibold text-slate-500 uppercase tracking-widest mb-3">
                    What best describes you?
                  </p>
                  <div className="grid grid-cols-3 gap-2">
                    {ROLES.map(r => (
                      <button
                        key={r}
                        onClick={() => setRole(r)}
                        className={`py-2.5 rounded-xl text-sm font-semibold border transition-all button-pulse ${
                          role === r
                            ? 'bg-indigo-600/30 border-indigo-500/60 text-indigo-300'
                            : 'bg-slate-900/40 border-slate-700/40 text-slate-400 hover:border-slate-600/60 hover:text-slate-200'
                        }`}
                      >
                        {r}
                      </button>
                    ))}
                  </div>
                </div>
              </div>

              <div className="mt-auto pt-8">
                <button
                  onClick={() => navigate(2)}
                  disabled={!canProceedProfile}
                  className="w-full h-14 bg-indigo-600 hover:bg-indigo-500 disabled:bg-slate-800 disabled:text-slate-600 disabled:cursor-not-allowed text-white font-semibold text-base rounded-2xl flex items-center justify-center gap-2 transition-all button-pulse"
                >
                  Continue
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          )}

          {/* ── STEP 2: FIRST HABIT ── */}
          {step === 2 && (
            <div className="flex-1 flex flex-col">
              <div className="mb-6">
                <h2 className="text-3xl font-bold text-white tracking-tight mb-2">
                  Your first habit
                </h2>
                <p className="text-slate-500 text-sm">
                  Pick one to start. You can add more any time.
                </p>
              </div>

              <div className="space-y-3 mb-4">
                {suggestions.map((habit) => {
                  const cat = CAT_STYLE[habit.category];
                  const isSelected = selectedHabit?.title === habit.title;
                  return (
                    <button
                      key={habit.title}
                      onClick={() => setSelectedHabit(isSelected ? null : habit)}
                      className={`w-full text-left glass-panel rounded-xl p-4 transition-all border-2 button-pulse ${
                        isSelected
                          ? 'border-indigo-500/60 bg-indigo-900/20'
                          : 'border-transparent hover:border-slate-700/60'
                      }`}
                    >
                      <div className="flex items-start justify-between gap-3">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 mb-1.5">
                            <span className={`text-[10px] font-semibold px-2 py-0.5 rounded-full border ${cat.badge}`}>
                              {habit.category}
                            </span>
                          </div>
                          <p className="text-sm font-semibold text-white leading-tight mb-1">
                            {habit.title}
                          </p>
                          <p className="text-xs text-slate-500 line-clamp-1">
                            <span className="text-slate-400">Cue:</span> {habit.anchorCue}
                          </p>
                        </div>
                        <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center flex-shrink-0 mt-0.5 transition-all ${
                          isSelected
                            ? 'bg-indigo-500 border-indigo-500'
                            : 'border-slate-600'
                        }`}>
                          {isSelected && <Check className="w-3 h-3 text-white" />}
                        </div>
                      </div>
                    </button>
                  );
                })}
              </div>

              <div className="mt-auto pt-2 space-y-3">
                <button
                  onClick={() => navigate(3)}
                  disabled={!selectedHabit}
                  className="w-full h-14 bg-indigo-600 hover:bg-indigo-500 disabled:bg-slate-800 disabled:text-slate-600 disabled:cursor-not-allowed text-white font-semibold text-base rounded-2xl flex items-center justify-center gap-2 transition-all button-pulse"
                >
                  Add this habit
                  <ChevronRight className="w-4 h-4" />
                </button>
                <button
                  onClick={() => navigate(3)}
                  className="w-full h-10 text-sm text-slate-500 hover:text-slate-300 transition-colors"
                >
                  Skip for now →
                </button>
              </div>
            </div>
          )}

          {/* ── STEP 3: COMEBACK PROTOCOL EXPLAINER ── */}
          {step === 3 && (
            <div className="flex-1 flex flex-col justify-center">
              <div className="mb-8">
                <div className="w-12 h-12 rounded-2xl bg-amber-900/20 border border-amber-800/30 flex items-center justify-center mb-6">
                  <RefreshCw className="w-6 h-6 text-amber-400" />
                </div>

                <h2 className="text-3xl font-bold text-white tracking-tight mb-3">
                  Meet the<br />
                  <span className="text-amber-400">Comeback Protocol.</span>
                </h2>

                <p className="text-slate-400 text-sm leading-relaxed mb-7">
                  Streaks punish you for being human. We built something different.
                </p>
              </div>

              <div className="space-y-4 mb-8">
                {[
                  {
                    num: '01',
                    color: 'text-amber-400',
                    bg: 'bg-amber-900/20 border-amber-800/30',
                    title: 'You miss a habit',
                    body: 'The protocol activates automatically. No guilt prompt, no streak broken notification.',
                  },
                  {
                    num: '02',
                    color: 'text-indigo-400',
                    bg: 'bg-indigo-900/20 border-indigo-800/30',
                    title: 'You get a reset plan',
                    body: '1–3 micro-actions tailored to your energy. Doable in under 2 minutes.',
                  },
                  {
                    num: '03',
                    color: 'text-emerald-400',
                    bg: 'bg-emerald-900/20 border-emerald-800/30',
                    title: 'Your playbook grows',
                    body: 'Every comeback is logged. Over time, patterns emerge. You learn how you recover.',
                  },
                ].map(({ num, color, bg, title, body }) => (
                  <div key={num} className="flex gap-4 glass-panel rounded-xl p-4">
                    <div className={`w-8 h-8 rounded-lg border flex items-center justify-center flex-shrink-0 text-[11px] font-bold font-mono ${color} ${bg}`}>
                      {num}
                    </div>
                    <div>
                      <p className="text-sm font-semibold text-white mb-0.5">{title}</p>
                      <p className="text-xs text-slate-500 leading-relaxed">{body}</p>
                    </div>
                  </div>
                ))}
              </div>

              <div className="glass-panel rounded-xl px-4 py-3 mb-8 border-amber-800/20">
                <p className="text-xs text-slate-400 leading-relaxed">
                  <span className="text-amber-400 font-semibold">Your Recovery Rate</span> — not your streak — is the number we track. It measures how often you activate the protocol and complete the reset plan.
                </p>
              </div>

              <button
                onClick={handleFinish}
                className="w-full h-14 bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-base rounded-2xl flex items-center justify-center gap-2 transition-all button-pulse shadow-[0_0_20px_rgba(99,102,241,0.3)] hover:shadow-[0_0_30px_rgba(99,102,241,0.45)]"
              >
                I'm ready
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          )}

        </div>
      </div>

      <style>{`
        @keyframes slideInRight {
          from { opacity: 0; transform: translateX(32px); }
          to   { opacity: 1; transform: translateX(0); }
        }
        @keyframes slideInLeft {
          from { opacity: 0; transform: translateX(-32px); }
          to   { opacity: 1; transform: translateX(0); }
        }
        @keyframes slideOutLeft {
          from { opacity: 1; transform: translateX(0); }
          to   { opacity: 0; transform: translateX(-32px); }
        }
        @keyframes slideOutRight {
          from { opacity: 1; transform: translateX(0); }
          to   { opacity: 0; transform: translateX(32px); }
        }
        .animate-slide-in-right  { animation: slideInRight  0.28s cubic-bezier(0.25,0.46,0.45,0.94) both; }
        .animate-slide-in-left   { animation: slideInLeft   0.28s cubic-bezier(0.25,0.46,0.45,0.94) both; }
        .animate-slide-out-left  { animation: slideOutLeft  0.22s cubic-bezier(0.55,0,1,0.45) both; }
        .animate-slide-out-right { animation: slideOutRight 0.22s cubic-bezier(0.55,0,1,0.45) both; }
      `}</style>
    </div>
  );
}
