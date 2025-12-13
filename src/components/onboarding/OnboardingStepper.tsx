import { Check } from 'lucide-react';

interface Step {
  number: number;
  title: string;
}

interface OnboardingStepperProps {
  currentStep: number;
  steps: Step[];
}

export function OnboardingStepper({ currentStep, steps }: OnboardingStepperProps) {
  return (
    <div className="w-full py-10 mb-8">
      <div className="flex items-center justify-between max-w-4xl mx-auto px-4">
        {steps.map((step, index) => (
          <div key={step.number} className="flex items-center flex-1">
            <div className="flex flex-col items-center relative">
              <div
                className={`w-16 h-16 rounded-2xl flex items-center justify-center font-bold text-lg transition-all duration-300 shadow-lg ${
                  currentStep > step.number
                    ? 'bg-gradient-to-br from-emerald-500 to-teal-500 text-white shadow-emerald-500/40'
                    : currentStep === step.number
                    ? 'bg-gradient-to-br from-teal-600 to-emerald-600 text-white ring-4 ring-teal-200 shadow-teal-500/50 scale-110'
                    : 'bg-slate-200 text-slate-400 shadow-slate-300/30'
                }`}
              >
                {currentStep > step.number ? (
                  <Check className="h-7 w-7" />
                ) : (
                  step.number
                )}
              </div>
              <div className="mt-3 text-center">
                <p
                  className={`text-sm font-semibold transition-colors ${
                    currentStep >= step.number ? 'text-white' : 'text-slate-400'
                  }`}
                >
                  {step.title}
                </p>
              </div>
            </div>
            {index < steps.length - 1 && (
              <div className="flex-1 h-2 mx-6 mb-10 rounded-full overflow-hidden bg-slate-700/30">
                <div
                  className={`h-full rounded-full transition-all duration-500 ${
                    currentStep > step.number
                      ? 'bg-gradient-to-r from-emerald-500 to-teal-500 w-full'
                      : 'w-0'
                  }`}
                />
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
