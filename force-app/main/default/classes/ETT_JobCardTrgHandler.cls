/**
 * Author: Janardhan Muddana
 * CreatedDate: 08/06/2022
 * Desc: creating misc issue in Oracle, when ever job card is created with customer type - supplier
 * 
 * */
public class ETT_JobCardTrgHandler {
    
    public static Set<Id> alreadyProcessed = new Set<Id>();
    public static boolean firstRun = true;
    
    public static void afterUpdate(List<ETT_Job_Card__c> triggerNew, Map<Id,ETT_Job_Card__c> trgoldMap){
        Set<Id> inspectionIds = new Set<Id>();
        for(ETT_Job_Card__c objJC : triggerNew){
            if(objJC.ETT_Overall_Status__c != null && trgoldMap.containsKey(objJC.Id) && trgoldMap.get(objJC.Id).ETT_Overall_Status__c != objJC.ETT_Overall_Status__c 
              && (objJC.ETT_Overall_Status__c == 'Accepted' || objJC.ETT_Overall_Status__c == 'Rejected')){
                inspectionIds.add(objJC.ETT_Inspection_Card__c);
            }
        }
        Map<Id, ETT_Inspection_Card__c> inspectionsToUpdate = new Map<Id, ETT_Inspection_Card__c>([SELECT Id, ETT_Status__c, RecordTypeId, RecordType.Name FROM ETT_Inspection_Card__c WHERE Id IN: inspectionIds]);
    	
        for(ETT_Job_Card__c objJC : triggerNew){
            if(objJC.ETT_Overall_Status__c != null && trgoldMap.containsKey(objJC.Id) && trgoldMap.get(objJC.Id).ETT_Overall_Status__c != objJC.ETT_Overall_Status__c 
              && objJC.ETT_Overall_Status__c == 'Rejected' && inspectionsToUpdate.containsKey(objJC.ETT_Inspection_Card__c)){
                  if(inspectionsToUpdate.get(objJC.ETT_Inspection_Card__c).RecordTypeId == Schema.SObjectType.ETT_Inspection_Card__c.getRecordTypeInfosByName().get('Tyre - Internal').getRecordTypeId()){
                      inspectionsToUpdate.get(objJC.ETT_Inspection_Card__c).ETT_Status__c = 'Scrap';
                  }else{
                      inspectionsToUpdate.get(objJC.ETT_Inspection_Card__c).ETT_Status__c = 'Sent back';
                  }
            }
            if(objJC.ETT_Overall_Status__c != null && trgoldMap.containsKey(objJC.Id) && trgoldMap.get(objJC.Id).ETT_Overall_Status__c != objJC.ETT_Overall_Status__c 
              && objJC.ETT_Overall_Status__c == 'Accepted' && inspectionsToUpdate.containsKey(objJC.ETT_Inspection_Card__c)){
                  inspectionsToUpdate.get(objJC.ETT_Inspection_Card__c).ETT_Status__c = 'Accepted/No Warranty';
            }
        }
        if(!inspectionsToUpdate.values().isEmpty()){
            update inspectionsToUpdate.values();
        }
    }
    
    Public static void OracleHelper(Map<Id,ETT_Job_Card__c> trgNewMap){
        System.debug('inside oracle1');
        for(ETT_Job_Card__c jc : [select id,name,Customer_Type__c,createdDate,Tyre_Inventory__r.Serial_Number__c,Tyre_Inventory__r.Item_Code__c, ETT_Job_Type__c from ETT_Job_Card__c where Id=:trgNewMap.keyset()]){
            System.debug('inside oracle1 type '+jc.ETT_Job_Type__c );
            System.debug('inside oracle1 serial '+jc.Tyre_Inventory__r.Serial_Number__c );
            System.debug('inside oracle1 item '+jc.Tyre_Inventory__r.Item_Code__c );
            if((jc.ETT_Job_Type__c == 'Tyre Supplier' || jc.ETT_Job_Type__c == 'Tyre - Internal') && jc.Tyre_Inventory__r.Serial_Number__c != null && jc.Tyre_Inventory__r.Item_Code__c != null){
                System.debug('before oracle');
                if(!ETT_JobCardTrgHandler.alreadyProcessed.contains(jc.Id))
                	createMiscInOracle(jc.Id,jc.createdDate,jc.Name,jc.Tyre_Inventory__r.Item_Code__c,jc.Tyre_Inventory__r.Serial_Number__c);
            }
        }
      
    }
    
