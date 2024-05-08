@isTest 
public class ETT_GoodsIssueNoteTriggerHandler_Test {
    public static testmethod void goodsIssueNote_Test(){
        
        ETT_Goods_Issue_Note__c goodIssue = new ETT_Goods_Issue_Note__c();
        goodIssue.Misc_Issue_Err_Msg__c = 'test issue error msg';
        goodIssue.Misc_Issue_Status__c = 'Success';
        goodIssue.Request_Body__c = 'test Request body';
        goodIssue.Issue_Type__c= 'Factory';
        goodIssue.Status__c = 'Approved';
        insert goodIssue;
        
        goodIssue.Request_Body__c = 'test Request body in good issue note.';
        update goodIssue;
        
        ETT_Tools_Master__c toolMaster = new ETT_Tools_Master__c();
        toolMaster.ETT_Serial_No__c = 'sr12';
        insert toolMaster;
        
        ETT_Goods_Issue_Lines__c gIssueLine = new ETT_Goods_Issue_Lines__c();
        gIssueLine.Goods_Issue_Note__c = goodIssue.id;
        gIssueLine.Issued_Quantity__c = 12;
        gIssueLine.Tool_Material_Name__c = toolMaster.id;
        insert gIssueLine;
        
    }
    
    
}