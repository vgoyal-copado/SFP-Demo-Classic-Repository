global with sharing class GroupStatementLineItemsByCategory implements vlocity_cmt.VlocityOpenInterface {
  public GroupStatementLineItemsByCategory() {
  }

  global Boolean invokeMethod(
    String methodName,
    Map<String, Object> inputs,
    Map<String, Object> output,
    Map<String, Object> options
  ) {
    System.debug('inside the call');

    if (methodName == 'execute') {
      System.debug('inside execute');
      System.debug(inputs);
      System.debug(inputs.get('statementLineItems'));
      // List<Object> arguments = (List<Object>) inputs.get('arguments');
      List<Object> statementLineItems = (List<Object>) inputs.get(
        'statementLineItems'
      );
      output.put('results', execute(statementLineItems));
    }
    // if (methodName == 'execute') {
    //   List<Object> arguments = (List<Object>) inputs.get('arguments');
    //   output.put('result', execute(arguments));
    // }
    return true;
  }

  public List<Object> execute(List<Object> arguments) {
    System.debug('begin loop');
    // Map<String,Object> tMap = new Map<String,Object>();
    // List<StatementCategory> scList = new List<StatementCategory>();
    List<Map<String, Object>> tList = new List<Map<String, Object>>();

    for (Object o : arguments) {
      Map<String, Object> tMap = new Map<String, Object>();
      Map<String, Object> oMap = (Map<String, Object>) o;

      //   StatementCategory sc = new StatementCategory();
      //     sc.CategoryName = (String)oMap.get('vlocity_cmt__ServiceName__c');
      //   scList.add(sc);
      String id = (String) oMap.get('Id');
      tMap.put('category', oMap.get('vlocity_cmt__Category__c'));
      tMap.put('id', id);
      tList.add(tMap);
    }
    System.debug('end loop');

    //   Object t = arguments.get(6);
    //   System.debug(t['vlocity_cmt__Category__c']);
    //   System.debug('post arguements');
    // List<Object> sourceList;

    //   Map<String, Object> sourceListContainer = (Map<String, Object>) arguments[0];

    // return (List<Object>) transformLineItems(
    //   (List<vlocity_cmt__StatementLineItem__c>) sourceList
    // );
    Map<String, Object> out = new Map<String, Object>();
    out.put('outs', tList);

    // return tList;

    return transformLineItems(arguments);
  }

  public List<Object> transformLineItems(List<Object> sli) {
    List<Object> statementCategories = new List<Object>();
    Boolean isExistingCategory;

    for (Object item : sli) {
      isExistingCategory = false;
      Map<String, Object> itemMap = (Map<String, Object>) item;

      for (Object sc : statementCategories) {
        Map<String, Object> scMap = (Map<String, Object>) sc;

        if (
          (String) itemMap.get('vlocity_cmt__Category__c') ==
          (String) scMap.get('CategoryName')
        ) {
          Decimal existingTotalAmount = (Decimal) scMap.get('TotalAmount');
          Decimal totalAmount = (Decimal) itemMap.get('vlocity_cmt__CurrencyAmount__c');
            Decimal newTotalAmount = existingTotalAmount + totalAmount;

          scMap.put('TotalAmount', newTotalAmount);

          Map<String, Object> lineItem = new Map<String, Object>();
          lineItem.put(
            'Amount',
            (Decimal) itemMap.get('vlocity_cmt__CurrencyAmount__c')
          );
          lineItem.put(
            'LineItemName',
            (String) itemMap.get('vlocity_cmt__ServiceName__c')
          );

          List<Object> lineItems = (List<Object>) scMap.get('LineItems');
          lineItems.add(lineItem);
          //   lineItems.add(lineItem);

          //   statementCategory.put('LineItems', lineItems);

          isExistingCategory = true;
          break;
        }
      }

      if (!isExistingCategory) {
        Map<String, Object> statementCategory = new Map<String, Object>();
        List<Object> lineItems = new List<Object>();

        String categoryName = (String) itemMap.get('vlocity_cmt__Category__c');
        statementCategory.put('CategoryName', categoryName);
        Decimal totalAmount = (Decimal) itemMap.get(
          'vlocity_cmt__CurrencyAmount__c'
        );
        statementCategory.put('TotalAmount', totalAmount);

        Map<String, Object> lineItem = new Map<String, Object>();
        lineItem.put(
          'Amount',
          (Decimal) itemMap.get('vlocity_cmt__CurrencyAmount__c')
        );
        lineItem.put(
          'LineItemName',
          (String) itemMap.get('vlocity_cmt__ServiceName__c')
        );
        lineItems.add(lineItem);

        statementCategory.put('LineItems', lineItems);

        statementCategories.add(statementCategory);
      }
    }
    return statementCategories;
  }

  global class StatementCategory {
    public String CategoryName { get; set; }
    public Decimal TotalAmount { get; set; }
    public List<StatementCategoryLineItem> StatementCategoryLineItemList {
      get;
      set;
    }
  }

  global class StatementCategoryLineItem {
    public string LineItemName { get; set; }
    public Decimal Amount { get; set; }
  }
}