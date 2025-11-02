import React from 'react';

interface DunsSealProps {
  className?: string;
  size?: 'small' | 'medium' | 'large';
  showText?: boolean;
}

const DunsSeal: React.FC<DunsSealProps> = ({ 
  className = '', 
  size = 'medium',
  showText = true 
}) => {
  const sizeClasses = {
    small: 'w-16 h-16',
    medium: 'w-24 h-24',
    large: 'w-32 h-32'
  };

  const textSizeClasses = {
    small: 'text-xs',
    medium: 'text-sm',
    large: 'text-base'
  };

  return (
    <div className={`flex flex-col items-center ${className}`}>
      <a
        href="https://dunsregistered.dnb.com/DunsRegisteredProfileAnywhere.aspx?Key1=3196184&PaArea=Email"
        target="_blank"
        rel="noopener noreferrer"
        className="block transition-transform hover:scale-105"
        title="D&B D-U-N-S Registered - Click to verify"
      >
        <div className={`${sizeClasses[size]} bg-blue-600 rounded-lg flex items-center justify-center shadow-lg hover:shadow-xl transition-shadow`}>
          <div className="text-white font-bold text-center">
            <div className="text-xs font-semibold">D&B</div>
            <div className="text-xs">D-U-N-S</div>
            <div className="text-xs">Registered</div>
          </div>
        </div>
      </a>
      {showText && (
        <div className={`mt-2 text-center ${textSizeClasses[size]} text-gray-600`}>
          <div className="font-semibold">D&B D-U-N-S Registered</div>
          <div className="text-xs">Business Verification</div>
        </div>
      )}
    </div>
  );
};

export default DunsSeal;
