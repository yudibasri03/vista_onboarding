import { useState } from 'react';
import { OnboardingStepper } from './OnboardingStepper';
import { AlertCircle, Upload, Check, Shield } from 'lucide-react';
import { supabase } from '../../lib/supabase';

const STEPS = [
  { number: 1, title: 'Data & KYC' },
  { number: 2, title: 'Pilih Produk' },
  { number: 3, title: 'Konfigurasi' },
  { number: 4, title: 'Konfirmasi' },
];

interface OnboardingData {
  fullName: string;
  email: string;
  whatsapp: string;
  occupation: string;
  position: string;
  address: string;
  ktpFile: File | null;
  productType: 'ea_trading' | 'bimbel_prop' | 'bimbel_only' | 'vip_membership' | 'vip_plus_membership' | '';
  eaType: string;
  riskProfile: 'aggressive' | 'moderate' | 'conservative' | '';
  maxDrawdown: string;
  programGoal: string;
  vipGoal: string;
  consentDataAccuracy: boolean;
  consentRiskUnderstanding: boolean;
  consentVerificationProcess: boolean;
  agreedToDisclaimer: boolean;
}

interface VistaOnboardingFormProps {
  onSuccess?: () => void;
}

export function VistaOnboardingForm({ onSuccess }: VistaOnboardingFormProps) {
  const [currentStep, setCurrentStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [data, setData] = useState<OnboardingData>({
    fullName: '',
    email: '',
    whatsapp: '',
    occupation: '',
    position: '',
    address: '',
    ktpFile: null,
    productType: '',
    eaType: '',
    riskProfile: '',
    maxDrawdown: '',
    programGoal: '',
    vipGoal: '',
    consentDataAccuracy: false,
    consentRiskUnderstanding: false,
    consentVerificationProcess: false,
    agreedToDisclaimer: false,
  });

  const handleInputChange = (field: keyof OnboardingData, value: any) => {
    setData((prev) => ({ ...prev, [field]: value }));
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (file.size > 5 * 1024 * 1024) {
        setError('Ukuran file maksimal 5 MB');
        return;
      }
      if (!['image/jpeg', 'image/png', 'application/pdf'].includes(file.type)) {
        setError('Format file harus JPG, PNG, atau PDF');
        return;
      }
      setError('');
      setData((prev) => ({ ...prev, ktpFile: file }));
    }
  };

  const validateStep = (step: number): boolean => {
    setError('');

    if (step === 1) {
      if (!data.agreedToDisclaimer) {
        setError('Harap centang persetujuan disclaimer');
        return false;
      }
      if (!data.fullName || !data.email || !data.whatsapp || !data.occupation || !data.position || !data.address) {
        setError('Semua field wajib diisi');
        return false;
      }
      if (!data.ktpFile) {
        setError('Upload KTP wajib dilakukan');
        return false;
      }
      return true;
    }

    if (step === 2) {
      if (!data.productType) {
        setError('Pilih salah satu produk');
        return false;
      }
      return true;
    }

    if (step === 3) {
      if (data.productType === 'ea_trading') {
        if (!data.eaType || !data.riskProfile || !data.maxDrawdown) {
          setError('Lengkapi semua konfigurasi Algo Signal Provider');
          return false;
        }
      } else if (data.productType === 'bimbel_prop' || data.productType === 'bimbel_only') {
        if (!data.programGoal) {
          setError('Pilih tujuan program');
          return false;
        }
      } else if (data.productType === 'vip_membership' || data.productType === 'vip_plus_membership') {
        if (!data.vipGoal) {
          setError('Pilih tujuan VIP Membership');
          return false;
        }
      }
      return true;
    }

    if (step === 4) {
      if (!data.consentDataAccuracy || !data.consentRiskUnderstanding || !data.consentVerificationProcess) {
        setError('Semua persetujuan wajib dicentang');
        return false;
      }
      return true;
    }

    return true;
  };

  const handleNext = () => {
    if (validateStep(currentStep)) {
      setCurrentStep((prev) => Math.min(prev + 1, 4));
    }
  };

  const handleBack = () => {
    setCurrentStep((prev) => Math.max(prev - 1, 1));
  };

  const handleSubmit = async () => {
    if (!validateStep(4)) return;

    setLoading(true);
    setError('');

    try {
      let ktpUrl = '';

      if (data.ktpFile) {
        const fileExt = data.ktpFile.name.split('.').pop();
        const fileName = `${Date.now()}-${Math.random().toString(36).substring(7)}.${fileExt}`;
        const filePath = `ktp/${fileName}`;

        const { error: uploadError } = await supabase.storage
          .from('documents')
          .upload(filePath, data.ktpFile);

        if (uploadError) {
          ktpUrl = `simulated_url/ktp/${fileName}`;
        } else {
          const { data: urlData } = supabase.storage
            .from('documents')
            .getPublicUrl(filePath);
          ktpUrl = urlData.publicUrl;
        }
      }

      const productConfig: any = {};
      if (data.productType === 'ea_trading') {
        productConfig.ea_type = data.eaType;
        productConfig.max_drawdown = data.maxDrawdown;
      } else if (data.productType === 'bimbel_prop' || data.productType === 'bimbel_only') {
        productConfig.program_goal = data.programGoal;
      } else if (data.productType === 'vip_membership' || data.productType === 'vip_plus_membership') {
        productConfig.vip_goal = data.vipGoal;
      }

      const { data: clientData, error: insertError } = await supabase
        .from('clients')
        .insert({
          user_id: null,
          full_name: data.fullName,
          email: data.email,
          whatsapp: data.whatsapp,
          occupation: data.occupation,
          position: data.position,
          address: data.address,
          ktp_url: ktpUrl,
          product_type: data.productType,
          product_config: productConfig,
          risk_profile: data.riskProfile || null,
          consent_data_accuracy: data.consentDataAccuracy,
          consent_risk_understanding: data.consentRiskUnderstanding,
          consent_verification_process: data.consentVerificationProcess,
          registration_completed_at: new Date().toISOString(),
          status: 'pending',
          company_name: data.fullName,
          pic_name: data.fullName,
          phone: data.whatsapp,
          business_type: data.occupation,
        })
        .select()
        .single();

      if (insertError) throw insertError;

      const { data: steps, error: stepsError } = await supabase
        .from('onboarding_steps')
        .select('id')
        .order('step_number');

      if (stepsError) throw stepsError;

      if (steps && steps.length > 0) {
        const progressRecords = steps.map((step) => ({
          client_id: clientData.id,
          step_id: step.id,
          status: 'not_started',
        }));

        await supabase.from('client_onboarding_progress').insert(progressRecords);
      }

      if (onSuccess) {
        onSuccess();
      }
    } catch (err: any) {
      console.error('Error submitting registration:', err);
      const errorMessage = err?.message || 'Terjadi kesalahan saat submit. Silakan coba lagi.';
      const errorDetails = err?.details || '';
      setError(`${errorMessage}${errorDetails ? ` (${errorDetails})` : ''}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-teal-900 py-12">
      <div className="max-w-5xl mx-auto px-4">
        <div className="text-center mb-10">
          <div className="inline-flex items-center justify-center mb-6 h-16">
            <img 
              src="/Vista-Logo_White.png" 
              alt="Vista Logo" 
              className="h-full w-auto object-contain"
              onError={(e) => {
                console.error('Logo failed to load from:', e.currentTarget.src);
                e.currentTarget.style.display = 'none';
                const logoContainer = e.currentTarget.parentElement;
                if (logoContainer) {
                  logoContainer.innerHTML = `
                    <div class="w-16 h-16 bg-gradient-to-br from-teal-600 to-emerald-600 rounded-xl flex items-center justify-center">
                      <span class="text-white font-bold text-2xl">V</span>
                    </div>
                  `;
                }
              }}
            />
          </div>
          <h1 className="text-4xl md:text-5xl font-bold text-white mb-3 bg-clip-text text-transparent bg-gradient-to-r from-white via-teal-100 to-emerald-100">
            Client Onboarding Portal
          </h1>
          <p className="text-lg text-slate-300 max-w-2xl mx-auto mb-2">
            Platform Registrasi Produk Investasi & Trading
          </p>
          <p className="text-sm text-slate-400 max-w-2xl mx-auto">
            Prosedur internal untuk onboarding klien dan verifikasi KYC sesuai standar compliance
          </p>
          <div className="mt-6">
            <a
              href="/admin"
              onClick={(e) => {
                e.preventDefault();
                window.history.pushState({}, '', '/admin');
                window.location.reload();
              }}
              className="inline-flex items-center gap-2 text-sm text-teal-400 hover:text-teal-300 transition-colors group"
            >
              <Shield className="h-4 w-4 group-hover:scale-110 transition-transform" />
              <span className="border-b border-teal-400/50 group-hover:border-teal-300">Admin Portal</span>
            </a>
          </div>
        </div>

        {currentStep === 1 && (
          <div className="bg-gradient-to-r from-amber-500/10 to-yellow-500/10 border border-amber-500/30 rounded-xl p-6 mb-8 backdrop-blur-sm">
            <div className="flex items-start gap-4">
              <div className="flex-shrink-0 w-10 h-10 bg-amber-500/20 rounded-lg flex items-center justify-center">
                <Shield className="h-5 w-5 text-amber-400" />
              </div>
              <div className="flex-1">
                <h3 className="font-semibold text-amber-100 mb-2 text-lg">Pemberitahuan Penting</h3>
                <p className="text-sm text-slate-300 mb-4 leading-relaxed">
                  Halaman ini ditujukan khusus bagi klien yang telah menyetujui penggunaan produk Vista.
                  Seluruh data yang diisi akan digunakan untuk keperluan verifikasi, kepatuhan, dan aktivasi produk
                  sesuai kebijakan perusahaan.
                </p>
                <label className="flex items-center gap-3 cursor-pointer group">
                  <input
                    type="checkbox"
                    checked={data.agreedToDisclaimer}
                    onChange={(e) => handleInputChange('agreedToDisclaimer', e.target.checked)}
                    className="w-5 h-5 text-teal-500 bg-slate-700 border-slate-600 rounded focus:ring-2 focus:ring-teal-500 cursor-pointer"
                  />
                  <span className="text-sm text-amber-100 font-medium group-hover:text-amber-50 transition-colors">
                    Saya memahami dan menyetujui tujuan halaman ini
                  </span>
                </label>
              </div>
            </div>
          </div>
        )}

        <OnboardingStepper currentStep={currentStep} steps={STEPS} />

        <div className="bg-white/95 backdrop-blur-sm rounded-2xl shadow-2xl border-2 border-teal-500/40 overflow-hidden">
          <div className="bg-gradient-to-r from-slate-800 via-slate-700 to-teal-800 px-8 py-6 border-b-4 border-teal-500/50">
            <h2 className="text-2xl font-bold text-white">
              {currentStep === 1 && 'Data Pribadi & KYC'}
              {currentStep === 2 && 'Pemilihan Produk'}
              {currentStep === 3 && 'Konfigurasi Produk'}
              {currentStep === 4 && 'Konfirmasi & Persetujuan'}
            </h2>
            <p className="text-sm text-slate-200 mt-1">
              {currentStep === 1 && 'Lengkapi informasi pribadi Anda untuk verifikasi identitas'}
              {currentStep === 2 && 'Pilih produk investasi yang sesuai dengan kebutuhan Anda'}
              {currentStep === 3 && 'Atur preferensi dan konfigurasi produk pilihan Anda'}
              {currentStep === 4 && 'Tinjau dan konfirmasi data registrasi Anda'}
            </p>
          </div>

          <div className="p-8 bg-slate-50">
            {error && (
              <div className="mb-6 bg-gradient-to-r from-red-900/40 to-rose-900/40 border border-red-500/50 rounded-xl px-5 py-4 flex items-start gap-3 shadow-sm">
                <div className="flex-shrink-0 w-8 h-8 bg-red-500/20 rounded-lg flex items-center justify-center">
                  <AlertCircle className="h-4 w-4 text-red-400" />
                </div>
                <p className="text-sm text-red-200 leading-relaxed flex-1">{error}</p>
              </div>
            )}

            {currentStep === 1 && (
              <div className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-sm font-semibold text-slate-800 mb-2">
                      Nama Lengkap <span className="text-sm font-normal text-slate-600">(sesuai KTP)</span> <span className="text-red-600">*</span>
                    </label>
                    <input
                      type="text"
                      value={data.fullName}
                      onChange={(e) => handleInputChange('fullName', e.target.value)}
                      className="w-full px-4 py-3 bg-white border-2 border-slate-300 text-slate-900 rounded-xl focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all placeholder:text-slate-400 shadow-sm"
                      placeholder="Nama lengkap sesuai KTP"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-semibold text-slate-800 mb-2">
                      Email Address <span className="text-red-600">*</span>
                    </label>
                    <input
                      type="email"
                      value={data.email}
                      onChange={(e) => handleInputChange('email', e.target.value)}
                      className="w-full px-4 py-3 bg-white border-2 border-slate-300 text-slate-900 rounded-xl focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all placeholder:text-slate-400 shadow-sm"
                      placeholder="email@example.com"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-semibold text-slate-800 mb-2">
                      WhatsApp Number <span className="text-red-600">*</span>
                    </label>
                    <input
                      type="tel"
                      value={data.whatsapp}
                      onChange={(e) => handleInputChange('whatsapp', e.target.value)}
                      className="w-full px-4 py-3 bg-white border-2 border-slate-300 text-slate-900 rounded-xl focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all placeholder:text-slate-400 shadow-sm"
                      placeholder="+62 812 3456 7890"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-semibold text-slate-800 mb-2">
                      Pekerjaan <span className="text-red-600">*</span>
                    </label>
                    <input
                      type="text"
                      value={data.occupation}
                      onChange={(e) => handleInputChange('occupation', e.target.value)}
                      className="w-full px-4 py-3 bg-white border-2 border-slate-300 text-slate-900 rounded-xl focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all placeholder:text-slate-400 shadow-sm"
                      placeholder="Pekerjaan Anda"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-semibold text-slate-800 mb-2">
                      Jabatan <span className="text-red-600">*</span>
                    </label>
                    <input
                      type="text"
                      value={data.position}
                      onChange={(e) => handleInputChange('position', e.target.value)}
                      className="w-full px-4 py-3 bg-white border-2 border-slate-300 text-slate-900 rounded-xl focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all placeholder:text-slate-400 shadow-sm"
                      placeholder="Jabatan Anda"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-semibold text-slate-800 mb-2">
                    Alamat Domisili <span className="text-red-600">*</span>
                  </label>
                  <textarea
                    value={data.address}
                    onChange={(e) => handleInputChange('address', e.target.value)}
                    rows={3}
                    className="w-full px-4 py-3 bg-white border-2 border-slate-300 text-slate-900 rounded-xl focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all placeholder:text-slate-400 shadow-sm"
                    placeholder="Alamat lengkap domisili Anda"
                  />
                </div>

                <div>
                  <label className="block text-sm font-semibold text-slate-800 mb-2">
                    Upload KTP (Depan) <span className="text-red-600">*</span>
                  </label>
                  <div className="border-2 border-dashed border-slate-300 rounded-xl p-8 text-center hover:border-teal-500 hover:bg-teal-50 transition-all group cursor-pointer bg-white shadow-sm">
                    <input
                      type="file"
                      accept="image/jpeg,image/png,application/pdf"
                      onChange={handleFileChange}
                      className="hidden"
                      id="ktp-upload"
                    />
                    <label htmlFor="ktp-upload" className="cursor-pointer">
                      {data.ktpFile ? (
                        <div className="flex flex-col items-center gap-3">
                          <div className="w-14 h-14 bg-emerald-100 rounded-full flex items-center justify-center">
                            <Check className="h-7 w-7 text-emerald-600" />
                          </div>
                          <div>
                            <p className="font-semibold text-emerald-600">{data.ktpFile.name}</p>
                            <p className="text-xs text-slate-600 mt-1">File berhasil diunggah</p>
                          </div>
                        </div>
                      ) : (
                        <div>
                          <div className="w-14 h-14 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-3 group-hover:bg-teal-100 transition-colors">
                            <Upload className="h-7 w-7 text-slate-500 group-hover:text-teal-600 transition-colors" />
                          </div>
                          <p className="text-base font-semibold text-slate-700 group-hover:text-teal-600 transition-colors">Klik untuk upload KTP</p>
                          <p className="text-sm text-slate-600 mt-1">Format: JPG, PNG, PDF (Max 5 MB)</p>
                        </div>
                      )}
                    </label>
                  </div>
                  <div className="flex items-center gap-2 mt-3 text-xs text-slate-600">
                    <Shield className="h-3.5 w-3.5" />
                    <p>Data disimpan secara aman dan hanya digunakan untuk keperluan verifikasi KYC</p>
                  </div>
                </div>
              </div>
            )}

            {currentStep === 2 && (
              <div className="space-y-5">
                <div className="space-y-4">
                  <label className={`group relative flex items-start gap-5 p-6 border-2 rounded-xl cursor-pointer transition-all ${
                    data.productType === 'ea_trading'
                      ? 'border-teal-500 bg-gradient-to-br from-teal-50 to-emerald-50 shadow-lg shadow-teal-500/20'
                      : 'border-slate-300 hover:border-teal-500 hover:shadow-md hover:bg-slate-50 bg-white'
                  }`}>
                    <input
                      type="radio"
                      name="product"
                      value="ea_trading"
                      checked={data.productType === 'ea_trading'}
                      onChange={(e) => handleInputChange('productType', e.target.value)}
                      className="mt-1.5 w-5 h-5 text-teal-600 border-slate-400 focus:ring-teal-500 cursor-pointer"
                    />
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                          data.productType === 'ea_trading' ? 'bg-teal-500' : 'bg-slate-200 group-hover:bg-teal-100'
                        } transition-colors`}>
                          <Shield className={`h-5 w-5 ${data.productType === 'ea_trading' ? 'text-white' : 'text-slate-600 group-hover:text-teal-600'}`} />
                        </div>
                        <p className="font-bold text-lg text-slate-900">Algo Signal Provider</p>
                      </div>
                      <p className="text-sm text-slate-700 leading-relaxed">Automated trading dengan signal provider untuk eksekusi strategi otomatis dan optimal</p>
                    </div>
                  </label>

                  <label className={`group relative flex items-start gap-5 p-6 border-2 rounded-xl cursor-pointer transition-all ${
                    data.productType === 'bimbel_prop'
                      ? 'border-teal-500 bg-gradient-to-br from-teal-50 to-emerald-50 shadow-lg shadow-teal-500/20'
                      : 'border-slate-300 hover:border-teal-500 hover:shadow-md hover:bg-slate-50 bg-white'
                  }`}>
                    <input
                      type="radio"
                      name="product"
                      value="bimbel_prop"
                      checked={data.productType === 'bimbel_prop'}
                      onChange={(e) => handleInputChange('productType', e.target.value)}
                      className="mt-1.5 w-5 h-5 text-teal-600 border-slate-400 focus:ring-teal-500 cursor-pointer"
                    />
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                          data.productType === 'bimbel_prop' ? 'bg-teal-500' : 'bg-slate-200 group-hover:bg-teal-100'
                        } transition-colors`}>
                          <Shield className={`h-5 w-5 ${data.productType === 'bimbel_prop' ? 'text-white' : 'text-slate-600 group-hover:text-teal-600'}`} />
                        </div>
                        <p className="font-bold text-lg text-slate-900">Kelas Bimbel + Propfunds</p>
                      </div>
                      <p className="text-sm text-slate-700 leading-relaxed">Program edukasi trading komprehensif dengan akses langsung ke proprietary trading funds</p>
                    </div>
                  </label>

                  <label className={`group relative flex items-start gap-5 p-6 border-2 rounded-xl cursor-pointer transition-all ${
                    data.productType === 'bimbel_only'
                      ? 'border-teal-500 bg-gradient-to-br from-teal-50 to-emerald-50 shadow-lg shadow-teal-500/20'
                      : 'border-slate-300 hover:border-teal-500 hover:shadow-md hover:bg-slate-50 bg-white'
                  }`}>
                    <input
                      type="radio"
                      name="product"
                      value="bimbel_only"
                      checked={data.productType === 'bimbel_only'}
                      onChange={(e) => handleInputChange('productType', e.target.value)}
                      className="mt-1.5 w-5 h-5 text-teal-600 border-slate-400 focus:ring-teal-500 cursor-pointer"
                    />
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                          data.productType === 'bimbel_only' ? 'bg-teal-500' : 'bg-slate-200 group-hover:bg-teal-100'
                        } transition-colors`}>
                          <Shield className={`h-5 w-5 ${data.productType === 'bimbel_only' ? 'text-white' : 'text-slate-600 group-hover:text-teal-600'}`} />
                        </div>
                        <p className="font-bold text-lg text-slate-900">Kelas Bimbel</p>
                      </div>
                      <p className="text-sm text-slate-700 leading-relaxed">Program edukasi trading komprehensif mulai dari basic hingga advance</p>
                    </div>
                  </label>

                  <label className={`group relative flex items-start gap-5 p-6 border-2 rounded-xl cursor-pointer transition-all ${
                    data.productType === 'vip_membership'
                      ? 'border-amber-500 bg-gradient-to-br from-amber-50 to-yellow-50 shadow-lg shadow-amber-500/20'
                      : 'border-slate-300 hover:border-amber-500 hover:shadow-md hover:bg-slate-50 bg-white'
                  }`}>
                    <input
                      type="radio"
                      name="product"
                      value="vip_membership"
                      checked={data.productType === 'vip_membership'}
                      onChange={(e) => handleInputChange('productType', e.target.value)}
                      className="mt-1.5 w-5 h-5 text-amber-600 border-slate-400 focus:ring-amber-500 cursor-pointer"
                    />
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                          data.productType === 'vip_membership' ? 'bg-gradient-to-br from-amber-500 to-yellow-500' : 'bg-slate-200 group-hover:bg-amber-100'
                        } transition-colors`}>
                          <Shield className={`h-5 w-5 ${data.productType === 'vip_membership' ? 'text-white' : 'text-slate-600 group-hover:text-amber-600'}`} />
                        </div>
                        <p className="font-bold text-lg text-slate-900">VIP Membership</p>
                      </div>
                      <p className="text-sm text-slate-700 leading-relaxed">Akses eksklusif ke seluruh layanan Vista dengan benefit dan privilege premium</p>
                    </div>
                  </label>

                  <label className={`group relative flex items-start gap-5 p-6 border-2 rounded-xl cursor-pointer transition-all ${
                    data.productType === 'vip_plus_membership'
                      ? 'border-purple-500 bg-gradient-to-br from-purple-50 to-pink-50 shadow-lg shadow-purple-500/20'
                      : 'border-slate-300 hover:border-purple-500 hover:shadow-md hover:bg-slate-50 bg-white'
                  }`}>
                    <input
                      type="radio"
                      name="product"
                      value="vip_plus_membership"
                      checked={data.productType === 'vip_plus_membership'}
                      onChange={(e) => handleInputChange('productType', e.target.value)}
                      className="mt-1.5 w-5 h-5 text-purple-600 border-slate-400 focus:ring-purple-500 cursor-pointer"
                    />
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-2">
                        <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                          data.productType === 'vip_plus_membership' ? 'bg-gradient-to-br from-purple-500 to-pink-500' : 'bg-slate-200 group-hover:bg-purple-100'
                        } transition-colors`}>
                          <Shield className={`h-5 w-5 ${data.productType === 'vip_plus_membership' ? 'text-white' : 'text-slate-600 group-hover:text-purple-600'}`} />
                        </div>
                        <p className="font-bold text-lg text-slate-900">VIP+ Membership</p>
                      </div>
                      <p className="text-sm text-slate-700 leading-relaxed">Akses signal trading dan live trade rutin</p>
                    </div>
                  </label>
                </div>
              </div>
            )}

            {currentStep === 3 && (
              <div className="space-y-6">
                {data.productType === 'ea_trading' && (
                  <div className="space-y-6">
                    <div>
                      <label className="block text-sm font-semibold text-slate-800 mb-2">
                        Jenis Signal Provider <span className="text-red-600">*</span>
                      </label>
                      <select
                        value={data.eaType}
                        onChange={(e) => handleInputChange('eaType', e.target.value)}
                        className="w-full px-4 py-3 bg-white border-2 border-slate-300 text-slate-900 rounded-xl focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all shadow-sm"
                      >
                        <option value="">Pilih Signal Provider</option>
                        <option value="gold_rh">Gold RH+</option>
                        <option value="gold_breakout">Gold Breakout System</option>
                        <option value="forex">Forex</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-semibold text-slate-800 mb-2">
                        Risk Profile <span className="text-red-600">*</span>
                      </label>
                      <select
                        value={data.riskProfile}
                        onChange={(e) => handleInputChange('riskProfile', e.target.value)}
                        className="w-full px-4 py-3 bg-white border-2 border-slate-300 text-slate-900 rounded-xl focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all shadow-sm"
                      >
                        <option value="">Pilih Risk Profile</option>
                        <option value="aggressive">Aggressive (Resiko Sangat Tinggi)</option>
                        <option value="moderate">Moderate (Resiko Tinggi)</option>
                        <option value="conservative">Conservative (Resiko Sedang)</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-semibold text-slate-800 mb-2">
                        Maximum Drawdown <span className="text-red-600">*</span>
                      </label>
                      <select
                        value={data.maxDrawdown}
                        onChange={(e) => handleInputChange('maxDrawdown', e.target.value)}
                        className="w-full px-4 py-3 bg-white border-2 border-slate-300 text-slate-900 rounded-xl focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all shadow-sm"
                      >
                        <option value="">Pilih Max Drawdown</option>
                        <option value="35">35%</option>
                        <option value="50">50%</option>
                        <option value="65">65%</option>
                      </select>
                    </div>

                    <div className="flex items-center gap-2 p-4 bg-teal-50 border border-teal-200 rounded-xl">
                      <Shield className="h-4 w-4 text-teal-600 flex-shrink-0" />
                      <p className="text-xs text-slate-700">
                        Semua konfigurasi dicatat sebagai keputusan dan preferensi klien
                      </p>
                    </div>
                  </div>
                )}

                {data.productType === 'bimbel_prop' && (
                  <div className="space-y-6">
                    <div>
                      <label className="block text-sm font-semibold text-slate-800 mb-2">
                        Tujuan Mengikuti Program <span className="text-red-600">*</span>
                      </label>
                      <select
                        value={data.programGoal}
                        onChange={(e) => handleInputChange('programGoal', e.target.value)}
                        className="w-full px-4 py-3 bg-white border-2 border-slate-300 text-slate-900 rounded-xl focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all shadow-sm"
                      >
                        <option value="">Pilih Tujuan Program</option>
                        <option value="basic">Kelas Basic</option>
                        <option value="intermediate">Kelas Intermediate</option>
                        <option value="advance">Kelas Advance</option>
                        <option value="private_elite">Kelas Private Elite (Program Sertifikasi Profesi)</option>
                      </select>
                    </div>
                  </div>
                )}

                {data.productType === 'bimbel_only' && (
                  <div className="space-y-6">
                    <div>
                      <label className="block text-sm font-semibold text-slate-800 mb-2">
                        Tujuan Mengikuti Program <span className="text-red-600">*</span>
                      </label>
                      <select
                        value={data.programGoal}
                        onChange={(e) => handleInputChange('programGoal', e.target.value)}
                        className="w-full px-4 py-3 bg-white border-2 border-slate-300 text-slate-900 rounded-xl focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all shadow-sm"
                      >
                        <option value="">Pilih Tujuan Program</option>
                        <option value="basic">Kelas Basic</option>
                        <option value="intermediate">Kelas Intermediate</option>
                        <option value="advance">Kelas Advance</option>
                        <option value="private_elite">Kelas Private Elite (Program Sertifikasi Profesi)</option>
                      </select>
                    </div>
                  </div>
                )}

                {(data.productType === 'vip_membership' || data.productType === 'vip_plus_membership') && (
                  <div className="space-y-6">
                    <div>
                      <label className="block text-sm font-semibold text-slate-800 mb-2">
                        Tujuan Mengikuti VIP Membership <span className="text-red-600">*</span>
                      </label>
                      <textarea
                        value={data.vipGoal}
                        onChange={(e) => handleInputChange('vipGoal', e.target.value)}
                        rows={5}
                        className="w-full px-4 py-3 bg-white border-2 border-slate-300 text-slate-900 rounded-xl focus:ring-2 focus:ring-teal-500 focus:border-teal-500 transition-all placeholder:text-slate-400 shadow-sm"
                        placeholder="Jelaskan tujuan dan harapan Anda mengikuti VIP Membership..."
                      />
                    </div>
                  </div>
                )}
              </div>
            )}

            {currentStep === 4 && (
              <div className="space-y-6">
                <div className="bg-gradient-to-br from-slate-100 to-teal-50 rounded-2xl p-6 border-2 border-slate-200 space-y-4 shadow-sm">
                  <h4 className="font-bold text-slate-900 text-lg">Ringkasan Registrasi</h4>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                    <div className="bg-white rounded-lg p-3 shadow-sm border border-slate-200">
                      <p className="text-slate-600 text-xs mb-1">Nama Lengkap</p>
                      <p className="font-semibold text-slate-900">{data.fullName}</p>
                    </div>
                    <div className="bg-white rounded-lg p-3 shadow-sm border border-slate-200">
                      <p className="text-slate-600 text-xs mb-1">Email</p>
                      <p className="font-semibold text-slate-900">{data.email}</p>
                    </div>
                    <div className="bg-white rounded-lg p-3 shadow-sm border border-slate-200">
                      <p className="text-slate-600 text-xs mb-1">WhatsApp</p>
                      <p className="font-semibold text-slate-900">{data.whatsapp}</p>
                    </div>
                    <div className="bg-white rounded-lg p-3 shadow-sm border border-slate-200">
                      <p className="text-slate-600 text-xs mb-1">Pekerjaan</p>
                      <p className="font-semibold text-slate-900">{data.occupation} - {data.position}</p>
                    </div>
                    <div className="md:col-span-2 bg-white rounded-lg p-3 shadow-sm border border-slate-200">
                      <p className="text-slate-600 text-xs mb-1">Produk Terpilih</p>
                      <p className="font-bold text-teal-600">
                        {data.productType === 'ea_trading' && 'Algo Signal Provider'}
                        {data.productType === 'bimbel_prop' && 'Kelas Bimbel + Propfunds'}
                        {data.productType === 'bimbel_only' && 'Kelas Bimbel'}
                        {data.productType === 'vip_membership' && 'VIP Membership'}
                        {data.productType === 'vip_plus_membership' && 'VIP+ Membership'}
                      </p>
                    </div>
                    {data.productType === 'ea_trading' && (
                      <>
                        <div className="bg-white rounded-lg p-3 shadow-sm border border-slate-200">
                          <p className="text-slate-600 text-xs mb-1">Jenis Signal Provider</p>
                          <p className="font-semibold text-slate-900">
                            {data.eaType === 'gold_rh' && 'Gold RH+'}
                            {data.eaType === 'gold_breakout' && 'Gold Breakout System'}
                            {data.eaType === 'forex' && 'Forex'}
                          </p>
                        </div>
                        <div className="bg-white rounded-lg p-3 shadow-sm border border-slate-200">
                          <p className="text-slate-600 text-xs mb-1">Risk Profile</p>
                          <p className="font-semibold text-slate-900">
                            {data.riskProfile === 'aggressive' && 'Aggressive (Resiko Sangat Tinggi)'}
                            {data.riskProfile === 'moderate' && 'Moderate (Resiko Tinggi)'}
                            {data.riskProfile === 'conservative' && 'Conservative (Resiko Sedang)'}
                          </p>
                        </div>
                        <div className="bg-white rounded-lg p-3 shadow-sm border border-slate-200">
                          <p className="text-slate-600 text-xs mb-1">Max Drawdown</p>
                          <p className="font-semibold text-slate-900">{data.maxDrawdown}%</p>
                        </div>
                      </>
                    )}
                    {(data.productType === 'bimbel_prop' || data.productType === 'bimbel_only') && data.programGoal && (
                      <div className="bg-white rounded-lg p-3 shadow-sm border border-slate-200">
                        <p className="text-slate-600 text-xs mb-1">Tujuan Program</p>
                        <p className="font-semibold text-slate-900">
                          {data.programGoal === 'basic' && 'Kelas Basic'}
                          {data.programGoal === 'intermediate' && 'Kelas Intermediate'}
                          {data.programGoal === 'advance' && 'Kelas Advance'}
                          {data.programGoal === 'private_elite' && 'Kelas Private Elite (Program Sertifikasi Profesi)'}
                        </p>
                      </div>
                    )}
                    <div className="bg-white rounded-lg p-3 shadow-sm border border-slate-200">
                      <p className="text-slate-600 text-xs mb-1">Status KYC</p>
                      <div className="flex items-center gap-2">
                        <Check className="h-4 w-4 text-emerald-600" />
                        <p className="font-semibold text-emerald-600">KTP Uploaded</p>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="bg-gradient-to-br from-teal-50 to-emerald-50 border-2 border-teal-300 rounded-2xl p-6 space-y-5 shadow-sm">
                  <div className="flex items-center gap-3 mb-2">
                    <div className="w-10 h-10 bg-teal-200 rounded-lg flex items-center justify-center">
                      <Shield className="h-5 w-5 text-teal-700" />
                    </div>
                    <h4 className="font-bold text-slate-900 text-lg">Persetujuan Wajib</h4>
                  </div>

                  <label className="flex items-start gap-4 cursor-pointer group hover:bg-teal-100 p-3 rounded-lg transition-all">
                    <input
                      type="checkbox"
                      checked={data.consentDataAccuracy}
                      onChange={(e) => handleInputChange('consentDataAccuracy', e.target.checked)}
                      className="mt-0.5 w-5 h-5 text-teal-600 bg-white border-2 border-slate-400 rounded focus:ring-2 focus:ring-teal-500 cursor-pointer"
                    />
                    <span className="text-sm text-slate-800 leading-relaxed">
                      Saya menyatakan bahwa seluruh data yang diisi adalah benar dan dapat dipertanggungjawabkan
                    </span>
                  </label>

                  <label className="flex items-start gap-4 cursor-pointer group hover:bg-teal-100 p-3 rounded-lg transition-all">
                    <input
                      type="checkbox"
                      checked={data.consentRiskUnderstanding}
                      onChange={(e) => handleInputChange('consentRiskUnderstanding', e.target.checked)}
                      className="mt-0.5 w-5 h-5 text-teal-600 bg-white border-2 border-slate-400 rounded focus:ring-2 focus:ring-teal-500 cursor-pointer"
                    />
                    <span className="text-sm text-slate-800 leading-relaxed">
                      Saya memahami risiko terkait produk trading dan investasi yang saya pilih
                    </span>
                  </label>

                  <label className="flex items-start gap-4 cursor-pointer group hover:bg-teal-100 p-3 rounded-lg transition-all">
                    <input
                      type="checkbox"
                      checked={data.consentVerificationProcess}
                      onChange={(e) => handleInputChange('consentVerificationProcess', e.target.checked)}
                      className="mt-0.5 w-5 h-5 text-teal-600 bg-white border-2 border-slate-400 rounded focus:ring-2 focus:ring-teal-500 cursor-pointer"
                    />
                    <span className="text-sm text-slate-800 leading-relaxed">
                      Saya bersedia mengikuti proses verifikasi lanjutan dari tim Vista
                    </span>
                  </label>
                </div>
              </div>
            )}

            <div className="flex justify-between items-center mt-8 pt-8 border-t-2 border-slate-300">
              <button
                onClick={handleBack}
                disabled={currentStep === 1 || loading}
                className="px-6 py-3 border-2 border-slate-300 rounded-xl text-slate-700 font-semibold hover:bg-slate-100 hover:border-slate-400 disabled:opacity-40 disabled:cursor-not-allowed transition-all shadow-sm"
              >
                Kembali
              </button>

              {currentStep < 4 ? (
                <button
                  onClick={handleNext}
                  disabled={loading}
                  className="px-8 py-3 bg-gradient-to-r from-teal-600 to-emerald-600 text-white rounded-xl font-semibold hover:from-teal-700 hover:to-emerald-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-lg shadow-teal-500/30 hover:shadow-xl hover:shadow-teal-500/40"
                >
                  Lanjutkan
                </button>
              ) : (
                <button
                  onClick={handleSubmit}
                  disabled={loading}
                  className="px-10 py-3 bg-gradient-to-r from-emerald-600 to-teal-600 text-white rounded-xl font-bold hover:from-emerald-700 hover:to-teal-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-xl shadow-emerald-500/40 hover:shadow-2xl hover:shadow-emerald-500/50 text-lg"
                >
                  {loading ? 'Memproses...' : 'Submit Registration'}
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
