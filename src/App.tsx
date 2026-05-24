import React from 'react';
import { ThemeProvider } from './contexts/ThemeContext';
import { useNeuroStore } from './store/useNeuroStore';
import Dashboard from './pages/Dashboard';
import Onboarding from './pages/Onboarding';
import BrainAssessment from './pages/BrainAssessment';

function AppRoutes() {
  const onboardingComplete = useNeuroStore(s => s.onboardingComplete);
  const brainProfile = useNeuroStore(s => s.brainProfile);

  if (!onboardingComplete) return <Onboarding />;
  if (!brainProfile) return <BrainAssessment />;
  return <Dashboard />;
}

export default function App() {
  return (
    <ThemeProvider>
      <AppRoutes />
    </ThemeProvider>
  );
}
