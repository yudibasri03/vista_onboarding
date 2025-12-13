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
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-blue-100 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading...</p>
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
      <div className="min-h-screen bg-gradient-to-br from-green-50 to-blue-50 flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl shadow-2xl p-8 max-w-md w-full text-center">
          <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Registrasi Berhasil!</h2>
          <p className="text-gray-600 mb-6">
            Terima kasih telah melengkapi formulir registrasi. Tim kami akan segera menghubungi Anda untuk proses selanjutnya.
          </p>
          <button
            onClick={() => {
              setShowSuccess(false);
              window.location.reload();
            }}
            className="w-full px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium"
          >
            Registrasi Lagi
          </button>
        </div>
      </div>
    );
  }

  return <VistaOnboardingForm onSuccess={() => setShowSuccess(true)} />;
}

export default App;
