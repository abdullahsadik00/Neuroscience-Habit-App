import React from 'react';
import { useNeuroStore } from './store/useNeuroStore';
import Dashboard from './pages/Dashboard';
import Onboarding from './pages/Onboarding';

export default function App() {
  const onboardingComplete = useNeuroStore(s => s.onboardingComplete);
  return onboardingComplete ? <Dashboard /> : <Onboarding />;
}
