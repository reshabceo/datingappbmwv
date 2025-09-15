import { createClient } from '@supabase/supabase-js';

// You'll need to replace these with your actual Supabase credentials
const supabaseUrl = 'YOUR_SUPABASE_URL';
const supabaseKey = 'YOUR_SUPABASE_ANON_KEY';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testReports() {
  try {
    console.log('Checking reports table...');
    
    // Check existing reports
    const { data: existingReports, error: fetchError } = await supabase
      .from('reports')
      .select('*')
      .limit(5);
    
    if (fetchError) {
      console.error('Error fetching reports:', fetchError);
      return;
    }
    
    console.log('Existing reports:', existingReports?.length || 0);
    console.log('Sample data:', existingReports);
    
    // If no reports exist, add some sample data
    if (!existingReports || existingReports.length === 0) {
      console.log('No reports found. Adding sample data...');
      
      // First, get some user IDs from profiles
      const { data: profiles } = await supabase
        .from('profiles')
        .select('id')
        .limit(3);
      
      if (profiles && profiles.length > 0) {
        const sampleReports = [
          {
            reporter_id: profiles[0].id,
            reported_id: profiles[1]?.id || profiles[0].id,
            type: 'inappropriate_content',
            reason: 'Inappropriate photos',
            description: 'User posted inappropriate photos in their profile',
            status: 'pending',
            priority: 'high',
            auto_flagged: false,
            created_at: new Date().toISOString()
          },
          {
            reporter_id: profiles[1]?.id || profiles[0].id,
            reported_id: profiles[2]?.id || profiles[0].id,
            type: 'harassment',
            reason: 'Harassment',
            description: 'User sent inappropriate messages',
            status: 'pending',
            priority: 'medium',
            auto_flagged: true,
            created_at: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
          },
          {
            reporter_id: profiles[2]?.id || profiles[0].id,
            reported_id: profiles[0].id,
            type: 'spam',
            reason: 'Spam',
            description: 'User is sending spam messages',
            status: 'resolved',
            priority: 'low',
            auto_flagged: false,
            created_at: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString()
          }
        ];
        
        const { data: insertedReports, error: insertError } = await supabase
          .from('reports')
          .insert(sampleReports)
          .select();
        
        if (insertError) {
          console.error('Error inserting sample reports:', insertError);
        } else {
          console.log('Sample reports added successfully:', insertedReports);
        }
      } else {
        console.log('No profiles found. Cannot create sample reports.');
      }
    }
    
  } catch (error) {
    console.error('Error:', error);
  }
}

testReports();
