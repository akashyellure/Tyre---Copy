public class ETT_GoodsIssueNoteTriggerHandler {
    
    public static Set<Id> alreadyProcessed = new Set<Id>();
    public static boolean firstRun = true;
    
    
    Public static void OracleHelper(Map<Id,ETT_Goods_Issue_Note__c> trgNewMap,List<ETT_Goods_Issue_Note__c> lstOld){
        
        List<id> lstEligibleIds=new  List<id>();
        for(ETT_Goods_Issue_Note__c rec:lstOld){
            ETT_Goods_Issue_Note__c newRecord=trgNewMap.get(rec.id);
            if(newRecord.Status__c=='Approved'){
                lstEligibleIds.add(rec.id);
            }
        }
        
        system.debug('lstEligibleIds'+lstEligibleIds);
        
        for(ETT_Goods_Issue_Note__c jc : [select id,name,Status__c,createdDate,Job_Card__r.Tyre_Inventory__r.Serial_Number__c,Job_Card__r.Tyre_Inventory__r.Item_Code__c from ETT_Goods_Issue_Note__c where Id=:lstEligibleIds]){
            if(jc.Status__c =='Approved'){
                if(!ETT_GoodsIssueNoteTriggerHandler.alreadyProcessed.contains(jc.Id))
                    createMiscInOracle(jc.Id,jc.createdDate,jc.Name,jc.Job_Card__r.Tyre_Inventory__r.Item_Code__c,jc.Job_Card__r.Tyre_Inventory__r.Serial_Number__c);
            }
        }
        
    }
    
    @future(Callout=True)
    public static void createMiscInOracle(String jcId,DateTime createdDate,String Name,String itemCode,String SerialNum ){
        
        alreadyProcessed.add(jcId);
        ETT_MiscIssue_Service.SyncCreateMiscellaneousIssuesServiceBPEL_pt req = new ETT_MiscIssue_Service.SyncCreateMiscellaneousIssuesServiceBPEL_pt();
        ETT_MiscIssue_Output.OutputParameters_element response = new ETT_MiscIssue_Output.OutputParameters_element();
        ETT_MiscIssues.Data_Header_type dataH = new ETT_MiscIssues.Data_Header_type();
        list<ETT_MiscIssues.Data_Lines_type> datalineList = new list<ETT_MiscIssues.Data_Lines_type>();
        ETT_MiscIssues.MessageXml msg = new ETT_MiscIssues.MessageXml();
        
        ETT_Goods_Issue_Note__c gin = [SELECT Id, Issue_Type__c FROM ETT_Goods_Issue_Note__c WHERE Id =: jcId LIMIT 1];
        
        ETT_Goods_Issue_Note__c jcUpdate = new ETT_Goods_Issue_Note__c();
        jcUpdate.Id = jcId;
        if(gin.Issue_Type__c == 'Expense'){
            dataH.TransactionType = 'RAW_MAT_ISSUE_EXP';
        }else{
        	dataH.TransactionType = 'RAW_MAT_ISSUE';
        }
        dataH.TransactionDate = date.valueOf(createdDate); //date.valueOf('2022-06-08T00:00:00');//
        dataH.DocumentNumber = Name;
        
        
        
        list<ETT_MiscIssues.Serialnumber_lines_element> serlinelist = new list<ETT_MiscIssues.Serialnumber_lines_element>();
        ETT_MiscIssues.Serialnumber_lines_element serline = new ETT_MiscIssues.Serialnumber_lines_element();
        serline.Serialnumber= SerialNum;
        serlinelist.add(serline);
        integer count=1;
        for(ETT_Goods_Issue_Lines__c ETT_GoodsIssueNoteTriggerHandler:[select Id, IsDeleted, Name, Avail_Qty__c, Average_Rate__c, Issued_Quantity__c, Item_Description__c, Process_Name__c, UOM__c, Value__c, Item_Code__c from ETT_Goods_Issue_Lines__c where Goods_Issue_Note__c=:jcId]){
            
            ETT_MiscIssues.Data_Lines_type line = new ETT_MiscIssues.Data_Lines_type();                
            line.LineNumber= string.valueof(count);
            line.ItemCode= GIL.Item_Code__c;
            line.OrgId = '426';
            line.Subinventory ='AUH-TF-MS';
            line.Locator = 'AUH-TF-MS.Stores.0';
            line.Quantity = string.valueof(GIL.Issued_Quantity__c);
            line.SerialControlFlag ='N';
            line.Serialnumber_lines = serlinelist;
            datalineList.add(line);
            count++;
        }
        
        msg.Data_Header =dataH;
        msg.Data_Lines_type=datalineList;
        
        try{         
            system.debug('-msgmsg-'+msg);
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
                jcUpdate.Misc_Issue_Err_Msg__c='';
            }else{
                jcUpdate.Misc_Issue_Status__c ='Failed';
                jcUpdate.Misc_Issue_Err_Msg__c = response.PV_OUT_ERRORMESSAGE;
            }
        }
        jcUpdate.Request_Body__c=JSON.serialize(msg);
        update jcUpdate; 
        
        
    }
    
}