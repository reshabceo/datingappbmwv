
import React, { useState } from 'react';
import { supabase } from '../admin-integrations/supabase/client';
import { toast } from 'sonner';

interface AdminLoginProps {
  onLogin: (adminData: { id: string; email: string; full_name: string; role: string }) => void;
  preFilledEmail?: string;
}

const AdminLogin: React.FC<AdminLoginProps> = ({ onLogin, preFilledEmail = '' }) => {
  const [credentials, setCredentials] = useState({
    username: preFilledEmail,
    password: ''
  });
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    
    try {
      console.log('=== ADMIN LOGIN DEBUG ===');
      console.log('Attempting admin login with:', credentials.username);
      
      // Simple admin authentication - check credentials directly
      if (credentials.username === 'admin@datingapp.com' && credentials.password === 'admin123') {
        console.log('✅ Admin credentials verified');
        
        // Create admin user data for the session
        const adminUser = {
          id: 'admin-user-id',
          email: credentials.username,
          full_name: 'Admin User',
          role: 'admin'
        };

        // Store admin session in localStorage
        localStorage.setItem('adminSession', JSON.stringify({
          ...adminUser,
          loginTime: new Date().toISOString()
        }));

        onLogin(adminUser);
        toast.success('Login successful!');
        console.log('=== END ADMIN LOGIN DEBUG ===');
      } else {
        console.error('Invalid admin credentials');
        toast.error('Invalid admin credentials');
      }
    } catch (error) {
      console.error('Login error:', error);
      toast.error('Login failed. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleInputChange = (field: string) => (e: React.ChangeEvent<HTMLInputElement>) => {
    setCredentials(prev => ({
      ...prev,
      [field]: e.target.value
    }));
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="rounded-2xl p-8 bg-gradient-card-pink border border-pink-30 backdrop-blur-md shadow-card-soft">
          <div className="text-center mb-8">
            <img src="/assets/images/logolight.png" alt="Logo" className="h-12 w-auto mx-auto mb-4" />
            <h2 className="text-3xl font-bold text-white mb-2">Admin Login</h2>
            <p className="text-light-white">Sign in to access the admin dashboard</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <input
                className="w-full px-4 py-3 bg-white/90 border border-border-black-10 rounded-xl focus:outline-none focus:ring-2 focus:ring-secondary focus:border-transparent transition-all"
                type="email"
                placeholder="Enter your email"
                value={credentials.username}
                onChange={handleInputChange('username')}
                required
              />
            </div>
            <div>
              <input
                type={showPassword ? 'text' : 'password'}
                className="w-full px-4 py-3 bg-white/90 border border-border-black-10 rounded-xl focus:outline-none focus:ring-2 focus:ring-secondary focus:border-transparent transition-all"
                placeholder="Enter your password"
                value={credentials.password}
                onChange={handleInputChange('password')}
                required
              />
            </div>
            <button
              type="submit"
              className="w-full bg-gradient-cta text-white px-6 py-3 rounded-full font-semibold hover:shadow-lg transform hover:scale-105 transition-all duration-200 disabled:opacity-50 disabled:transform-none"
              disabled={isLoading}
            >
              {isLoading ? 'Signing in...' : 'Sign In'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default AdminLogin;
