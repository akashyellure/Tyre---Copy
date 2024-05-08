trigger ETT_JobCardCloseTrg on ETT_Job_Card_Close__c (after Update) {
    
    ETT_JobCardCloseTrgHelper.updateToolsItemMaster(trigger.NewMap,trigger.OldMap);
    
    for(ETT_Job_Card_Close__c objJCC : trigger.New){
        if(!ETT_JobCardCloseTrgHelper.alreadyProcessed.contains(objJCC.Id) && objJCC.Status__c != trigger.oldMap.get(objJCC.Id).Status__c && objJCC.Status__c == 'Approved'){
            if(objJCC.Job_Type__c == 'Tyre - Internal' || objJCC.Job_Type__c == 'Tyre - Internal Private'){
                ETT_JobCardCloseTrgHelper.createMRInOracle(objJCC.Id);
            }
            if(objJCC.Party_Type__c == 'Customer'){
                System.debug('Customer');
                ETT_JobCardCloseTrgHelper.createJCCLinesInOracle(objJCC.Id,objJCC.createdDate,objJCC.Name);
            }else if(/*objJCC.Party_Type__c != null && */objJCC.Party_Type__c != 'Customer'){
                ETT_JobCardCloseTrgHelper.createJCCLinesInOracle(objJCC.Id,objJCC.createdDate,objJCC.Name);
            }
        }
    }

}