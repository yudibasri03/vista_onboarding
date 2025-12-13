import { useState, useEffect } from 'react';
import { useAuth } from './hooks/useAuth';
import { AdminLoginForm } from './components/auth/AdminLoginForm';
import { AdminDashboard } from './components/dashboard/AdminDashboard';
import { VistaOnboardingForm } from './components/onboarding/VistaOnboardingForm';

function App() {
  const { user, loading, isAdmin } = useAuth();
  const [currentPath, setCurrentPath] = useState(window.location.pathname);
  const [showSuccess, setShowSuccess] = useState(false);

  useEffect(() => {
    const handlePopState = () => {
      setCurrentPath(window.location.pathname);
    };

    window.addEventListener('popstate', handlePopState);
    return () => window.removeEventListener('popstate', handlePopState);
  }, []);

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-teal-900 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-4 border-slate-600 border-t-teal-500 mx-auto mb-4 shadow-xl"></div>
          <p className="text-slate-300 text-lg font-semibold">Loading Vista Portal...</p>
        </div>
      </div>
    );
  }

  if (currentPath === '/admin') {
    if (!user || !isAdmin) {
      return <AdminLoginForm />;
    }
    return <AdminDashboard />;
  }

  if (showSuccess) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-teal-900 flex items-center justify-center p-4">
        <div className="bg-white/95 backdrop-blur-sm rounded-3xl shadow-2xl p-10 max-w-lg w-full text-center border border-slate-200/50">
          <div className="w-20 h-20 bg-gradient-to-br from-emerald-500 to-teal-500 rounded-2xl flex items-center justify-center mx-auto mb-6 shadow-xl shadow-emerald-500/50">
            <svg className="w-10 h-10 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h2 className="text-3xl font-bold text-slate-800 mb-3">Thank You!</h2>
          <p className="text-slate-600 mb-8 leading-relaxed">
            Terima kasih telah melengkapi formulir registrasi. Tim kami akan segera menghubungi Anda untuk proses verifikasi dan aktivasi produk.
          </p>
          <button
            onClick={() => {
              window.location.href = 'https://produk.govista.co.id';
            }}
            className="w-full px-6 py-4 bg-gradient-to-r from-teal-600 to-emerald-600 text-white rounded-xl hover:from-teal-700 hover:to-emerald-700 transition-all font-semibold text-lg shadow-lg shadow-teal-500/30 hover:shadow-xl hover:shadow-teal-500/40"
          >
            Thank You
          </button>
        </div>
      </div>
    );
  }

  return <VistaOnboardingForm onSuccess={() => setShowSuccess(true)} />;
}

export default App;
