import React from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Calendar, MapPin, Heart } from 'lucide-react';

interface MatchProfileEnhancementProps {
  user: {
    name: string;
    age: number;
    zodiac_sign: string;
    birth_date?: string;
    location?: string;
    hobbies?: string[];
  };
}

export const MatchProfileEnhancement: React.FC<MatchProfileEnhancementProps> = ({ user }) => {
  const getZodiacEmoji = (sign: string) => {
    const emojis = {
      aries: '♈', taurus: '♉', gemini: '♊', cancer: '♋',
      leo: '♌', virgo: '♍', libra: '♎', scorpio: '♏',
      sagittarius: '♐', capricorn: '♑', aquarius: '♒', pisces: '♓'
    };
    return emojis[sign?.toLowerCase()] || '⭐';
  };

  return (
    <Card className="bg-gradient-to-br from-indigo-50 to-purple-50 border-indigo-200">
      <CardContent className="p-4">
        <div className="flex items-center justify-between mb-3">
          <h3 className="font-semibold text-lg text-indigo-800">{user.name}</h3>
          <Badge className="bg-indigo-600 text-white">
            {getZodiacEmoji(user.zodiac_sign)} {user.zodiac_sign}
          </Badge>
        </div>
        
        <div className="space-y-2 text-sm text-gray-600">
          <div className="flex items-center gap-2">
            <Calendar className="h-4 w-4" />
            <span>{user.age} years old</span>
          </div>
          
          {user.location && (
            <div className="flex items-center gap-2">
              <MapPin className="h-4 w-4" />
              <span>{user.location}</span>
            </div>
          )}
          
          {user.hobbies && user.hobbies.length > 0 && (
            <div className="flex items-center gap-2">
              <Heart className="h-4 w-4" />
              <div className="flex flex-wrap gap-1">
                {user.hobbies.slice(0, 3).map((hobby, i) => (
                  <Badge key={i} variant="outline" className="text-xs">
                    {hobby}
                  </Badge>
                ))}
                {user.hobbies.length > 3 && (
                  <Badge variant="outline" className="text-xs">
                    +{user.hobbies.length - 3} more
                  </Badge>
                )}
              </div>
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
};
