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
    <div className="w-full py-6 md:py-10 mb-6 md:mb-8">
      <div className="flex items-center justify-between max-w-4xl mx-auto px-2 sm:px-4">
        {steps.map((step, index) => (
          <div key={step.number} className="flex items-center flex-1">
            <div className="flex flex-col items-center relative">
              <div
                className={`w-10 h-10 sm:w-12 sm:h-12 md:w-16 md:h-16 rounded-lg md:rounded-2xl flex items-center justify-center font-bold text-sm sm:text-base md:text-lg transition-all duration-300 shadow-md md:shadow-lg ${
                  currentStep > step.number
                    ? 'bg-gradient-to-br from-amber-500 to-yellow-500 text-white shadow-amber-500/40'
                    : currentStep === step.number
                    ? 'bg-gradient-to-br from-amber-600 to-yellow-600 text-white ring-2 md:ring-4 ring-amber-200 shadow-amber-500/50 scale-105 md:scale-110'
                    : 'bg-slate-200 text-slate-400 shadow-slate-300/30'
                }`}
              >
                {currentStep > step.number ? (
                  <Check className="h-4 w-4 sm:h-5 sm:w-5 md:h-7 md:w-7" />
                ) : (
                  step.number
                )}
              </div>
              <div className="mt-1.5 sm:mt-2 md:mt-3 text-center">
                <p
                  className={`text-[10px] sm:text-xs md:text-sm font-semibold transition-colors whitespace-nowrap ${
                    currentStep >= step.number ? 'text-white' : 'text-slate-400'
                  }`}
                >
                  {step.title}
                </p>
              </div>
            </div>
            {index < steps.length - 1 && (
              <div className="flex-1 h-1.5 md:h-2 mx-1 sm:mx-2 md:mx-6 mb-6 sm:mb-8 md:mb-10 rounded-full overflow-hidden bg-slate-700/30">
                <div
                  className={`h-full rounded-full transition-all duration-500 ${
                    currentStep > step.number
                      ? 'bg-gradient-to-r from-amber-500 to-yellow-500 w-full'
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
