@RestResource(urlmapping='/CreateInventoryData')
global with sharing class  ETT_InventoryUpsertAPI {
     @HttpPost
    global static updateServiceRequestResult  CreateInventory() 
    { 
        RestRequest     request    = RestContext.request;
        RestResponse    response   = RestContext.response; 
           updateServiceRequestResult responseWrapper = new updateServiceRequestResult();
        try{       
       Inventorywrapper wrpData = (Inventorywrapper)System.JSON.deserialize(request.requestBody.toString(), Inventorywrapper.class); 
       Set<String> TyreSerialSet = new set<String>();
       Set<String> BrandSet= new set<String>();
       Set<String> Countryset= new set<String>();
       Set<String> Patternset= new set<String>();
       Set<String> TyreSizeset= new set<String>();
        system.debug('========>'+request.requestBody.toString());
         system.debug('========>'+wrpData);
         system.debug('========>'+wrpData.item);   
       Set<String> ItemCodeSet= new set<String>();
       for(InventoryList invwrap: wrpData.item ){
       if( invwrap.ItemMajorcategory=='Tyre'){
       TyreSerialSet.add(invwrap.SerialNumber);
       BrandSet.add(invwrap.Brand);
       TyreSizeset.add(invwrap.TyreSize);
       Countryset.add(invwrap.country);
       Patternset.add(invwrap.Pattern);
       ItemCodeSet.add(invwrap.ItemCode);
       }
       else if(invwrap.ItemMajorcategory!='Tyre'){
       ItemCodeSet.add(invwrap.ItemCode);
       }
       
       }
        Map<String,ETT_Tyre_Inventory__c> mapofTyreInventory = new Map<String,ETT_Tyre_Inventory__c>();
         Map<String,ETT_Brand_Master__c > mapofBrand= new Map<String,ETT_Brand_Master__c >();
        Map<String,ETT_Country_Master__c > mapofCountry= new Map<String,ETT_Country_Master__c >();
        Map<String,ETT_Tyre_Size_Master__c > mapofTyreSize= new Map<String,ETT_Tyre_Size_Master__c >();
          Map<String,ETT_Pattern_Master__c> mapofPattern= new Map<String,ETT_Pattern_Master__c>();
      
      // Map<String,ETT_Tyre_Inventory__c> mapofTyreInventory = new Map<String,ETT_Tyre_Inventory__c>([Select id,Serial_Number__c from ETT_Tyre_Inventory__c where ETT_Tyre_Serial_Number__c in:TyreSerialSet]);
      for(ETT_Tyre_Inventory__c etInv:[Select id,Serial_Number__c,ETT_Tyre_Serial_Number__c,ETT_Country__c,ETT_Brand__c,ETT_Pattern__c from ETT_Tyre_Inventory__c where ETT_Tyre_Serial_Number__c in:TyreSerialSet]){
      mapofTyreInventory.put(etInv.ETT_Tyre_Serial_Number__c ,etInv);
  
      
      }
      
       for(ETT_Country_Master__c etInv:[Select id,Name,ETT_Last_Update_Date__c from ETT_Country_Master__c where Name in:Countryset]){
      mapofCountry.put(etInv.Name,etInv);
  
      
      }
       for(ETT_Brand_Master__c etInv:[Select id,Name,ETT_Brand_Code__c from ETT_Brand_Master__c  where Name in:BrandSet]){
       mapofBrand.put(etInv.Name,etInv);
  
      
      }
      for(ETT_Tyre_Size_Master__c etInv:[Select id,Name,ETT_Tyre_Size__c from ETT_Tyre_Size_Master__c where Name in:TyreSizeset]){
       mapofTyreSize.put(etInv.Name,etInv);
  
      
      }
       for(ETT_Pattern_Master__c etInv:[Select id,Name from ETT_Pattern_Master__c where Name in:Patternset]){
       mapofPattern.put(etInv.Name,etInv);
  
      
      }
      system.debug('=========='+mapofPattern);
          Map<String,ETT_Tools_Master__c> mapofToolInventory = new Map<String,ETT_Tools_Master__c>();
  
        for(ETT_Tools_Master__c etInv:[Select id,ETT_Unique_Code__c,ETT_Allocated_Units__c,ETT_Main_Stock_Units__c from ETT_Tools_Master__c where ETT_Unique_Code__c in: ItemCodeSet]){
          mapofToolInventory.put(etInv.ETT_Unique_Code__c ,etInv);
          
      }
      List<ETT_Tools_Master__c>etMasterList = new List<ETT_Tools_Master__c>();
        List<ETT_Tyre_Inventory__c >etInvList = new List<ETT_Tyre_Inventory__c>();
    system.debug('========>'+wrpData);
     system.debug('========>'+wrpData.item);
     for(InventoryList invwrap: wrpData.item ){
     system.debug('========>'+invwrap);
     system.debug('========>'+mapofToolInventory);
     if( invwrap.ItemMajorcategory=='Tyre' || invwrap.ItemMajorcategory=='Tyres')
     {
      ETT_Tyre_Inventory__c eInventory= new ETT_Tyre_Inventory__c ();
        system.debug('========>'+invwrap.ItemCode);
      if( mapofToolInventory.containskey(invwrap.ItemCode)){
       system.debug('========>'+mapofToolInventory);
       eInventory.Tyre_Type__c='New';
       eInventory.Item_Code_Oracle__c=invwrap.ItemCode;
       eInventory.Serial_Number__c=invwrap.SerialNumber;
       if(mapofBrand.containskey(invwrap.Brand))eInventory.ETT_Brand__c=mapofBrand.get(invwrap.Brand).Id;
       else{
        ETT_Brand_Master__c env= new ETT_Brand_Master__c (Name=invwrap.Brand);
        insert env;
        eInventory.ETT_Brand__c=env.id;
       
       }
        //else eInventory.ETT_Brand__c=new ETT_Brand_Master__c (name=invwrap.brand) ;
       if(mapofTyreSize.containskey(invwrap.TyreSize))eInventory.ETT_Tyre_Size_Master__c=mapofTyreSize.get(invwrap.TyreSize).Id;
       else{
        ETT_Tyre_Size_Master__c env= new ETT_Tyre_Size_Master__c (Name=invwrap.TyreSize);
        insert env;
        eInventory.ETT_Tyre_Size_Master__c=env.id;
       
       }
       if(mapofCountry.containskey(invwrap.country))eInventory.ETT_Country__c=mapofCountry.get(invwrap.country).Id;
       else{
        ETT_Country_Master__c env= new ETT_Country_Master__c (Name=invwrap.country);
        insert env;
        eInventory.ETT_Country__c=env.id;
       }
       if(mapofPattern.containskey(invwrap.Pattern))eInventory.ETT_Pattern__c=mapofPattern.get(invwrap.Pattern).Id;
       else{
        ETT_Pattern_Master__c env= new ETT_Pattern_Master__c (Name=invwrap.Pattern);
        insert env;
        eInventory.ETT_Pattern__c=env.id;
       
       }
       //eInventory.ETT_Tyre_Size_Master__c=invwrap.TyreSize;
       //eInventory.ETT_Country__c=invwrap.Country;
       //eInventory.ETT_Pattern__c=invwrap.Pattern;
       etInvList.add(eInventory);
       }
     }
      else if(invwrap.ItemMajorcategory!='Tyre'){
      ETT_Tools_Master__c  etMaster= new ETT_Tools_Master__c ();
       if( mapofToolInventory.containskey(invwrap.ItemCode)){
       etMaster=mapofToolInventory.get(invwrap.ItemCode);
       etMaster.ETT_Main_Stock_Units__c=mapofToolInventory.get(invwrap.ItemCode).ETT_Main_Stock_Units__c+Integer.valueof(invwrap.Quantity);
       
       etMaster.UOM__c=invwrap.UOM;
       
       }
       else {
       etMaster.ETT_Unique_Code__c=invwrap.ItemCode;
       etMaster.UOM__c=invwrap.UOM;
       etMaster.ETT_Main_Stock_Units__c=Integer.valueof(invwrap.Quantity);
       
       }
       etMasterList.add(etMaster);
      } 
       }
       
       if(etInvList.size()<1 && etMasterList.size()<1){
       return  returnWrapper('Item Code Doesnot Exist!',etMasterList,etInvList,300,'FAILURE');
       }
      else{
        Upsert etMasterList;
         Upsert etInvList;
       }
     
      
       Upsert etMasterList;
        system.debug('===etMasterList=====>'+etMasterList);
       system.debug('==etInvList======>'+etInvList);
      
        return  returnWrapper('Updated successfully!',etMasterList,etInvList,200,'SUCCESS');
     
     }
      catch(Exception e){
            system.debug('EXCEPTION '+ e.getStackTraceString());
          system.debug('error=='+e.getMessage());
            responseWrapper.statusCode = 300;
            responseWrapper.status = 'FAILURE';
            responseWrapper.message = e.getMessage();
            return responseWrapper;
        }
}
    global class Inventorywrapper{
        
        global list<InventoryList> item;
        }
        global class InventoryList{
        global String ItemMajorcategory;  
        global string ItemCode;  
        global String SerialNumber;    
        global String Quantity;  
        global String Brand;  
        global String TyreSize;  
        global String Country;  
        global String Pattern;  
        global String UOM;  
    } 
     
    public static updateServiceRequestResult returnWrapper(String errorMessage,List<ETT_Tools_Master__c> MasterList,List<ETT_Tyre_Inventory__c > InventoryList,Integer statusCode,String status){
        updateServiceRequestResult responseWrapper = new updateServiceRequestResult();
        responseWrapper.ETInventoryList= InventoryList;
        responseWrapper.ETMasterList= MasterList;
        responseWrapper.statusCode = statusCode;
        responseWrapper.status = status;
        responseWrapper.message = errorMessage;
        return responseWrapper;
    }
     global Class updateServiceRequestResult{
        Integer statusCode;
        String message;
        String status;
        List<ETT_Tools_Master__c> ETMasterList;
         List<ETT_Tyre_Inventory__c > ETInventoryList;
    }
}