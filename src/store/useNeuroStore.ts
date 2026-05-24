import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { getLocalDateString, calculateStreak, calculateMyelination, decayNeurochemical } from '../utils/neuroHelpers';

export interface NeuroStack {
  id: string;
  title: string;
  anchorCue: string;
  action: string;
  reward: string;
  category: 'focus' | 'wellness' | 'mindset' | 'fitness';
  acetylcholineDuration: number; // focus timer in minutes
  myelinationLevel: number; // 0 to 100%
  streak: number;
  completions: string[]; // "YYYY-MM-DD" local date strings
  createdAt: string;
  isActive: boolean;
}

export interface NeuroSwap {
  id: string;
  title: string;
  cue: string;
  badResponse: string;
  interceptAction: string;
  frictionLevel: number; // 1 (low) to 5 (high)
  frictionSteps: string[];
  urgeSurfingCompletions: string[]; // "YYYY-MM-DD" local date strings
  slips: string[]; // "YYYY-MM-DD" local date strings
  createdAt: string;
  isActive: boolean;
}

export interface NeuroLog {
  id: string;
  timestamp: string;
  type: 'completion' | 'urge_surf' | 'slip' | 'comeback';
  itemId: string;
  itemTitle: string;
  notes?: string;
  dopamineChange: number;
  epinephrineChange: number;
  gabaChange: number;
  acetylcholineChange: number;
}

export interface ComebackRecord {
  id: string;
  stackId: string;
  date: string; // YYYY-MM-DD
  microActionsCompleted: boolean;
  completedAt: string; // ISO timestamp
}

export interface Neurochemistry {
  dopamine: number; // 0 - 100, baseline 50
  acetylcholine: number; // 0 - 100, baseline 50
  epinephrine: number; // 0 - 100, baseline 50
  gaba: number; // 0 - 100, baseline 50
}

interface NeuroState {
  stacks: NeuroStack[];
  swaps: NeuroSwap[];
  logs: NeuroLog[];
  comebacks: ComebackRecord[];
  neurochemistry: Neurochemistry;
  dopaminePoints: number;

  // Stacks Actions
  addNeuroStack: (stack: Omit<NeuroStack, 'id' | 'myelinationLevel' | 'streak' | 'completions' | 'createdAt' | 'isActive'>) => void;
  updateNeuroStack: (id: string, updates: Partial<NeuroStack>) => void;
  deleteNeuroStack: (id: string) => void;
  completeNeuroStack: (id: string, notes?: string) => void;

  // Swaps Actions
  addNeuroSwap: (swap: Omit<NeuroSwap, 'id' | 'urgeSurfingCompletions' | 'slips' | 'createdAt' | 'isActive'>) => void;
  updateNeuroSwap: (id: string, updates: Partial<NeuroSwap>) => void;
  deleteNeuroSwap: (id: string) => void;
  logUrgeSurf: (id: string, notes?: string) => void;
  logSlip: (id: string, reflection?: string) => void;

  // Comeback Actions
  acknowledgeComeback: (stackId: string, stackTitle: string, microActionsCompleted: boolean) => void;
  getTodayComebackIds: () => string[];

  // Global Actions
  decayNeurochemistry: () => void;
  claimDopaminePoints: (amount: number) => void;
  resetAllData: () => void;
}

const DEFAULT_NEUROCHEMISTRY: Neurochemistry = {
  dopamine: 65, // slightly elevated for onboarding
  acetylcholine: 55,
  epinephrine: 50,
  gaba: 60
};

