@isTest
public class ETT_JobCardTrgHand_Test {
    public static testmethod void testETT_JobCardTrgHand(){
        
        
        ETT_Job_Card__c jobCard = new ETT_Job_Card__c();
        jobCard.ETT_Overall_Status__c = 'In-Progress';
        insert jobCard;
        
        jobCard.ETT_Overall_Status__c = 'Rejected';
        update jobCard;
        
        ETT_JobCardTrgHandler.createMiscInOracle(jobCard.id, system.today(),' test','IC1234',' SR123');
         
        
    }

}