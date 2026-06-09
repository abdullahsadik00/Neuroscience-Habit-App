import { useState } from 'react';
import { Brain, ArrowRight, Check, RefreshCw, ChevronRight, Zap, Sun, Moon } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { useNeuroStore } from '../store/useNeuroStore';
import { useTheme } from '../contexts/ThemeContext';
import type { NeuroStack } from '../store/useNeuroStore';

type Role = 'Builder' | 'Designer' | 'Athlete' | 'Student' | 'Other';
type HabitSuggestion = Omit<NeuroStack, 'id' | 'myelinationLevel' | 'streak' | 'completions' | 'createdAt' | 'isActive'>;

const SUGGESTIONS: Record<Role, HabitSuggestion[]> = {
  Builder: [
    { title: 'Morning Deep Work', anchorCue: 'After I sit at my desk and open my laptop', action: 'I will write down my one critical task and work on only that for 25 minutes', reward: 'I will take a 5-minute walk and acknowledge what I shipped', category: 'focus', acetylcholineDuration: 25 },
    { title: 'No-Phone First Hour', anchorCue: 'When I wake up and silence my alarm', action: 'I will leave my phone face-down and not check it for one hour', reward: 'I will make a drink of my choice and appreciate the clarity', category: 'mindset', acetylcholineDuration: 60 },
    { title: 'End-of-Day Shutdown', anchorCue: 'Before I close my laptop for the last time', action: 'I will write 3 things I shipped today and my one priority for tomorrow', reward: 'I will close everything and fully disconnect for the evening', category: 'focus', acetylcholineDuration: 10 },
  ],
  Designer: [
    { title: 'Morning Sketch', anchorCue: 'After breakfast, before opening any design tools', action: 'I will sketch one idea on paper for 10 minutes', reward: 'I will photograph the sketch and keep it as a record', category: 'focus', acetylcholineDuration: 10 },
    { title: 'Daily Inspiration Block', anchorCue: 'After lunch, when energy naturally dips', action: 'I will browse design references for exactly 15 minutes, no more', reward: 'I will save three things that genuinely surprised me', category: 'mindset', acetylcholineDuration: 15 },
    { title: 'Screen-Free Wind Down', anchorCue: 'One hour before I plan to sleep', action: 'I will put all screens away and do something analog', reward: 'I will notice how differently my brain feels without a screen', category: 'wellness', acetylcholineDuration: 60 },
  ],
  Athlete: [
    { title: 'Morning Training', anchorCue: 'After I wake up and put on my training kit', action: 'I will complete my planned session without checking my phone beforehand', reward: 'I will log it immediately and acknowledge I showed up', category: 'fitness', acetylcholineDuration: 45 },
    { title: 'Daily Mobility Work', anchorCue: 'After every main training session', action: 'I will do 10 minutes of targeted mobility work for my weak area', reward: 'I will appreciate the small compound gain happening in my body', category: 'fitness', acetylcholineDuration: 10 },
    { title: 'Lights Out by 10pm', anchorCue: 'When my phone alarm goes off at 9:30pm', action: 'I will stop all screens and begin my sleep preparation', reward: 'I will wake up with the satisfaction of having respected recovery', category: 'wellness', acetylcholineDuration: 30 },
  ],
  Student: [
    { title: 'Daily Review Session', anchorCue: 'When I sit down at my study space', action: 'I will review yesterday\'s notes for 15 minutes before any new material', reward: 'I will acknowledge how much more I\'m retaining than most people', category: 'focus', acetylcholineDuration: 15 },
    { title: 'Deep Work Block', anchorCue: 'After I\'ve set up my study environment', action: 'I will work on my hardest task for 45 minutes with zero interruptions', reward: 'I will take a real break — leave the room and do something physical', category: 'focus', acetylcholineDuration: 45 },
    { title: 'Morning Intention', anchorCue: 'While having breakfast, before touching my phone', action: 'I will write one sentence: what is the one thing I need to accomplish today?', reward: 'I will read it once more before starting and let it anchor my day', category: 'mindset', acetylcholineDuration: 5 },
  ],
  Other: [
    { title: 'Morning Grounding', anchorCue: 'After I wake up and before checking any screen', action: 'I will sit quietly for 5 minutes — no input, just presence', reward: 'I will acknowledge that I started the day on my terms', category: 'mindset', acetylcholineDuration: 5 },
    { title: 'Daily Movement', anchorCue: 'Every day at 2pm when my energy flags', action: 'I will step outside and walk for at least 10 minutes', reward: 'I will notice how my thinking sharpens after movement', category: 'fitness', acetylcholineDuration: 10 },
    { title: 'Evening Reflection', anchorCue: 'Before I get into bed, pen and paper only', action: 'I will write 3 things: one that went well, one I\'ll improve, one I\'m grateful for', reward: 'I will close the notebook and leave the day behind', category: 'mindset', acetylcholineDuration: 10 },
  ],
};

