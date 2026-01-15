import { ArrowRight, CheckCircle2, Sparkles } from 'lucide-react';
import { createWhatsAppLink, WHATSAPP_MESSAGES } from '../utils/whatsapp';

export default function Hero() {
  return (
    <section className="relative bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 text-white overflow-hidden pt-32 pb-24">
      <div className="absolute inset-0 bg-grid-pattern opacity-40"></div>

      <div className="absolute top-20 left-10 w-72 h-72 bg-amber-500/10 rounded-full blur-3xl animate-pulse-slow"></div>
      <div className="absolute bottom-20 right-10 w-96 h-96 bg-amber-600/10 rounded-full blur-3xl animate-pulse-slow" style={{ animationDelay: '1s' }}></div>

      <div className="absolute top-1/4 right-1/4 w-2 h-2 bg-amber-400 rounded-full animate-float"></div>
      <div className="absolute top-1/3 left-1/4 w-3 h-3 bg-amber-500 rounded-full animate-float" style={{ animationDelay: '0.5s' }}></div>
      <div className="absolute bottom-1/4 right-1/3 w-2 h-2 bg-amber-300 rounded-full animate-float" style={{ animationDelay: '1s' }}></div>

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center max-w-5xl mx-auto">
          <div className="inline-flex items-center gap-2 bg-amber-500/10 border border-amber-500/30 rounded-full px-5 py-2 mb-8 animate-scale-in">
            <Sparkles className="w-4 h-4 text-amber-400" />
            <span className="text-sm font-semibold text-amber-400">Ekosistem Trading Terintegrasi</span>
          </div>

          <h1 className="text-5xl sm:text-6xl lg:text-7xl font-extrabold leading-tight mb-8 animate-slide-up">
            <span className="bg-gradient-to-r from-white via-gray-100 to-gray-300 bg-clip-text text-transparent">
              Kuasai Analisis Pasar dan Raih Kesempatan Menjadi
            </span>
            <br />
            <span className="bg-gradient-to-r from-amber-400 to-amber-600 bg-clip-text text-transparent">
              Professional Trader
            </span>
          </h1>

          <p className="text-lg sm:text-xl text-gray-300 mb-12 leading-relaxed max-w-3xl mx-auto animate-fade-in">
            Bergabunglah bersama Vista Trading untuk mendapatkan pembelajaran langsung dari para ahli di bidangnya. Pelajari strategi trading yang terbukti efektif, kuasai analisis pasar secara menyeluruh, dan tingkatkan kemampuan Anda.
          </p>

          <div className="grid sm:grid-cols-2 gap-4 max-w-3xl mx-auto mb-12">
            {[
              'Edukasi step-by-step sampai bisa praktek',
              'Akses modal trading tambahan lewat prop challenge',
              'Algo trading untuk yang sibuk & ingin semi-pasif',
              'Sinyal & live trade harian bersama mentor'
            ].map((benefit, index) => (
              <div
                key={index}
                className="group flex items-start gap-3 text-left bg-gradient-to-br from-slate-800/50 to-slate-900/50 backdrop-blur-sm rounded-xl p-5 border border-slate-700/50 hover:border-amber-500/50 transition-all duration-300 hover:shadow-lg hover:shadow-amber-500/10 hover:-translate-y-1"
                style={{ animationDelay: `${index * 0.1}s` }}
              >
                <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-amber-500 to-amber-600 flex items-center justify-center flex-shrink-0 shadow-lg shadow-amber-500/25 group-hover:scale-110 transition-transform">
                  <CheckCircle2 className="w-4 h-4 text-white" />
                </div>
                <span className="text-gray-200 text-sm leading-relaxed font-medium">{benefit}</span>
              </div>
            ))}
          </div>

          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center animate-fade-in">
            <a
              href={createWhatsAppLink(WHATSAPP_MESSAGES.KONSULTASI_GRATIS)}
              target="_blank"
              rel="noopener noreferrer"
              className="group relative bg-gradient-to-r from-amber-500 to-amber-600 hover:from-amber-600 hover:to-amber-700 text-white font-bold px-10 py-5 rounded-xl transition-all duration-300 shadow-xl shadow-amber-500/25 hover:shadow-2xl hover:shadow-amber-500/40 hover:scale-105 flex items-center gap-3 overflow-hidden"
            >
              <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent translate-x-[-200%] group-hover:translate-x-[200%] transition-transform duration-700"></div>
              <span className="relative">Konsultasi Gratis dengan Tim Vista</span>
              <ArrowRight className="relative w-5 h-5 group-hover:translate-x-2 transition-transform" />
            </a>
          </div>
          <p className="text-sm text-gray-400 mt-6 animate-fade-in">
            Tanya produk mana yang paling cocok dengan kondisi Anda sekarang
          </p>
        </div>
      </div>

      <div className="absolute bottom-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-amber-500/50 to-transparent"></div>
    </section>
  );
}
