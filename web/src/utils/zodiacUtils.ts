export const calculateZodiacSign = (birthDate: string): string => {
  const date = new Date(birthDate);
  const month = date.getMonth() + 1;
  const day = date.getDate();

  if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'aries';
  if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'taurus';
  if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return 'gemini';
  if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'cancer';
  if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'leo';
  if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'virgo';
  if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'libra';
  if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 'scorpio';
  if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return 'sagittarius';
  if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) return 'capricorn';
  if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'aquarius';
  if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return 'pisces';
  
  return 'unknown';
};

export const getZodiacEmoji = (sign: string) => {
  const emojis = {
    aries: '♈', taurus: '♉', gemini: '♊', cancer: '♋',
    leo: '♌', virgo: '♍', libra: '♎', scorpio: '♏',
    sagittarius: '♐', capricorn: '♑', aquarius: '♒', pisces: '♓'
  };
  return emojis[sign.toLowerCase()] || '⭐';
};

export const getZodiacTraits = (sign: string) => {
  const traits = {
    aries: { element: 'fire', quality: 'cardinal', planet: 'mars', traits: ['energetic', 'pioneering', 'confident'] },
    taurus: { element: 'earth', quality: 'fixed', planet: 'venus', traits: ['reliable', 'practical', 'sensual'] },
    gemini: { element: 'air', quality: 'mutable', planet: 'mercury', traits: ['curious', 'adaptable', 'communicative'] },
    cancer: { element: 'water', quality: 'cardinal', planet: 'moon', traits: ['nurturing', 'intuitive', 'emotional'] },
    leo: { element: 'fire', quality: 'fixed', planet: 'sun', traits: ['confident', 'generous', 'dramatic'] },
    virgo: { element: 'earth', quality: 'mutable', planet: 'mercury', traits: ['analytical', 'helpful', 'practical'] },
    libra: { element: 'air', quality: 'cardinal', planet: 'venus', traits: ['harmonious', 'diplomatic', 'aesthetic'] },
    scorpio: { element: 'water', quality: 'fixed', planet: 'pluto', traits: ['intense', 'transformative', 'mysterious'] },
    sagittarius: { element: 'fire', quality: 'mutable', planet: 'jupiter', traits: ['adventurous', 'philosophical', 'optimistic'] },
    capricorn: { element: 'earth', quality: 'cardinal', planet: 'saturn', traits: ['ambitious', 'disciplined', 'practical'] },
    aquarius: { element: 'air', quality: 'fixed', planet: 'uranus', traits: ['innovative', 'independent', 'humanitarian'] },
    pisces: { element: 'water', quality: 'mutable', planet: 'neptune', traits: ['intuitive', 'compassionate', 'artistic'] }
  };
  
  return traits[sign.toLowerCase()] || null;
};

export const getCompatibilityScore = (sign1: string, sign2: string): number => {
  // Basic compatibility matrix
  const compatibility = {
    'aries': {'leo': 95, 'sagittarius': 90, 'gemini': 85, 'aquarius': 80, 'libra': 75, 'cancer': 60, 'capricorn': 55, 'virgo': 50, 'scorpio': 45, 'taurus': 40, 'pisces': 35},
    'taurus': {'virgo': 95, 'capricorn': 90, 'cancer': 85, 'pisces': 80, 'scorpio': 75, 'libra': 70, 'leo': 60, 'aquarius': 55, 'gemini': 50, 'sagittarius': 45, 'aries': 40},
    'gemini': {'libra': 95, 'aquarius': 90, 'leo': 85, 'aries': 85, 'sagittarius': 80, 'virgo': 70, 'cancer': 65, 'scorpio': 60, 'capricorn': 55, 'taurus': 50, 'pisces': 45},
    'cancer': {'scorpio': 95, 'pisces': 90, 'taurus': 85, 'virgo': 80, 'capricorn': 75, 'leo': 70, 'libra': 65, 'aquarius': 60, 'gemini': 65, 'sagittarius': 50, 'aries': 60},
    'leo': {'aries': 95, 'sagittarius': 90, 'gemini': 85, 'libra': 85, 'aquarius': 80, 'cancer': 70, 'virgo': 65, 'scorpio': 70, 'capricorn': 60, 'taurus': 60, 'pisces': 55},
    'virgo': {'taurus': 95, 'capricorn': 90, 'cancer': 80, 'scorpio': 75, 'pisces': 70, 'leo': 65, 'libra': 60, 'aquarius': 55, 'gemini': 70, 'sagittarius': 60, 'aries': 50},
    'libra': {'aquarius': 95, 'gemini': 95, 'leo': 85, 'sagittarius': 80, 'taurus': 70, 'cancer': 65, 'virgo': 60, 'scorpio': 70, 'capricorn': 65, 'aries': 75, 'pisces': 60},
    'scorpio': {'cancer': 95, 'pisces': 90, 'virgo': 75, 'capricorn': 80, 'taurus': 75, 'leo': 70, 'libra': 70, 'aquarius': 65, 'gemini': 60, 'sagittarius': 55, 'aries': 45},
    'sagittarius': {'aries': 90, 'leo': 90, 'aquarius': 85, 'libra': 80, 'gemini': 80, 'cancer': 50, 'virgo': 60, 'scorpio': 55, 'capricorn': 70, 'taurus': 45, 'pisces': 60},
    'capricorn': {'taurus': 90, 'virgo': 90, 'scorpio': 80, 'pisces': 75, 'cancer': 75, 'leo': 60, 'libra': 65, 'aquarius': 70, 'gemini': 55, 'sagittarius': 70, 'aries': 55},
    'aquarius': {'gemini': 90, 'libra': 95, 'sagittarius': 85, 'leo': 80, 'aries': 80, 'cancer': 60, 'virgo': 55, 'scorpio': 65, 'capricorn': 70, 'taurus': 55, 'pisces': 65},
    'pisces': {'cancer': 90, 'scorpio': 90, 'taurus': 80, 'capricorn': 75, 'virgo': 70, 'leo': 55, 'libra': 60, 'aquarius': 65, 'gemini': 45, 'sagittarius': 60, 'aries': 35}
  };
  
  return compatibility[sign1.toLowerCase()]?.[sign2.toLowerCase()] || 70;
};
