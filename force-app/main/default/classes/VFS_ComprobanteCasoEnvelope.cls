public with sharing class VFS_ComprobanteCasoEnvelope {

    public class VFS_ComprobanteCasoEnvelopeException extends Exception {}

    public static List<VFS_EsignSendingEnvelope.EnvelopeAction> CreateSigns(String recordId) {

        try {
            if (String.isBlank(recordId)) {
                throw new VFS_ComprobanteCasoEnvelopeException('El Id del caso no puede estar vacío.');
            }

            Case caso = [
                SELECT Id,
                       CaseNumber,
                       AccountId,
                       Account.Name,
                       Account.FirstName,
                       Account.LastName,
                       Account.IsPersonAccount,
                       Account.PersonContactId
                FROM Case
                WHERE Id = :recordId
                LIMIT 1
            ];

            if (caso.AccountId == null) {
                throw new VFS_ComprobanteCasoEnvelopeException(
                    'El caso no tiene cliente asociado. No se puede enviar el comprobante a firma.'
                );
            }

            String emailCliente = obtenerCorreoCliente(caso.AccountId, caso.Account.PersonContactId);

            if (String.isBlank(emailCliente)) {
                throw new VFS_ComprobanteCasoEnvelopeException(
                    'No se encontró un correo principal en ContactPointEmail para el cliente del caso.'
                );
            }

            String firstName = String.isNotBlank(caso.Account.FirstName)
                ? caso.Account.FirstName
                : caso.Account.Name;

            String lastName = String.isNotBlank(caso.Account.LastName)
                ? caso.Account.LastName
                : '';

            List<VFS_FirmarDocumentoUtility.SignatureParams> firmas =
                new List<VFS_FirmarDocumentoUtility.SignatureParams>();

            VFS_FirmarDocumentoUtility.SignatureParams firmaCliente =
                new VFS_FirmarDocumentoUtility.SignatureParams();

            firmaCliente.ElementId = 'sig_comprobante_cliente_' + caso.CaseNumber;
            firmaCliente.DocumentNumber = 1;

            // Página 2, zona inferior izquierda sobre "Firma del cliente".
            firmaCliente.PageNumber = 3;
            firmaCliente.X = 90;
            firmaCliente.Y = 650;
            firmaCliente.Width = 180;
            firmaCliente.Height = 45;
            firmaCliente.DisplayName = 'Firma cliente';

            firmas.add(firmaCliente);

            return new List<VFS_EsignSendingEnvelope.EnvelopeAction>{
                VFS_FirmarDocumentoUtility.buildSignAction(
                    emailCliente,
                    firstName,
                    lastName,
                    'cliente_comprobante_caso',
                    firmas
                )
            };

        } catch (VFS_ComprobanteCasoEnvelopeException e) {
            throw new AuraHandledException(e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error al generar las firmas del comprobante de caso: ' + e.getMessage()
            );
        }
    }

    private static String obtenerCorreoCliente(Id accountId, Id personContactId) {

        Set<Id> parentIds = new Set<Id>();
        parentIds.add(accountId);

        if (personContactId != null) {
            parentIds.add(personContactId);
        }

        List<ContactPointEmail> correos = [
            SELECT Id,
                   ParentId,
                   EmailAddress,
                   IsPrimary,
                   CreatedDate
            FROM ContactPointEmail
            WHERE ParentId IN :parentIds
              AND EmailAddress != null
            ORDER BY IsPrimary DESC, CreatedDate ASC
            LIMIT 1
        ];

        return correos.isEmpty() ? null : correos[0].EmailAddress;
    }
}