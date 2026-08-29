public with sharing class FSC_LookupSearchResult implements Comparable {
    
    private String id;
    private String sObjectType;
    private String icon;
    private String title;
    private String subtitle;

    /**
     * @param id the lookup entry identifier (generally a record ID)
     * @param sObjectType Optional - The sObject type of the selected record. This value is not used for lookup rendering. It's passed back to the selection handler in case you search on multiple object types.
     * @param icon Optional - A qualified SLDS icon name taken from https://www.lightningdesignsystem.com/icons. No icon is displayed by default.
     * @param title Required - The label of the lookup entry
     * @param subtitle Optional - A subtitle that is displayed under the lookup entry label
     */
    public FSC_LookupSearchResult(String id, String sObjectType, String icon, String title, String subtitle) {
        this.id = id;
        this.sObjectType = sObjectType;
        this.icon = icon;
        this.title = title;
        this.subtitle = subtitle;
    }

    @AuraEnabled
    public String getId() {
        return id;
    }

    @AuraEnabled
    public String getSObjectType() {
        return sObjectType;
    }

    @AuraEnabled
    public String getIcon() {
        return icon;
    }

    @AuraEnabled
    public String getTitle() {
        return title;
    }

    @AuraEnabled
    public String getSubtitle() {
        return subtitle;
    }

    public Integer compareTo(Object compareTo) {
        FSC_LookupSearchResult other = (FSC_LookupSearchResult) compareTo;
        if (this.getTitle() == null) {
            return (other.getTitle() == null) ? 0 : 1;
        }
        if (other.getTitle() == null) {
            return -1;
        }
        return this.getTitle().compareTo(other.getTitle());
    }
}