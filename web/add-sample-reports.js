// Simple script to add sample reports data
// Run this in the browser console on your admin dashboard page

async function addSampleReports() {
  // Get the supabase client from the page
  const { supabase } = await import('./src/supabaseClient.ts');
  
  try {
    console.log('Adding sample reports...');
    
    // First, get some user IDs
    const { data: profiles } = await supabase
      .from('profiles')
      .select('id, name')
      .limit(3);
    
    if (!profiles || profiles.length === 0) {
      console.log('No profiles found. Please create some users first.');
      return;
    }
    
    console.log('Found profiles:', profiles);
    
    // Create sample reports
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
    
    const { data: insertedReports, error } = await supabase
      .from('reports')
      .insert(sampleReports)
      .select();
    
    if (error) {
      console.error('Error inserting reports:', error);
    } else {
      console.log('Sample reports added successfully:', insertedReports);
      // Refresh the page to see the changes
      window.location.reload();
    }
    
  } catch (error) {
    console.error('Error:', error);
  }
}

// Run the function
addSampleReports();
