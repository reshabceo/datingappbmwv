
import React, { useState } from 'react';
import { Heart, Eye, EyeOff, Lock, User } from 'lucide-react';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Label } from './ui/label';
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
      
      // First, try to sign in with Supabase
      const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email: credentials.username,
        password: credentials.password
      });

      console.log('Supabase auth response:', { authData, authError });

      if (authError) {
        console.error('Supabase auth failed:', authError);
        toast.error(`Authentication failed: ${authError.message}`);
        setIsLoading(false);
        return;
      }

      if (!authData.user) {
        console.error('No user returned from Supabase');
        toast.error('Authentication failed: No user returned');
        setIsLoading(false);
        return;
      }

      console.log('✅ Supabase authentication successful');
      console.log('User ID:', authData.user.id);
      console.log('User email:', authData.user.email);

      // Create admin user data for the session
      const adminUser = {
        id: authData.user.id,
        email: authData.user.email || credentials.username,
        full_name: authData.user.user_metadata?.full_name || 'Admin User',
        role: 'admin'
      };

      // Store admin session in localStorage
      localStorage.setItem('adminSession', JSON.stringify({
        ...adminUser,
        loginTime: new Date().toISOString(),
        supabaseSession: authData.session
      }));

      onLogin(adminUser);
      toast.success('Login successful!');
      console.log('=== END ADMIN LOGIN DEBUG ===');
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
    <div className="min-h-screen bg-gradient-to-br from-pink-100 via-purple-50 to-indigo-100 flex items-center justify-center p-4">
      <div className="absolute inset-0 opacity-20" style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23f472b6' fill-opacity='0.1'%3E%3Ccircle cx='7' cy='7' r='7'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`
      }}></div>
      
      <Card className="w-full max-w-md relative backdrop-blur-sm bg-white/90 shadow-2xl border-0">
        <CardHeader className="space-y-4 pb-6">
          <div className="flex justify-center">
            <div className="bg-gradient-to-r from-pink-500 to-purple-600 p-4 rounded-2xl shadow-lg">
              <Heart className="h-8 w-8 text-white fill-white" />
            </div>
          </div>
          <div className="text-center">
            <CardTitle className="text-2xl font-bold bg-gradient-to-r from-pink-600 to-purple-600 bg-clip-text text-transparent">
              Love Bug Admin
            </CardTitle>
            <CardDescription className="text-gray-600 mt-2">
              Sign in to access the admin dashboard
            </CardDescription>
          </div>
        </CardHeader>
        
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="space-y-2">
              <Label htmlFor="username" className="text-sm font-medium text-gray-700">
                Email
              </Label>
              <div className="relative">
                <User className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                  <Input
                   id="username"
                   type="email"
                   placeholder="Enter your email"
                   value={credentials.username}
                   onChange={handleInputChange('username')}
                   className="pl-10 h-12 border-gray-200 focus:border-pink-400 focus:ring-pink-400"
                   required
                 />
              </div>
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="password" className="text-sm font-medium text-gray-700">
                Password
              </Label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                <Input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  placeholder="Enter your password"
                  value={credentials.password}
                  onChange={handleInputChange('password')}
                  className="pl-10 pr-10 h-12 border-gray-200 focus:border-pink-400 focus:ring-pink-400"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400 hover:text-gray-600"
                >
                  {showPassword ? <EyeOff /> : <Eye />}
                </button>
              </div>
            </div>
            
            <Button
              type="submit"
              className="w-full h-12 bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700 text-white font-medium transition-all duration-200 shadow-lg hover:shadow-xl"
              disabled={isLoading}
            >
              {isLoading ? (
                <div className="flex items-center space-x-2">
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                  <span>Signing in...</span>
                </div>
              ) : (
                'Sign In'
              )}
            </Button>
          </form>
          
            <div className="mt-6 text-center">
            <p className="text-xs text-gray-500">
              Demo credentials: admin@datingapp.com / admin123
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default AdminLogin;