const INITIAL_STACKS: NeuroStack[] = [
  {
    id: 'demo-stack-1',
    title: 'Morning Focus Alignment',
    anchorCue: 'After I sit at my desk and open my laptop',
    action: 'I will write down my 1 critical task and focus on it for 10 minutes',
    reward: 'I will take a deep breath, smile, and say: "I am actively building a powerful brain!"',
    category: 'focus',
    acetylcholineDuration: 10,
    myelinationLevel: 28,
    streak: 3,
    completions: [
      getLocalDateString(new Date(Date.now() - 172800000)), // 2 days ago
      getLocalDateString(new Date(Date.now() - 86400000)),  // yesterday
      getLocalDateString(new Date())                        // today
    ],
    createdAt: new Date().toISOString(),
    isActive: true
  },
  {
    id: 'demo-stack-2',
    title: 'Neuro-Reset Break',
    anchorCue: 'Immediately after completing a deep work session',
    action: 'I will stand up, look out the window at a distant object, and stretch my body',
    reward: 'I will say "My focus is rested, my eyes are recovered."',
    category: 'wellness',
    acetylcholineDuration: 5,
    myelinationLevel: 8,
    streak: 1,
    completions: [
      getLocalDateString(new Date())
    ],
    createdAt: new Date().toISOString(),
    isActive: true
  }
];

const INITIAL_SWAPS: NeuroSwap[] = [
  {
    id: 'demo-swap-1',
    title: 'Mindless Phone Checking',
    cue: 'When I hit a hard coding bug or feel a moment of mental friction',
    badResponse: 'Unconsciously grab my phone and check social media feeds',
    interceptAction: 'Stand up and do 3 full deep box breaths (4s inhale, 4s hold, 4s exhale, 4s hold)',
    frictionLevel: 3,
    frictionSteps: [
      'Place my phone inside a drawer in another room.',
      'Delete immediate shortcut bookmarks from my desktop.',
      'Switch my phone display to Grayscale to strip visual dopamine rewards.'
    ],
    urgeSurfingCompletions: [
      getLocalDateString(new Date(Date.now() - 86400000)),
      getLocalDateString(new Date())
    ],
    slips: [],
    createdAt: new Date().toISOString(),
    isActive: true
  }
];

