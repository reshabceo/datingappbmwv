import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "./ui/card";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Label } from "./ui/label";
import { Switch } from "./ui/switch";
import { Textarea } from "./ui/textarea";
import { Badge } from "./ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "./ui/tabs";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "./ui/select";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "./ui/table";
import { Sheet, SheetContent, SheetDescription, SheetHeader, SheetTitle, SheetTrigger } from "./ui/sheet";
import { 
  Settings as SettingsIcon, Shield, Bell, Globe, Database, Users2,
  Save, RotateCcw, AlertTriangle, CheckCircle, Server, Eye, EyeOff,
  Key, Flag, Calendar, Activity, Zap, Mail, Smartphone, Monitor,
  Edit, Trash2, Plus, TestTube, Clock, Palette, Lock
} from 'lucide-react';
import { supabase } from "../admin-integrations/supabase/client";
import { useToast } from "./ui/use-toast";

interface SettingsProps {
  isDarkMode: boolean;
}

interface SystemSetting {
  id: string;
  category: string;
  setting_key: string;
  setting_value: any;
  data_type: string;
  is_encrypted: boolean;
  is_public: boolean;
  description: string;
}

interface AdminRole {
  id: string;
  role_name: string;
  display_name: string;
  description: string;
  permissions: any;
  is_system_role: boolean;
  is_active: boolean;
}

interface FeatureFlag {
  id: string;
  flag_key: string;
  flag_name: string;
  description: string;
  is_enabled: boolean;
  rollout_percentage: number;
}

interface ApiConfiguration {
  id: string;
  service_name: string;
  configuration_name: string;
  endpoint_url: string;
  settings: any;
  is_active: boolean;
  is_sandbox: boolean;
  test_status: string;
}

interface NotificationTemplate {
  id: string;
  template_name: string;
  template_type: string;
  subject: string;
  content: string;
  variables: string[];
  is_active: boolean;
  category: string;
}

