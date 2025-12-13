import { useState, useEffect } from 'react';
import { useAuth } from './hooks/useAuth';
import { supabase } from './lib/supabase';
import { LoginForm } from './components/auth/LoginForm';
import { RegisterForm } from './components/auth/RegisterForm';
import { ClientDashboard } from './components/dashboard/ClientDashboard';
import { AdminLoginForm } from './components/auth/AdminLoginForm';
import { AdminDashboard } from './components/dashboard/AdminDashboard';
import { VistaOnboardingForm } from './components/onboarding/VistaOnboardingForm';

function App() {
  const { user, loading, signOut, isAdmin, userRole } = useAuth();
  const [authMode, setAuthMode] = useState<'login' | 'register'>('login');
  const [hasClientProfile, setHasClientProfile] = useState(false);
  const [checkingProfile, setCheckingProfile] = useState(true);
  const [currentPath, setCurrentPath] = useState(window.location.pathname);

  useEffect(() => {
    const handlePopState = () => {
      setCurrentPath(window.location.pathname);
    };

    window.addEventListener('popstate', handlePopState);
    return () => window.removeEventListener('popstate', handlePopState);
  }, []);

  useEffect(() => {
    if (user) {
      if (!isAdmin) {
        checkClientProfile();
      } else {
        setCheckingProfile(false);
      }
    } else {
      setCheckingProfile(false);
    }
  }, [user, isAdmin]);

  const checkClientProfile = async () => {
    try {
      const { data, error } = await supabase
        .from('clients')
        .select('id')
        .eq('user_id', user?.id)
        .maybeSingle();

      if (error) throw error;

      setHasClientProfile(!!data);
    } catch (error) {
      console.error('Error checking client profile:', error);
      setHasClientProfile(false);
    } finally {
      setCheckingProfile(false);
    }
  };


  if (loading || checkingProfile) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-blue-100 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    if (currentPath === '/admin') {
      return <AdminLoginForm />;
    }

    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-blue-100 flex items-center justify-center p-4">
        <div className="w-full max-w-6xl">
          <div className="text-center mb-8">
            <h1 className="text-4xl font-bold text-gray-900 mb-2">Vista Produk</h1>
            <p className="text-gray-600">Sistem Onboarding Client</p>
          </div>

          {authMode === 'login' ? (
            <div className="flex justify-center">
              <LoginForm onToggleMode={() => setAuthMode('register')} />
            </div>
          ) : (
            <div className="flex justify-center">
              <RegisterForm
                onToggleMode={() => setAuthMode('login')}
                onRegistrationComplete={() => {}}
              />
            </div>
          )}

          <div className="text-center mt-6">
            <a
              href="/admin"
              onClick={(e) => {
                e.preventDefault();
                window.history.pushState({}, '', '/admin');
                setCurrentPath('/admin');
              }}
              className="text-sm text-gray-500 hover:text-gray-700 transition-colors"
            >
              Login sebagai Admin
            </a>
          </div>
        </div>
      </div>
    );
  }

  if (!hasClientProfile) {
    return <VistaOnboardingForm />;
  }

  if (isAdmin) {
    return <AdminDashboard />;
  }

  return <ClientDashboard />;
}

export default App;
