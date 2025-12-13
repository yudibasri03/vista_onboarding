import { useState, useEffect } from 'react';
import { useAuth } from './hooks/useAuth';
import { supabase } from './lib/supabase';
import { LoginForm } from './components/auth/LoginForm';
import { RegisterForm } from './components/auth/RegisterForm';
import { ProfileCompletionForm } from './components/auth/ProfileCompletionForm';
import { ClientDashboard } from './components/dashboard/ClientDashboard';
import { LogOut } from 'lucide-react';

function App() {
  const { user, loading, signOut } = useAuth();
  const [authMode, setAuthMode] = useState<'login' | 'register'>('login');
  const [hasClientProfile, setHasClientProfile] = useState(false);
  const [checkingProfile, setCheckingProfile] = useState(true);

  useEffect(() => {
    if (user) {
      checkClientProfile();
    } else {
      setCheckingProfile(false);
    }
  }, [user]);

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

  const handleRegistrationComplete = async (data: {
    email: string;
    company_name: string;
    pic_name: string;
    phone: string;
    address: string;
    business_type: string;
  }) => {
    await createClientProfile({
      email: data.email,
      company_name: data.company_name,
      pic_name: data.pic_name,
      phone: data.phone,
      address: data.address,
      business_type: data.business_type,
    });
  };

  const handleProfileCompletion = async (data: {
    company_name: string;
    pic_name: string;
    phone: string;
    address: string;
    business_type: string;
  }) => {
    await createClientProfile({
      email: user?.email || '',
      company_name: data.company_name,
      pic_name: data.pic_name,
      phone: data.phone,
      address: data.address,
      business_type: data.business_type,
    });
  };

  const createClientProfile = async (data: {
    email: string;
    company_name: string;
    pic_name: string;
    phone: string;
    address: string;
    business_type: string;
  }) => {
    try {
      const { data: clientData, error: clientError } = await supabase
        .from('clients')
        .insert({
          user_id: user?.id,
          company_name: data.company_name,
          pic_name: data.pic_name,
          email: data.email,
          phone: data.phone,
          address: data.address,
          business_type: data.business_type,
          status: 'pending',
        })
        .select()
        .single();

      if (clientError) throw clientError;

      const { data: steps, error: stepsError } = await supabase
        .from('onboarding_steps')
        .select('id')
        .order('step_number');

      if (stepsError) throw stepsError;

      const progressRecords = steps.map(step => ({
        client_id: clientData.id,
        step_id: step.id,
        status: 'not_started',
      }));

      const { error: progressError } = await supabase
        .from('client_onboarding_progress')
        .insert(progressRecords);

      if (progressError) throw progressError;

      const { error: notifError } = await supabase
        .from('notifications')
        .insert({
          user_id: user?.id,
          title: 'Selamat Datang!',
          message: 'Registrasi Anda berhasil. Silakan lengkapi tahapan onboarding untuk mengaktifkan akun Anda.',
          type: 'success',
        });

      if (notifError) throw notifError;

      setHasClientProfile(true);
    } catch (error) {
      console.error('Error creating client profile:', error);
      alert('Terjadi kesalahan saat membuat profil. Silakan hubungi administrator.');
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
                onRegistrationComplete={handleRegistrationComplete}
              />
            </div>
          )}
        </div>
      </div>
    );
  }

  if (!hasClientProfile) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 to-blue-100 flex items-center justify-center p-4">
        <div className="w-full max-w-6xl">
          <div className="flex justify-end mb-4">
            <button
              onClick={signOut}
              className="flex items-center gap-2 px-4 py-2 text-gray-700 bg-white rounded-lg hover:bg-gray-50 transition-colors shadow-sm"
            >
              <LogOut className="w-4 h-4" />
              <span>Logout</span>
            </button>
          </div>

          <div className="text-center mb-8">
            <h1 className="text-4xl font-bold text-gray-900 mb-2">Lengkapi Profil Anda</h1>
            <p className="text-gray-600">Silakan lengkapi data perusahaan untuk melanjutkan</p>
          </div>

          <div className="flex justify-center">
            <ProfileCompletionForm
              userEmail={user?.email || ''}
              onComplete={handleProfileCompletion}
            />
          </div>
        </div>
      </div>
    );
  }

  return <ClientDashboard />;
}

export default App;