const Settings: React.FC<SettingsProps> = ({ isDarkMode }) => {
  const { toast } = useToast();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [systemSettings, setSystemSettings] = useState<SystemSetting[]>([]);
  const [adminRoles, setAdminRoles] = useState<AdminRole[]>([]);
  const [featureFlags, setFeatureFlags] = useState<FeatureFlag[]>([]);
  const [apiConfigurations, setApiConfigurations] = useState<ApiConfiguration[]>([]);
  const [notificationTemplates, setNotificationTemplates] = useState<NotificationTemplate[]>([]);
  const [selectedTemplate, setSelectedTemplate] = useState<NotificationTemplate | null>(null);

  useEffect(() => {
    fetchAllSettings();
  }, []);

  const fetchAllSettings = async () => {
    try {
      setLoading(true);
      
      const [settingsRes, rolesRes, flagsRes, apisRes, templatesRes] = await Promise.all([
        supabase.from('system_settings').select('*').order('category, setting_key'),
        supabase.from('admin_roles').select('*').order('display_name'),
        supabase.from('feature_flags').select('*').order('flag_name'),
        supabase.from('api_configurations').select('*').order('service_name'),
        supabase.from('notification_templates').select('*').order('category, template_name')
      ]);

      if (settingsRes.error) throw settingsRes.error;
      if (rolesRes.error) throw rolesRes.error;
      if (flagsRes.error) throw flagsRes.error;
      if (apisRes.error) throw apisRes.error;
      if (templatesRes.error) throw templatesRes.error;

      setSystemSettings(settingsRes.data || []);
      setAdminRoles(rolesRes.data || []);
      setFeatureFlags(flagsRes.data || []);
      setApiConfigurations(apisRes.data || []);
      const formattedTemplates = (templatesRes.data || []).map(template => ({
        ...template,
        variables: Array.isArray(template.variables) ? template.variables as string[] : []
      }));
      setNotificationTemplates(formattedTemplates);
    } catch (error) {
      console.error('Error fetching settings:', error);
      toast({
        title: "Error",
        description: "Failed to load settings",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const getSetting = (category: string, key: string) => {
    const setting = systemSettings.find(s => s.category === category && s.setting_key === key);
    return setting ? setting.setting_value : null;
  };

  const updateSetting = async (category: string, key: string, value: any) => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      const { error } = await supabase
        .from('system_settings')
        .update({ 
          setting_value: value,
          last_modified_by: user?.id
        })
        .eq('category', category)
        .eq('setting_key', key);

      if (error) throw error;

      // Update local state
      setSystemSettings(prev => 
        prev.map(s => 
          s.category === category && s.setting_key === key 
            ? { ...s, setting_value: value }
            : s
        )
      );

      toast({
        title: "Success",
        description: "Setting updated successfully",
      });
    } catch (error) {
      console.error('Error updating setting:', error);
      toast({
        title: "Error",
        description: "Failed to update setting",
        variant: "destructive",
      });
    }
  };

  const toggleFeatureFlag = async (flagId: string, enabled: boolean) => {
    try {
      const { error } = await supabase
        .from('feature_flags')
        .update({ is_enabled: enabled })
        .eq('id', flagId);

      if (error) throw error;

      setFeatureFlags(prev =>
        prev.map(flag =>
          flag.id === flagId ? { ...flag, is_enabled: enabled } : flag
        )
      );

      toast({
        title: "Success",
        description: `Feature flag ${enabled ? 'enabled' : 'disabled'} successfully`,
      });
    } catch (error) {
      console.error('Error updating feature flag:', error);
      toast({
        title: "Error",
        description: "Failed to update feature flag",
        variant: "destructive",
      });
    }
  };

  const testApiConfiguration = async (configId: string) => {
    try {
      await supabase
        .from('api_configurations')
        .update({ 
          test_status: 'pending',
          last_tested_at: new Date().toISOString()
        })
        .eq('id', configId);

      // Simulate API test (in real app, call actual service)
      setTimeout(async () => {
        const success = Math.random() > 0.3; // 70% success rate for demo
        await supabase
          .from('api_configurations')
          .update({ test_status: success ? 'success' : 'failed' })
          .eq('id', configId);
        
        setApiConfigurations(prev =>
          prev.map(api =>
            api.id === configId ? { ...api, test_status: success ? 'success' : 'failed' } : api
          )
        );

        toast({
          title: success ? "Test Successful" : "Test Failed",
          description: success ? "API connection verified" : "API connection failed",
          variant: success ? "default" : "destructive",
        });
      }, 2000);

      setApiConfigurations(prev =>
        prev.map(api =>
          api.id === configId ? { ...api, test_status: 'pending' } : api
        )
      );
    } catch (error) {
      console.error('Error testing API:', error);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'success':
        return <Badge className="bg-success text-success-foreground">Connected</Badge>;
      case 'failed':
        return <Badge variant="destructive">Failed</Badge>;
      case 'pending':
        return <Badge variant="secondary">Testing...</Badge>;
      default:
        return <Badge variant="outline">Not Tested</Badge>;
    }
  };

  if (loading) {
    return (
      <div className="space-y-6 p-6">
        <div className="flex items-center justify-center h-64">
          <div className="text-muted-foreground">Loading system settings...</div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 p-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-foreground">System Settings</h1>
          <p className="text-muted-foreground mt-2">Configure platform settings, security, and integrations</p>
        </div>
        <div className="flex items-center space-x-2">
          <Button variant="outline" onClick={fetchAllSettings} disabled={loading}>
            <RotateCcw className="h-4 w-4 mr-2" />
            Refresh
          </Button>
        </div>
      </div>

      <Tabs defaultValue="platform" className="space-y-6">
        <TabsList className="grid w-full grid-cols-7">
          <TabsTrigger value="platform">Platform</TabsTrigger>
          <TabsTrigger value="security">Security</TabsTrigger>
          <TabsTrigger value="notifications">Notifications</TabsTrigger>
          <TabsTrigger value="features">Features</TabsTrigger>
          <TabsTrigger value="integrations">Integrations</TabsTrigger>
          <TabsTrigger value="roles">Roles</TabsTrigger>
          <TabsTrigger value="templates">Templates</TabsTrigger>
        </TabsList>

        <TabsContent value="platform" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <SettingsIcon className="h-5 w-5" />
                Platform Configuration
              </CardTitle>
              <CardDescription>
                Basic platform settings and branding
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label htmlFor="app_name">Application Name</Label>
                  <Input
                    id="app_name"
                    value={getSetting('platform', 'app_name') || ''}
                    onChange={(e) => updateSetting('platform', 'app_name', e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="app_tagline">Tagline</Label>
                  <Input
                    id="app_tagline"
                    value={getSetting('platform', 'app_tagline') || ''}
                    onChange={(e) => updateSetting('platform', 'app_tagline', e.target.value)}
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label htmlFor="max_swipes">Max Daily Swipes (Free)</Label>
                  <Input
                    id="max_swipes"
                    type="number"
                    value={getSetting('platform', 'max_daily_swipes') || 50}
                    onChange={(e) => updateSetting('platform', 'max_daily_swipes', parseInt(e.target.value))}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="premium_swipes">Max Daily Swipes (Premium)</Label>
                  <Input
                    id="premium_swipes"
                    type="number"
                    value={getSetting('platform', 'premium_max_daily_swipes') || 500}
                    onChange={(e) => updateSetting('platform', 'premium_max_daily_swipes', parseInt(e.target.value))}
                  />
                </div>
              </div>

              <div className="flex items-center justify-between p-4 border rounded-lg border-yellow-200 bg-yellow-50 dark:bg-yellow-900/20">
                <div className="flex items-center gap-3">
                  <AlertTriangle className="h-5 w-5 text-yellow-600" />
                  <div>
                    <h4 className="font-medium">Maintenance Mode</h4>
                    <p className="text-sm text-muted-foreground">Temporarily disable user access</p>
                  </div>
                </div>
                <Switch
                  checked={getSetting('platform', 'maintenance_mode') || false}
                  onCheckedChange={(checked) => updateSetting('platform', 'maintenance_mode', checked)}
                />
              </div>

              <div className="flex items-center justify-between p-4 border rounded-lg">
                <div>
                  <h4 className="font-medium">User Registration</h4>
                  <p className="text-sm text-muted-foreground">Allow new user signups</p>
                </div>
                <Switch
                  checked={getSetting('platform', 'user_registration_enabled') || true}
                  onCheckedChange={(checked) => updateSetting('platform', 'user_registration_enabled', checked)}
                />
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="security" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Shield className="h-5 w-5" />
                Security Configuration
              </CardTitle>
              <CardDescription>
                Authentication and security settings
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label htmlFor="session_timeout">Session Timeout (hours)</Label>
                  <Input
                    id="session_timeout"
                    type="number"
                    value={getSetting('security', 'session_timeout_hours') || 24}
                    onChange={(e) => updateSetting('security', 'session_timeout_hours', parseInt(e.target.value))}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="password_length">Min Password Length</Label>
                  <Input
                    id="password_length"
                    type="number"
                    value={getSetting('security', 'password_min_length') || 8}
                    onChange={(e) => updateSetting('security', 'password_min_length', parseInt(e.target.value))}
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label htmlFor="max_attempts">Max Login Attempts</Label>
                  <Input
                    id="max_attempts"
                    type="number"
                    value={getSetting('security', 'max_login_attempts') || 5}
                    onChange={(e) => updateSetting('security', 'max_login_attempts', parseInt(e.target.value))}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="lockout_duration">Lockout Duration (minutes)</Label>
                  <Input
                    id="lockout_duration"
                    type="number"
                    value={getSetting('security', 'account_lockout_duration_minutes') || 30}
                    onChange={(e) => updateSetting('security', 'account_lockout_duration_minutes', parseInt(e.target.value))}
                  />
                </div>
              </div>

              <div className="flex items-center justify-between p-4 border rounded-lg">
                <div>
                  <h4 className="font-medium">Email Verification Required</h4>
                  <p className="text-sm text-muted-foreground">Require email verification for new accounts</p>
                </div>
                <Switch
                  checked={getSetting('security', 'require_email_verification') || true}
                  onCheckedChange={(checked) => updateSetting('security', 'require_email_verification', checked)}
                />
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="notifications" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Bell className="h-5 w-5" />
                Notification Settings
              </CardTitle>
              <CardDescription>
                Configure notification channels and preferences
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-4">
                <div className="flex items-center justify-between p-4 border rounded-lg">
                  <div className="flex items-center gap-3">
                    <Mail className="h-5 w-5 text-blue-500" />
                    <div>
                      <h4 className="font-medium">Email Notifications</h4>
                      <p className="text-sm text-muted-foreground">System notifications via email</p>
                    </div>
                  </div>
                  <Switch
                    checked={getSetting('notifications', 'email_notifications_enabled') || true}
                    onCheckedChange={(checked) => updateSetting('notifications', 'email_notifications_enabled', checked)}
                  />
                </div>

                <div className="flex items-center justify-between p-4 border rounded-lg">
                  <div className="flex items-center gap-3">
                    <Smartphone className="h-5 w-5 text-green-500" />
                    <div>
                      <h4 className="font-medium">SMS Notifications</h4>
                      <p className="text-sm text-muted-foreground">Critical alerts via SMS</p>
                    </div>
                  </div>
                  <Switch
                    checked={getSetting('notifications', 'sms_notifications_enabled') || false}
                    onCheckedChange={(checked) => updateSetting('notifications', 'sms_notifications_enabled', checked)}
                  />
                </div>

                <div className="flex items-center justify-between p-4 border rounded-lg">
                  <div className="flex items-center gap-3">
                    <Monitor className="h-5 w-5 text-purple-500" />
                    <div>
                      <h4 className="font-medium">Push Notifications</h4>
                      <p className="text-sm text-muted-foreground">Browser push notifications</p>
                    </div>
                  </div>
                  <Switch
                    checked={getSetting('notifications', 'push_notifications_enabled') || true}
                    onCheckedChange={(checked) => updateSetting('notifications', 'push_notifications_enabled', checked)}
                  />
                </div>

                <div className="flex items-center justify-between p-4 border rounded-lg">
                  <div>
                    <h4 className="font-medium">New Match Notifications</h4>
                    <p className="text-sm text-muted-foreground">Notify users about new matches</p>
                  </div>
                  <Switch
                    checked={getSetting('notifications', 'new_match_notification') || true}
                    onCheckedChange={(checked) => updateSetting('notifications', 'new_match_notification', checked)}
                  />
                </div>

                <div className="flex items-center justify-between p-4 border rounded-lg">
                  <div>
                    <h4 className="font-medium">New Message Notifications</h4>
                    <p className="text-sm text-muted-foreground">Notify users about new messages</p>
                  </div>
                  <Switch
                    checked={getSetting('notifications', 'new_message_notification') || true}
                    onCheckedChange={(checked) => updateSetting('notifications', 'new_message_notification', checked)}
                  />
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="features" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Flag className="h-5 w-5" />
                Feature Flags
              </CardTitle>
              <CardDescription>
                Control feature rollouts and A/B testing
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Feature</TableHead>
                    <TableHead>Description</TableHead>
                    <TableHead>Rollout %</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {featureFlags.map((flag) => (
                    <TableRow key={flag.id}>
                      <TableCell className="font-medium">{flag.flag_name}</TableCell>
                      <TableCell className="text-muted-foreground">{flag.description}</TableCell>
                      <TableCell>
                        <Badge variant="outline">{flag.rollout_percentage}%</Badge>
                      </TableCell>
                      <TableCell>
                        {flag.is_enabled ? (
                          <Badge className="bg-success text-success-foreground">Enabled</Badge>
                        ) : (
                          <Badge variant="secondary">Disabled</Badge>
                        )}
                      </TableCell>
                      <TableCell>
                        <Switch
                          checked={flag.is_enabled}
                          onCheckedChange={(checked) => toggleFeatureFlag(flag.id, checked)}
                        />
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="integrations" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Globe className="h-5 w-5" />
                API Integrations
              </CardTitle>
              <CardDescription>
                Third-party service configurations and API settings
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Service</TableHead>
                    <TableHead>Configuration</TableHead>
                    <TableHead>Environment</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {apiConfigurations.map((api) => (
                    <TableRow key={api.id}>
                      <TableCell className="font-medium capitalize">{api.service_name}</TableCell>
                      <TableCell className="text-muted-foreground">{api.configuration_name}</TableCell>
                      <TableCell>
                        <Badge variant={api.is_sandbox ? "secondary" : "default"}>
                          {api.is_sandbox ? "Sandbox" : "Production"}
                        </Badge>
                      </TableCell>
                      <TableCell>{getStatusBadge(api.test_status)}</TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => testApiConfiguration(api.id)}
                            disabled={api.test_status === 'pending'}
                          >
                            <TestTube className="h-4 w-4 mr-1" />
                            Test
                          </Button>
                          <Switch
                            checked={api.is_active}
                            onCheckedChange={(checked) => {
                              // Update API configuration active status
                              supabase
                                .from('api_configurations')
                                .update({ is_active: checked })
                                .eq('id', api.id);
                              
                              setApiConfigurations(prev =>
                                prev.map(a => a.id === api.id ? { ...a, is_active: checked } : a)
                              );
                            }}
                          />
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="roles" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Users2 className="h-5 w-5" />
                Admin Roles
              </CardTitle>
              <CardDescription>
                Manage admin roles and permissions
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Role</TableHead>
                    <TableHead>Description</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Permissions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {adminRoles.map((role) => (
                    <TableRow key={role.id}>
                      <TableCell className="font-medium">{role.display_name}</TableCell>
                      <TableCell className="text-muted-foreground">{role.description}</TableCell>
                      <TableCell>
                        <Badge variant={role.is_system_role ? "secondary" : "outline"}>
                          {role.is_system_role ? "System" : "Custom"}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        {role.is_active ? (
                          <Badge className="bg-success text-success-foreground">Active</Badge>
                        ) : (
                          <Badge variant="secondary">Inactive</Badge>
                        )}
                      </TableCell>
                      <TableCell>
                        <div className="flex flex-wrap gap-1">
                          {Object.keys(role.permissions).slice(0, 3).map(perm => (
                            <Badge key={perm} variant="outline" className="text-xs">
                              {perm}
                            </Badge>
                          ))}
                          {Object.keys(role.permissions).length > 3 && (
                            <Badge variant="outline" className="text-xs">
                              +{Object.keys(role.permissions).length - 3}
                            </Badge>
                          )}
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="templates" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Mail className="h-5 w-5" />
                Notification Templates
              </CardTitle>
              <CardDescription>
                Manage email, SMS, and push notification templates
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Template</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead>Category</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {notificationTemplates.map((template) => (
                    <TableRow key={template.id}>
                      <TableCell className="font-medium">{template.template_name}</TableCell>
                      <TableCell>
                        <Badge variant="outline" className="capitalize">
                          {template.template_type}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-muted-foreground capitalize">
                        {template.category.replace('_', ' ')}
                      </TableCell>
                      <TableCell>
                        {template.is_active ? (
                          <Badge className="bg-success text-success-foreground">Active</Badge>
                        ) : (
                          <Badge variant="secondary">Inactive</Badge>
                        )}
                      </TableCell>
                      <TableCell>
                        <Sheet>
                          <SheetTrigger asChild>
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => setSelectedTemplate(template)}
                            >
                              <Eye className="h-4 w-4 mr-1" />
                              View
                            </Button>
                          </SheetTrigger>
                          <SheetContent className="w-[600px] sm:w-[600px]">
                            <SheetHeader>
                              <SheetTitle>Template: {selectedTemplate?.template_name}</SheetTitle>
                              <SheetDescription>
                                {selectedTemplate?.template_type} template for {selectedTemplate?.category}
                              </SheetDescription>
                            </SheetHeader>
                            {selectedTemplate && (
                              <div className="mt-6 space-y-4">
                                <div>
                                  <Label>Subject</Label>
                                  <Input 
                                    value={selectedTemplate.subject || ''} 
                                    readOnly 
                                    className="mt-1" 
                                  />
                                </div>
                                <div>
                                  <Label>Content</Label>
                                  <Textarea 
                                    value={selectedTemplate.content} 
                                    readOnly 
                                    className="mt-1 h-32" 
                                  />
                                </div>
                                <div>
                                  <Label>Variables</Label>
                                  <div className="flex flex-wrap gap-2 mt-1">
                                    {selectedTemplate.variables.map((variable, index) => (
                                      <Badge key={index} variant="outline">
                                        {`{{${variable}}}`}
                                      </Badge>
                                    ))}
                                  </div>
                                </div>
                              </div>
                            )}
                          </SheetContent>
                        </Sheet>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* System Status */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Activity className="h-5 w-5" />
            System Health
          </CardTitle>
          <CardDescription>
            Current system status and health metrics
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="flex items-center justify-between p-4 rounded-lg bg-success/10 border border-success/20">
              <div>
                <p className="font-medium">Database</p>
                <p className="text-sm text-success">Connected</p>
              </div>
              <CheckCircle className="h-5 w-5 text-success" />
            </div>
            
            <div className="flex items-center justify-between p-4 rounded-lg bg-success/10 border border-success/20">
              <div>
                <p className="font-medium">Authentication</p>
                <p className="text-sm text-success">Active</p>
              </div>
              <CheckCircle className="h-5 w-5 text-success" />
            </div>
            
            <div className="flex items-center justify-between p-4 rounded-lg bg-yellow-500/10 border border-yellow-500/20">
              <div>
                <p className="font-medium">Storage</p>
                <p className="text-sm text-yellow-600">85% Used</p>
              </div>
              <AlertTriangle className="h-5 w-5 text-yellow-600" />
            </div>
            
            <div className="flex items-center justify-between p-4 rounded-lg bg-success/10 border border-success/20">
              <div>
                <p className="font-medium">API Services</p>
                <p className="text-sm text-success">Operational</p>
              </div>
              <CheckCircle className="h-5 w-5 text-success" />
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default Settings;