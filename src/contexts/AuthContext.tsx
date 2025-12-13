import { createContext, useEffect, useState, ReactNode } from 'react';
import { User, Session } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';

interface AuthContextType {
  user: User | null;
  session: Session | null;
  loading: boolean;
  userRole: 'admin' | 'client' | null;
  isAdmin: boolean;
  mustChangePassword: boolean;
  signUp: (email: string, password: string, userData: { pic_name: string; company_name: string }) => Promise<void>;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  changePassword: (newPassword: string) => Promise<void>;
}

export const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const [userRole, setUserRole] = useState<'admin' | 'client' | null>(null);
  const [mustChangePassword, setMustChangePassword] = useState(false);

  const fetchUserRole = async (userId: string) => {
    try {
      const { data, error } = await supabase
        .from('user_roles')
        .select('role, must_change_password')
        .eq('user_id', userId)
        .maybeSingle();

      if (error) throw error;
      setUserRole(data?.role || 'client');
      setMustChangePassword(data?.must_change_password || false);
    } catch (error) {
      console.error('Error fetching user role:', error);
      setUserRole('client');
      setMustChangePassword(false);
    }
  };

  useEffect(() => {
    supabase.auth.getSession().then(async ({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);

      if (session?.user) {
        await fetchUserRole(session.user.id);
      }

      setLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      (async () => {
        setSession(session);
        setUser(session?.user ?? null);

        if (session?.user) {
          await fetchUserRole(session.user.id);
        } else {
          setUserRole(null);
        }
      })();
    });

    return () => subscription.unsubscribe();
  }, []);

  const signUp = async (email: string, password: string, userData: { pic_name: string; company_name: string }) => {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          pic_name: userData.pic_name,
          company_name: userData.company_name,
        },
      },
    });

    if (error) throw error;

    if (data.user) {
      setUser(data.user);
      setSession(data.session);
    }
  };

  const signIn = async (email: string, password: string) => {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) throw error;

    setUser(data.user);
    setSession(data.session);
  };

  const signOut = async () => {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;

    setUser(null);
    setSession(null);
  };

  const changePassword = async (newPassword: string) => {
    const { error } = await supabase.auth.updateUser({
      password: newPassword,
    });

    if (error) throw error;

    if (user) {
      await supabase
        .from('user_roles')
        .update({
          must_change_password: false,
          last_password_change: new Date().toISOString(),
        })
        .eq('user_id', user.id);

      setMustChangePassword(false);
    }
  };

  const value = {
    user,
    session,
    loading,
    userRole,
    isAdmin: userRole === 'admin',
    mustChangePassword,
    signUp,
    signIn,
    signOut,
    changePassword,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
