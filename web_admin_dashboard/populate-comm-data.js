import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = "https://dkcitxzvojvecuvacwsp.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrY2l0eHp2b2p2ZWN1dmFjd3NwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcxNDcwMTAsImV4cCI6MjA3MjcyMzAxMH0.0YmJgKVDkdmH6o-IMeT_eeMZEKBUfTuba9XsOruCYYw";

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function populateCommunicationData() {
  console.log('🚀 Populating communication data for demo...\n');
  
  try {
    // Authenticate as admin first
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: 'admin@datingapp.com',
      password: 'admin123'
    });
    
    if (authError) {
      console.log('❌ Admin login failed:', authError.message);
      return;
    }
    
    console.log('✅ Admin authenticated');
    
    // Get existing profiles
    const { data: profiles } = await supabase
      .from('profiles')
      .select('id, name')
      .limit(4);
    
    if (!profiles || profiles.length < 2) {
      console.log('❌ Need at least 2 profiles');
      return;
    }
    
    console.log(`✅ Found ${profiles.length} profiles`);
    
    // Create matches between profiles
    const matches = [];
    for (let i = 0; i < profiles.length - 1; i++) {
      for (let j = i + 1; j < profiles.length; j++) {
        matches.push({
          user_id_1: profiles[i].id,
          user_id_2: profiles[j].id,
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
    
    // Create conversation metadata
    const conversationData = createdMatches.map((match, index) => ({
      match_id: match.id,
      last_activity: new Date(Date.now() - (index * 24 * 60 * 60 * 1000)).toISOString(),
      message_count: Math.floor(Math.random() * 30) + 5,
      is_flagged: index === 0, // Flag first conversation
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
    
    // Create sample messages
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
      "Thanks! Talk to you soon!"
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
          is_flagged: Math.random() > 0.9,
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
    
    // Create message analytics
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
    
    console.log('\n🎉 COMMUNICATION DATA POPULATED SUCCESSFULLY!');
    console.log('The Communication Logs section should now display data!');
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

populateCommunicationData();
