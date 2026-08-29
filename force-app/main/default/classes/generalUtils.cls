public class generalUtils {
    
    /* Funciones relativas a Picklist */
	public static String pickListGetLabel(Schema.DescribeFieldResult F, String Value){
        
       	List<Schema.PicklistEntry> P = F.getPicklistValues();
        
       	for (Schema.PicklistEntry auxPick : P){
            if(auxPick.getValue() == Value) return auxPick.getLabel();
        }
        
        return Value;
    }
    
    /* Funciones relativas a Fechas */
    public static String getDate(Date newDate){
        return ((newDate.day() < 10)? '0' : '') + newDate.day() + '/' + ((newDate.month() < 10)? '0' : '') + newDate.month() + '/' + newDate.year();
    }
    
    public static String getDateTime(DateTime newDateTime){
        return getDate(newDateTime.date()) + ' ' + ((newDateTime.hour() < 10)? '0' : '') + newDateTime.hour() + ':' + ((newDateTime.minute() < 10)? '0' : '') + newDateTime.minute() + ':' + ((newDateTime.second() < 10)? '0' : '') + newDateTime.second();
    }
    
    public static Date parseStringtoDate(String stringDate){
        /* La stringDate viene en formato MM/DD/YYYY */
        List<String> dateSplit = stringDate.split('/');
        /* Formato DD/MM/YYYY */
        Date newDate = Date.newinstance(integer.valueOf(dateSplit[2]), integer.valueOf(dateSplit[0]), integer.valueOf(dateSplit[1]));
        return newDate;
    }
    
}