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
  productType: 'ea_trading' | 'bimbel_prop' | 'vip_membership' | '';
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
          setError('Lengkapi semua konfigurasi EA Trading');
          return false;
        }
      } else if (data.productType === 'bimbel_prop') {
        if (!data.programGoal) {
          setError('Pilih tujuan program');
          return false;
        }
      } else if (data.productType === 'vip_membership') {
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
      } else if (data.productType === 'bimbel_prop') {
        productConfig.program_goal = data.programGoal;
      } else if (data.productType === 'vip_membership') {
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
      setError('Terjadi kesalahan saat submit. Silakan coba lagi.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-blue-50 py-8">
      <div className="max-w-5xl mx-auto px-4">
        <div className="text-center mb-6">
          <h1 className="text-3xl font-bold text-gray-900">Vista Penasihat Berjangka</h1>
          <h2 className="text-xl text-gray-700 mt-2">Client Onboarding & Product Registration</h2>
          <p className="text-sm text-gray-600 mt-1">
            Halaman ini merupakan bagian dari prosedur internal perusahaan untuk proses onboarding klien.
          </p>
          <div className="mt-4">
            <a
              href="/admin"
              onClick={(e) => {
                e.preventDefault();
                window.history.pushState({}, '', '/admin');
                window.location.reload();
              }}
              className="text-sm text-blue-600 hover:text-blue-700 underline"
            >
              Login sebagai Admin
            </a>
          </div>
        </div>

        {currentStep === 1 && (
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
            <div className="flex items-start gap-3">
              <Shield className="h-5 w-5 text-blue-600 flex-shrink-0 mt-0.5" />
              <div>
                <h3 className="font-semibold text-blue-900 mb-2">Pemberitahuan Penting</h3>
                <p className="text-sm text-blue-800 mb-3">
                  Halaman ini ditujukan khusus bagi klien yang telah menyetujui penggunaan produk Vista.
                  Seluruh data yang diisi akan digunakan untuk keperluan verifikasi, kepatuhan, dan aktivasi produk
                  sesuai kebijakan perusahaan.
                </p>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={data.agreedToDisclaimer}
                    onChange={(e) => handleInputChange('agreedToDisclaimer', e.target.checked)}
                    className="w-4 h-4 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
                  />
                  <span className="text-sm text-blue-900 font-medium">Saya memahami tujuan halaman ini</span>
                </label>
              </div>
            </div>
          </div>
        )}

        <OnboardingStepper currentStep={currentStep} steps={STEPS} />

        <div className="bg-white rounded-xl shadow-lg p-8">
          {error && (
            <div className="mb-6 bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg flex items-start gap-3">
              <AlertCircle className="h-5 w-5 flex-shrink-0 mt-0.5" />
              <p className="text-sm">{error}</p>
            </div>
          )}

          {currentStep === 1 && (
            <div className="space-y-6">
              <h3 className="text-xl font-bold text-gray-900 mb-4">Data Pribadi & KYC Awal</h3>
              <p className="text-sm text-gray-600 mb-6">
                Data ini digunakan untuk identifikasi klien, pencegahan fraud, dan compliance awal.
              </p>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Nama Lengkap (sesuai KTP) <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    value={data.fullName}
                    onChange={(e) => handleInputChange('fullName', e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    placeholder="Nama lengkap Anda"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Email <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="email"
                    value={data.email}
                    onChange={(e) => handleInputChange('email', e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    placeholder="email@example.com"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    No. WhatsApp <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="tel"
                    value={data.whatsapp}
                    onChange={(e) => handleInputChange('whatsapp', e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    placeholder="08123456789"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Pekerjaan <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    value={data.occupation}
                    onChange={(e) => handleInputChange('occupation', e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    placeholder="Pekerjaan Anda"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Jabatan <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    value={data.position}
                    onChange={(e) => handleInputChange('position', e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    placeholder="Jabatan Anda"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Alamat Domisili <span className="text-red-500">*</span>
                </label>
                <textarea
                  value={data.address}
                  onChange={(e) => handleInputChange('address', e.target.value)}
                  rows={3}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Alamat lengkap domisili Anda"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Upload KTP (Depan) <span className="text-red-500">*</span>
                </label>
                <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-blue-500 transition-colors">
                  <input
                    type="file"
                    accept="image/jpeg,image/png,application/pdf"
                    onChange={handleFileChange}
                    className="hidden"
                    id="ktp-upload"
                  />
                  <label htmlFor="ktp-upload" className="cursor-pointer">
                    {data.ktpFile ? (
                      <div className="flex items-center justify-center gap-2 text-green-600">
                        <Check className="h-5 w-5" />
                        <span className="font-medium">{data.ktpFile.name}</span>
                      </div>
                    ) : (
                      <div>
                        <Upload className="h-12 w-12 text-gray-400 mx-auto mb-2" />
                        <p className="text-sm text-gray-600">Klik untuk upload KTP</p>
                        <p className="text-xs text-gray-500 mt-1">Format: JPG, PNG, PDF (Max 5 MB)</p>
                      </div>
                    )}
                  </label>
                </div>
                <p className="text-xs text-gray-500 mt-2">
                  Data disimpan secara aman dan hanya digunakan untuk keperluan verifikasi.
                </p>
              </div>
            </div>
          )}

          {currentStep === 2 && (
            <div className="space-y-6">
              <h3 className="text-xl font-bold text-gray-900 mb-4">Pemilihan Produk</h3>
              <p className="text-sm text-gray-600 mb-6">
                Pilihan produk akan menentukan konfigurasi dan proses berikutnya.
              </p>

              <div className="space-y-4">
                <label className="flex items-start gap-4 p-4 border-2 border-gray-300 rounded-lg cursor-pointer hover:border-blue-500 transition-colors">
                  <input
                    type="radio"
                    name="product"
                    value="ea_trading"
                    checked={data.productType === 'ea_trading'}
                    onChange={(e) => handleInputChange('productType', e.target.value)}
                    className="mt-1"
                  />
                  <div>
                    <p className="font-semibold text-gray-900">EA Trading</p>
                    <p className="text-sm text-gray-600">Automated trading dengan Expert Advisor</p>
                  </div>
                </label>

                <label className="flex items-start gap-4 p-4 border-2 border-gray-300 rounded-lg cursor-pointer hover:border-blue-500 transition-colors">
                  <input
                    type="radio"
                    name="product"
                    value="bimbel_prop"
                    checked={data.productType === 'bimbel_prop'}
                    onChange={(e) => handleInputChange('productType', e.target.value)}
                    className="mt-1"
                  />
                  <div>
                    <p className="font-semibold text-gray-900">Kelas Bimbel + Prop Funds</p>
                    <p className="text-sm text-gray-600">Program edukasi trading dengan akses prop funds</p>
                  </div>
                </label>

                <label className="flex items-start gap-4 p-4 border-2 border-gray-300 rounded-lg cursor-pointer hover:border-blue-500 transition-colors">
                  <input
                    type="radio"
                    name="product"
                    value="vip_membership"
                    checked={data.productType === 'vip_membership'}
                    onChange={(e) => handleInputChange('productType', e.target.value)}
                    className="mt-1"
                  />
                  <div>
                    <p className="font-semibold text-gray-900">VIP Membership</p>
                    <p className="text-sm text-gray-600">Akses eksklusif ke semua layanan Vista</p>
                  </div>
                </label>
              </div>
            </div>
          )}

          {currentStep === 3 && (
            <div className="space-y-6">
              <h3 className="text-xl font-bold text-gray-900 mb-4">Konfigurasi Produk</h3>

              {data.productType === 'ea_trading' && (
                <div className="space-y-6">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Jenis EA <span className="text-red-500">*</span>
                    </label>
                    <select
                      value={data.eaType}
                      onChange={(e) => handleInputChange('eaType', e.target.value)}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    >
                      <option value="">Pilih Jenis EA</option>
                      <option value="gold">Gold EA</option>
                      <option value="forex">Forex EA</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Risk Profile <span className="text-red-500">*</span>
                    </label>
                    <select
                      value={data.riskProfile}
                      onChange={(e) => handleInputChange('riskProfile', e.target.value)}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    >
                      <option value="">Pilih Risk Profile</option>
                      <option value="aggressive">Agresif</option>
                      <option value="moderate">Moderat</option>
                      <option value="conservative">Konservatif</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Maximum Drawdown <span className="text-red-500">*</span>
                    </label>
                    <select
                      value={data.maxDrawdown}
                      onChange={(e) => handleInputChange('maxDrawdown', e.target.value)}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    >
                      <option value="">Pilih Max Drawdown</option>
                      <option value="10">10%</option>
                      <option value="30">30%</option>
                      <option value="50">50%</option>
                    </select>
                  </div>

                  <p className="text-xs text-gray-500">
                    Semua pilihan dicatat sebagai keputusan klien.
                  </p>
                </div>
              )}

              {data.productType === 'bimbel_prop' && (
                <div className="space-y-6">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Tujuan Mengikuti Program <span className="text-red-500">*</span>
                    </label>
                    <select
                      value={data.programGoal}
                      onChange={(e) => handleInputChange('programGoal', e.target.value)}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    >
                      <option value="">Pilih Tujuan Program</option>
                      <option value="intermediate">Intermediate</option>
                      <option value="advance">Advance</option>
                    </select>
                  </div>
                </div>
              )}

              {data.productType === 'vip_membership' && (
                <div className="space-y-6">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Tujuan Mengikuti VIP Membership <span className="text-red-500">*</span>
                    </label>
                    <textarea
                      value={data.vipGoal}
                      onChange={(e) => handleInputChange('vipGoal', e.target.value)}
                      rows={4}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      placeholder="Jelaskan tujuan Anda mengikuti VIP Membership..."
                    />
                  </div>
                </div>
              )}
            </div>
          )}

          {currentStep === 4 && (
            <div className="space-y-6">
              <h3 className="text-xl font-bold text-gray-900 mb-4">Konfirmasi & Persetujuan</h3>

              <div className="bg-gray-50 rounded-lg p-6 space-y-4">
                <h4 className="font-semibold text-gray-900">Ringkasan Registrasi</h4>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                  <div>
                    <p className="text-gray-600">Nama Lengkap</p>
                    <p className="font-medium text-gray-900">{data.fullName}</p>
                  </div>
                  <div>
                    <p className="text-gray-600">Email</p>
                    <p className="font-medium text-gray-900">{data.email}</p>
                  </div>
                  <div>
                    <p className="text-gray-600">WhatsApp</p>
                    <p className="font-medium text-gray-900">{data.whatsapp}</p>
                  </div>
                  <div>
                    <p className="text-gray-600">Pekerjaan</p>
                    <p className="font-medium text-gray-900">{data.occupation} - {data.position}</p>
                  </div>
                  <div className="md:col-span-2">
                    <p className="text-gray-600">Produk</p>
                    <p className="font-medium text-gray-900">
                      {data.productType === 'ea_trading' && 'EA Trading'}
                      {data.productType === 'bimbel_prop' && 'Kelas Bimbel + Prop Funds'}
                      {data.productType === 'vip_membership' && 'VIP Membership'}
                    </p>
                  </div>
                  {data.productType === 'ea_trading' && (
                    <>
                      <div>
                        <p className="text-gray-600">Jenis EA</p>
                        <p className="font-medium text-gray-900">{data.eaType === 'gold' ? 'Gold EA' : 'Forex EA'}</p>
                      </div>
                      <div>
                        <p className="text-gray-600">Risk Profile</p>
                        <p className="font-medium text-gray-900">
                          {data.riskProfile === 'aggressive' && 'Agresif'}
                          {data.riskProfile === 'moderate' && 'Moderat'}
                          {data.riskProfile === 'conservative' && 'Konservatif'}
                        </p>
                      </div>
                      <div>
                        <p className="text-gray-600">Max Drawdown</p>
                        <p className="font-medium text-gray-900">{data.maxDrawdown}%</p>
                      </div>
                    </>
                  )}
                  <div>
                    <p className="text-gray-600">Status KYC</p>
                    <p className="font-medium text-green-600">KTP Uploaded</p>
                  </div>
                </div>
              </div>

              <div className="bg-blue-50 border border-blue-200 rounded-lg p-6 space-y-4">
                <h4 className="font-semibold text-blue-900">Persetujuan Wajib</h4>

                <label className="flex items-start gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={data.consentDataAccuracy}
                    onChange={(e) => handleInputChange('consentDataAccuracy', e.target.checked)}
                    className="mt-1 w-4 h-4 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
                  />
                  <span className="text-sm text-gray-700">
                    Saya menyatakan data yang diisi benar dan dapat dipertanggungjawabkan
                  </span>
                </label>

                <label className="flex items-start gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={data.consentRiskUnderstanding}
                    onChange={(e) => handleInputChange('consentRiskUnderstanding', e.target.checked)}
                    className="mt-1 w-4 h-4 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
                  />
                  <span className="text-sm text-gray-700">
                    Saya memahami risiko terkait produk trading dan investasi
                  </span>
                </label>

                <label className="flex items-start gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={data.consentVerificationProcess}
                    onChange={(e) => handleInputChange('consentVerificationProcess', e.target.checked)}
                    className="mt-1 w-4 h-4 text-blue-600 rounded focus:ring-2 focus:ring-blue-500"
                  />
                  <span className="text-sm text-gray-700">
                    Saya bersedia mengikuti proses verifikasi lanjutan dari tim Vista
                  </span>
                </label>
              </div>
            </div>
          )}

          <div className="flex justify-between mt-8 pt-6 border-t border-gray-200">
            <button
              onClick={handleBack}
              disabled={currentStep === 1 || loading}
              className="px-6 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              Kembali
            </button>

            {currentStep < 4 ? (
              <button
                onClick={handleNext}
                disabled={loading}
                className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                Lanjutkan
              </button>
            ) : (
              <button
                onClick={handleSubmit}
                disabled={loading}
                className="px-8 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700 disabled:opacity-50 disabled:cursor-not-allowed font-semibold transition-colors"
              >
                {loading ? 'Memproses...' : 'Submit Registration'}
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
