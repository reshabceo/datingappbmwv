
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
}

const AdminLogin: React.FC<AdminLoginProps> = ({ onLogin }) => {
  const [credentials, setCredentials] = useState({
    username: '',
    password: ''
  });
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    
    try {
      // For demo purposes, check against the sample admin user
      // In production, you'd implement proper password hashing and verification
      const { data: adminUser, error } = await supabase
        .from('admin_users')
        .select('*')
        .eq('email', credentials.username)
        .eq('is_active', true)
        .single();

      if (error || !adminUser) {
        toast.error('Invalid credentials');
        setIsLoading(false);
        return;
      }

      // In a real implementation, verify password hash here
      // For demo, using simple password check
      if (credentials.password === 'admin123') {
        // Update last login
        await supabase
          .from('admin_users')
          .update({ last_login: new Date().toISOString() })
          .eq('id', adminUser.id);

        onLogin({
          id: adminUser.id,
          email: adminUser.email,
          full_name: adminUser.full_name || 'Admin User',
          role: adminUser.role
        });

        toast.success('Login successful!');
      } else {
        toast.error('Invalid credentials');
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
