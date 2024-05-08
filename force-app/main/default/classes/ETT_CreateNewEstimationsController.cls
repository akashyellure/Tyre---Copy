public class ETT_CreateNewEstimationsController {
    @auraEnabled 
    public static Tyre_Estimation__c getTyreEstimations(String estimationId){
        Tyre_Estimation__c objTyreEstimation=[select id,SubInventory__c,Account__c,Account__r.Name,SubInventory__r.Name from Tyre_Estimation__c where id=:estimationId]; 
        return objTyreEstimation; 
    }
    
    @auraEnabled 
    public static list<TyreInventoryWrapper> getTyreDetails(String serialVal,String tyreSizeVal,String brandVal,String patternVal,String tyreType,String countryVal,String customerVal,string threadPattern){
        //return [SELECT Id,Tyre_Type__c,Party_Type__c,Unit_Price__c,Name,ETT_Tyre_Size_Master__r.Name,Serial_Number__c,ETT_Brand__r.Name,ETT_Pattern__r.Name,ETT_Country__r.Name,ETT_Collection_Card__r.Name,ETT_Account__r.Name from ETT_Tyre_Inventory__c where Id NOT IN (SELECT Tyre_Inventory__c FROM Tyre_Estimation_Line_Item__c) AND (Party_Type__c='Supplier' OR Party_Type__c='Internal Project') AND (Tyre_Type__c = 'Refurbished' OR Tyre_Type__c  = 'New') LIMIT 49000];
        System.debug('countryVal '+countryVal);
        System.debug('TyreType '+TyreType);
        System.debug('customerVal '+customerVal);
        String query='SELECT Id, Tyre_Type__c, Unit_Price__c, Name, ETT_Tyre_Size_Master__r.Name, Serial_Number__c, ETT_Brand__r.Name, ETT_Pattern__r.Name, ETT_Country__r.Name, ETT_Collection_Card__r.Name, ETT_Account__r.Name from ETT_Tyre_Inventory__c where Id NOT IN (SELECT Tyre_Inventory__c FROM Tyre_Estimation_Line_Item__c) AND ((Party_Type__c=\'Supplier\' OR Party_Type__c=\'Internal\') OR (Party_Type__c=\'\' OR Party_Type__c=\'Null\')) ';
        System.debug('Sandip '+query);
        set<id> setInventryIds=new set<id> ();

        if(threadPattern!=null && threadPattern!=''){
             System.debug('Sandip '+threadPattern);
            List<ETT_Job_Card_Close__c> lstETTJobCardClose=[select id,Job_Card__c from ETT_Job_Card_Close__c where Thread_Pattern__c=:threadPattern];
            System.debug('Sandip '+lstETTJobCardClose);
            set<id> setJobIds=new set<id> ();
            
            for(ETT_Job_Card_Close__c e:lstETTJobCardClose){
                setJobIds.add(e.Job_Card__c);
            }
            
            List<ETT_Job_Card__c> lstETTJobCard=[select id,Tyre_Inventory__c from ETT_Job_Card__c where id in:setJobIds];
            for(ETT_Job_Card__c jc:lstETTJobCard){
                setInventryIds.add(jc.Tyre_Inventory__c);
            }
            
        }
        
        if(setInventryIds.size()>0){
            system.debug('setInventryIds'+setInventryIds);
            query += 'AND id in:setInventryIds ';
        }
        
        if(serialVal != null && serialVal != ''){
            query += 'AND Serial_Number__c =: serialVal ';
        }
        if(tyreSizeVal != null && tyreSizeVal != ''){
            query += 'AND ETT_Tyre_Size_Master__r.Name =: tyreSizeVal ';
        }
        if(brandVal != null && brandVal != ''){
            query += 'AND ETT_Brand__r.Name =: brandVal ';
        }
        if(patternVal != null && patternVal != ''){
            query += 'AND ETT_Pattern__r.Name =: patternVal ';
        }
        
        
        if(tyreType != null && tyreType != ''){
            query += 'AND Tyre_Type__c =: tyreType ';
        }else{
            query += 'AND (Tyre_Type__c = \'Refurbished\' OR Tyre_Type__c  = \'New\' OR Tyre_Type__c  = \'Scrapped\') ';
        } 
        if(countryVal != null && countryVal != ''){
            query += 'AND ETT_Country__r.Name =: countryVal ';
        }
        Account accObj;
        if(customerVal != null && customerVal != ''){
            List<Account> accList=new List<Account>([select id,ETT_Party_Code__c from Account where id=:customerVal]);
            if(!accList.isEmpty()){
                accObj=accList[0];
            }
        }
        System.debug('accObj '+accObj);
        Map<String,TyreInventoryPriceSettings__c> tyreInventoryPSMap = new Map<String,TyreInventoryPriceSettings__c>();  
        for(TyreInventoryPriceSettings__c tyreInventory:[Select Name, Party_Type__c, Party_code__c, Selling_Price__c from TyreInventoryPriceSettings__c]){
            if(customerVal != null && customerVal != ''){
                tyreInventoryPSMap.put(tyreInventory.Party_code__c+'-'+tyreInventory.Name,tyreInventory);
            }else if(tyreInventory.Party_Type__c == 'Internal'){
                tyreInventoryPSMap.put(tyreInventory.Name,tyreInventory);
            }
        }
        System.debug('tyreInventoryPSMap '+tyreInventoryPSMap);
        System.debug('query '+query);
        List<ETT_Tyre_Inventory__c> tyreList = Database.query(query+' LIMIT 49000');
        System.debug('tyreList size '+tyreList.size()+' values '+tyreList);
        List<TyreInventoryWrapper> wrapTyreInventoryList = new List<TyreInventoryWrapper>();
        for(ETT_Tyre_Inventory__c tyre: tyreList){
            System.debug('tyre '+tyre);
            if(customerVal != null && customerVal != '' && accObj !=null && tyreInventoryPSMap.containsKey(accObj.ETT_Party_Code__c+'-'+tyre.ETT_Tyre_Size_Master__r.Name)){
                TyreInventoryWrapper tyreWrapper = new TyreInventoryWrapper(tyre,tyreInventoryPSMap.get(accObj.ETT_Party_Code__c+'-'+tyre.ETT_Tyre_Size_Master__r.Name).Selling_Price__c);
                wrapTyreInventoryList.add(tyreWrapper);
            }else if((customerVal==null || customerVal=='') && tyreInventoryPSMap.containsKey(tyre.ETT_Tyre_Size_Master__r.Name)){
                TyreInventoryWrapper tyreWrapper = new TyreInventoryWrapper(tyre,tyreInventoryPSMap.get(tyre.ETT_Tyre_Size_Master__r.Name).Selling_Price__c);
                wrapTyreInventoryList.add(tyreWrapper);
            } 
        }
        System.debug('tyreList '+tyreList);
        return wrapTyreInventoryList;
    }
    
    @auraEnabled 
    public static list<Tyre_Estimation_Line_Item__c> createEstimations(list<TyreInventoryWrapper> selectedTyres, String customerId, String subInventoryId, String tyreEstimationId){
        
        Savepoint sp = Database.setSavepoint();
        
        List<Tyre_Estimation_Line_Item__c> listOfEstimationLI = new List<Tyre_Estimation_Line_Item__c>();
        Tyre_Estimation__c tyreEstimationObj = new Tyre_Estimation__c();
        if(tyreEstimationId == null || tyreEstimationId == ''){
            if(customerId != null && customerId != ''){
                tyreEstimationObj.Account__c = customerId;
                tyreEstimationObj.Type__c = 'Customer';
            }
            if(subInventoryId != null && subInventoryId != ''){
                tyreEstimationObj.SubInventory__c = subInventoryId;
                tyreEstimationObj.Type__c = 'Internal';
            }
            tyreEstimationObj.Status__c='Pending'; 
            tyreEstimationObj.Payment_Terms__c='Cash';
            insert tyreEstimationObj;
        }
        try{
            for(TyreInventoryWrapper objWrap:selectedTyres){
                system.debug('entered');
                Tyre_Estimation_Line_Item__c objEstimationLI = new Tyre_Estimation_Line_Item__c();
                objEstimationLI.Tyre_Inventory__c=objWrap.objTI.id;
                if(tyreEstimationId != null && tyreEstimationId != ''){
                    objEstimationLI.Tyre_Estimation__c = tyreEstimationId;
                }else{
                    objEstimationLI.Tyre_Estimation__c = tyreEstimationObj.id;
                }
                objEstimationLI.origin__c = objWrap.objTI.ETT_Country__r.Name;
                objEstimationLI.Original_pattern__c = objWrap.objTI.ETT_Pattern__r.Name;
                objEstimationLI.Serial_No__c = objWrap.objTI.Serial_Number__c;
                objEstimationLI.Tyre_size__c = objWrap.objTI.ETT_Tyre_Size_Master__r.Name;
                objEstimationLI.Collection_Card_No__c = objWrap.objTI.ETT_Collection_Card__c;
                objEstimationLI.Unit_Price__c = objWrap.unitPrice;
                listOfEstimationLI.add(objEstimationLI);
            }
            if(!listOfEstimationLI.isEmpty()){
                insert listOfEstimationLI;    
            }
            return [select id,name,Tyre_Estimation__r.Id,Tyre_Estimation__r.Name from Tyre_Estimation_Line_Item__c where id=:listOfEstimationLI limit 1];
            
        }catch(Exception e){
            system.debug('---ca'+e.getCause());
            system.debug('----Line'+e.getLineNumber());
            system.debug('---Trac-'+e.getStackTraceString());
            system.debug('---Type-'+e.getTypeName());
            system.debug('---err-'+e.getMessage());
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage()+'--'+e.getCause()+'--'+e.getStackTraceString()); 
        }    
    }
    
    public class TyreInventoryWrapper {
        @AuraEnabled
        public ETT_Tyre_Inventory__c objTI {get; set;}
        @AuraEnabled
        public decimal unitPrice {get; set;}
        public TyreInventoryWrapper(){}
        public TyreInventoryWrapper(ETT_Tyre_Inventory__c tyreInventoryObj, decimal uPrice) {
            objTI = tyreInventoryObj;
            if(uPrice != null){
                unitPrice = uPrice;
            }else{
                unitPrice = 0;
            }
        }
    }
    
}