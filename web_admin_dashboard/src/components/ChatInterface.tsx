import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Heart, Star, MessageCircle, Sparkles } from 'lucide-react';
import { supabase } from '@/integrations/supabase/client';

interface ChatInterfaceProps {
  matchId: string;
  currentUserId: string;
  otherUser: {
    id: string;
    name: string;
    zodiac_sign: string;
    age: number;
    hobbies: string[];
  };
}

export const ChatInterface: React.FC<ChatInterfaceProps> = ({
  matchId,
  currentUserId, 
  otherUser
}) => {
  const [matchEnhancements, setMatchEnhancements] = useState(null);
  const [loading, setLoading] = useState(true);
  const [usedIceBreakers, setUsedIceBreakers] = useState([]);

  useEffect(() => {
    loadMatchEnhancements();
  }, [matchId]);

  const loadMatchEnhancements = async () => {
    try {
      // Check if enhancements already exist
      const { data: existing } = await supabase
        .from('match_enhancements')
        .select('*')
        .eq('match_id', matchId)
        .single();

      if (existing && new Date(existing.expires_at) > new Date()) {
        setMatchEnhancements(existing);
      } else {
        // Generate new enhancements
        await generateEnhancements();
      }

      // Load used ice breakers
      const { data: usage } = await supabase
        .from('ice_breaker_usage')
        .select('ice_breaker_text')
        .eq('match_id', matchId);
      
      setUsedIceBreakers(usage?.map(u => u.ice_breaker_text) || []);
      
    } catch (error) {
      console.error('Error loading match enhancements:', error);
    } finally {
      setLoading(false);
    }
  };

  const generateEnhancements = async () => {
    try {
      // Get current user data
      const { data: currentUserData } = await supabase
        .from('profiles')
        .select('name, zodiac_sign, age, hobbies, location')
        .eq('id', currentUserId)
        .single();

      // Call edge function to generate insights
      const { data, error } = await supabase.functions.invoke('generate-match-insights', {
        body: {
          matchId,
          user1Data: currentUserData,
          user2Data: otherUser
        }
      });

      if (error) throw error;

      // Save to database
      const { data: saved } = await supabase
        .from('match_enhancements')
        .upsert({
          match_id: matchId,
          astro_compatibility: data.astroCompatibility,
          ice_breakers: data.iceBreakers
        })
        .select()
        .single();

      setMatchEnhancements(saved);
    } catch (error) {
      console.error('Error generating enhancements:', error);
    }
  };

  const useIceBreaker = async (iceBreaker) => {
    try {
      // Mark as used
      await supabase
        .from('ice_breaker_usage')
        .insert({
          match_id: matchId,
          ice_breaker_text: iceBreaker.question,
          used_by_user_id: currentUserId
        });

      setUsedIceBreakers([...usedIceBreakers, iceBreaker.question]);

      // Could auto-populate message input here
      console.log('Ice breaker used:', iceBreaker.question);
    } catch (error) {
      console.error('Error tracking ice breaker usage:', error);
    }
  };

  if (loading) {
    return <div className="animate-pulse">Loading match insights...</div>;
  }

  return (
    <div className="space-y-4">
      {/* Astrological Compatibility Card */}
      {matchEnhancements?.astro_compatibility && (
        <Card className="bg-gradient-to-r from-purple-50 to-pink-50 border-purple-200">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-purple-700">
              <Sparkles className="h-5 w-5" />
              Astrological Compatibility
              <Badge className="bg-purple-600 text-white">
                {matchEnhancements.astro_compatibility.compatibility_score}% Match
              </Badge>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <p className="text-gray-700">
              {matchEnhancements.astro_compatibility.summary}
            </p>
            
            <div className="grid md:grid-cols-2 gap-4">
              <div>
                <h4 className="font-semibold text-green-700 flex items-center gap-1">
                  <Heart className="h-4 w-4" /> Strengths
                </h4>
                <ul className="text-sm text-gray-600 ml-2">
                  {matchEnhancements.astro_compatibility.strengths?.map((strength, i) => (
                    <li key={i}>• {strength}</li>
                  ))}
                </ul>
              </div>
              
              <div>
                <h4 className="font-semibold text-blue-700 flex items-center gap-1">
                  <Star className="h-4 w-4" /> Romantic Outlook
                </h4>
                <p className="text-sm text-gray-600">
                  {matchEnhancements.astro_compatibility.romantic_outlook}
                </p>
              </div>
            </div>

            <div className="bg-white/50 p-3 rounded-lg">
              <h4 className="font-semibold text-purple-700">Compatibility Advice</h4>
              <p className="text-sm text-gray-700">
                {matchEnhancements.astro_compatibility.advice}
              </p>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Ice Breakers Card */}
      {matchEnhancements?.ice_breakers && (
        <Card className="bg-gradient-to-r from-blue-50 to-cyan-50 border-blue-200">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-blue-700">
              <MessageCircle className="h-5 w-5" />
              Conversation Starters
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {matchEnhancements.ice_breakers.map((iceBreaker, index) => {
                const isUsed = usedIceBreakers.includes(iceBreaker.question);
                
                return (
                  <div 
                    key={index}
                    className={`p-3 rounded-lg border ${
                      isUsed 
                        ? 'bg-gray-100 border-gray-300 opacity-60' 
                        : 'bg-white border-blue-200 hover:border-blue-400 cursor-pointer'
                    }`}
                    onClick={() => !isUsed && useIceBreaker(iceBreaker)}
                  >
                    <div className="flex justify-between items-start">
                      <div className="flex-1">
                        <p className={`font-medium ${isUsed ? 'text-gray-500' : 'text-gray-800'}`}>
                          {iceBreaker.question}
                        </p>
                        <div className="flex items-center gap-2 mt-2">
                          <Badge 
                            variant="outline" 
                            className={`text-xs ${
                              iceBreaker.category === 'hobbies' ? 'border-green-300 text-green-600' :
                              iceBreaker.category === 'astrology' ? 'border-purple-300 text-purple-600' :
                              'border-blue-300 text-blue-600'
                            }`}
                          >
                            {iceBreaker.category}
                          </Badge>
                          {isUsed && <Badge variant="secondary" className="text-xs">Used</Badge>}
                        </div>
                      </div>
                      {!isUsed && (
                        <Button size="sm" variant="outline" className="ml-2">
                          Use This
                        </Button>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
};
