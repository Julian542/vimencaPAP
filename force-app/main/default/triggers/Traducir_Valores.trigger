trigger Traducir_Valores on Direccion__c (before insert, before update) {
    
    for(Direccion__c  Dir: Trigger.new)
    {
        if(Dir.DIR_Pais__c !=''){
            
            Dir.DIR_Direccion_Traduccion__c = '';
            Dir.DIR_Direccion_Traduccion__c = Dir.DIR_Direccion_Traduccion__c + (Dir.DIR_Calle__c == NULL? '' : Dir.DIR_Calle__c + ' - ');
            Dir.DIR_Direccion_Traduccion__c = Dir.DIR_Direccion_Traduccion__c + (Dir.DIR_Numero__c == NULL? '' : Dir.DIR_Numero__c + ' - ');
            Dir.DIR_Direccion_Traduccion__c = Dir.DIR_Direccion_Traduccion__c + (Dir.DIR_Pais__c == NULL ? '' : generalUtils.pickListGetLabel(Direccion__c.DIR_Pais__c.getDescribe(), Dir.DIR_Pais__c) + ' - ');
            Dir.DIR_Direccion_Traduccion__c = Dir.DIR_Direccion_Traduccion__c + (Dir.DIR_Provincia__c == NULL ? '': generalUtils.pickListGetLabel(Direccion__c.DIR_Provincia__c.getDescribe(), Dir.DIR_Provincia__c) + ' - ');
            Dir.DIR_Direccion_Traduccion__c = Dir.DIR_Direccion_Traduccion__c + (Dir.DIR_Municipio__c == NULL ? '': generalUtils.pickListGetLabel(Direccion__c.DIR_Municipio__c.getDescribe(), Dir.DIR_Municipio__c) + ' - ');
            Dir.DIR_Direccion_Traduccion__c = Dir.DIR_Direccion_Traduccion__c + (Dir.DIR_Distrito__c == NULL ? '': generalUtils.pickListGetLabel(Direccion__c.DIR_Distrito__c.getDescribe(), Dir.DIR_Distrito__c));
            
            Dir.DIR_Pais_Texto__c = (Dir.DIR_Pais__c == NULL ? '' : generalUtils.pickListGetLabel(Direccion__c.DIR_Pais__c.getDescribe(), Dir.DIR_Pais__c));
            Dir.DIR_Provincia_texto__c  = (Dir.DIR_Provincia__c == NULL ? '':generalUtils.pickListGetLabel(Direccion__c.DIR_Provincia__c.getDescribe(), Dir.DIR_Provincia__c));
            Dir.DIR_Municipio_texto__c = (Dir.DIR_Municipio__c == NULL ? '':generalUtils.pickListGetLabel(Direccion__c.DIR_Municipio__c.getDescribe(), Dir.DIR_Municipio__c));
            Dir.DIR_Distrito_texto__c = (Dir.DIR_Distrito__c == NULL ? '':generalUtils.pickListGetLabel(Direccion__c.DIR_Distrito__c.getDescribe(), Dir.DIR_Distrito__c));
            
        }   
    }

}