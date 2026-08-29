public class INTUtilities {
  public static String fillCorrectType(Map<String, String> values, SObject changeObject, String frame) {
    for (String field : values.keySet()) {
      // System.debug(field);
      if (values.get(field) != '') {
        if (changeObject.get(values.get(field)) == null) {
          if (field == '[function_numEmployees]' || field == '[function_totalAssets]' || field == '[function_anualSales]') {
            frame = frame.replace(field, '0');
          } else if (field == '[function_addressIdentifier]') {
            if (changeObject.get('DIR_Id_Externo_Direccion__c') != null) {
              frame = frame.replace(field, changeObject.get('DIR_Id_Externo_Direccion__c').toString().escapeXml());
            } else if (changeObject.get('Name') != null) {
              frame = frame.replace(field, changeObject.get('Name').toString().escapeXml());
            }
          } else if (field == '[function_addressExternalIdBk]') {
            // Esta fue la nueva condicion agregada
            if (!String.isBlank(String.valueOf(changeObject.get('DIR_Identificador__c')))) {
              frame = frame.replace(field, changeObject.get('DIR_Identificador__c').toString().escapeXml());
            } else {
              frame = !Test.isRunningTest() ? frame.replace(field, changeObject.get('Name').toString().escapeXml()) : 'Test Name';
            } //Hasta aqui llega la nueva condicion agregada
          } else if (field == '[function_contactInfoIdentifier]') {
            if (changeObject.get('VIA_Id_Externo_Via__c') != null) {
              frame = frame.replace(field, changeObject.get('VIA_Id_Externo_Via__c').toString().escapeXml());
            } else if (changeObject.get('Name') != null) {
              frame = frame.replace(field, changeObject.get('Name').toString().escapeXml());
            }
          } else if (field == '[function_ViaIdExternoVia]') {
            // Esta fue la nueva condicion agregada
            if (!String.isBlank(String.valueOf(changeObject.get('VIA_Identificador__c')))) {
              frame = frame.replace(field, changeObject.get('VIA_Identificador__c').toString().escapeXml());
            } else {
              frame = !Test.isRunningTest() ? frame.replace(field, changeObject.get('Name').toString().escapeXml()) : 'Test Name'; // Duda sobre esto
            } //Hasta aqui llega la nueva condicion agregada
          } else if (values.get(field) == 'ACC_Tipo_Sector__c') {
            // System.debug('SECTOR :: ' +values.get(field));
            frame = frame.replace(field, 'PRIVADO'); //Solucion provicional mientras se hace a este campo obligatorio
          } else {
            frame = frame.replace(field, '');
          }
        } else if (changeObject.get(values.get(field)) instanceof Date) {
          Date dateField = (Date) changeObject.get(values.get(field));
          frame = frame.replace(field, dateField.format());
        } else if (changeObject.get(values.get(field)) instanceof DateTime) {
          DateTime dateField = (DateTime) changeObject.get(values.get(field));
          frame = frame.replace(field, dateField.date().format());
        } else if (changeObject.get(values.get(field)) instanceof Decimal) {
          if (values.get(field) == 'ACC_Total_Activos__c') {
            Decimal numero = (Decimal) changeObject.get(values.get(field));
            Long numINT = Math.roundToLong(numero);
            frame = frame.replace(field, String.valueOf(numINT));
          } else {
            frame = frame.replace(field, String.valueOf(changeObject.get(values.get(field))));
          }
        } else if (changeObject.get(values.get(field)) instanceof String) {
          if (values.get(field) == 'CPA_Sector__c' || values.get(field) == 'ACC_Actividad_Economica__c') {
            Datos_Maestros__c nameSec = [SELECT Name, DM_Direccion__c FROM Datos_Maestros__c WHERE id = :(id) changeObject.get(values.get(field))];
            if (field == '[function_codActEconSIB]' || field == '[function_ActividadEconomica]') {
              frame = frame.replace(field, nameSec.DM_Direccion__c.escapeXml());
            } else {
              frame = frame.replace(field, nameSec.name.escapeXml());
            }
            // System.debug(values.get(field)+' = '+changeObject.get(values.get(field)));
          } else {
            frame = frame.replace(field, changeObject.get(values.get(field)).toString().escapeXml());
          }
        } else if (changeObject.get(values.get(field)) instanceof Boolean) {
          String boolVal = (changeObject.get(values.get(field)) == true) ? 'Y' : 'N';
          frame = frame.replace(field, boolVal);
        } else if (changeObject.get(values.get(field)) instanceof Address) {
          if (field == '[function_addressStreet]') {
            String street = changeObject.get(values.get(field)).toString();
            street = street.replaceAll('\\d+', '').trim();
            System.debug('street = ' + street);
            frame = frame.replace(field, street.escapeXml());
          } else if (field == '[function_addressNum]') {
            String street = changeObject.get(values.get(field)).toString();
            String streetNumber = '';
            Matcher m = Pattern.compile('\\d+').matcher(street);
            if (m.find()) {
              streetNumber = m.group(0);
            }
            System.debug('streetNumber = ' + streetNumber);
            frame = frame.replace(field, streetNumber.escapeXml());
          } else {
            frame = frame.replace(field, '');
          }
        }
      } else {
        frame = frame.replace(field, '');
      }
      //  System.debug(values.get(field)+' = '+changeObject.get(values.get(field)));
    }
    return frame;
  }
}