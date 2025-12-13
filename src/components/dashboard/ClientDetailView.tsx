import { useState, useEffect } from 'react';
import {
  X, User, Mail, Phone, Briefcase, MapPin, FileText, Shield,
  CheckCircle, XCircle, Clock, Calendar, ExternalLink, Download
} from 'lucide-react';
import { supabase } from '../../lib/supabase';

interface ClientDetailViewProps {
  clientId: string;
  onClose: () => void;
  onUpdate: () => void;
}

interface ClientData {
  id: string;
  full_name: string;
  email: string;
  whatsapp: string;
  occupation: string;
  position: string;
  address: string;
  ktp_url: string;
  product_type: 'ea_trading' | 'bimbel_prop' | 'vip_membership';
  product_config: any;
  risk_profile: 'aggressive' | 'moderate' | 'conservative' | null;
  status: string;
  consent_data_accuracy: boolean;
  consent_risk_understanding: boolean;
  consent_verification_process: boolean;
  registration_completed_at: string;
  created_at: string;
}

interface KYCReview {
  id: string;
  status: 'pending' | 'verified' | 'rejected';
  notes: string | null;
  reviewed_at: string | null;
}

interface AuditLog {
  id: string;
  action: string;
  details: any;
  created_at: string;
  admin_email: string;
}