export const useNeuroStore = create<NeuroState>()(
  persist(
    (set, get) => ({
      stacks: INITIAL_STACKS,
      swaps: INITIAL_SWAPS,
      logs: [],
      comebacks: [],
      neurochemistry: DEFAULT_NEUROCHEMISTRY,
      dopaminePoints: 120,

      // --- STACKS ACTIONS ---
      addNeuroStack: (stack) => {
        const newStack: NeuroStack = {
          ...stack,
          id: `stack-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
          myelinationLevel: 0,
          streak: 0,
          completions: [],
          createdAt: new Date().toISOString(),
          isActive: true
        };
        set((state) => ({
          stacks: [newStack, ...state.stacks]
        }));
      },

      updateNeuroStack: (id, updates) => {
        set((state) => ({
          stacks: state.stacks.map((stack) =>
            stack.id === id ? { ...stack, ...updates } : stack
          )
        }));
      },

      deleteNeuroStack: (id) => {
        set((state) => ({
          stacks: state.stacks.filter((stack) => stack.id !== id)
        }));
      },

      completeNeuroStack: (id, notes) => {
        const todayStr = getLocalDateString(new Date());
        let dopamineAward = 25;
        let acetylcholineAward = 20;

        set((state) => {
          const updatedStacks = state.stacks.map((stack) => {
            if (stack.id !== id) return stack;
            
            // Avoid duplicate daily completions for calculation safety
            const alreadyCompletedToday = stack.completions.includes(todayStr);
            const completions = alreadyCompletedToday 
              ? stack.completions 
              : [...stack.completions, todayStr];
            
            const streak = calculateStreak(completions);
            const myelinationLevel = calculateMyelination(completions.length, streak);

            // Double reward if they are maintaining a long streak
            if (streak > 5) {
              dopamineAward = 40;
              acetylcholineAward = 30;
            }

            return {
              ...stack,
              completions,
              streak,
              myelinationLevel
            };
          });

          const completedStack = state.stacks.find((s) => s.id === id);
          if (!completedStack) return {};

          const newLog: NeuroLog = {
            id: `log-${Date.now()}`,
            timestamp: new Date().toISOString(),
            type: 'completion',
            itemId: id,
            itemTitle: completedStack.title,
            notes,
            dopamineChange: dopamineAward,
            epinephrineChange: 5, // completing tasks gives a slight alert energy kick
            gabaChange: 0,
            acetylcholineChange: acetylcholineAward
          };

          return {
            stacks: updatedStacks,
            logs: [newLog, ...state.logs],
            dopaminePoints: state.dopaminePoints + dopamineAward,
            neurochemistry: {
              dopamine: Math.min(100, state.neurochemistry.dopamine + dopamineAward),
              acetylcholine: Math.min(100, state.neurochemistry.acetylcholine + acetylcholineAward),
              epinephrine: Math.min(100, state.neurochemistry.epinephrine + 5),
              gaba: state.neurochemistry.gaba
            }
          };
        });
      },

      // --- SWAPS ACTIONS ---
      addNeuroSwap: (swap) => {
        const newSwap: NeuroSwap = {
          ...swap,
          id: `swap-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
          urgeSurfingCompletions: [],
          slips: [],
          createdAt: new Date().toISOString(),
          isActive: true
        };
        set((state) => ({
          swaps: [newSwap, ...state.swaps]
        }));
      },

      updateNeuroSwap: (id, updates) => {
        set((state) => ({
          swaps: state.swaps.map((swap) =>
            swap.id === id ? { ...swap, ...updates } : swap
          )
        }));
      },

      deleteNeuroSwap: (id) => {
        set((state) => ({
          swaps: state.swaps.filter((swap) => swap.id !== id)
        }));
      },

      logUrgeSurf: (id, notes) => {
        const todayStr = getLocalDateString(new Date());
        const dopamineAward = 15;
        const gabaAward = 30; // Calms down craving circuitry dramatically

        set((state) => {
          const updatedSwaps = state.swaps.map((swap) => {
            if (swap.id !== id) return swap;

            const alreadyCompletedToday = swap.urgeSurfingCompletions.includes(todayStr);
            const completions = alreadyCompletedToday
              ? swap.urgeSurfingCompletions
              : [...swap.urgeSurfingCompletions, todayStr];

            return {
              ...swap,
              urgeSurfingCompletions: completions
            };
          });

          const swapItem = state.swaps.find((s) => s.id === id);
          if (!swapItem) return {};

          const newLog: NeuroLog = {
            id: `log-${Date.now()}`,
            timestamp: new Date().toISOString(),
            type: 'urge_surf',
            itemId: id,
            itemTitle: swapItem.title,
            notes: notes || 'Successfully rode out the craving using box breathing.',
            dopamineChange: dopamineAward,
            epinephrineChange: -10, // lowers distress and stress/adrenaline
            gabaChange: gabaAward,
            acetylcholineChange: 10 // conscious control strengthens attention networks
          };

          return {
            swaps: updatedSwaps,
            logs: [newLog, ...state.logs],
            dopaminePoints: state.dopaminePoints + dopamineAward + 10, // extra reward for successful self-control
            neurochemistry: {
              dopamine: Math.min(100, state.neurochemistry.dopamine + dopamineAward),
              gaba: Math.min(100, state.neurochemistry.gaba + gabaAward),
              epinephrine: Math.max(0, state.neurochemistry.epinephrine - 10),
              acetylcholine: Math.min(100, state.neurochemistry.acetylcholine + 10)
            }
          };
        });
      },

      logSlip: (id, reflection) => {
        const todayStr = getLocalDateString(new Date());
        // In neuroscience, a slip is a massive teaching signal for the brain.
        // It triggers high error-signaling (Epinephrine/Adrenaline), which
        // opens a window of heightened neuroplasticity. We use this productively!
        const epinephrineIncrease = 40; 
        const dopamineDrop = -15;

        set((state) => {
          const updatedSwaps = state.swaps.map((swap) => {
            if (swap.id !== id) return swap;

            const alreadySlippedToday = swap.slips.includes(todayStr);
            const slips = alreadySlippedToday
              ? swap.slips
              : [...swap.slips, todayStr];

            return {
              ...swap,
              slips
            };
          });

          const swapItem = state.swaps.find((s) => s.id === id);
          if (!swapItem) return {};

          const newLog: NeuroLog = {
            id: `log-${Date.now()}`,
            timestamp: new Date().toISOString(),
            type: 'slip',
            itemId: id,
            itemTitle: swapItem.title,
            notes: reflection || 'Logged a slip. Triggered neural correction alert.',
            dopamineChange: dopamineDrop,
            epinephrineChange: epinephrineIncrease,
            gabaChange: -10,
            acetylcholineChange: 15 // error reviews trigger acetylcholine focus
          };

          return {
            swaps: updatedSwaps,
            logs: [newLog, ...state.logs],
            neurochemistry: {
              dopamine: Math.max(0, state.neurochemistry.dopamine + dopamineDrop),
              epinephrine: Math.min(100, state.neurochemistry.epinephrine + epinephrineIncrease),
              gaba: Math.max(0, state.neurochemistry.gaba - 10),
              acetylcholine: Math.min(100, state.neurochemistry.acetylcholine + 15)
            }
          };
        });
      },

      // --- COMEBACK ACTIONS ---
      acknowledgeComeback: (stackId, stackTitle, microActionsCompleted) => {
        const today = getLocalDateString(new Date());
        const dopamineBoost = microActionsCompleted ? 20 : 10;

        const record: ComebackRecord = {
          id: `comeback-${Date.now()}`,
          stackId,
          date: today,
          microActionsCompleted,
          completedAt: new Date().toISOString(),
        };

        const newLog: NeuroLog = {
          id: `log-${Date.now()}`,
          timestamp: new Date().toISOString(),
          type: 'comeback',
          itemId: stackId,
          itemTitle: stackTitle,
          notes: microActionsCompleted
            ? 'Activated comeback protocol — micro-actions completed.'
            : 'Activated comeback protocol — acknowledged failure, ready to continue.',
          dopamineChange: dopamineBoost,
          epinephrineChange: -15, // reduces the stress/guilt response
          gabaChange: 15,         // calming — reduces avoidance activation
          acetylcholineChange: 10,
        };

        set((state) => ({
          comebacks: [record, ...state.comebacks],
          logs: [newLog, ...state.logs],
          dopaminePoints: state.dopaminePoints + dopamineBoost,
          neurochemistry: {
            dopamine: Math.min(100, state.neurochemistry.dopamine + dopamineBoost),
            epinephrine: Math.max(0, state.neurochemistry.epinephrine - 15),
            gaba: Math.min(100, state.neurochemistry.gaba + 15),
            acetylcholine: Math.min(100, state.neurochemistry.acetylcholine + 10),
          },
        }));
      },

      getTodayComebackIds: () => {
        const today = getLocalDateString(new Date());
        return get().comebacks
          .filter((c) => c.date === today)
          .map((c) => c.stackId);
      },

      // --- GLOBAL ACTIONS ---
      decayNeurochemistry: () => {
        set((state) => {
          const chem = state.neurochemistry;
          return {
            neurochemistry: {
              dopamine: decayNeurochemical(chem.dopamine, 50, 0.08),
              acetylcholine: decayNeurochemical(chem.acetylcholine, 50, 0.08),
              epinephrine: decayNeurochemical(chem.epinephrine, 50, 0.08),
              gaba: decayNeurochemical(chem.gaba, 50, 0.08)
            }
          };
        });
      },

      claimDopaminePoints: (amount) => {
        set((state) => ({
          dopaminePoints: Math.max(0, state.dopaminePoints - amount),
          neurochemistry: {
            ...state.neurochemistry,
            dopamine: Math.min(100, state.neurochemistry.dopamine + Math.round(amount * 0.15))
          }
        }));
      },

      resetAllData: () => {
        set({
          stacks: [],
          swaps: [],
          logs: [],
          comebacks: [],
          neurochemistry: { dopamine: 50, acetylcholine: 50, epinephrine: 50, gaba: 50 },
          dopaminePoints: 0,
        });
      }
    }),
    {
      name: 'neuroflow-state-storage', // key in LocalStorage
    }
  )
);
