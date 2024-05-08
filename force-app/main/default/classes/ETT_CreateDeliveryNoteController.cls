public class ETT_CreateDeliveryNoteController {
    
    @auraEnabled 
    public static list<Tyre_Estimation_Line_Item__c> getTyreDetails(String serialVal, String tyreSizeVal, String brandVal, String patternVal, String tyreType, String countryVal,String customerId, String subInventoryId, String tyreEstimationId){
        System.debug('countryVal '+countryVal);
        System.debug('TyreType '+TyreType);
        String query='Select Id,Unit_Price__c,Tyre_Estimation__r.Name,Tyre_Inventory__c,Tyre_Inventory__r.ETT_Tyre_Size_Master__r.Name,Tyre_Inventory__r.ETT_Pattern__r.Name,Tyre_Inventory__r.ETT_Brand__r.Name,Tyre_Inventory__r.ETT_Country__r.Name,Tyre_Inventory__r.Tyre_Type__c,Tyre_Inventory__r.Serial_Number__c,Collection_Card_No__r.Name from Tyre_Estimation_Line_Item__c where Tyre_Inventory__c NOT IN (SELECT Tyre_Inventory__c FROM ETT_Delivery_Line_Item__c) AND ((Tyre_Inventory__r.Party_Type__c=\'Supplier\' OR Tyre_Inventory__r.Party_Type__c=\'Internal\') OR (Tyre_Inventory__r.Party_Type__c=\'\' OR Tyre_Inventory__r.Party_Type__c=\'Null\'))';
        //return [SELECT Id,Tyre_Type__c,Unit_Price__c,Name,ETT_Tyre_Size_Master__r.Name,Serial_Number__c,ETT_Brand__r.Name,ETT_Pattern__r.Name,ETT_Country__r.Name,ETT_Collection_Card__r.Name,ETT_Account__r.Name from ETT_Tyre_Inventory__c where Id IN (SELECT Tyre_Inventory__c FROM Tyre_Estimation_Line_Item__c) AND (Party_Type__c='Supplier' OR Party_Type__c='Internal Project') LIMIT 49000];
        if(customerId != null && customerId != ''){
            query += 'AND Tyre_Estimation__r.Account__c =: customerId ';
        }else if(subInventoryId != null && subInventoryId != ''){
            query += 'AND Tyre_Estimation__r.SubInventory__c =: subInventoryId ';
        }
        if(tyreEstimationId != null && tyreEstimationId != ''){
            query += 'AND Tyre_Estimation__c =: tyreEstimationId ';
        }/*else{
            query += ') ';
        } */
        if(serialVal != null && serialVal != ''){
            query += 'AND Tyre_Inventory__r.Serial_Number__c =: serialVal ';
        }
        if(tyreSizeVal != null && tyreSizeVal != ''){
            query += 'AND Tyre_Inventory__r.ETT_Tyre_Size_Master__r.Name =: tyreSizeVal ';
        }
        if(brandVal != null && brandVal != ''){
            query += 'AND Tyre_Inventory__r.ETT_Brand__r.Name =: brandVal ';
        }
        if(patternVal != null && patternVal != ''){
            query += 'AND Tyre_Inventory__r.ETT_Pattern__r.Name =: patternVal ';
        }
        if(tyreType != null && tyreType != ''){
            query += 'AND Tyre_Inventory__r.Tyre_Type__c =: tyreType ';
        }else{
            query += 'AND (Tyre_Inventory__r.Tyre_Type__c = \'Refurbished\' OR Tyre_Inventory__r.Tyre_Type__c  = \'New\' OR Tyre_Inventory__r.Tyre_Type__c  = \'Scrapped\') ';
        }
        if(countryVal != null && countryVal != ''){
            query += 'AND Tyre_Inventory__r.ETT_Country__r.Name =: countryVal ';
        }
        System.debug('query '+query);
        return Database.query(query+' LIMIT 49000');
    }
    @auraEnabled 
    public static list<ETT_Delivery_Line_Item__c> createEstimations(list<Tyre_Estimation_Line_Item__c> selectedTyres, String customerId, String subInventoryId){
        
        Savepoint sp = Database.setSavepoint();
        
        List<ETT_Delivery_Line_Item__c> listOfDeliveryNote = new List<ETT_Delivery_Line_Item__c>();
        ETT_Delivery_Note__c deliveryNoteObj = new ETT_Delivery_Note__c();
        if(customerId != null && customerId != ''){
            deliveryNoteObj.ETT_Account__c =customerId;   
        }
        if(subInventoryId != null && subInventoryId != ''){
            deliveryNoteObj.SubInventory__c = subInventoryId;   
        }
        deliveryNoteObj.DN_Status__c='New';
        deliveryNoteObj.ETT_Date__c = System.now();
        deliveryNoteObj.ETT_Job_Type__c='Accepted';
        insert deliveryNoteObj;
        
        try{
            Set<Id> tyreInventories = new Set<Id>();
            Map<Id,ETT_Inspection_Card__c> inspectionsMap = new Map<Id,ETT_Inspection_Card__c>();
            for(Tyre_Estimation_Line_Item__c objTELI:selectedTyres){
                if(objTELI.Tyre_Inventory__c != null){
                    tyreInventories.add(objTELI.Tyre_Inventory__c);
                }
            }
            for(ETT_Inspection_Card__c objInspection : [SELECT Id, Tyre_Inventory__c FROM ETT_Inspection_Card__c WHERE Tyre_Inventory__c IN: tyreInventories]){
                if(objInspection.Tyre_Inventory__c != null){
                    inspectionsMap.put(objInspection.Tyre_Inventory__c, objInspection);
                }
            }
            
            for(Tyre_Estimation_Line_Item__c objTELI:selectedTyres){
                system.debug('entered');
                ETT_Delivery_Line_Item__c objDeliveryLineItem = new ETT_Delivery_Line_Item__c();
                objDeliveryLineItem.Tyre_Inventory__c=objTELI.Tyre_Inventory__c;
                objDeliveryLineItem.ETT_Delivery_Note__c=deliveryNoteObj.id;
                objDeliveryLineItem.ETT_Collection_Card__c=objTELI.Collection_Card_No__c;
                if(inspectionsMap.containsKey(objTELI.Tyre_Inventory__c)){
                    objDeliveryLineItem.ETT_Inspection_Card__c = inspectionsMap.get(objTELI.Tyre_Inventory__c).Id;
                }
                /*objDelivaryLineItem.origin__c = objTI.ETT_Country__r.Name;
                objDelivaryLineItem.Original_pattern__c = objTI.ETT_Pattern__r.Name;
                objDelivaryLineItem.Serial_No__c = objTI.Serial_Number__c;
                objDelivaryLineItem.Tyre_size__c = objTI.ETT_Tyre_Size_Master__r.Name;*/
                listOfDeliveryNote.add(objDeliveryLineItem);
            }
            if(!listOfDeliveryNote.isEmpty()){
                insert listOfDeliveryNote;
            }
            return [select id,name,ETT_Delivery_Note__r.Name,ETT_Delivery_Note__r.Id from ETT_Delivery_Line_Item__c where id=:listOfDeliveryNote limit 1];
            
        }catch(Exception e){
            system.debug('----Line'+e.getLineNumber());
            system.debug('---Trac-'+e.getStackTraceString());
            system.debug('---err-'+e.getMessage());
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage()+'--'+e.getCause()+'--'+e.getStackTraceString()); 
        }    
    }
    
}