    @future(Callout=True)
    public static void createMiscInOracle(String jcId,DateTime createdDate,String Name,String itemCode,String SerialNum ){
         system.debug('Name: '+Name);
         system.debug('itemCode: '+itemCode);
        system.debug('SerialNum: '+SerialNum);
        alreadyProcessed.add(jcId);
        ETT_MiscIssue_Service.SyncCreateMiscellaneousIssuesServiceBPEL_pt req = new ETT_MiscIssue_Service.SyncCreateMiscellaneousIssuesServiceBPEL_pt();
        ETT_MiscIssue_Output.OutputParameters_element response = new ETT_MiscIssue_Output.OutputParameters_element();
        ETT_MiscIssues.Data_Header_type dataH = new ETT_MiscIssues.Data_Header_type();
        list<ETT_MiscIssues.Data_Lines_type> datalineList = new list<ETT_MiscIssues.Data_Lines_type>();
        ETT_MiscIssues.MessageXml msg = new ETT_MiscIssues.MessageXml();
        ETT_MiscIssues.MessageHeader msgHeader = new ETT_MiscIssues.MessageHeader();
        
            
            ETT_Job_Card__c jcUpdate = new ETT_Job_Card__c();
            jcUpdate.Id = jcId;
            
            dataH.TransactionType = 'JOB_CARD_OPN_USED_TYRE';
            dataH.TransactionDate = date.valueOf(createdDate); //date.valueOf('2022-06-08T00:00:00');//
            dataH.DocumentNumber = Name;
            
            ETT_MiscIssues.Data_Lines_type line = new ETT_MiscIssues.Data_Lines_type();                
            line.LineNumber= '1';
            line.ItemCode= itemCode;
            line.OrgId = '426';
            line.Subinventory ='AUH-TF-MS';
            line.Locator = 'AUH-TF-MS.Used Tyres.0';
            line.Quantity ='1';
            line.SerialControlFlag ='Y';
            
           
            list<ETT_MiscIssues.Serialnumber_lines_element> serlinelist = new list<ETT_MiscIssues.Serialnumber_lines_element>();
            ETT_MiscIssues.Serialnumber_lines_element serline = new ETT_MiscIssues.Serialnumber_lines_element();
            serline.Serialnumber= SerialNum;
            serlinelist.add(serline);
            line.Serialnumber_lines = serlinelist;
            datalineList.add(line);
            
            msg.Data_Header =dataH;
            msg.Data_Lines_type=datalineList;
            
            try{         
                
                response = req.process(msg);
                system.debug('--'+response);
            }catch(exception ex){
                UTIL_Logging.ExceptionLog exLog = new UTIL_Logging.ExceptionLog(ex, 'ETT_MiscellaneousTrgHandler', 'showData', '', UTIL_Logging.DEBUG_LEVEL_WARN);
                UTIL_Logging.logException(exLog);
                //throw new AuraHandledException(ex.getMessage()); 
            }
            if(response != null){
                if(response.PV_OUT_STATUS == 'Y'){
                    jcUpdate.Misc_Issue_Status__c ='Success';
                    jcUpdate.Misc_Issue_Status__c ='Success';
                    //jcUpdate.Misc_Issue_Err_Msg__c=response.PV_OUT_EBS_REF_NO;
                }else{
                    jcUpdate.Misc_Issue_Status__c ='Failed';
                    jcUpdate.Misc_Issue_Err_Msg__c = response.PV_OUT_ERRORMESSAGE;
                }
            }
            update jcUpdate; 
       
        
    }

}