const CAT_BADGE: Record<string, string> = {
  focus:    'bg-indigo-50 text-indigo-600 dark:bg-indigo-500/15 dark:text-indigo-400',
  wellness: 'bg-emerald-50 text-emerald-600 dark:bg-emerald-500/15 dark:text-emerald-400',
  mindset:  'bg-sky-50 text-sky-600 dark:bg-sky-500/15 dark:text-sky-400',
  fitness:  'bg-amber-50 text-amber-600 dark:bg-amber-500/15 dark:text-amber-400',
};

const ROLES: Role[] = ['Builder', 'Designer', 'Athlete', 'Student', 'Other'];

const slideVariants = {
  enter: (dir: number) => ({ opacity: 0, x: dir * 28 }),
  center: { opacity: 1, x: 0 },
  exit: (dir: number) => ({ opacity: 0, x: dir * -28 }),
};

export default function Onboarding() {
  const { setUserProfile, addNeuroStack, completeOnboarding } = useNeuroStore();
  const { theme, toggleTheme } = useTheme();

  const [step, setStep] = useState(0);
  const [dir, setDir] = useState(1);
  const [name, setName] = useState('');
  const [role, setRole] = useState<Role | null>(null);
  const [selectedHabit, setSelectedHabit] = useState<HabitSuggestion | null>(null);

  function navigate(to: number) {
    setDir(to > step ? 1 : -1);
    setStep(to);
  }

  function handleFinish() {
    setUserProfile({ name: name.trim() || 'You', role: role ?? 'Builder' });
    if (selectedHabit) addNeuroStack(selectedHabit);
    completeOnboarding();
  }

  const suggestions = role ? SUGGESTIONS[role] : SUGGESTIONS['Builder'];
  const canProceed = name.trim().length > 0 && role !== null;

  return (
    <div className="min-h-screen bg-[#FAFAF8] dark:bg-[#0F1115] transition-colors duration-300">
      {/* Theme toggle */}
      <button onClick={toggleTheme} className="theme-toggle fixed top-5 right-5 z-50">
        {theme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
      </button>

      <div className="max-w-md mx-auto px-6 min-h-screen flex flex-col py-10">

        {/* Progress bar — steps 1–3 */}
        {step > 0 && (
          <div className="flex items-center justify-between mb-10">
            <button
              onClick={() => navigate(step - 1)}
              className="text-[13px] font-medium text-[color:var(--text-3)] hover:text-[color:var(--text-2)] transition-colors"
            >
              ← Back
            </button>
            <div className="flex gap-1.5">
              {[1, 2, 3].map(i => (
                <div
                  key={i}
                  className={`h-[3px] rounded-full transition-all duration-300 ${
                    i <= step ? 'bg-indigo-500 dark:bg-indigo-400 w-6' : 'bg-[color:var(--surface-3)] w-4'
                  }`}
                />
              ))}
            </div>
            <div className="w-10" />
          </div>
        )}

        <AnimatePresence mode="wait" custom={dir}>
          <motion.div
            key={step}
            custom={dir}
            variants={slideVariants}
            initial="enter"
            animate="center"
            exit="exit"
            transition={{ duration: 0.26, ease: [0.25, 0.46, 0.45, 0.94] }}
            className="flex-1 flex flex-col"
          >

            {/* ── STEP 0: WELCOME ── */}
            {step === 0 && (
              <div className="flex-1 flex flex-col justify-center">
                <div className="mb-10">
                  <div className="flex items-center gap-2.5 mb-10">
                    <div className="w-9 h-9 rounded-xl bg-indigo-50 dark:bg-indigo-500/15 flex items-center justify-center">
                      <Brain className="w-5 h-5 text-indigo-600 dark:text-indigo-400" />
                    </div>
                    <span className="text-[13px] font-semibold text-[color:var(--text-3)] tracking-wide">NeuroSync</span>
                  </div>

                  <h1 className="text-[42px] font-bold text-[color:var(--text-1)] tracking-tight leading-[1.1] mb-5">
                    Build habits that<br />
                    <span className="text-indigo-600 dark:text-indigo-400">survive failure.</span>
                  </h1>

                  <p className="text-[color:var(--text-2)] text-[16px] leading-relaxed">
                    Most apps reward you for not failing. This one helps you recover when you do — faster every time.
                  </p>
                </div>

                <div className="space-y-2.5 mb-10">
                  {[
                    { icon: Brain,     color: 'text-indigo-500 dark:text-indigo-400', bg: 'bg-indigo-50 dark:bg-indigo-500/12', text: 'Track habits with myelination science' },
                    { icon: RefreshCw, color: 'text-amber-600 dark:text-amber-400',   bg: 'bg-amber-50 dark:bg-amber-500/12',   text: 'Activate the Comeback Protocol on failure' },
                    { icon: Zap,       color: 'text-sky-500 dark:text-sky-400',       bg: 'bg-sky-50 dark:bg-sky-500/12',       text: 'Build your personal recovery playbook' },
                  ].map(({ icon: Icon, color, bg, text }) => (
                    <div key={text} className="flex items-center gap-3.5 px-4 py-3.5 card-2 rounded-xl">
                      <div className={`w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 ${bg}`}>
                        <Icon className={`w-4 h-4 ${color}`} />
                      </div>
                      <span className="text-[14px] font-medium text-[color:var(--text-1)]">{text}</span>
                    </div>
                  ))}
                </div>

                <button onClick={() => navigate(1)} className="btn-primary w-full h-14 text-[15px] rounded-[10px]">
                  Get started
                  <ArrowRight className="w-4 h-4" />
                </button>
                <p className="text-center text-[12px] text-[color:var(--text-3)] mt-4">
                  No account needed · Stored locally
                </p>
              </div>
            )}

            {/* ── STEP 1: PROFILE ── */}
            {step === 1 && (
              <div className="flex-1 flex flex-col">
                <div className="mb-8">
                  <h2 className="text-[32px] font-bold text-[color:var(--text-1)] tracking-tight leading-tight mb-2">
                    What should we call you?
                  </h2>
                  <p className="text-[14px] text-[color:var(--text-2)]">This personalises your recovery plans.</p>
                </div>

                <div className="space-y-6">
                  <input
                    type="text"
                    value={name}
                    onChange={e => setName(e.target.value)}
                    onKeyDown={e => e.key === 'Enter' && canProceed && navigate(2)}
                    placeholder="Your name"
                    maxLength={32}
                    autoFocus
                    className="ns-input text-[17px]"
                  />

                  <div>
                    <p className="ns-label">What best describes you?</p>
                    <div className="grid grid-cols-3 gap-2">
                      {ROLES.map(r => (
                        <button
                          key={r}
                          onClick={() => setRole(r)}
                          className={`py-2.5 rounded-[9px] text-[13px] font-semibold border transition-all ${
                            role === r
                              ? 'bg-indigo-50 dark:bg-indigo-500/15 border-indigo-300 dark:border-indigo-500/50 text-indigo-600 dark:text-indigo-400'
                              : 'bg-[color:var(--surface-2)] border-[color:var(--border)] text-[color:var(--text-2)] hover:border-[color:var(--border-2)] hover:text-[color:var(--text-1)]'
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
                    disabled={!canProceed}
                    className="btn-primary w-full h-14 rounded-[10px]"
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
                  <h2 className="text-[32px] font-bold text-[color:var(--text-1)] tracking-tight leading-tight mb-2">
                    Your first habit
                  </h2>
                  <p className="text-[14px] text-[color:var(--text-2)]">
                    Pick one to start. You can add more any time.
                  </p>
                </div>

                <div className="space-y-3 mb-4">
                  {suggestions.map(habit => {
                    const isSelected = selectedHabit?.title === habit.title;
                    const badge = CAT_BADGE[habit.category] ?? CAT_BADGE.focus;
                    return (
                      <button
                        key={habit.title}
                        onClick={() => setSelectedHabit(isSelected ? null : habit)}
                        className={`w-full text-left card p-5 transition-all ${
                          isSelected ? 'ring-2 ring-indigo-500 dark:ring-indigo-400' : 'card-hover'
                        }`}
                      >
                        <div className="flex items-start justify-between gap-3">
                          <div className="flex-1 min-w-0">
                            <div className="mb-2">
                              <span className={`inline-block text-[11px] font-semibold px-2 py-0.5 rounded-full ${badge}`}>
                                {habit.category}
                              </span>
                            </div>
                            <p className="text-[14px] font-semibold text-[color:var(--text-1)] leading-tight mb-1">
                              {habit.title}
                            </p>
                            <p className="text-[12px] text-[color:var(--text-3)] line-clamp-1">
                              Cue: {habit.anchorCue}
                            </p>
                          </div>
                          <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center flex-shrink-0 mt-0.5 transition-all ${
                            isSelected
                              ? 'bg-indigo-500 dark:bg-indigo-400 border-indigo-500 dark:border-indigo-400'
                              : 'border-[color:var(--surface-3)]'
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
                    className="btn-primary w-full h-14 rounded-[10px]"
                  >
                    Add this habit
                    <ChevronRight className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => navigate(3)}
                    className="w-full h-10 text-[13px] font-medium text-[color:var(--text-3)] hover:text-[color:var(--text-2)] transition-colors"
                  >
                    Skip for now →
                  </button>
                </div>
              </div>
            )}

            {/* ── STEP 3: COMEBACK PROTOCOL ── */}
            {step === 3 && (
              <div className="flex-1 flex flex-col justify-center">
                <div className="mb-8">
                  <div className="w-12 h-12 rounded-2xl bg-amber-50 dark:bg-amber-500/12 flex items-center justify-center mb-6">
                    <RefreshCw className="w-6 h-6 text-amber-600 dark:text-amber-400" />
                  </div>
                  <h2 className="text-[32px] font-bold text-[color:var(--text-1)] tracking-tight leading-tight mb-3">
                    Meet the<br />
                    <span className="text-amber-600 dark:text-amber-400">Comeback Protocol.</span>
                  </h2>
                  <p className="text-[14px] text-[color:var(--text-2)] leading-relaxed">
                    Streaks punish you for being human. We built something different.
                  </p>
                </div>

                <div className="space-y-3 mb-7">
                  {[
                    { num: '01', accent: 'text-amber-600 dark:text-amber-400 bg-amber-50 dark:bg-amber-500/12', title: 'You miss a habit', body: 'The protocol activates automatically. No guilt prompt, no streak broken notification.' },
                    { num: '02', accent: 'text-indigo-600 dark:text-indigo-400 bg-indigo-50 dark:bg-indigo-500/12', title: 'You get a reset plan', body: '1–3 micro-actions tailored to your energy. Doable in under 2 minutes.' },
                    { num: '03', accent: 'text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-500/12', title: 'Your playbook grows', body: 'Every comeback is logged. Over time, patterns emerge. You learn how you recover.' },
                  ].map(({ num, accent, title, body }) => (
                    <div key={num} className="flex gap-4 card-2 p-4 rounded-xl">
                      <div className={`w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 text-[11px] font-bold font-mono ${accent}`}>
                        {num}
                      </div>
                      <div>
                        <p className="text-[13px] font-semibold text-[color:var(--text-1)] mb-0.5">{title}</p>
                        <p className="text-[12px] text-[color:var(--text-2)] leading-relaxed">{body}</p>
                      </div>
                    </div>
                  ))}
                </div>

                <div className="card-2 px-4 py-3.5 mb-8 rounded-xl">
                  <p className="text-[13px] text-[color:var(--text-2)] leading-relaxed">
                    <span className="font-semibold text-amber-600 dark:text-amber-400">Your Recovery Rate</span> — not your streak — is the number we track.
                  </p>
                </div>

                <button onClick={handleFinish} className="btn-primary w-full h-14 rounded-[10px]">
                  I'm ready
                  <ArrowRight className="w-4 h-4" />
                </button>
              </div>
            )}

          </motion.div>
        </AnimatePresence>
      </div>
    </div>
  );
}
