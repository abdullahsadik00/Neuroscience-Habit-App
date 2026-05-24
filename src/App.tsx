import React from 'react';
import { ThemeProvider } from './contexts/ThemeContext';
import { useNeuroStore } from './store/useNeuroStore';
import Dashboard from './pages/Dashboard';
import Onboarding from './pages/Onboarding';
import BrainAssessment from './pages/BrainAssessment';
import RoutineBlueprint from './pages/RoutineBlueprint';

function AppRoutes() {
  const onboardingComplete = useNeuroStore(s => s.onboardingComplete);
  const brainProfile = useNeuroStore(s => s.brainProfile);
  const blueprintAccepted = useNeuroStore(s => s.blueprintAccepted);

  if (!onboardingComplete) return <Onboarding />;
  if (!brainProfile) return <BrainAssessment />;
  if (!blueprintAccepted) return <RoutineBlueprint />;
  return <Dashboard />;
}

export default function App() {
  return (
    <ThemeProvider>
      <AppRoutes />
    </ThemeProvider>
  );
}
