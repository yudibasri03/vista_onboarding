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
    <div className="w-full py-8">
      <div className="flex items-center justify-between max-w-4xl mx-auto px-4">
        {steps.map((step, index) => (
          <div key={step.number} className="flex items-center flex-1">
            <div className="flex flex-col items-center relative">
              <div
                className={`w-12 h-12 rounded-full flex items-center justify-center font-semibold transition-all ${
                  currentStep > step.number
                    ? 'bg-emerald-600 text-white'
                    : currentStep === step.number
                    ? 'bg-blue-600 text-white ring-4 ring-blue-200'
                    : 'bg-gray-200 text-gray-500'
                }`}
              >
                {currentStep > step.number ? (
                  <Check className="h-6 w-6" />
                ) : (
                  step.number
                )}
              </div>
              <div className="mt-2 text-center">
                <p
                  className={`text-sm font-medium ${
                    currentStep >= step.number ? 'text-gray-900' : 'text-gray-500'
                  }`}
                >
                  {step.title}
                </p>
              </div>
            </div>
            {index < steps.length - 1 && (
              <div className="flex-1 h-1 mx-4 mb-8">
                <div
                  className={`h-full rounded transition-all ${
                    currentStep > step.number ? 'bg-emerald-600' : 'bg-gray-200'
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
