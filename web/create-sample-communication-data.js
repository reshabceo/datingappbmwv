import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = "https://dkcitxzvojvecuvacwsp.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function createSampleCommunicationData() {
  console.log('🚀 Creating sample communication data...\n');
  
  try {
    // First, get existing profiles
    const { data: profiles, error: profilesError } = await supabase
      .from('profiles')
      .select('id, name')
      .limit(10);
    
    if (profilesError) {
      console.log(`❌ Error fetching profiles: ${profilesError.message}`);
      return;
    }
    
    if (!profiles || profiles.length < 2) {
      console.log('❌ Need at least 2 profiles to create matches');
      return;
    }
    
    console.log(`✅ Found ${profiles.length} profiles: ${profiles.map(p => p.name).join(', ')}`);
    
    // Create some matches between profiles
    const matches = [];
    const profileIds = profiles.map(p => p.id);
    
    // Create matches between different profiles
    for (let i = 0; i < profileIds.length - 1; i++) {
      for (let j = i + 1; j < profileIds.length; j++) {
        matches.push({
          user_id_1: profileIds[i],
          user_id_2: profileIds[j],
          status: 'matched',
          created_at: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString()
        });
      }
    }
    
    console.log(`\n📊 Creating ${matches.length} matches...`);
    const { data: createdMatches, error: matchesError } = await supabase
      .from('matches')
      .insert(matches)
      .select();
    
    if (matchesError) {
      console.log(`❌ Error creating matches: ${matchesError.message}`);
      return;
    }
    
    console.log(`✅ Created ${createdMatches.length} matches`);
    
    // Create conversation metadata for each match
    const conversationData = createdMatches.map((match, index) => ({
      match_id: match.id,
      last_activity: new Date(Date.now() - (index * 24 * 60 * 60 * 1000)).toISOString(),
      message_count: Math.floor(Math.random() * 30) + 5,
      is_flagged: index === 0, // Flag the first conversation
      flagged_reason: index === 0 ? 'Inappropriate language detected' : null,
      risk_score: Math.floor(Math.random() * 100)
    }));
    
    console.log(`\n💬 Creating conversation metadata...`);
    const { data: conversations, error: convError } = await supabase
      .from('conversation_metadata')
      .insert(conversationData)
      .select();
    
    if (convError) {
      console.log(`❌ Error creating conversations: ${convError.message}`);
      return;
    }
    
    console.log(`✅ Created ${conversations.length} conversation records`);
    
    // Create sample messages for each conversation
    const messageData = [];
    const sampleMessages = [
      "Hey! How's your day going?",
      "I'm doing great, thanks for asking!",
      "Want to grab coffee sometime?",
      "That sounds lovely! When are you free?",
      "How about this weekend?",
      "Perfect! I'll see you then 😊",
      "Looking forward to it!",
      "Me too! Have a great day!",
      "You too! Talk soon!",
      "Hey, I had a great time yesterday!",
      "So did I! We should do it again soon",
      "Absolutely! Maybe next week?",
      "Sounds perfect!",
      "Great! I'll text you the details",
      "Thanks! Talk to you soon!",
      "What are your hobbies?",
      "I love hiking and photography",
      "That's awesome! I enjoy cooking",
      "We should cook together sometime!",
      "I'd love that! What's your favorite cuisine?",
      "I love Italian food",
      "Perfect! I make a mean pasta",
      "Can't wait to try it!",
      "When are you free this week?",
      "I'm free on Thursday evening"
    ];
    
    for (let i = 0; i < createdMatches.length; i++) {
      const match = createdMatches[i];
      const messageCount = Math.floor(Math.random() * 15) + 5;
      
      for (let j = 0; j < messageCount; j++) {
        const isUser1 = Math.random() > 0.5;
        const senderId = isUser1 ? match.user_id_1 : match.user_id_2;
        const messageText = sampleMessages[Math.floor(Math.random() * sampleMessages.length)];
        
        messageData.push({
          match_id: match.id,
          sender_id: senderId,
          content: messageText,
          message_type: Math.random() > 0.8 ? 'media' : 'text',
          is_flagged: Math.random() > 0.9, // 10% chance of being flagged
          flagged_reason: Math.random() > 0.9 ? 'Inappropriate content' : null,
          created_at: new Date(Date.now() - (j * 60 * 60 * 1000)).toISOString()
        });
      }
    }
    
    console.log(`\n💬 Creating ${messageData.length} messages...`);
    const { data: messages, error: msgError } = await supabase
      .from('messages')
      .insert(messageData)
      .select();
    
    if (msgError) {
      console.log(`❌ Error creating messages: ${msgError.message}`);
      return;
    }
    
    console.log(`✅ Created ${messages.length} messages`);
    
    // Create daily analytics for the last 7 days
    const analyticsData = [];
    for (let i = 0; i < 7; i++) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      
      analyticsData.push({
        date: date.toISOString().split('T')[0],
        total_messages: Math.floor(Math.random() * 50) + 10,
        flagged_messages: Math.floor(Math.random() * 5),
        active_conversations: Math.floor(Math.random() * 10) + 2,
        new_conversations: Math.floor(Math.random() * 3) + 1
      });
    }
    
    console.log(`\n📈 Creating analytics data...`);
    const { data: analytics, error: analyticsError } = await supabase
      .from('message_analytics')
      .insert(analyticsData)
      .select();
    
    if (analyticsError) {
      console.log(`❌ Error creating analytics: ${analyticsError.message}`);
      return;
    }
    
    console.log(`✅ Created ${analytics.length} analytics records`);
    
    // Summary
    console.log('\n🎉 SAMPLE COMMUNICATION DATA CREATED SUCCESSFULLY!');
    console.log(`- Matches: ${createdMatches.length}`);
    console.log(`- Conversations: ${conversations.length}`);
    console.log(`- Messages: ${messages.length}`);
    console.log(`- Analytics records: ${analytics.length}`);
    console.log('\nThe Communication Logs section should now display data!');
    
  } catch (error) {
    console.error('❌ Error creating sample data:', error);
  }
}

createSampleCommunicationData();
