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
        return <CheckCircle2 className="w-8 h-8 text-green-500" />;
      case 'in_progress':
        return <Clock className="w-8 h-8 text-blue-500" />;
      default:
        return <Circle className="w-8 h-8 text-gray-300" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'bg-green-50 border-green-200';
      case 'in_progress':
        return 'bg-blue-50 border-blue-200';
      default:
        return 'bg-gray-50 border-gray-200';
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <h3 className="text-xl font-bold text-gray-900 mb-6">Progress Onboarding</h3>

      <div className="space-y-4">
        {steps.map((progress, index) => (
          <div key={progress.id}>
            <div className={`border rounded-lg p-4 ${getStatusColor(progress.status)}`}>
              <div className="flex items-start">
                <div className="flex-shrink-0 mr-4">
                  {getStatusIcon(progress.status)}
                </div>
                <div className="flex-1">
                  <div className="flex items-center justify-between mb-2">
                    <h4 className="text-lg font-semibold text-gray-900">
                      {progress.step?.step_number}. {progress.step?.title}
                    </h4>
                    <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                      progress.status === 'completed' ? 'bg-green-100 text-green-800' :
                      progress.status === 'in_progress' ? 'bg-blue-100 text-blue-800' :
                      'bg-gray-100 text-gray-800'
                    }`}>
                      {progress.status === 'completed' ? 'Selesai' :
                       progress.status === 'in_progress' ? 'Sedang Berjalan' :
                       'Belum Dimulai'}
                    </span>
                  </div>
                  <p className="text-gray-600 text-sm mb-2">{progress.step?.description}</p>
                  {progress.notes && (
                    <div className="mt-2 p-2 bg-white rounded border border-gray-200">
                      <p className="text-sm text-gray-700">
                        <span className="font-medium">Catatan:</span> {progress.notes}
                      </p>
                    </div>
                  )}
                  {progress.completed_at && (
                    <p className="text-xs text-gray-500 mt-2">
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
                <ArrowRight className="w-6 h-6 text-gray-400 transform rotate-90" />
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
