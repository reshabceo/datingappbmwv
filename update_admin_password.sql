-- Update admin password
UPDATE auth.users SET encrypted_password = crypt('NEW_PASSWORD_HERE', gen_salt('bf')) WHERE email = 'admin@datingapp.com';
