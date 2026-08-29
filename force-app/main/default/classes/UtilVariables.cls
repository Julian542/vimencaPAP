/**
 * @description       : Class created to contain all relevant variables to be reused
 * @author            : Luisina Platino (lplatino@keystoneadvisors.cl)
 * @group             : 
 * @last modified on  : 07-12-2025
 * @last modified by  : Luisina Platino (lplatino@keystoneadvisors.cl)
**/
public with sharing class UtilVariables {

    /* Please keep it in alphabetical order */

    //A
    //B
    //C
    //D
    public static final string DEV_RT_BANCARIA          = 'Bancaria';
    public static final string DEV_RT_COMERCIAL         = 'Comercial';
    public static final string DEV_RT_PERSONA_FISICA    = 'PersonAccount';
    public static final string DEV_RT_PERSONA_JURIDICA  = 'Personas_Juridicas';
    public static final string DEV_RT_PERSONAL          = 'Personal';
    public static final string DEV_RT_BUSINESS          = 'IndustriesBusiness';

    //R
    public static final Map<Integer,String> RES_STATUS  = new Map<Integer,String>{
        200=>'Success',
        202=>'Partial Success',
        404=>'Not found',
        500=>'Error Internal Server'
    };
}