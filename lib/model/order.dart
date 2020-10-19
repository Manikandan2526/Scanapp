class Order{

  int orderid;
  String awbno;
  String shippername;
  int noofboxesinorder;
  int orderitemid;
  int itemid;
  String itemdesc;
  int noofboxesinorderitem;
  int customerlocationid;
  int warehouseid;
  String warehousename;
  String customerorwh;
  int distributionboxes;
  int scannedboxes;
  int iscompleted;
  int isdeleted;
  
  Order({this.orderid, this.awbno,this.shippername,this.noofboxesinorder,this.orderitemid,
  this.itemid,this.itemdesc,this.noofboxesinorderitem,this.customerlocationid,
  this.warehouseid,this.warehousename,this.customerorwh,this.distributionboxes,
  this.scannedboxes,this.iscompleted,this.isdeleted});
  

  Map<String, dynamic> toMap() {
    return {
      'orderid': orderid,
      'awbno': awbno,    
      'shippername': shippername,    
      'noofboxesinorder': noofboxesinorder,   
      'orderitemid': orderitemid,
      'itemid': itemid,
      'itemdesc': itemdesc,
      'noofboxesinorderitem': noofboxesinorderitem,
      'customerlocationid': customerlocationid,
      'warehouseid': warehouseid,
      'warehousename': warehousename,
      'customerorwh': customerorwh,
      'distributionboxes': distributionboxes,
      'scannedboxes': scannedboxes,      
      'iscompleted': iscompleted, 
      'isdeleted': isdeleted
    };
  }

  //  Order.fromMap(Map map) {
  //   orderId = map[orderId];
  //   awbNo = map[awbNo];
  //   shipper = map[shipper];
  //   noOfBoxes = map[noOfBoxes];
  //   scanned = map[scanned];
  // }
  
}

class OrderScanned{

  int orderid;
  String awbno;
  int orderitemid;
  int itemid;
  int customerlocationid;
  int warehouseid;
  String uom;
  String barcode;  
  dynamic weight;
  int iscompleted;
  int isdeleted;
  
  OrderScanned({this.orderid, this.awbno,this.orderitemid,
  this.itemid,this.customerlocationid,
  this.warehouseid,this.barcode,this.weight,this.uom,
 this.iscompleted,this.isdeleted});
  

  Map<String, dynamic> toMap() {
    return {
      'orderid': orderid,
      'awbno': awbno,        
      'orderitemid': orderitemid,
      'itemid': itemid,      
      'customerlocationid': customerlocationid,
      'warehouseid': warehouseid,
       'barcode':barcode,
       'weight':weight,
       'uom':uom,
      'iscompleted': iscompleted, 
      'isdeleted': isdeleted
    };
  }

  //  Order.fromMap(Map map) {
  //   orderId = map[orderId];
  //   awbNo = map[awbNo];
  //   shipper = map[shipper];
  //   noOfBoxes = map[noOfBoxes];
  //   scanned = map[scanned];
  // }
  
}

class Manufacturer {

  int manufacturerid;
  String manufacturername;
  String defaultuom;
  String barcoderegex;
  int isbarcodecontainsweight;
  int barcodelength;
  Manufacturer({this.manufacturerid, this.manufacturername,this.defaultuom,this.barcoderegex,this.isbarcodecontainsweight
  ,this.barcodelength});
  

  Map<String, dynamic> toMap() {
    return {
      'manufacturerid': manufacturerid,
      'manufacturername': manufacturername,         
      'defaultuom': defaultuom,   
      'barcoderegex': barcoderegex,   
      'isbarcodecontainsweight': isbarcodecontainsweight,   
      'barcodelength': barcodelength,   
    };
  }

  
}