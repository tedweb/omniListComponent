global class GetPicklistValueByContact implements Callable {
    public Object call(String action, Map<String, Object> args) {

        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        return invokeMethod(action, input, output, options);
    }

    private Object invokeMethod(String methodName, Map<String,Object> input, Map<String,Object> output, Map<String,Object> option){
        System.debug(LoggingLevel.DEBUG,'***input**** ' + input);
        
        //MethodName Will be same as the value that we have mentioned while calling
        if(methodName == 'AccountNames'){
            List< Map <String, String>> UIoptions = new List< Map <String, String>>();
            for(Account acc : [Select Id, Name FROM Account ORDER BY Name LIMIT 200]){
                Map<String,String> tempMap = new Map<String,String>();
                tempMap.put('name', acc.Id);
                tempMap.put('value', acc.Name);

                UIoptions.add(tempMap);
            }
            output.put('options', UIoptions);
        }

        if(methodName == 'ContactNames'){
            String accountId = (String) input.get('accountId');

            List< Map <String, String>> UIoptions = new List< Map <String, String>>();
            for(Contact con : [Select Id, Name FROM Contact WHERE AccountId = :accountId ORDER BY Name LIMIT 200]){
                Map<String,String> tempMap = new Map<String,String>();
                tempMap.put('value', con.Id);
                tempMap.put('label', con.Name);
                UIoptions.add(tempMap);
            }
            output.put('options', UIoptions);
        }

        return true;
    }
}