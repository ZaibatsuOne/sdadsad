import Foundation

@available(iOS 13.0.0, *)
actor CertificateValidator {
    var certificates = [SecCertificate]()
    
    func prepareCertificates(_ names: [String]) {
        certificates = names.compactMap(certificate(name:))
    }
    
    //Проблема тут
    private func certificate(name: String) -> SecCertificate? {
        if let path = Bundle.main.url(forResource: name, withExtension: "der", subdirectory: "Certificates"),
           let certData = try? Data(contentsOf: path),
           let certificate = SecCertificateCreateWithData(nil, certData as CFData) {
            return certificate
        } else {
            print("123")
            return nil
        }

    }
    
    func isCertificatesValid(at date: Date) -> Bool {
        for certificate in certificates {
            var trust: SecTrust!
            _ = SecTrustCreateWithCertificates(certificate, nil, &trust)
            
            let _ = SecTrustSetVerifyDate(trust, date as CFDate)
            
            if !checkValidity(of: trust!) {
                return false
            }
        }
        
        return true
    }
    
    func checkValidity(of serverTrust: SecTrust, anchorCertificatesOnly: Bool = false) -> Bool {
        SecTrustSetAnchorCertificates(serverTrust, certificates as CFArray)
        SecTrustSetAnchorCertificatesOnly(serverTrust, anchorCertificatesOnly)
        var error: CFError?
        
        if #available(iOS 12.0, *) {
            let isTrusted = SecTrustEvaluateWithError(serverTrust, &error)
            return isTrusted
        } else {
            print("Бим бим бам бам")
            return false
        }
        
    }
}




