export function ClientDetailView({ clientId, onClose, onUpdate }: ClientDetailViewProps) {
  const [client, setClient] = useState<ClientData | null>(null);
  const [kycReview, setKycReview] = useState<KYCReview | null>(null);
  const [auditLogs, setAuditLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [kycNotes, setKycNotes] = useState('');
  const [showApprovalConfirm, setShowApprovalConfirm] = useState(false);
  const [showRejectConfirm, setShowRejectConfirm] = useState(false);

  useEffect(() => {
    loadClientData();
  }, [clientId]);

  const loadClientData = async () => {
    try {
      const { data: clientData, error: clientError } = await supabase
        .from('clients')
        .select('*')
        .eq('id', clientId)
        .single();

      if (clientError) throw clientError;
      setClient(clientData);

      const { data: kycData } = await supabase
        .from('kyc_reviews')
        .select('*')
        .eq('client_id', clientId)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

      setKycReview(kycData);
      if (kycData?.notes) setKycNotes(kycData.notes);

      const { data: logsData } = await supabase
        .from('audit_logs')
        .select(`
          id,
          action,
          details,
          created_at,
          admin:auth.users!audit_logs_admin_id_fkey(email)
        `)
        .eq('client_id', clientId)
        .order('created_at', { ascending: false });

      if (logsData) {
        setAuditLogs(logsData.map(log => ({
          ...log,
          admin_email: log.admin?.email || 'System'
        })));
      }
    } catch (error) {
      console.error('Error loading client data:', error);
    } finally {
      setLoading(false);
    }
  };

  const logAuditAction = async (action: string, details: any = {}) => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      await supabase.from('audit_logs').insert({
        client_id: clientId,
        admin_id: user?.id,
        action,
        details,
        ip_address: 'system',
      });
    } catch (error) {
      console.error('Error logging audit:', error);
    }
  };

  const handleKYCReview = async (status: 'verified' | 'rejected') => {
    setActionLoading(true);
    try {
      const { data: { user } } = await supabase.auth.getUser();

      if (kycReview) {
        await supabase
          .from('kyc_reviews')
          .update({
            status,
            notes: kycNotes,
            reviewed_at: new Date().toISOString(),
          })
          .eq('id', kycReview.id);
      } else {
        await supabase.from('kyc_reviews').insert({
          client_id: clientId,
          reviewer_id: user?.id,
          document_type: 'KTP',
          status,
          notes: kycNotes,
          reviewed_at: new Date().toISOString(),
        });
      }

      await logAuditAction('review_kyc', { status, notes: kycNotes });
      await loadClientData();
    } catch (error) {
      console.error('Error reviewing KYC:', error);
      alert('Terjadi kesalahan saat review KYC');
    } finally {
      setActionLoading(false);
    }
  };

  const handleApprove = async () => {
    setActionLoading(true);
    try {
      await supabase
        .from('clients')
        .update({ status: 'approved' })
        .eq('id', clientId);

      await logAuditAction('approve_client', {
        previous_status: client?.status,
        new_status: 'approved',
      });

      await supabase.from('notifications').insert({
        user_id: client?.user_id,
        title: 'Onboarding Disetujui',
        message: 'Selamat! Onboarding Anda telah disetujui. Tim kami akan segera menghubungi Anda.',
        type: 'success',
      });

      setShowApprovalConfirm(false);
      onUpdate();
      onClose();
    } catch (error) {
      console.error('Error approving client:', error);
      alert('Terjadi kesalahan saat approve client');
    } finally {
      setActionLoading(false);
    }
  };

  const handleReject = async () => {
    setActionLoading(true);
    try {
      await supabase
        .from('clients')
        .update({ status: 'rejected' })
        .eq('id', clientId);

      await logAuditAction('reject_client', {
        previous_status: client?.status,
        new_status: 'rejected',
        reason: kycNotes,
      });

      await supabase.from('notifications').insert({
        user_id: client?.user_id,
        title: 'Onboarding Ditolak',
        message: 'Mohon maaf, onboarding Anda belum dapat disetujui. Silakan hubungi tim kami untuk informasi lebih lanjut.',
        type: 'error',
      });

      setShowRejectConfirm(false);
      onUpdate();
      onClose();
    } catch (error) {
      console.error('Error rejecting client:', error);
      alert('Terjadi kesalahan saat reject client');
    } finally {
      setActionLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
        <div className="bg-white rounded-lg p-8">
          <p>Loading...</p>
        </div>
      </div>
    );
  }

  if (!client) {
    return null;
  }

  const getProductLabel = () => {
    switch (client.product_type) {
      case 'ea_trading': return 'EA Trading';
      case 'bimbel_prop': return 'Kelas Bimbel + Prop Funds';
      case 'vip_membership': return 'VIP Membership';
      default: return '-';
    }
  };

  const getRiskLabel = () => {
    switch (client.risk_profile) {
      case 'aggressive': return 'Agresif';
      case 'moderate': return 'Moderat';
      case 'conservative': return 'Konservatif';
      default: return '-';
    }
  };

  const getStatusBadge = (status: string) => {
    const styles = {
      pending: 'bg-yellow-100 text-yellow-800',
      approved: 'bg-green-100 text-green-800',
      rejected: 'bg-red-100 text-red-800',
      in_review: 'bg-blue-100 text-blue-800',
    };
    return styles[status as keyof typeof styles] || 'bg-gray-100 text-gray-800';
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4 overflow-y-auto">
      <div className="bg-white rounded-xl shadow-2xl max-w-6xl w-full my-8">
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h2 className="text-2xl font-bold text-gray-900">Detail Client</h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X className="h-6 w-6 text-gray-500" />
          </button>
        </div>

        <div className="p-6 max-h-[calc(100vh-200px)] overflow-y-auto">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="space-y-6">
              <div className="bg-white border border-gray-200 rounded-lg p-6">
                <div className="flex items-center gap-2 mb-4">
                  <User className="h-5 w-5 text-blue-600" />
                  <h3 className="text-lg font-semibold text-gray-900">Client Profile</h3>
                </div>

                <div className="space-y-3">
                  <div>
                    <p className="text-sm text-gray-600">Nama Lengkap</p>
                    <p className="font-medium text-gray-900">{client.full_name}</p>
                  </div>

                  <div className="flex items-center gap-2">
                    <Mail className="h-4 w-4 text-gray-400" />
                    <div>
                      <p className="text-sm text-gray-600">Email</p>
                      <p className="font-medium text-gray-900">{client.email}</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <Phone className="h-4 w-4 text-gray-400" />
                    <div>
                      <p className="text-sm text-gray-600">WhatsApp</p>
                      <p className="font-medium text-gray-900">{client.whatsapp}</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <Briefcase className="h-4 w-4 text-gray-400" />
                    <div>
                      <p className="text-sm text-gray-600">Pekerjaan</p>
                      <p className="font-medium text-gray-900">{client.occupation} - {client.position}</p>
                    </div>
                  </div>

                  <div className="flex items-start gap-2">
                    <MapPin className="h-4 w-4 text-gray-400 mt-1" />
                    <div>
                      <p className="text-sm text-gray-600">Alamat</p>
                      <p className="font-medium text-gray-900">{client.address}</p>
                    </div>
                  </div>

                  <div>
                    <p className="text-sm text-gray-600">Status</p>
                    <span className={`inline-block px-3 py-1 rounded-full text-sm font-medium ${getStatusBadge(client.status)}`}>
                      {client.status.toUpperCase()}
                    </span>
                  </div>
                </div>
              </div>

              <div className="bg-white border border-gray-200 rounded-lg p-6">
                <div className="flex items-center gap-2 mb-4">
                  <FileText className="h-5 w-5 text-blue-600" />
                  <h3 className="text-lg font-semibold text-gray-900">KYC Document</h3>
                </div>

                {client.ktp_url ? (
                  <div className="space-y-3">
                    <div className="border border-gray-200 rounded-lg p-4 bg-gray-50">
                      <p className="text-sm font-medium text-gray-700 mb-2">KTP (Kartu Tanda Penduduk)</p>
                      <div className="flex gap-2">
                        <a
                          href={client.ktp_url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-sm"
                        >
                          <ExternalLink className="h-4 w-4" />
                          View Document
                        </a>
                        <a
                          href={client.ktp_url}
                          download
                          className="flex items-center gap-2 px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 text-sm"
                        >
                          <Download className="h-4 w-4" />
                          Download
                        </a>
                      </div>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Status Review
                      </label>
                      <select
                        value={kycReview?.status || 'pending'}
                        disabled={client.status === 'approved'}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                      >
                        <option value="pending">Pending</option>
                        <option value="verified">Verified</option>
                        <option value="rejected">Rejected</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Catatan Compliance
                      </label>
                      <textarea
                        value={kycNotes}
                        onChange={(e) => setKycNotes(e.target.value)}
                        disabled={client.status === 'approved'}
                        rows={3}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 disabled:bg-gray-100"
                        placeholder="Tambahkan catatan review..."
                      />
                    </div>

                    {client.status !== 'approved' && (
                      <div className="flex gap-2">
                        <button
                          onClick={() => handleKYCReview('verified')}
                          disabled={actionLoading}
                          className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
                        >
                          <CheckCircle className="h-4 w-4" />
                          Verify KYC
                        </button>
                        <button
                          onClick={() => handleKYCReview('rejected')}
                          disabled={actionLoading}
                          className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
                        >
                          <XCircle className="h-4 w-4" />
                          Reject KYC
                        </button>
                      </div>
                    )}
                  </div>
                ) : (
                  <p className="text-gray-500">No document uploaded</p>
                )}
              </div>
            </div>

            <div className="space-y-6">
              <div className="bg-white border border-gray-200 rounded-lg p-6">
                <div className="flex items-center gap-2 mb-4">
                  <Shield className="h-5 w-5 text-blue-600" />
                  <h3 className="text-lg font-semibold text-gray-900">Product & Risk Configuration</h3>
                </div>

                <div className="space-y-3">
                  <div>
                    <p className="text-sm text-gray-600">Produk</p>
                    <p className="font-medium text-gray-900">{getProductLabel()}</p>
                  </div>

                  {client.product_type === 'ea_trading' && (
                    <>
                      <div>
                        <p className="text-sm text-gray-600">Jenis EA</p>
                        <p className="font-medium text-gray-900">
                          {client.product_config?.ea_type === 'gold' ? 'Gold EA' : 'Forex EA'}
                        </p>
                      </div>
                      <div>
                        <p className="text-sm text-gray-600">Risk Profile</p>
                        <p className="font-medium text-gray-900">{getRiskLabel()}</p>
                      </div>
                      <div>
                        <p className="text-sm text-gray-600">Maximum Drawdown</p>
                        <p className="font-medium text-gray-900">{client.product_config?.max_drawdown}%</p>
                      </div>
                    </>
                  )}

                  {client.product_type === 'bimbel_prop' && (
                    <div>
                      <p className="text-sm text-gray-600">Tujuan Program</p>
                      <p className="font-medium text-gray-900 capitalize">{client.product_config?.program_goal}</p>
                    </div>
                  )}

                  {client.product_type === 'vip_membership' && (
                    <div>
                      <p className="text-sm text-gray-600">Tujuan VIP Membership</p>
                      <p className="font-medium text-gray-900">{client.product_config?.vip_goal}</p>
                    </div>
                  )}

                  <div className="mt-4 pt-4 border-t border-gray-200">
                    <p className="text-sm font-medium text-gray-700 mb-2">Status Aktivasi</p>
                    {client.status === 'approved' ? (
                      <div className="flex items-center gap-2 text-green-600">
                        <CheckCircle className="h-5 w-5" />
                        <span className="font-medium">Ready for Activation</span>
                      </div>
                    ) : (
                      <div className="flex items-center gap-2 text-yellow-600">
                        <Clock className="h-5 w-5" />
                        <span className="font-medium">Pending Review</span>
                      </div>
                    )}
                  </div>
                </div>
              </div>

              <div className="bg-white border border-gray-200 rounded-lg p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Declaration & Consent</h3>

                <div className="space-y-3">
                  <div className="flex items-center gap-3">
                    {client.consent_data_accuracy ? (
                      <CheckCircle className="h-5 w-5 text-green-600" />
                    ) : (
                      <XCircle className="h-5 w-5 text-red-600" />
                    )}
                    <span className="text-sm text-gray-700">Data Confirmation</span>
                  </div>

                  <div className="flex items-center gap-3">
                    {client.consent_risk_understanding ? (
                      <CheckCircle className="h-5 w-5 text-green-600" />
                    ) : (
                      <XCircle className="h-5 w-5 text-red-600" />
                    )}
                    <span className="text-sm text-gray-700">Risk Disclosure Accepted</span>
                  </div>

                  <div className="flex items-center gap-3">
                    {client.consent_verification_process ? (
                      <CheckCircle className="h-5 w-5 text-green-600" />
                    ) : (
                      <XCircle className="h-5 w-5 text-red-600" />
                    )}
                    <span className="text-sm text-gray-700">Verification Process Agreement</span>
                  </div>

                  <div className="mt-4 pt-4 border-t border-gray-200">
                    <div className="flex items-center gap-2 text-sm text-gray-600">
                      <Calendar className="h-4 w-4" />
                      <span>Registered: {new Date(client.registration_completed_at).toLocaleString('id-ID')}</span>
                    </div>
                  </div>
                </div>
              </div>

              <div className="bg-white border border-gray-200 rounded-lg p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-4">Audit Trail</h3>

                <div className="space-y-2 max-h-64 overflow-y-auto">
                  {auditLogs.length > 0 ? (
                    auditLogs.map((log) => (
                      <div key={log.id} className="text-xs bg-gray-50 p-3 rounded border border-gray-200">
                        <div className="flex justify-between items-start mb-1">
                          <span className="font-medium text-gray-900">{log.action.replace(/_/g, ' ').toUpperCase()}</span>
                          <span className="text-gray-500">{new Date(log.created_at).toLocaleString('id-ID')}</span>
                        </div>
                        <p className="text-gray-600">By: {log.admin_email}</p>
                      </div>
                    ))
                  ) : (
                    <p className="text-sm text-gray-500">No audit logs yet</p>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="flex justify-end gap-3 p-6 border-t border-gray-200 bg-gray-50">
          {client.status === 'pending' && (
            <>
              <button
                onClick={() => setShowRejectConfirm(true)}
                disabled={actionLoading}
                className="px-6 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 font-medium"
              >
                Reject
              </button>
              <button
                onClick={() => setShowApprovalConfirm(true)}
                disabled={actionLoading}
                className="px-6 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 font-medium"
              >
                Approve Onboarding
              </button>
            </>
          )}
          <button
            onClick={onClose}
            className="px-6 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700"
          >
            Close
          </button>
        </div>
      </div>

      {showApprovalConfirm && (
        <div className="fixed inset-0 bg-black bg-opacity-70 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md">
            <h3 className="text-lg font-bold text-gray-900 mb-4">Konfirmasi Approval</h3>
            <p className="text-gray-700 mb-6">
              Apakah Anda yakin ingin approve onboarding client ini? Aksi ini akan mengirimkan notifikasi ke client.
            </p>
            <div className="flex justify-end gap-3">
              <button
                onClick={() => setShowApprovalConfirm(false)}
                className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                Batal
              </button>
              <button
                onClick={handleApprove}
                disabled={actionLoading}
                className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
              >
                {actionLoading ? 'Processing...' : 'Ya, Approve'}
              </button>
            </div>
          </div>
        </div>
      )}

      {showRejectConfirm && (
        <div className="fixed inset-0 bg-black bg-opacity-70 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md">
            <h3 className="text-lg font-bold text-gray-900 mb-4">Konfirmasi Rejection</h3>
            <p className="text-gray-700 mb-6">
              Apakah Anda yakin ingin reject onboarding client ini? Aksi ini akan mengirimkan notifikasi ke client.
            </p>
            <div className="flex justify-end gap-3">
              <button
                onClick={() => setShowRejectConfirm(false)}
                className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
              >
                Batal
              </button>
              <button
                onClick={handleReject}
                disabled={actionLoading}
                className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50"
              >
                {actionLoading ? 'Processing...' : 'Ya, Reject'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
