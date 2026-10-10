global with sharing class FSC_ObtenerOpcionesPicklist implements Callable
{
   global Object call(String action, Map<String, Object> args)
   {
       switch on action {
           when 'codigoAprobacion' {
               return codigoAprobacion((Map<String, Object>)args.get('input'), (Map<String, Object>)args.get('output'));
           }
       }
       return null;
    }
   
    private List<Map<String, Object>> codigoAprobacion(Map<String, Object> inputMap, Map<String, Object> outMap)
    {
        List<Map<String, Object>> optionList = new List<Map<String, Object>>();
        for (FSC_Codigo_de_Aprobacion_Desembolso__mdt cad : [SELECT Id,Label,FSC_Codigo_de_Aprobacion__c,FSC_Descripcion__c FROM FSC_Codigo_de_Aprobacion_Desembolso__mdt])
        {
             Map<String, Object> option = new Map<String, Object>();
             option.put('name', cad.FSC_Codigo_de_Aprobacion__c);
             option.put('value', cad.FSC_Descripcion__c);
             optionList.add(option);
        }
        
        outMap.put('options', optionList);
                
        return optionList;
    }
}