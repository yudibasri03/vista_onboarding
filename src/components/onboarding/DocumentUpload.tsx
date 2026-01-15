import { useState, useEffect } from 'react';
import { supabase } from '../../lib/supabase';
import { Document } from '../../types';
import { Upload, FileText, CheckCircle, XCircle, Clock } from 'lucide-react';

interface DocumentUploadProps {
  clientId: string;
}

const REQUIRED_DOCUMENTS = [
  { type: 'npwp', label: 'NPWP Perusahaan' },
  { type: 'siup', label: 'SIUP' },
  { type: 'nib', label: 'NIB' },
];

export function DocumentUpload({ clientId }: DocumentUploadProps) {
  const [documents, setDocuments] = useState<Document[]>([]);
  const [uploading, setUploading] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDocuments();
  }, [clientId]);

  const fetchDocuments = async () => {
    try {
      const { data, error } = await supabase
        .from('documents')
        .select('*')
        .eq('client_id', clientId)
        .order('uploaded_at', { ascending: false });

      if (error) throw error;

      setDocuments(data || []);
    } catch (error) {
      console.error('Error fetching documents:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleFileUpload = async (documentType: string, file: File) => {
    setUploading(documentType);

    try {
      const fileExt = file.name.split('.').pop();
      const fileName = `${clientId}/${documentType}-${Date.now()}.${fileExt}`;
      const fileUrl = `https://placeholder.com/documents/${fileName}`;

      const { error } = await supabase.from('documents').insert({
        client_id: clientId,
        document_type: documentType,
        file_name: file.name,
        file_url: fileUrl,
        status: 'pending',
      });

      if (error) throw error;

      await fetchDocuments();
    } catch (error) {
      console.error('Error uploading document:', error);
      alert('Gagal mengupload dokumen. Silakan coba lagi.');
    } finally {
      setUploading(null);
    }
  };

  const getDocumentStatus = (type: string) => {
    return documents.find(doc => doc.document_type === type);
  };

  const getStatusIcon = (status?: string) => {
    switch (status) {
      case 'verified':
        return <CheckCircle className="w-5 h-5 text-emerald-400" />;
      case 'rejected':
        return <XCircle className="w-5 h-5 text-red-400" />;
      case 'pending':
        return <Clock className="w-5 h-5 text-amber-400" />;
      default:
        return <FileText className="w-5 h-5 text-slate-500" />;
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-amber-500"></div>
      </div>
    );
  }

  return (
    <div className="bg-gradient-to-br from-slate-800/50 to-slate-900/50 backdrop-blur-sm rounded-2xl shadow-xl border border-slate-700/50 p-6">
      <h3 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
        <FileText className="w-6 h-6 text-amber-400" />
        Upload Dokumen Persyaratan
      </h3>

      <div className="space-y-4">
        {REQUIRED_DOCUMENTS.map(({ type, label }) => {
          const doc = getDocumentStatus(type);
          return (
            <div key={type} className="border border-slate-600/50 rounded-xl p-5 bg-slate-900/30 backdrop-blur-sm hover:border-amber-500/50 transition-all duration-300">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                    doc?.status === 'verified' ? 'bg-emerald-500/20' :
                    doc?.status === 'rejected' ? 'bg-red-500/20' :
                    doc?.status === 'pending' ? 'bg-amber-500/20' :
                    'bg-slate-700/50'
                  }`}>
                    {getStatusIcon(doc?.status)}
                  </div>
                  <span className="font-semibold text-white">{label}</span>
                </div>
                {doc && (
                  <span className={`px-3 py-1.5 rounded-lg text-xs font-bold ${
                    doc.status === 'verified' ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30' :
                    doc.status === 'rejected' ? 'bg-red-500/20 text-red-400 border border-red-500/30' :
                    'bg-amber-500/20 text-amber-400 border border-amber-500/30'
                  }`}>
                    {doc.status === 'verified' ? 'Terverifikasi' :
                     doc.status === 'rejected' ? 'Ditolak' :
                     'Menunggu Verifikasi'}
                  </span>
                )}
              </div>

              {doc ? (
                <div className="bg-slate-800/50 rounded-lg p-4 border border-slate-700/50">
                  <p className="text-sm text-slate-300">
                    <span className="font-semibold text-white">File:</span> {doc.file_name}
                  </p>
                  <p className="text-xs text-slate-400 mt-1">
                    Diupload: {new Date(doc.uploaded_at).toLocaleDateString('id-ID')}
                  </p>
                  {doc.status === 'rejected' && (
                    <label className="mt-3 inline-block">
                      <input
                        type="file"
                        className="hidden"
                        accept=".pdf,.jpg,.jpeg,.png"
                        onChange={(e) => {
                          const file = e.target.files?.[0];
                          if (file) handleFileUpload(type, file);
                        }}
                        disabled={uploading === type}
                      />
                      <span className="cursor-pointer text-sm text-amber-400 hover:text-amber-300 font-semibold flex items-center gap-2 transition-colors">
                        <Upload className="w-4 h-4" />
                        Upload Ulang
                      </span>
                    </label>
                  )}
                </div>
              ) : (
                <label className="group flex items-center justify-center border-2 border-dashed border-slate-600/50 rounded-xl p-6 cursor-pointer hover:border-amber-500/50 hover:bg-amber-500/5 transition-all duration-300">
                  <input
                    type="file"
                    className="hidden"
                    accept=".pdf,.jpg,.jpeg,.png"
                    onChange={(e) => {
                      const file = e.target.files?.[0];
                      if (file) handleFileUpload(type, file);
                    }}
                    disabled={uploading === type}
                  />
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-slate-700/50 rounded-lg flex items-center justify-center group-hover:bg-amber-500/20 transition-colors">
                      <Upload className="w-5 h-5 text-slate-400 group-hover:text-amber-400 transition-colors" />
                    </div>
                    <span className="text-sm text-slate-300 group-hover:text-amber-300 font-medium transition-colors">
                      {uploading === type ? 'Mengupload...' : 'Klik untuk upload file'}
                    </span>
                  </div>
                </label>
              )}
            </div>
          );
        })}
      </div>

      <div className="mt-6 p-4 bg-gradient-to-r from-amber-500/10 to-yellow-500/10 border border-amber-500/30 rounded-xl">
        <p className="text-sm text-slate-300">
          <span className="font-semibold text-amber-400">Catatan:</span> Format file yang diterima: PDF, JPG, JPEG, PNG. Maksimal ukuran file: 5MB
        </p>
      </div>
    </div>
  );
}
