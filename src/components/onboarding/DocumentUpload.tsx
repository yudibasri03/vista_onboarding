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
        return <CheckCircle className="w-5 h-5 text-green-500" />;
      case 'rejected':
        return <XCircle className="w-5 h-5 text-red-500" />;
      case 'pending':
        return <Clock className="w-5 h-5 text-yellow-500" />;
      default:
        return <FileText className="w-5 h-5 text-gray-400" />;
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <h3 className="text-xl font-bold text-gray-900 mb-6">Upload Dokumen Persyaratan</h3>

      <div className="space-y-4">
        {REQUIRED_DOCUMENTS.map(({ type, label }) => {
          const doc = getDocumentStatus(type);
          return (
            <div key={type} className="border rounded-lg p-4">
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center">
                  {getStatusIcon(doc?.status)}
                  <span className="ml-3 font-medium text-gray-900">{label}</span>
                </div>
                {doc && (
                  <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                    doc.status === 'verified' ? 'bg-green-100 text-green-800' :
                    doc.status === 'rejected' ? 'bg-red-100 text-red-800' :
                    'bg-yellow-100 text-yellow-800'
                  }`}>
                    {doc.status === 'verified' ? 'Terverifikasi' :
                     doc.status === 'rejected' ? 'Ditolak' :
                     'Menunggu Verifikasi'}
                  </span>
                )}
              </div>

              {doc ? (
                <div className="bg-gray-50 rounded p-3">
                  <p className="text-sm text-gray-600">
                    <span className="font-medium">File:</span> {doc.file_name}
                  </p>
                  <p className="text-xs text-gray-500 mt-1">
                    Diupload: {new Date(doc.uploaded_at).toLocaleDateString('id-ID')}
                  </p>
                  {doc.status === 'rejected' && (
                    <label className="mt-2 inline-block">
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
                      <span className="cursor-pointer text-sm text-blue-600 hover:text-blue-700 font-medium">
                        Upload Ulang
                      </span>
                    </label>
                  )}
                </div>
              ) : (
                <label className="flex items-center justify-center border-2 border-dashed border-gray-300 rounded-lg p-4 cursor-pointer hover:border-blue-500 transition-colors">
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
                  <Upload className="w-5 h-5 text-gray-400 mr-2" />
                  <span className="text-sm text-gray-600">
                    {uploading === type ? 'Mengupload...' : 'Pilih file untuk diupload'}
                  </span>
                </label>
              )}
            </div>
          );
        })}
      </div>

      <div className="mt-6 p-4 bg-blue-50 rounded-lg">
        <p className="text-sm text-blue-800">
          <span className="font-medium">Catatan:</span> Format file yang diterima: PDF, JPG, JPEG, PNG. Maksimal ukuran file: 5MB
        </p>
      </div>
    </div>
  );
}
