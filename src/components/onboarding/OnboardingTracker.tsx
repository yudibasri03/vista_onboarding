import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { OnboardingProgress, OnboardingStep } from '../../types';
import { CheckCircle2, Circle, Clock, ArrowRight } from 'lucide-react';

interface OnboardingTrackerProps {
  clientId: string;
}

export function OnboardingTracker({ clientId }: OnboardingTrackerProps) {
  const [steps, setSteps] = useState<(OnboardingProgress & { step: OnboardingStep })[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchOnboardingProgress();
  }, [clientId]);

  const fetchOnboardingProgress = async () => {
    try {
      const { data: progressData, error } = await supabase
        .from('client_onboarding_progress')
        .select(`
          *,
          step:onboarding_steps(*)
        `)
        .eq('client_id', clientId)
        .order('step(step_number)');

      if (error) throw error;

      setSteps(progressData as any);
    } catch (error) {
      console.error('Error fetching onboarding progress:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <CheckCircle2 className="w-8 h-8 text-emerald-400" />;
      case 'in_progress':
        return <Clock className="w-8 h-8 text-amber-400 animate-pulse" />;
      default:
        return <Circle className="w-8 h-8 text-slate-500" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'bg-emerald-500/10 border-emerald-500/30';
      case 'in_progress':
        return 'bg-amber-500/10 border-amber-500/30';
      default:
        return 'bg-slate-800/30 border-slate-600/30';
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-amber-500"></div>
      </div>
    );
  }

  return (
    <div className="bg-gradient-to-br from-slate-800/50 to-slate-900/50 backdrop-blur-sm rounded-2xl shadow-xl border border-slate-700/50 p-6">
      <h3 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
        <CheckCircle2 className="w-6 h-6 text-amber-400" />
        Progress Onboarding
      </h3>

      <div className="space-y-4">
        {steps.map((progress, index) => (
          <div key={progress.id}>
            <div className={`border rounded-xl p-5 transition-all duration-300 hover:shadow-lg hover:shadow-amber-500/10 ${getStatusColor(progress.status)}`}>
              <div className="flex items-start">
                <div className="flex-shrink-0 mr-4">
                  {getStatusIcon(progress.status)}
                </div>
                <div className="flex-1">
                  <div className="flex items-center justify-between mb-2 gap-3">
                    <h4 className="text-lg font-bold text-white">
                      {progress.step?.step_number}. {progress.step?.title}
                    </h4>
                    <span className={`px-3 py-1.5 rounded-lg text-xs font-bold whitespace-nowrap ${
                      progress.status === 'completed' ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30' :
                      progress.status === 'in_progress' ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30' :
                      'bg-slate-700/50 text-slate-400 border border-slate-600/30'
                    }`}>
                      {progress.status === 'completed' ? 'Selesai' :
                       progress.status === 'in_progress' ? 'Sedang Berjalan' :
                       'Belum Dimulai'}
                    </span>
                  </div>
                  <p className="text-slate-300 text-sm mb-2 leading-relaxed">{progress.step?.description}</p>
                  {progress.notes && (
                    <div className="mt-3 p-3 bg-slate-800/50 rounded-lg border border-slate-700/50">
                      <p className="text-sm text-slate-300">
                        <span className="font-semibold text-amber-400">Catatan:</span> {progress.notes}
                      </p>
                    </div>
                  )}
                  {progress.completed_at && (
                    <p className="text-xs text-slate-400 mt-2 flex items-center gap-2">
                      <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                      Selesai pada: {new Date(progress.completed_at).toLocaleDateString('id-ID', {
                        day: 'numeric',
                        month: 'long',
                        year: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit'
                      })}
                    </p>
                  )}
                </div>
              </div>
            </div>
            {index < steps.length - 1 && (
              <div className="flex justify-center my-2">
                <ArrowRight className="w-6 h-6 text-amber-500/50 transform rotate-90" />
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
